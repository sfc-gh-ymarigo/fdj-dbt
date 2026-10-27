-- Paris en ligne : parsing du JSON brut, normalisation des horodatages multi-formats,
-- dédoublonnage et qualification (motif de rejet) de chaque événement.
-- Les décisions des data stewards (dq_decisions_actives) sont appliquées AVANT les contrôles :
-- une ligne corrigée repasse toutes les règles et rejoint SILVER si elle est désormais conforme.
with src as (
    select
        raw_json,
        try_parse_json(raw_json) as j,
        _file_name,
        _file_row,
        _load_ts
    from {{ source('raw', 'bets_events') }}
),

parsed as (
    select
        j:event_id::string                          as event_id,
        j:bet.bet_id::string                        as bet_id,
        j:player.account_id::string                 as account_id,
        j:bet.product_code::string                  as code_produit,
        j:bet.stake.amount::number(12, 2)           as mise_eur,
        j:bet.odds::number(8, 2)                    as cote,
        j:result.status::string                     as statut_resultat,
        j:result.payout::number(14, 2)              as gain_eur,
        j:context.channel::string                   as canal,
        j:context.device_os::string                 as device_os,
        j:ingest.batch_id::string                   as batch_id,
        j:occurred_at::string                       as horodatage_brut,
        case
            when regexp_like(horodatage_brut, '^[0-9]{4}-[0-9]{2}-[0-9]{2}T.*') then 'ISO8601'
            when regexp_like(horodatage_brut, '^[0-9]{13}$') then 'EPOCH_MS'
            when regexp_like(horodatage_brut, '^[0-9]{2}/[0-9]{2}/[0-9]{4} .*') then 'FR'
            else 'INCONNU'
        end                                         as format_horodatage,
        case format_horodatage
            when 'ISO8601' then try_to_timestamp_ntz(left(horodatage_brut, 19), 'YYYY-MM-DD"T"HH24:MI:SS')
            when 'EPOCH_MS' then convert_timezone('UTC', 'Europe/Paris', to_timestamp_ntz(try_to_number(horodatage_brut), 3))
            when 'FR' then try_to_timestamp_ntz(horodatage_brut, 'DD/MM/YYYY HH24:MI')
        end::timestamp_ntz(6)                       as horodatage_pari,
        try_to_date(right(batch_id, 8), 'YYYYMMDD') as date_reception,
        raw_json,
        _file_name,
        _file_row,
        _load_ts
    from src
),

corrige as (
    select
        p.* exclude (code_produit, mise_eur),
        coalesce(iff(d.decision = 'CORRIGER', d.code_produit_corrige, null), p.code_produit) as code_produit,
        coalesce(iff(d.decision = 'CORRIGER', d.montant_corrige, null), p.mise_eur)          as mise_eur,
        p.code_produit                                                                       as code_produit_recu,
        p.mise_eur                                                                           as mise_eur_recue,
        d.decision                                                                           as decision_steward
    from parsed p
    left join {{ ref('dq_decisions_actives') }} d
        on d.source = 'PARIS_EN_LIGNE' and d.cle_enregistrement = p.bet_id
)

select
    p.*,
    (p.date_reception > p.horodatage_pari::date)    as arrivee_tardive,
    row_number() over (
        partition by p.bet_id
        order by iff(endswith(p.batch_id, '-RETRY'), 1, 0), p._load_ts, p._file_name, p._file_row
    )                                               as rang_doublon,
    case
        when p.event_id is null then 'JSON_INVALIDE'
        when c.account_id is null then 'COMPTE_INCONNU'
        when p.code_produit is null then 'CODE_PRODUIT_ABSENT'
        when r.code_produit is null then 'PRODUIT_INCONNU'
        when p.mise_eur is null or p.mise_eur <= 0 then 'MISE_NON_POSITIVE'
        when p.horodatage_pari is null then 'HORODATAGE_INVALIDE'
        when rang_doublon > 1 then 'DOUBLON'
        when p.decision_steward = 'REJET_DEFINITIF' then 'REJET_STEWARD'
    end                                             as motif_rejet,
    r.famille
from corrige p
left join {{ ref('clients') }} c on c.account_id = p.account_id
left join {{ ref('ref_produits') }} r on r.code_produit = p.code_produit
