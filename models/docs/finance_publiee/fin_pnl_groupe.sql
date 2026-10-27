-- Chiffres clés publiés (dossier de presse résultats annuels 2024, FDJ United) + historique
select * from (values
    (2021, 'PUBLIE',    2137.0, 504.0, 23.6, 308.0, 350.0, 420.0, 450.0, 0.9, 1.37),
    (2022, 'PUBLIE',    2496.0, 580.0, 23.2, 373.0, 405.0, 510.0, 380.0, 0.7, 1.54),
    (2023, 'PUBLIE',    2618.0, 656.0, 25.1, 423.0, 434.0, 585.0, 320.0, 0.5, 1.78),
    (2024, 'PUBLIE',    3065.0, 792.0, 25.8, 399.0, 490.0, 675.0, 1818.0, 1.9, 2.05),
    (2024, 'PRO_FORMA', 3788.0, 964.0, 25.5, 351.0, 537.0, 847.0, 1818.0, 1.9, 2.05)
) as t(annee, type_publication, ca_meur, ebitda_courant_meur, taux_marge_ebitda_pct, resultat_net_meur,
       resultat_net_ajuste_meur, cash_flow_libre_meur, dette_nette_meur, levier_dette_ebitda, dividende_par_action_eur)
