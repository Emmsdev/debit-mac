import Darwin
import Foundation

public enum DarwinTraffic {
    private enum ReadError: Error {
        case system(Int32)
        case invalidMessage
    }

    public static func read() throws -> [String: TrafficBytes] {
        var route = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0]
        return try route.withUnsafeMutableBufferPointer { mib in
            for _ in 0..<3 {
                var size = 0
                guard sysctl(mib.baseAddress, u_int(mib.count), nil, &size, nil, 0) == 0 else {
                    throw ReadError.system(errno)
                }
                guard size > 0 else { return [:] }
                var buffer = [UInt8](repeating: 0, count: size)
                let result = buffer.withUnsafeMutableBytes { bytes in
                    sysctl(mib.baseAddress, u_int(mib.count), bytes.baseAddress, &size, nil, 0)
                }
                if result == 0 {
                    return try buffer.withUnsafeBytes {
                        try parse(UnsafeRawBufferPointer(rebasing: $0.prefix(size)))
                    }
                }
                if errno != ENOMEM { throw ReadError.system(errno) }
            }
            throw ReadError.system(ENOMEM)
        }
    }

    private static func parse(_ bytes: UnsafeRawBufferPointer) throws -> [String: TrafficBytes] {
        var result: [String: TrafficBytes] = [:]
        var cursor = 0
        while cursor < bytes.count {
            // Routing messages share a two-byte length, version and type.
            guard bytes.count - cursor >= 4 else { throw ReadError.invalidMessage }
            let length = Int(bytes.loadUnaligned(fromByteOffset: cursor, as: UInt16.self))
            guard length >= 4, length <= bytes.count - cursor else { throw ReadError.invalidMessage }
            defer { cursor += length }

            guard bytes[cursor + 2] == RTM_VERSION, bytes[cursor + 3] == RTM_IFINFO2 else { continue }
            guard length >= MemoryLayout<if_msghdr2>.size else { throw ReadError.invalidMessage }
            let header = bytes.loadUnaligned(fromByteOffset: cursor, as: if_msghdr2.self)
            guard header.ifm_data.ifi_type == IFT_ETHER,
                  let name = interfaceName(index: UInt32(header.ifm_index)),
                  name.hasPrefix("en"),
                  !name.dropFirst(2).isEmpty,
                  name.dropFirst(2).allSatisfy(\.isNumber)
            else { continue }

            result["\(name)#\(header.ifm_index)"] = TrafficBytes(
                received: header.ifm_data.ifi_ibytes,
                sent: header.ifm_data.ifi_obytes
            )
        }
        return result
    }

    private static func interfaceName(index: UInt32) -> String? {
        var name = [CChar](repeating: 0, count: Int(IF_NAMESIZE))
        return name.withUnsafeMutableBufferPointer { buffer in
            guard let base = buffer.baseAddress, if_indextoname(index, base) != nil else { return nil }
            return String(validatingCString: base)
        }
    }
}
