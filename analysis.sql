-- =============================================================================
-- Projet e-commerce : analyses SQL (Parties 3 à 7)
-- Lancer : psql -U {username} -d ecommerce_db -f analysis.sql
-- =============================================================================
-- Règle de calcul du sujet :
--   montant d'une ligne = quantite * prix_unitaire (prix effectivement payé)
--   les commandes au statut « annulée » sont exclues du chiffre d'affaires,
--   des quantités vendues et du panier moyen.
-- =============================================================================

\pset pager off

-- =============================================================================
-- PARTIE 3 : ANALYSE SQL
-- =============================================================================

\echo
\echo '=== Exercice 1. Explorer les produits ==='
SELECT nom, categorie , prix, stock FROM produit
ORDER BY categorie, nom;

SELECT nom, categorie , prix, stock  FROM produit
WHERE prix > 100
ORDER BY prix DESC;

\echo '=== Exercice 2. Explorer les clients ==='
SELECT * FROM client
WHERE ville='Paris'
ORDER BY nom, prenom;

SELECT ville, COUNT(*) AS nombre_clients
FROM client
GROUP BY ville
ORDER BY nombre_clients DESC,ville;

\echo '=== Exercice 3. Explorer les commandes ==='
SELECT c.id AS commande_id, c.date_commande, c.statut, cl.id AS client_id,cl.nom, cl.prenom, cl.email, cl.ville, cl.date_inscription
FROM commande AS c
JOIN client AS cl ON c.client_id = cl.id
ORDER BY c.date_commande, c.id;

\echo '=== Exercice 4. Montant d une ligne ==='
SELECT id, commande_id, produit_id, quantite, prix_unitaire, quantite * prix_unitaire AS montant_ligne
FROM ligne_commande
ORDER BY commande_id, id;

\echo '=== Exercice 5. Montant des commandes ==='
SELECT c.id , c.date_commande, c.statut,
    COALESCE(
        SUM(lc.quantite * lc.prix_unitaire),
        0
    ) AS montant_total
FROM commande AS c
LEFT JOIN ligne_commande AS lc ON lc.commande_id = c.id
GROUP BY c.id, c.date_commande, c.statut
ORDER BY c.id;

\echo '=== Exercice 6. Chiffre d affaires par categorie ==='
SELECT p.categorie, SUM(lc.quantite * lc.prix_unitaire) AS chiffre_affaires, SUM(lc.quantite) AS quantite_vendue
FROM produit AS p
JOIN ligne_commande AS lc ON lc.produit_id = p.id
JOIN commande AS c ON c.id = lc.commande_id
WHERE c.statut <> 'annulée'
GROUP BY p.categorie
ORDER BY chiffre_affaires DESC;

\echo '=== Exercice 7. Produits les plus vendus ==='
SELECT p.id, p.nom, p.categorie, SUM(lc.quantite) AS quantite_vendue
FROM produit AS p
JOIN ligne_commande AS lc ON lc.produit_id = p.id
JOIN commande AS c ON c.id = lc.commande_id
WHERE c.statut <> 'annulée'
GROUP BY p.id, p.nom, p.categorie
ORDER BY quantite_vendue DESC, p.id
LIMIT 10;

\echo '=== Exercice 8. Produits generant le plus de chiffre d affaires ==='
SELECT p.id, p.nom, p.categorie, SUM(lc.quantite * lc.prix_unitaire) AS chiffre_affaires
FROM produit AS p
JOIN ligne_commande AS lc ON lc.produit_id = p.id
JOIN commande AS c ON c.id = lc.commande_id
WHERE c.statut <> 'annulée'
GROUP BY p.id, p.nom, p.categorie
ORDER BY chiffre_affaires DESC, p.id;

\echo '=== Exercice 9. Clients ==='
-- Choix : nombre_commandes compte toutes les commandes passées par le client,
-- y compris les annulées (elles ont bien été passées). Le montant dépensé, lui,
-- exclut les commandes annulées, conformément à la règle de calcul.
-- LEFT JOIN : on garde aussi les clients sans commande (montant à 0).
SELECT cl.id, cl.nom, cl.prenom, COUNT(DISTINCT c.id) AS nombre_commandes,
    COALESCE( SUM( CASE
                WHEN c.statut <> 'annulée'
                THEN lc.quantite * lc.prix_unitaire
                ELSE 0
            END ), 0) AS montant_total_depense
FROM client AS cl
LEFT JOIN commande AS c ON c.client_id = cl.id
LEFT JOIN ligne_commande AS lc ON lc.commande_id = c.id
GROUP BY cl.id, cl.nom, cl.prenom
ORDER BY montant_total_depense DESC, cl.id;

SELECT cl.id, cl.nom, cl.prenom, cl.email FROM client AS cl
WHERE NOT EXISTS ( SELECT 1 FROM commande AS c WHERE c.client_id = cl.id )
ORDER BY cl.id;

\echo '=== Exercice 10. Panier moyen ==='
-- Différence entre les trois indicateurs (hors commandes annulées) :
-- - chiffre d'affaires : somme des montants de toutes les commandes (617 494,76 €) ;
-- - nombre de commandes : combien de commandes ont été passées (484) ;
-- - panier moyen : montant moyen d'une commande, soit le chiffre d'affaires
--   divisé par le nombre de commandes (617 494,76 / 484 = 1 275,82 €).
-- Le CA peut donc augmenter de deux façons : plus de commandes, ou des
-- commandes plus importantes (panier moyen plus élevé).
-- La première requête donne le panier moyen de la plateforme, la seconde
-- le panier moyen par mois.
WITH montants_commandes AS ( SELECT c.id, SUM(lc.quantite * lc.prix_unitaire) AS montant_total
FROM commande AS c
JOIN ligne_commande AS lc ON lc.commande_id = c.id
WHERE c.statut <> 'annulée'
GROUP BY c.id
)
SELECT SUM(montant_total) AS chiffre_affaires, COUNT(*) AS nombre_commandes, ROUND(AVG(montant_total), 2) AS panier_moyen
FROM montants_commandes;



WITH montants_commandes AS ( SELECT c.id, c.date_commande, SUM(lc.quantite * lc.prix_unitaire) AS montant_total
FROM commande AS c
JOIN ligne_commande AS lc ON lc.commande_id = c.id
WHERE c.statut <> 'annulée'
GROUP BY c.id, c.date_commande 
)
SELECT DATE_TRUNC('month', date_commande)::DATE AS mois, COUNT(*) AS nombre_commandes, SUM(montant_total) AS chiffre_affaires,
ROUND(AVG(montant_total), 2) AS panier_moyen
FROM montants_commandes
GROUP BY DATE_TRUNC('month', date_commande)::DATE
ORDER BY mois;

