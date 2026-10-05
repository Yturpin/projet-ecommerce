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


\echo '=== Exercice 12. Analyse temporelle ==='


-- =============================================================================
-- PARTIE 5 : QUALITÉ DES DONNÉES
-- =============================================================================

\echo '=== Exercice 13. Commandes anterieures a l inscription du client ==='


\echo '=== Exercice 14. Produits sans vente ==='


-- =============================================================================
-- PARTIE 6 : TABLEAU DE BORD EN SQL
-- =============================================================================

\echo '=== Exercice 15.A. Exploration ==='


\echo '=== Exercice 15.B. Analyse commerciale ==='


\echo '=== Exercice 15.C. Analyse des clients ==='


\echo '=== Exercice 15.D. Synthese mensuelle ==='


-- =============================================================================
-- PARTIE 7 : ANALYSE LIBRE
-- Pour chaque analyse : question, données nécessaires, requête, observation,
-- intérêt pour l'entreprise (en commentaire au-dessus de la requête).
-- =============================================================================

\echo '=== Analyse libre 1 ==='


\echo '=== Analyse libre 2 ==='


\echo '=== Analyse libre 3 ==='

