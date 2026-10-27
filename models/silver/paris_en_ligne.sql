-- Paris en ligne valides (dédoublonnés, conformes au référentiel)
select
    bet_id,
    event_id,
    account_id,
    horodatage_pari,
    horodatage_pari::date                         as date_pari,
    hour(horodatage_pari)                         as heure_pari,
    code_produit,
    famille,
    canal,
    device_os,
    mise_eur,
    cote,
    statut_resultat,
    gain_eur,
    mise_eur - gain_eur                           as pbj_eur,
    format_horodatage,
    arrivee_tardive,
    date_reception,
    _load_ts
from {{ ref('int_paris_qualifies') }}
where motif_rejet is null
