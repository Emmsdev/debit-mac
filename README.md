# Débit Mac

Débit Mac est une application gratuite pour suivre le débit et la consommation réseau dans la barre des menus. Elle fonctionne sur les Mac Intel et Apple Silicon à partir de macOS 14. Le panneau utilise le Liquid Glass natif sur macOS 26.

[**Télécharger Débit Mac**](https://github.com/Emmsdev/debit-mac/releases/latest/download/Debit-Mac.dmg) · [Versions et archive ZIP](https://github.com/Emmsdev/debit-mac/releases)

## Installer

1. Télécharge et ouvre `Debit-Mac.dmg`.
2. Glisse **Débit Mac** vers **Applications**.
3. Ouvre **Débit Mac** depuis **Applications**. Un clic sur les valeurs ↓ et ↑ dans la barre des menus ouvre le panneau.

La version distribuée est signée localement et sans notarisation Apple. Si macOS bloque l’ouverture d’une copie téléchargée depuis ce dépôt, consulte la procédure de confirmation dans **Réglages Système → Confidentialité et sécurité**. [Assistance Apple](https://support.apple.com/fr-fr/102445)

## Utiliser

- Vois le débit descendant et montant en Mb/s et une courbe du trafic récent.
- Consulte la consommation du jour et du mois, séparée entre réception et envoi.
- Active **Ouvrir à la connexion** pour lancer l’app automatiquement à l’ouverture de session.
- Clique trois fois sur **Réinitialiser les cumuls** pour les remettre à zéro.

L’app mesure les octets échangés sur le Wi-Fi et l’Ethernet du Mac pendant qu’elle tourne, trafic local compris. Les cumuls restent sur le Mac.

## Compiler

Avec Xcode et Swift 6, exécute `swift test` pour les tests, `./script/build_and_run.sh --verify` pour lancer l’app et `./script/build_and_run.sh --package` pour créer une app universelle dans `dist/`.
