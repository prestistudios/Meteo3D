# Meteo3D

Une application iOS météo en SwiftUI qui transforme les conditions actuelles en
une petite scène 3D animée.

## Fonctionnalités

- météo actuelle et prévisions sur 7 jours ;
- recherche de villes dans le monde ;
- scène 3D procédurale : soleil, nuages, pluie et neige ;
- rotation de la scène au toucher ;
- aucune clé API et aucune dépendance externe ;
- interface en français, mode sombre inclus.

## Démarrage

1. Ouvrez `Meteo3D.xcodeproj` avec Xcode 26 ou plus récent.
2. Choisissez un simulateur iOS 17+ ou **My Mac (Mac Catalyst)**.
3. Lancez l’application avec `⌘R`.

Le projet utilise [Open-Meteo](https://open-meteo.com/) pour les prévisions et
le géocodage. L’accès gratuit sans clé est destiné aux usages non commerciaux ;
l’attribution des données doit être conservée.

## Architecture

- `Models` : modèles métier et décodage des réponses ;
- `Services` : client HTTP Open-Meteo ;
- `ViewModels` : état, recherche et chargement ;
- `Views` : vues SwiftUI et scène SceneKit.

## Confidentialité

L’application n’utilise pas la position GPS et ne collecte aucune donnée
personnelle. Seuls le nom de ville recherché et les coordonnées du résultat
choisi sont envoyés à Open-Meteo.

## Licence

MIT. Les données météo restent soumises à la licence et aux conditions
d’Open-Meteo.
