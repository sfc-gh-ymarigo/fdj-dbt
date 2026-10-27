-- KPI extra-financiers (dossier de presse 2024)
select * from (values
    (2024, 'Impact économique', 'Contribution à la richesse nationale', 7000.0, 'M€', '0,25 % du PIB France'),
    (2024, 'Impact économique', 'Contribution aux finances publiques', 4700.0, 'M€', 'dont 4,5 Md€ de prélèvements publics sur les jeux'),
    (2024, 'Impact économique', 'Emplois créés ou pérennisés', 57200.0, 'emplois', 'dont 21 600 dans le réseau bars-tabacs-presse'),
    (2024, 'Impact économique', 'Rémunération des détaillants', 994.0, 'M€', null),
    (2024, 'Jeu responsable', 'Part du CA loterie en ligne France portée par des joueurs à risque élevé', 1.0, '%', 'vs 1,8 % en 2023 ; objectif < 2 % en 2025'),
    (2024, 'Jeu responsable', 'Part du CA Kindred portée par des joueurs à risque élevé', 3.0, '%', 'vs 3,2 % en 2023'),
    (2024, 'Jeu responsable', 'Appels vers des joueurs à risque en ligne', 20000.0, 'appels', 'niveau Groupe'),
    (2024, 'Jeu responsable', 'Part des moyens publicitaires dédiés au jeu responsable', 10.0, '%', '> 10 %'),
    (2024, 'Réseau', 'Points de vente', 34000.0, 'PDV', 'dont > 29 000 en France'),
    (2024, 'Réseau', 'Joueurs', 33000000.0, 'joueurs', 'dont > 9 M en ligne'),
    (2024, 'Réseau', 'Part du CA en ligne', 35.0, '%', 'vs 65 % en point de vente'),
    (2024, 'Structure financière', 'Conversion EBITDA courant en cash-flow libre', 85.0, '%', null),
    (2024, 'Structure financière', 'Taux de distribution du dividende', 77.0, '%', null)
) as t(annee, categorie, indicateur, valeur, unite, commentaire)
