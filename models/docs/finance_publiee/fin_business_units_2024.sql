-- Business Units 2024 pro forma (dossier de presse)
select * from (values
    (1, 'Loterie et paris sportifs en réseau France', 'Patrick Buffard', 2503.0, 0.66),
    (2, 'Paris et jeux en ligne',                     'Nils Andén',      1030.0, 0.27),
    (3, 'Loterie internationale',                     'Giovanna D''Esposito', 190.0, 0.05),
    (4, 'Paiement & Services',                        'Raphaël Botbol',   65.0, 0.02)
) as t(bu_id, bu_nom, responsable, ca_meur, part_ca_groupe)
