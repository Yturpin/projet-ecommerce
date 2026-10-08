# Projet e-commerce : analyse SQL d'une plateforme de vente

Projet de groupe du cours « Bases de données relationnelles » (Efrei, M1 Data et IA), réalisé entièrement en SQL avec PostgreSQL.

**Groupe 3 (comptes GitHub) :** `Yturpin`, `Yacine2512`, `Aksal04`, `Ragna2024`, `touria123`, `nirzara13`

## Contenu du dépôt

| Fichier | Rôle |
|---------|------|
| `create_schema.sql` | Crée les 4 tables : `client`, `produit`, `commande`, `ligne_commande` |
| `seed_ecommerce.sql` | Données fournies par l'enseignant. Ne pas modifier |
| `analysis.sql` | Toutes les requêtes d'analyse : exercices 1 à 15 et 3 analyses libres |
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

Pour vérifier que le chargement s'est bien passé :

```bash
psql -U {username} -d ecommerce_db -c "SELECT COUNT(*) FROM client;"
```

Volumes attendus : 100 clients, 65 produits, 500 commandes et 1 547 lignes de commande. La requête 15.A.1 de `analysis.sql` affiche ces quatre nombres.

### 4. Exécuter les analyses

```bash
psql -U {username} -d ecommerce_db -f analysis.sql
```

Pour enregistrer les résultats dans un fichier texte :

```bash
psql -U {username} -d ecommerce_db -f analysis.sql > resultats.txt
```

Le fichier peut être relancé plusieurs fois : les tables qu'il crée (`montant_commandes`, `ca_mensuel`, `synthese_mensuelle`) sont supprimées puis recréées à chaque exécution.

### Encodage sous Windows

Les fichiers SQL sont encodés en UTF-8 et contiennent des accents (statuts `payée`, `expédiée`, `livrée`, `annulée`). Sous Windows, il faut lancer psql depuis un terminal en UTF-8 (terminal de VS Code, ou `chcp 65001` dans l'invite de commandes) et exécuter `SET client_encoding = 'UTF8';` après la connexion. Sans cela, le filtre `statut <> 'annulée'` ne fonctionne pas et les commandes annulées sont comptées dans le chiffre d'affaires.

### Repartir de zéro

```bash
dropdb -U {username} ecommerce_db
```

puis reprendre à l'étape 1.

## Règle de calcul

Le montant d'une ligne correspond à la quantité multipliée par le prix effectivement payé (`quantite * prix_unitaire`). Les commandes au statut `annulée` sont exclues du chiffre d'affaires, des quantités vendues et du panier moyen.

## Principales conclusions

Les données couvrent l'année 2025.

**Activité globale**

- Chiffre d'affaires : 617 494,76 € pour 484 commandes non annulées, soit un panier moyen de 1 275,82 €.
- 90 clients actifs sur 100 inscrits. 10 clients n'ont jamais passé de commande.
- Taux d'annulation : 3,2 % (16 commandes sur 500).

**Produits et catégories**

- Le Sport est la première catégorie (162 149,83 €, 26,3 % du CA), l'Audio la dernière (81 758,76 €, 13,2 %). L'Informatique est la catégorie qui vend le plus d'unités (1 051).
- Produit le plus vendu en quantité : Montre sport 1 (101 unités). Produit qui génère le plus de CA : Sac à dos 1 (24 925,47 €).
- 5 produits n'ont jamais été vendus, un par catégorie. Ils immobilisent 22 296,30 € de stock.

**Commandes et clients**

- Les gros paniers (1 500 € ou plus) représentent 38 % des commandes mais 64 % du CA. Les petits paniers (moins de 500 €) représentent 1 commande sur 5 et seulement 5 % du CA.
- Le meilleur client a généré 17 169,00 € en 11 commandes.

**Évolution dans le temps**

- Mai est le meilleur mois (68 841,64 €), janvier le plus faible (34 765,36 €).
- L'activité est en hausse : le CA du 2e semestre dépasse celui du 1er de 13 %, alors que le nombre de commandes est stable (244 puis 240). La hausse vient du panier moyen.
- Avec une seule année de données, on ne peut pas conclure à une saisonnalité.

**Qualité des données**

- 30 commandes ont une date antérieure à la date d'inscription de leur client. Elles concernent 12 clients : c'est plus probablement la date d'inscription qui est erronée.
- Aucune valeur manquante dans les 4 tables.

**Analyses libres**

- Stock : 4 produits qui se vendent bien risquent la rupture, dont 3 sont déjà à zéro (Lampe 2, Souris 2, Sweat 1).
- Remises : plus d'une ligne sur deux est vendue avec une remise. Elles représentent 40 350,04 €, soit 6,1 % du CA potentiel, sans effet visible sur les quantités achetées.
- Villes : à nombre de clients égal, le CA varie du simple au double (83 721,92 € à Montpellier, 40 273,45 € à Strasbourg). L'écart vient surtout du nombre de commandes.

Le détail des requêtes, des résultats et des interprétations se trouve en commentaire dans `analysis.sql`.
