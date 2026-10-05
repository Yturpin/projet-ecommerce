# Projet e-commerce : analyse SQL d'une plateforme de vente

Projet de groupe du cours « Bases de données relationnelles » (Efrei, M1 Data et IA), réalisé entièrement en SQL avec PostgreSQL.

**Groupe 3 :** à compléter (noms des membres)

## Contenu du dépôt

| Fichier | Rôle |
|---------|------|
| `create_schema.sql` | Crée les 4 tables : `client`, `produit`, `commande`, `ligne_commande` |
| `seed_ecommerce.sql` | Données fournies par l'enseignant. Ne pas modifier |
| `analysis.sql` | Toutes les requêtes d'analyse, exercices 1 à 15 et analyse libre |
| `README.md` | Ce fichier |

## Prérequis

- PostgreSQL installé et démarré
- `psql` disponible dans le terminal
- Un rôle PostgreSQL, noté `{username}` dans les commandes ci-dessous

## Installation

Toutes les commandes se lancent depuis la racine du dépôt.

### 1. Créer la base

```bash
createdb -U {username} ecommerce_db
```

### 2. Créer les tables

```bash
psql -U {username} -d ecommerce_db -f create_schema.sql
```

### 3. Charger les données

```bash
psql -U {username} -d ecommerce_db -f seed_ecommerce.sql
```

Le fichier de données doit être exécuté après la création des tables.

### 4. Exécuter les analyses

```bash
psql -U {username} -d ecommerce_db -f analysis.sql
```

Pour enregistrer les résultats dans un fichier texte :

```bash
psql -U {username} -d ecommerce_db -f analysis.sql > resultats.txt
```

### Repartir de zéro

```bash
dropdb -U {username} ecommerce_db
```

puis reprendre à l'étape 1.

## Principales conclusions

À compléter une fois les analyses terminées.

## Travailler à plusieurs

La branche `main` contient toujours une version qui fonctionne. Personne ne travaille directement dessus : chacun passe par une branche, puis une pull request.

### Première fois

```bash
git clone <url-du-depot>
cd projet-ecommerce
```

### À chaque session de travail

```bash
# 1. Récupérer le travail des autres
git switch main
git pull

# 2. Créer sa branche, nommée d'après la partie traitée
git switch -c partie3-exercices-1-5

# 3. Travailler, puis vérifier que le fichier s'exécute sans erreur
psql -U {username} -d ecommerce_db -f analysis.sql

# 4. Enregistrer et envoyer
git add analysis.sql
git commit -m "Ajouter les exercices 1 à 5"
git push -u origin partie3-exercices-1-5
```

Ouvrir ensuite une pull request sur GitHub, la faire relire par un autre membre, puis la fusionner dans `main`.

### Règles du groupe

- Un commit correspond à un changement cohérent, avec un message qui dit ce qui a été fait.
- Dans `analysis.sql`, chacun écrit sous l'en-tête de son exercice, sans toucher aux autres sections. Cela évite les conflits de fusion.
- Avant de commencer, toujours faire `git pull` sur `main`.
- Ne jamais versionner de mot de passe ni de fichier `.env`.
- En cas de conflit de fusion, prévenir le groupe avant de forcer quoi que ce soit. Pas de `git push --force` sur `main`.

### Répartition

| Partie | Responsable | État |
|--------|-------------|------|
| 1. Modélisation (`create_schema.sql`) | | À faire |
| 2. Chargement et vérification | | À faire |
| 3. Analyse SQL (exercices 1 à 10) | | À faire |
| 4. Transformation (exercices 11 et 12) | | À faire |
| 5. Qualité des données (exercices 13 et 14) | | À faire |
| 6. Tableau de bord (exercice 15) | | À faire |
| 7. Analyse libre | | À faire |
| README et conclusions | | À faire |