-- =============================================================================
-- PARTIE 4 : TRANSFORMATION DES DONNÉES
-- =============================================================================

\echo '=== Exercice 11. Categoriser les commandes ==='
--===========================================
--  > ⚠️ **Encodage (Windows)** : les fichiers SQL sont encodés en UTF-8 et contiennent
--  > des accents (statuts `payée`, `expédiée`, `livrée`, `annulée`). Avant de charger
--  > les données, il faut s'assurer que psql utilise le même encodage :
--  >
--  > - lancer psql depuis un terminal en UTF-8 (par exemple le terminal de VS Code,
--  >   ou `chcp 65001` dans l'invite de commandes Windows) ;
--  > - exécuter `SET client_encoding = 'UTF8';` après chaque connexion à la base.

-- > Sans cette précaution, les filtres sur le statut (`statut <> 'annulée'`) ne
--> fonctionnent pas et les commandes annulées sont comptées dans le chiffre d'affaires.

-- Exercice 11 — Catégoriser les commandes
-- Étape 1 : on stocke le montant de chaque commande dans une table
-- intermédiaire (CREATE TABLE ... AS SELECT, vu en cours).
-- Le DROP permet de réexécuter le fichier sans erreur.

DROP TABLE IF EXISTS montant_commandes;
CREATE TABLE montant_commandes AS
SELECT
    c.id AS commande_id,
    c.client_id,
    c.date_commande,
    c.statut,
    SUM(l.quantite * l.prix_unitaire) AS montant_total
FROM commande c
INNER JOIN ligne_commande l ON l.commande_id = c.id
WHERE c.statut <> 'annulée'  -- on ne prend pas en compte les commandes annulées, le <> veut dire différent de
GROUP BY c.id, c.client_id, c.date_commande, c.statut;

-- Étape 2 : on catégorise chaque commande avec CASE WHEN
SELECT
    commande_id,
    date_commande,
    statut,
    montant_total,
    CASE
        WHEN montant_total IS NULL THEN 'Non calculable'
        WHEN montant_total < 500   THEN 'Petit panier'
        WHEN montant_total < 1500  THEN 'Panier moyen'
        ELSE 'Gros panier'
    END AS categorie_panier
FROM montant_commandes
ORDER BY montant_total DESC;

-- Étape 3 : nombre de commandes par catégorie
-- (PostgreSQL accepte l'alias dans le GROUP BY, comme vu en cours)
SELECT
    CASE
        WHEN montant_total IS NULL THEN 'Non calculable'
        WHEN montant_total < 500   THEN 'Petit panier'
        WHEN montant_total < 1500  THEN 'Panier moyen'
        ELSE 'Gros panier'
    END AS nb_categorie_panier,
    COUNT(*)           AS nb_commandes,
    SUM(montant_total) AS chiffre_affaires
FROM montant_commandes
GROUP BY nb_categorie_panier
ORDER BY chiffre_affaires DESC;



-- OBSERVATIONS :
-- Répartition des 484 commandes non annulées (CA total : 617 494,76 €) :
--
--   Catégorie      | Commandes        | Chiffre d'affaires
--   Gros panier    | 184 (38 %)       | 394 973,39 € (64 %)
--   Panier moyen   | 201 (41,5 %)     | 192 525,62 € (31 %)
--   Petit panier   |  99 (20,5 %)     |  29 995,75 € (5 %)
--
-- - Les paniers moyens sont les plus nombreux, mais ce sont les gros paniers
--   qui génèrent l'essentiel du chiffre d'affaires : 38 % des commandes
--   représentent près des deux tiers du CA.
-- - À l'inverse, les petits paniers représentent 1 commande sur 5 mais
--   seulement 5 % du CA.
--
-- Intérêt pour l'entreprise :
-- - Le CA dépend fortement des grosses commandes : perdre quelques clients
--   qui passent ce type de commande aurait un impact important.
-- - Il serait utile de fidéliser ces clients (offres dédiées, suivi
--   personnalisé) et d'essayer de faire monter les paniers moyens vers les
--   gros paniers (produits complémentaires, frais de port offerts au-delà
--   d'un seuil etc...).

\echo '=== Exercice 12. Analyse temporelle ==='
-- =====================================================================
-- Exercice 12 — Analyse temporelle du chiffre d'affaires
-- =====================================================================
-- Objectif : comparer les ventes selon les périodes pour identifier
-- les périodes les plus et les moins importantes, ainsi que
-- l'évolution générale de l'activité.
--
-- Méthode : on calcule une seule fois les indicateurs par mois et on
-- les stocke dans une table intermédiaire (CREATE TABLE ca_mensuel ... AS SELECT).
-- Toutes les requêtes suivantes s'appuient sur cette table, ce qui
-- évite de répéter le même calcul.
-- Les commandes annulées sont exclues, conformément à la règle de calcul.

DROP TABLE IF EXISTS ca_mensuel;

CREATE TABLE ca_mensuel AS
SELECT
    TO_CHAR(c.date_commande, 'YYYY-MM') AS mois,
    COUNT(DISTINCT c.id)                AS nb_commandes,
    SUM(l.quantite * l.prix_unitaire)   AS chiffre_affaires,
    ROUND(SUM(l.quantite * l.prix_unitaire)
          / NULLIF(COUNT(DISTINCT c.id), 0), 2) AS panier_moyen
FROM commande c
INNER JOIN ligne_commande l ON l.commande_id = c.id
WHERE c.statut <> 'annulée'
GROUP BY TO_CHAR(c.date_commande, 'YYYY-MM');

-- 12.1 — Évolution chronologique, mois par mois
SELECT *
FROM ca_mensuel
ORDER BY mois;

-- 12.2 — Les 6 mois les plus importants (CA le plus élevé)
SELECT mois, chiffre_affaires, nb_commandes
FROM ca_mensuel
ORDER BY chiffre_affaires DESC
LIMIT 6;

-- 12.3 — Les 6 mois les moins importants (CA le plus faible)
SELECT mois, chiffre_affaires, nb_commandes
FROM ca_mensuel
ORDER BY chiffre_affaires ASC
LIMIT 6;

-- 12.4 — Évolution générale : comparaison des deux semestres
-- On classe chaque mois dans un semestre avec CASE WHEN.
-- Si le CA du 2e semestre est supérieur au 1er, l'activité est en hausse.
SELECT
    CASE
        WHEN SUBSTRING(mois FROM 6 FOR 2) <= '06' THEN LEFT(mois, 4) || ' - 1er semestre'
        ELSE LEFT(mois, 4) || ' - 2e semestre'
    END AS semestre,
    SUM(nb_commandes)     AS nb_commandes,
    SUM(chiffre_affaires) AS chiffre_affaires
FROM ca_mensuel
GROUP BY semestre
ORDER BY semestre;

-- Remarques :
-- - La table ca_mensuel n'est pas mise à jour automatiquement si de
--   nouvelles commandes sont ajoutées : elle est recréée à chaque
--   exécution du fichier grâce au DROP TABLE IF EXISTS.



-- OBSERVATIONS :
-- - Périodes les plus importantes : mai (68 841,64 €, 54 commandes),
--   août (65 441,63 €, 50 commandes) ,juin (58782.33 €, 46 commandes) et décembre (60 655,34 €, 42 commandes).

-- - Périodes les moins importantes : janvier (34 765,36 €, 29 commandes),
--   avril (35 932,15 €, 34 commandes), septembre (40 578,54 €, 36 commandes) et février (44 673,74 €, 44 commandes).
--   Le meilleur mois (mai) génère presque deux fois plus de CA que le plus
--   faible (janvier).
--
-- - Évolution générale : l'activité est en hausse. Le CA passe de
--   289 837,21 € au 1er semestre à 327 657,55 € au 2e semestre (+13 %).
--   Pourtant, le nombre de commandes est quasiment stable (244 puis 240).
--   La hausse vient donc du panier moyen, qui passe d'environ 1 188 € à
--   1 365 € (+15 %) : les clients ne commandent pas plus souvent, mais
--   dépensent davantage par commande.
--
-- - Le CA varie-t-il à cause du nombre de commandes ou du panier moyen ?
--   Les deux, selon les mois :
--   * Mai est porté par le volume : c'est le mois avec le plus de commandes
--     (54), pour un panier moyen dans la moyenne (1 274,85 €).
--   * Octobre est porté par le panier moyen : seulement 34 commandes, mais le
--     panier moyen le plus élevé de l'année (1 578,81 €).
--   * Avril et octobre ont le même nombre de commandes (34), mais le CA
--     d'octobre est environ 50 % plus élevé, uniquement grâce au panier moyen.
--   * Décembre combine un bon volume et un panier élevé (1 444,17 €), ce qui
--     peut s'expliquer par les achats de fin d'année.
--
-- Limite : les données ne couvrent qu'une seule année (2025). On ne peut donc
-- pas affirmer qu'il s'agit d'une saisonnalité qui se répète chaque année :
-- il faudrait plusieurs années de données pour le confirmer.

-- =============================================================================
-- PARTIE 5 : QUALITÉ DES DONNÉES
-- =============================================================================

\echo '=== Exercice 13. Commandes anterieures a l inscription du client ==='
-- Exercice 13 — Détecter une incohérence
-- Règle : un client ne peut pas commander avant de s'être inscrit.
-- Cette règle compare deux tables (commande et client) : elle ne peut
-- donc pas être imposée par une simple contrainte CHECK, qui ne porte
-- que sur une seule ligne d'une seule table. On la vérifie donc avec
-- une requête de détection.

-- 13.1 — Liste des anomalies
SELECT
    c.id                               AS commande_id,
    cl.id                              AS client_id,
    c.date_commande,
    cl.date_inscription,
    cl.date_inscription - c.date_commande AS jours_d_ecart,
    c.statut
FROM commande c
INNER JOIN client cl ON c.client_id = cl.id
WHERE c.date_commande < cl.date_inscription
ORDER BY jours_d_ecart DESC;


--Voici ce que l'on obtient avec les données actuelles (30 anomalies détectées) :
--  commande_id | client_id | date_commande | date_inscription | jours_d_ecart |  statut
-------------+-----------+---------------+------------------+---------------+----------
--          493 |        68 | 2025-01-20    | 2025-08-02       |           194 | expédiée
--          366 |        77 | 2025-01-02    | 2025-06-01       |           150 | livrée
--           35 |        68 | 2025-03-22    | 2025-08-02       |           133 | livrée
--          429 |        77 | 2025-01-29    | 2025-06-01       |           123 | livrée
--          326 |        57 | 2025-01-18    | 2025-05-17       |           119 | expédiée
--          151 |        49 | 2025-05-23    | 2025-09-07       |           107 | payée
--          416 |        68 | 2025-04-21    | 2025-08-02       |           103 | livrée
--          381 |        57 | 2025-02-07    | 2025-05-17       |            99 | payée
--          293 |        49 | 2025-06-12    | 2025-09-07       |            87 | expédiée
--          153 |        61 | 2025-01-10    | 2025-04-06       |            86 | expédiée
--          286 |        57 | 2025-02-21    | 2025-05-17       |            85 | livrée
--          202 |        13 | 2025-04-10    | 2025-07-02       |            83 | livrée
--          256 |        67 | 2025-07-05    | 2025-09-23       |            80 | expédiée
--           47 |        73 | 2025-02-21    | 2025-04-29       |            67 | livrée
--            8 |        76 | 2025-04-23    | 2025-06-25       |            63 | livrée
--          282 |        49 | 2025-07-17    | 2025-09-07       |            52 | annulée
--          199 |        89 | 2025-04-05    | 2025-05-25       |            50 | livrée
--          164 |        49 | 2025-07-23    | 2025-09-07       |            46 | payée
--            3 |        89 | 2025-04-13    | 2025-05-25       |            42 | expédiée
--          178 |        76 | 2025-05-18    | 2025-06-25       |            38 | livrée
--          194 |        68 | 2025-06-26    | 2025-08-02       |            37 | livrée
--          198 |        41 | 2025-03-03    | 2025-04-05       |            33 | expédiée
--          392 |        13 | 2025-06-10    | 2025-07-02       |            22 | livrée
--          192 |        89 | 2025-05-05    | 2025-05-25       |            20 | livrée
--          218 |        49 | 2025-08-19    | 2025-09-07       |            19 | payée
--          127 |        67 | 2025-09-06    | 2025-09-23       |            17 | expédiée
--          312 |        89 | 2025-05-09    | 2025-05-25       |            16 | livrée
--          159 |        73 | 2025-04-22    | 2025-04-29       |             7 | livrée
--          285 |        76 | 2025-06-19    | 2025-06-25       |             6 | payée
--          142 |        63 | 2025-01-15    | 2025-01-17       |             2 | livrée
-- (30 rows)

-- 13.2 — Nombre d'anomalies détectées
SELECT COUNT(*) AS nb_anomalies
FROM commande c
INNER JOIN client cl ON c.client_id = cl.id
WHERE c.date_commande < cl.date_inscription;

-- OBSERVATIONS :
-- - 30 anomalies détectées : 30 commandes ont une date antérieure à la date
--   d'inscription de leur client (résultat de la requête 13.2).
-- - Les écarts vont de 2 jours (commande 142) à 194 jours (commande 493).
-- - Ces anomalies ne concernent que 12 clients, dont la plupart ont plusieurs
--   commandes en anomalie (jusqu'à 5 pour le client 49, 4 pour les clients
--   68 et 89). Pour un même client, toutes les commandes concernées sont
--   antérieures à la même date d'inscription : c'est donc plus probablement
--   la date d'inscription qui est erronée que les dates de commande.
-- - Une seule de ces commandes est annulée (commande 282). Les 29 autres
--   sont donc incluses dans le calcul du chiffre d'affaires.
--
-- Causes possibles :
-- - date d'inscription écrasée lors d'une mise à jour du compte client
--   (réinscription, changement d'email, migration de données) ;
-- - commandes passées sans compte (en tant qu'invité), puis rattachées
--   au compte créé plus tard. Dans ce cas, il ne s'agirait pas d'une erreur
--   mais d'un fonctionnement normal du site.
--
-- Choix : ces commandes sont conservées dans le calcul du chiffre
-- d'affaires, car rien n'indique qu'elles n'ont pas eu lieu. En revanche,
-- les dates d'inscription des 12 clients concernés devraient être vérifiées.

\echo '=== Exercice 14. Produits sans vente ==='
-- Exercice 14 — Produits sans vente :
-- 14.1 — Produits qui n'apparaissent dans AUCUNE commande
-- LEFT JOIN : on garde tous les produits, même sans ligne de commande.
-- WHERE l.id IS NULL : on ne garde que ceux sans correspondance.

SELECT p.nom , p.categorie, p.prix , p.stock
FROM produit p
LEFT JOIN ligne_commande lc
    ON p.id = lc.produit_id
WHERE lc.produit_id IS NULL;


-- 14.2 — Produits jamais vendus dans une commande VALIDE
-- (inclut aussi les produits présents uniquement dans des commandes
-- annulées, qui n'ont donc jamais réellement été vendus).
-- Le filtre sur le statut est dans le ON pour ne pas casser le LEFT JOIN.
-- COUNT(c.id) ne compte que les commandes valides (il ignore les NULL).
SELECT
    p.nom       AS produit,
    p.categorie,
    p.prix,
    p.stock
FROM produit p
LEFT JOIN ligne_commande l ON l.produit_id = p.id
LEFT JOIN commande c       ON c.id = l.commande_id AND c.statut <> 'annulée'
GROUP BY p.id, p.nom, p.categorie, p.prix, p.stock
HAVING COUNT(c.id) = 0
ORDER BY p.categorie, p.nom;

-- 14.3 — Valeur totale du stock des produits jamais vendus
-- (valeur calculée au prix de vente actuel)
SELECT
    COUNT(*)              AS nb_produits_sans_vente,
    SUM(p.prix * p.stock) AS valeur_stock_immobilise
FROM produit p
LEFT JOIN ligne_commande l ON l.produit_id = p.id
WHERE l.id IS NULL;

-- OBSERVATIONS :
-- - 5 produits n'ont jamais été commandés : Platine vinyle 1 (Audio),
--   Imprimante 1 (Informatique), Grille-pain 1 (Maison), Chemise 1 (Mode)
--   et Corde à sauter 1 (Sport).
-- - Les requêtes 14.1 et 14.2 renvoient les mêmes produits : aucun produit
--   n'a été commandé uniquement dans des commandes annulées. Ces 5 produits
--   n'apparaissent dans aucune commande.
-- - Il y a exactement un produit invendu dans chaque catégorie, ce qui
--   pourrait correspondre à des produits récemment ajoutés au catalogue
--   (à vérifier avec les équipes concernées).
-- - Valeur totale du stock de ces produits : 22 296,30 € (requête 14.3),
--   calculée au prix de vente actuel. L'Imprimante 1 représente à elle
--   seule 7 975,80 €, soit plus d'un tiers de ce montant.
--
-- Intérêt pour l'entreprise :
-- - Ces produits immobilisent du stock, donc de l'argent, sans générer
--   de chiffre d'affaires.
-- - Cela peut révéler un prix trop élevé, un manque de visibilité sur
--   le site, un produit récemment ajouté, ou un produit qui ne
--   correspond pas à la demande.
-- - Actions possibles : promotion, révision du prix, mise en avant sur le
--   site, arrêt du réapprovisionnement ou retrait du catalogue.
-- - Réussir à vendre ces produits permettrait aussi d'obtenir de premiers
--   avis clients, qui rassurent les futurs acheteurs et peuvent relancer
--   les ventes.

-- =============================================================================
-- PARTIE 6 : TABLEAU DE BORD EN SQL
-- =============================================================================

\echo '=== Exercice 15.A. Exploration ==='
-- 15.A.1 — Nombre de lignes de chaque table
-- UNION ALL empile les résultats de plusieurs SELECT dans un seul tableau
-- (les SELECT doivent avoir le même nombre de colonnes).
SELECT 'client' AS table_name, COUNT(*) AS nb_lignes FROM client
UNION ALL
SELECT 'produit', COUNT(*) FROM produit
UNION ALL
SELECT 'commande', COUNT(*) FROM commande
UNION ALL
SELECT 'ligne_commande', COUNT(*) FROM ligne_commande;

--Sinon, on  peut également faire juste 4 SELECT COUNT(*) dans chaque table :
-- 15.A.1 — Nombre de lignes de chaque table
SELECT COUNT(*) AS nb_clients        FROM client;
SELECT COUNT(*) AS nb_produits       FROM produit;
SELECT COUNT(*) AS nb_commandes      FROM commande;
SELECT COUNT(*) AS nb_lignes_commande FROM ligne_commande;



-- 15.A.2 — Colonnes et types de données
-- information_schema.columns est une vue système de PostgreSQL qui
-- décrit toutes les colonnes de toutes les tables.
-- On filtre sur nos 4 tables pour ne pas afficher les tables créées
-- par CREATE TABLE AS (montant_commandes, ca_mensuel...).
SELECT
    table_name,
    column_name,
    data_type,
    character_maximum_length,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('client', 'produit', 'commande', 'ligne_commande')
ORDER BY table_name, ordinal_position;

-- ordinal_position trie les colonnes dans l'ordre où elles ont été créées.
-- is_nullable vaut NO pour les colonnes en NOT NULL,
-- ce qui permet de vérifier directement que tes contraintes ont bien été appliquées.



-- 15.A.3 — Valeurs manquantes
-- COUNT(*) compte toutes les lignes, COUNT(colonne) ignore les NULL :
-- la différence donne le nombre de valeurs manquantes.
-- Pour les colonnes texte, on traite aussi les chaînes vides ('' ou '  ')
-- comme manquantes : TRIM supprime les espaces, NULLIF transforme ''
-- en NULL, puis COUNT l'ignore.


-- Table client
SELECT
    COUNT(*) - COUNT(NULLIF(TRIM(nom), ''))    AS nom_manquant,
    COUNT(*) - COUNT(NULLIF(TRIM(prenom), '')) AS prenom_manquant,
    COUNT(*) - COUNT(NULLIF(TRIM(email), ''))  AS email_manquant,
    COUNT(*) - COUNT(NULLIF(TRIM(ville), ''))  AS ville_manquante,
    COUNT(*) - COUNT(date_inscription)         AS date_inscription_manquante
FROM client;

-- Table produit
SELECT
    COUNT(*) - COUNT(NULLIF(TRIM(nom), ''))       AS nom_manquant,
    COUNT(*) - COUNT(NULLIF(TRIM(categorie), '')) AS categorie_manquante,
    COUNT(*) - COUNT(prix)                        AS prix_manquant,
    COUNT(*) - COUNT(stock)                       AS stock_manquant
FROM produit;

-- Table commande
SELECT
    COUNT(*) - COUNT(client_id)     AS client_manquant,
    COUNT(*) - COUNT(date_commande) AS date_manquante,
    COUNT(*) - COUNT(statut)        AS statut_manquant
FROM commande;

-- Pas de NULLIF(TRIM(...)) sur statut : le CHECK n'autorise que 4 valeurs
-- précises, une chaîne vide est donc déjà impossible.

-- Table ligne_commande
SELECT
    COUNT(*) - COUNT(commande_id)   AS commande_manquante,
    COUNT(*) - COUNT(produit_id)    AS produit_manquant,
    COUNT(*) - COUNT(quantite)      AS quantite_manquante,
    COUNT(*) - COUNT(prix_unitaire) AS prix_unitaire_manquant
FROM ligne_commande;

-- OBSERVATIONS :
-- Toutes les colonnes étant déclarées NOT NULL dans le fichier create_schema.sql,
-- aucun NULL ne peut exister : les contraintes d'intégrité ont empêché
-- leur insertion. Les seules valeurs manquantes possibles sont des
-- chaînes vides, que NOT NULL ne bloque pas.
-- Résultat :
--Table client :
--  nom_manquant | prenom_manquant | email_manquant | ville_manquante | date_inscription_manquante
--------------+-----------------+----------------+-----------------+----------------------------
--             0 |               0 |              0 |               0 |                          0
-- (1 row)

--Table produit
-- nom_manquant | categorie_manquante | prix_manquant | stock_manquant
--------------+---------------------+---------------+----------------
--             0 |                   0 |             0 |              0
-- (1 row)

--Table commande :
--  client_manquant | date_manquante | statut_manquant
-----------------+----------------+-----------------
--                0 |              0 |               0
-- (1 row)

--Table ligne_commande :
--  commande_manquante | produit_manquant | quantite_manquante | prix_unitaire_manquant
--------------------+------------------+--------------------+------------------------
--                   0 |                0 |                  0 |                      0
-- (1 row)

\echo '=== Exercice 15.B. Analyse commerciale ==='
-- 15.B.1 — Indicateurs clés en une seule requête (hors commandes annulées)
-- Définition retenue : un client actif est un client ayant passé au moins
-- une commande non annulée au cours des 12 derniers mois.
-- Les données ne couvrent que l'année 2025 (du 2025-01-01 au 2025-12-29) : toutes
-- les commandes sont dans cette fenêtre, la requête n'a donc pas besoin de filtre sur la date.
-- Il n'existe pas de définition unique : chaque entreprise fixe sa propre
-- durée (12, 6 ou 2 mois sans achat selon les cas).
-- Source : Brevo, « Clients inactifs : comment les relancer »
-- https://www.brevo.com/fr/blog/email-relance-clients-inactifs/


SELECT
    SUM(l.quantite * l.prix_unitaire)              AS chiffre_affaires_total,
    COUNT(DISTINCT c.id)                           AS nb_commandes,
    ROUND(SUM(l.quantite * l.prix_unitaire)
          / NULLIF(COUNT(DISTINCT c.id), 0), 2)    AS panier_moyen,
    COUNT(DISTINCT c.client_id)                    AS nb_clients_actifs
FROM commande c
INNER JOIN ligne_commande l ON l.commande_id = c.id
WHERE c.statut <> 'annulée';

--Résultat obtenu :
--  chiffre_affaires_total | nb_commandes | panier_moyen | nb_clients_actifs
------------------------+--------------+--------------+-------------------
--               617494.76 |          484 |      1275.82 |                90
-- (1 row)


-- 15.B.2 — Taux d'annulation des commandes
-- Ici on travaille sur TOUTES les commandes (y compris les annulées),
-- sinon le taux serait toujours de 0 %.
-- COUNT(CASE WHEN ... THEN 1 END) ne compte que les commandes annulées :
-- pour les autres, le CASE renvoie NULL, que COUNT ignore.
-- 100.0 (et non 100) force un calcul décimal : sinon PostgreSQL ferait
-- une division entière et le résultat serait arrondi à 0.
-- Taux d'annulation (version simple) :

SELECT
    COUNT(*) AS nb_commandes_total,
    SUM(CASE WHEN statut = 'annulée' THEN 1 ELSE 0 END) AS nb_commandes_annulees,
    ROUND(100.0 * SUM(CASE WHEN statut = 'annulée' THEN 1 ELSE 0 END)
          / NULLIF(COUNT(*), 0), 2) AS taux_annulation_pourcentage
FROM commande;

--Résultat obtenu suite à l'exécution de la requête :
--  nb_commandes_total | nb_commandes_annulees | taux_annulation_pourcentage
--------------------+-----------------------+-----------------------------
--                 500 |                    16 |                        3.20

-- OBSERVATIONS :
-- - CA total : 617494.76 € pour 484 commandes, soit un panier moyen de 1275.82 €
-- - 90 clients actifs sur 100 inscrits
-- - Taux d'annulation : 3.20 %

\echo '=== Exercice 15.C. Analyse des clients ==='
-- INNER JOIN : on ne s'intéresse ici qu'aux clients ayant acheté
-- (contrairement à l'exercice 9 où l'on gardait tous les clients).
SELECT
    cl.id                                        AS client_id,
    cl.nom,
    cl.prenom,
    cl.ville,
    COUNT(DISTINCT c.id)                         AS nb_commandes,
    SUM(l.quantite * l.prix_unitaire)            AS chiffre_affaires,
    ROUND(SUM(l.quantite * l.prix_unitaire)
          / NULLIF(COUNT(DISTINCT c.id), 0), 2)  AS panier_moyen_client
FROM client cl
INNER JOIN commande c       ON c.client_id = cl.id
INNER JOIN ligne_commande l ON l.commande_id = c.id
WHERE c.statut <> 'annulée'
GROUP BY cl.id, cl.nom, cl.prenom, cl.ville
ORDER BY chiffre_affaires DESC
LIMIT 10;

--Résultat obtenu suite à l'exécution de la requête :
--  client_id |   nom   | prenom |    ville    | nb_commandes | chiffre_affaires | panier_moyen_client
-----------+---------+--------+-------------+--------------+------------------+---------------------
--         59 | Dubois  | Alice  | Nice        |           11 |         17169.00 |             1560.82
--         31 | Bernard | Sarah  | Paris       |            9 |         15432.22 |             1714.69
--         32 | Bernard | Nathan | Lyon        |           10 |         15324.36 |             1532.44
--         80 | Thomas  | Paul   | Montpellier |            9 |         14916.74 |             1657.42
--         30 | Bernard | Arthur | Montpellier |            9 |         13293.83 |             1477.09
--         81 | Robert  | Emma   | Paris       |           10 |         13249.07 |             1324.91
--         83 | Robert  | Léa    | Marseille   |            8 |         12744.56 |             1593.07
--         60 | Dubois  | Paul   | Montpellier |            7 |         12528.08 |             1789.73
--         63 | Thomas  | Léa    | Marseille   |           11 |         12492.76 |             1135.71
--         57 | Dubois  | Zoé    | Lille       |            9 |         11428.87 |             1269.87
-- (10 rows)



-- OBSERVATIONS  :
-- - Le meilleur client a généré 17169.00 € en 11 commandes.
-- - Villes les plus représentées dans le top 10 : Montpellier (3 clients), puis Paris et Marseille (2 clients chacune).

\echo '=== Exercice 15.D. Synthese mensuelle ==='
-- On stocke les indicateurs mensuels dans une table (CREATE TABLE AS).
-- DROP TABLE IF EXISTS permet de réexécuter le fichier sans erreur.
-- Remarque : cette table contient les mêmes indicateurs que ca_mensuel
-- (exercice 12), mais sous le nom demandé par l'énoncé.

DROP TABLE IF EXISTS synthese_mensuelle;

CREATE TABLE synthese_mensuelle AS
SELECT
    TO_CHAR(c.date_commande, 'YYYY-MM')          AS mois,
    COUNT(DISTINCT c.id)                         AS nb_commandes,
    SUM(l.quantite * l.prix_unitaire)            AS chiffre_affaires,
    ROUND(SUM(l.quantite * l.prix_unitaire)
          / NULLIF(COUNT(DISTINCT c.id), 0), 2)  AS panier_moyen
FROM commande c
INNER JOIN ligne_commande l ON l.commande_id = c.id
WHERE c.statut <> 'annulée'
GROUP BY TO_CHAR(c.date_commande, 'YYYY-MM');

-- Vérification du contenu
SELECT *
FROM synthese_mensuelle
ORDER BY mois;

-- OBSERVATIONS - Ce que cette table permet d'observer :
-- - La tendance générale du CA mois après mois (croissance, baisse,
--   stabilité) et les éventuels effets saisonniers.
-- - L'origine des variations : en comparant les colonnes, on voit si
--   une hausse du CA vient d'une hausse du nombre de commandes (plus de
--   clients ou plus d'achats) ou d'une hausse du panier moyen (des
--   commandes plus importantes). Ces deux situations n'appellent pas
--   les mêmes actions commerciales.
-- - Les mois atypiques (pics ou creux) à expliquer : promotions,
--   période de fêtes, problème technique, anomalie de données...
--
-- Limites :
-- - La table n'est pas synchronisée : si de nouvelles commandes sont
--   ajoutées, il faut la recréer.

-- =============================================================================
-- PARTIE 7 : ANALYSE LIBRE
-- Pour chaque analyse : question, données nécessaires, requête, observation,
-- intérêt pour l'entreprise (en commentaire au-dessus de la requête).
-- =============================================================================

\echo '=== Analyse libre 1 ==='
-- PARTIE 7 — ANALYSE LIBRE 1 : Quels produits risquent une rupture de stock ?
-- =====================================================================
-- 1. Question :
-- Parmi les produits vendus, lesquels risquent d'être en rupture de
-- stock prochainement, compte tenu de leur rythme de vente ? Et ces
-- produits sont-ils souvent achetés dans des gros paniers ?
--
-- 2. Données nécessaires :
--    - produit : nom, catégorie, stock actuel
--    - ligne_commande : quantités vendues
--    - montant_commandes (table créée à l'exercice 11) : montant de chaque
--      commande non annulée, pour savoir si le produit a été acheté dans un
--      gros panier (1 500 € ou plus)
--
-- 3. Méthode :
--    - ventes moyennes par mois = quantité vendue sur l'année / 12
--    - couverture du stock (en mois) = stock actuel / ventes moyennes par mois
--       -> indique dans combien de mois le stock sera épuisé si les ventes
--          continuent au même rythme
--    - niveau de risque (CASE WHEN) :
--        moins d'1 mois de stock  -> Risque élevé
--        de 1 à moins de 3 mois   -> À surveiller
--        3 mois ou plus           -> Stock suffisant

--    Hypothèses : les ventes de 2025 sont représentatives de la demande
--    future, et le stock enregistré est le stock actuel. Les seuils de 1
--    et 3 mois sont des choix à adapter aux délais réels de
--    réapprovisionnement de l'entreprise.
--    La jointure avec montant_commandes exclut automatiquement les
--    commandes annulées, puisque cette table ne contient que les commandes
--    non annulées.

SELECT
    p.nom                                         AS produit,
    p.categorie,
    p.stock,
    SUM(l.quantite)                               AS quantite_vendue,
    ROUND(SUM(l.quantite) / 12.0, 1)              AS ventes_moyennes_par_mois,
    ROUND(p.stock / NULLIF(SUM(l.quantite) / 12.0, 0), 1) AS couverture_mois,
    ROUND(100.0 * SUM(CASE WHEN m.montant_total >= 1500 THEN l.quantite ELSE 0 END)
          / NULLIF(SUM(l.quantite), 0), 1)        AS part_vendue_gros_paniers_pct,
    CASE
        WHEN p.stock / NULLIF(SUM(l.quantite) / 12.0, 0) < 1 THEN 'Risque élevé'
        WHEN p.stock / NULLIF(SUM(l.quantite) / 12.0, 0) < 3 THEN 'À surveiller'
        ELSE 'Stock suffisant'
    END                                           AS niveau_risque
FROM ligne_commande l
INNER JOIN montant_commandes m ON m.commande_id = l.commande_id
INNER JOIN produit p           ON p.id = l.produit_id
GROUP BY p.id, p.nom, p.categorie, p.stock
ORDER BY couverture_mois ASC
LIMIT 15;

-- 4. Résultat (15 produits dont le stock est le plus tendu) :
--   Produit         | Stock | Vendus | Couverture | Gros paniers | Niveau
--   Lampe 2         |     0 |     62 |   0,0 mois |       72,6 % | Risque élevé
--   Souris 2        |     0 |     41 |   0,0 mois |       70,7 % | Risque élevé
--   Sweat 1         |     0 |     56 |   0,0 mois |       50,0 % | Risque élevé
--   Haltères 1      |     1 |     48 |   0,3 mois |       56,3 % | Risque élevé
--   Enceinte 1      |     7 |     73 |   1,2 mois |       38,4 % | À surveiller
--   Tapis de yoga 1 |     8 |     64 |   1,5 mois |       31,3 % | À surveiller
--   Plaid 1         |    11 |     81 |   1,6 mois |       65,4 % | À surveiller
--   (suite dans le résultat de la requête)
--
-- OBSERVATIONS :
-- - Sur les 60 produits vendus, 4 sont en risque élevé, 8 sont à surveiller
--   et 48 ont un stock suffisant.
-- - 3 produits sont déjà en rupture (stock à 0) : Lampe 2, Souris 2 et
--   Sweat 1. Haltères 1 n'a plus qu'une unité en stock.
-- - Ces produits se vendent bien : entre 41 et 62 unités sur l'année pour
--   les 4 produits en risque élevé.
-- - Lampe 2 et Souris 2 sont vendus à plus de 70 % dans des gros paniers
--   (1 500 € ou plus). Leur rupture touche donc surtout les commandes qui
--   rapportent le plus.
--
-- Intérêt pour l'entreprise :
-- - Un produit en rupture ne peut plus être vendu : c'est du chiffre
--   d'affaires perdu, sur des produits pour lesquels la demande existe.
-- - Cette analyse donne une liste de priorités pour le réapprovisionnement :
--   d'abord les 4 produits en risque élevé, puis les 8 produits à surveiller.
-- - Elle complète l'exercice 14 : certains produits immobilisent du stock
--   sans se vendre, alors que d'autres se vendent bien et n'ont plus de stock.

\echo '=== Analyse libre 2 ==='
-- =====================================================================
-- PARTIE 7 — ANALYSE LIBRE 2 : Les remises font-elles vendre davantage ?
-- =====================================================================
-- 1. Question :
-- Quelle part des ventes est réalisée avec une remise, combien ces remises
-- coûtent-elles à l'entreprise, et les clients achètent-ils en plus grande
-- quantité lorsqu'un produit est remisé ?
--
-- 2. Données nécessaires :
--    - ligne_commande : quantité et prix unitaire effectivement payé
--    - produit : prix actuel et catégorie
--    - commande : statut, pour exclure les commandes annulées
--
-- 3. Méthode :
--    - une ligne est remisée si le prix payé est inférieur au prix actuel
--    - taux de remise = 1 - (prix payé / prix actuel), en pourcentage
--    - montant des remises = quantité * (prix actuel - prix payé)
--       -> c'est le chiffre d'affaires auquel l'entreprise a renoncé
--
--    Hypothèse : on compare le prix payé au prix ACTUEL du produit. Si le
--    prix catalogue a changé au cours de l'année, l'écart ne correspond pas
--    exactement à une remise. Les taux obtenus (0, 5, 10 et 20 %) sont
--    toutefois des valeurs rondes, ce qui correspond bien à des promotions.
--    NULLIF évite une division par zéro si un prix actuel vaut 0.

-- Libre 2.1 — Vue d'ensemble des remises
SELECT
    COUNT(*)                                               AS nb_lignes,
    SUM(CASE WHEN l.prix_unitaire < p.prix THEN 1 ELSE 0 END) AS nb_lignes_remisees,
    ROUND(100.0 * SUM(CASE WHEN l.prix_unitaire < p.prix THEN 1 ELSE 0 END)
          / NULLIF(COUNT(*), 0), 1)                        AS part_lignes_remisees_pct,
    SUM(l.quantite * p.prix)                               AS ca_au_prix_actuel,
    SUM(l.quantite * l.prix_unitaire)                      AS chiffre_affaires,
    SUM(l.quantite * (p.prix - l.prix_unitaire))           AS montant_remises
FROM ligne_commande l
INNER JOIN produit p  ON p.id = l.produit_id
INNER JOIN commande c ON c.id = l.commande_id
WHERE c.statut <> 'annulée';

-- Libre 2.2 — Détail par taux de remise
-- (PostgreSQL accepte l'alias dans le GROUP BY, comme vu en cours)
SELECT
    ROUND(100 * (1 - l.prix_unitaire / NULLIF(p.prix, 0))) AS taux_remise_pct,
    COUNT(*)                                               AS nb_lignes,
    SUM(l.quantite)                                        AS quantite_vendue,
    ROUND(AVG(l.quantite), 2)                              AS quantite_moyenne_par_ligne,
    SUM(l.quantite * l.prix_unitaire)                      AS chiffre_affaires,
    SUM(l.quantite * (p.prix - l.prix_unitaire))           AS montant_remises
FROM ligne_commande l
INNER JOIN produit p  ON p.id = l.produit_id
INNER JOIN commande c ON c.id = l.commande_id
WHERE c.statut <> 'annulée'
GROUP BY taux_remise_pct
ORDER BY taux_remise_pct;

-- Libre 2.3 — Détail par catégorie
SELECT
    p.categorie,
    COUNT(*)                                               AS nb_lignes,
    ROUND(100.0 * SUM(CASE WHEN l.prix_unitaire < p.prix THEN 1 ELSE 0 END)
          / NULLIF(COUNT(*), 0), 1)                        AS part_lignes_remisees_pct,
    SUM(l.quantite * (p.prix - l.prix_unitaire))           AS montant_remises
FROM ligne_commande l
INNER JOIN produit p  ON p.id = l.produit_id
INNER JOIN commande c ON c.id = l.commande_id
WHERE c.statut <> 'annulée'
GROUP BY p.categorie
ORDER BY montant_remises DESC;

-- 4. Résultat :
--   Taux de remise | Lignes        | Quantité moyenne | Chiffre d'affaires | Remises
--   0 %            | 725 (48,3 %)  | 2,50             | 312 603,76 €       |      0,00 €
--   5 %            | 255 (17,0 %)  | 2,55             | 107 737,85 €       |  5 670,32 €
--   10 %           | 262 (17,5 %)  | 2,65             | 105 178,80 €       | 11 686,37 €
--   20 %           | 258 (17,2 %)  | 2,51             |  91 974,35 €       | 22 993,35 €
--
-- OBSERVATIONS :
-- - Plus d'une ligne sur deux est vendue avec une remise : 775 lignes sur
--   1 500, soit 51,7 %. Aucune ligne n'est vendue au-dessus du prix actuel.
-- - Les remises représentent 40 350,04 € : au prix actuel, le chiffre
--   d'affaires aurait été de 657 844,80 € au lieu de 617 494,76 € (-6,1 %).
-- - Les remises de 20 % coûtent à elles seules 22 993,35 €, soit plus de la
--   moitié du montant total des remises.
-- - La quantité moyenne par ligne ne change presque pas : 2,50 sans remise
--   contre 2,51 avec une remise de 20 %. Les clients n'achètent donc pas en
--   plus grande quantité lorsque le produit est remisé.
-- - Le Sport est la catégorie la plus remisée (58,6 % des lignes,
--   12 008,59 € de remises), l'Audio la moins remisée (45,4 %, 4 119,68 €).
--
-- Intérêt pour l'entreprise :
-- - Les remises ont un coût important (6,1 % du chiffre d'affaires
--   potentiel) sans effet visible sur les quantités achetées.
-- - Les remises de 20 % sont les plus coûteuses : il serait utile de
--   vérifier si elles sont vraiment nécessaires, ou si une remise de 5 ou
--   10 % suffirait.
--
-- Limite : les données ne permettent pas de savoir si le client aurait
-- acheté sans la remise. Une remise peut déclencher un achat sans augmenter
-- la quantité. Pour le vérifier, il faudrait comparer les ventes d'un même
-- produit avec et sans promotion, sur des périodes comparables.


\echo '=== Analyse libre 3 ==='
-- =====================================================================
-- PARTIE 7 — ANALYSE LIBRE 3 : Quelles villes rapportent le plus ?
-- =====================================================================
-- 1. Question :
-- Le chiffre d'affaires est-il réparti de la même façon entre les villes ?
-- Les écarts viennent-ils du nombre de commandes ou du panier moyen ?
--
-- 2. Données nécessaires :
--    - client : ville
--    - montant_commandes (table créée à l'exercice 11) : montant de chaque
--      commande non annulée et client ayant passé la commande
--
-- 3. Méthode :
--    - pour chaque ville : nombre de clients ayant commandé, nombre de
--      commandes, chiffre d'affaires, panier moyen et CA moyen par client
--    - part du CA = CA de la ville / CA total (sous-requête sur
--      montant_commandes)
--    La jointure avec montant_commandes exclut automatiquement les
--    commandes annulées, puisque cette table ne contient que les commandes
--    non annulées.

SELECT
    cl.ville,
    COUNT(DISTINCT cl.id)                             AS nb_clients_acheteurs,
    COUNT(*)                                          AS nb_commandes,
    SUM(m.montant_total)                              AS chiffre_affaires,
    ROUND(AVG(m.montant_total), 2)                    AS panier_moyen,
    ROUND(SUM(m.montant_total)
          / NULLIF(COUNT(DISTINCT cl.id), 0), 2)      AS ca_moyen_par_client,
    ROUND(100.0 * SUM(m.montant_total)
          / NULLIF((SELECT SUM(montant_total) FROM montant_commandes), 0), 1) AS part_ca_pct
FROM client cl
INNER JOIN montant_commandes m ON m.client_id = cl.id
GROUP BY cl.ville
ORDER BY chiffre_affaires DESC;

-- 4. Résultat :
--   Ville       | Clients | Commandes | Chiffre d'affaires | Panier moyen | Part du CA
--   Montpellier |       9 |        60 |        83 721,92 € |   1 395,37 € |     13,6 %
--   Marseille   |       9 |        60 |        75 129,81 € |   1 252,16 € |     12,2 %
--   Nice        |       9 |        54 |        66 706,48 € |   1 235,31 € |     10,8 %
--   Paris       |       9 |        48 |        64 073,31 € |   1 334,86 € |     10,4 %
--   Lyon        |       9 |        45 |        63 758,54 € |   1 416,86 € |     10,3 %
--   Lille       |       9 |        51 |        62 782,84 € |   1 231,04 € |     10,2 %
--   Toulouse    |       9 |        45 |        57 541,48 € |   1 278,70 € |      9,3 %
--   Bordeaux    |       9 |        43 |        53 697,99 € |   1 248,79 € |      8,7 %
--   Nantes      |       9 |        45 |        49 808,94 € |   1 106,87 € |      8,1 %
--   Strasbourg  |       9 |        33 |        40 273,45 € |   1 220,41 € |      6,5 %
--
-- OBSERVATIONS :
-- - Chaque ville compte le même nombre de clients : 10 inscrits, dont 9 ont
--   commandé. Les écarts ne viennent donc pas du nombre de clients.
-- - Pourtant, le chiffre d'affaires varie du simple au double : 83 721,92 €
--   à Montpellier contre 40 273,45 € à Strasbourg.
-- - L'écart vient surtout du nombre de commandes : 60 à Montpellier et à
--   Marseille, contre 33 à Strasbourg. Le panier moyen varie beaucoup moins
--   (de 1 106,87 € à Nantes à 1 416,86 € à Lyon).
-- - Lyon a le panier moyen le plus élevé, mais seulement 45 commandes :
--   les clients y commandent moins souvent, pour des montants plus importants.
-- - Paris n'est que 4e, avec 10,4 % du CA.
--
-- Intérêt pour l'entreprise :
-- - À nombre de clients égal, certaines villes rapportent deux fois plus
--   que d'autres : il existe une marge de progression à Strasbourg, Nantes
--   et Bordeaux.
-- - Le levier n'est pas le même selon la ville : à Strasbourg, il faut
--   faire commander plus souvent (relances, offres de fidélité) ; à Nantes,
--   il faut plutôt augmenter le panier moyen (produits complémentaires).
--
-- Limite : avec 10 clients par ville, quelques gros clients suffisent à
-- changer le classement (3 des 10 meilleurs clients sont à Montpellier,
-- voir l'exercice 15 C). Ces résultats sont à confirmer sur un plus grand
-- nombre de clients.
