{{ config(external_volume='ICEBERG_SILO_VOLUME') }}
-- Référentiel produits typé (source on-prem, petit volume -> volume on-prem)
select
    code_produit,
    libelle,
    famille,
    nullif(sous_famille, '')                     as sous_famille,
    try_to_number(mise_min_eur, 10, 2)           as mise_min_eur,
    try_to_number(taux_retour_joueur, 5, 3)      as taux_retour_joueur,
    try_to_boolean(vendu_en_ligne)               as vendu_en_ligne,
    try_to_boolean(vendu_pdv)                    as vendu_pdv,
    bu_en_ligne,
    bu_pdv,
    try_to_boolean(actif)                        as actif
from {{ source('raw', 'ref_produits') }}
