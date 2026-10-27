{{ config(external_volume='ICEBERG_SILO_VOLUME') }}
-- Clients en ligne : historique SCD2 reconstruit à partir des extractions full + deltas (PII, on-prem)
with src as (
    select
        account_id,
        civilite,
        prenom,
        nom,
        lower(trim(email))                                   as email,
        telephone,
        try_to_date(date_naissance)                          as date_naissance,
        nullif(trim(code_postal), '')                        as code_postal,
        ville,
        try_to_date(date_inscription)                        as date_inscription,
        statut_kyc,
        try_to_number(limite_depot_mensuelle, 12, 2)         as limite_depot_mensuelle,
        try_to_boolean(optin_marketing)                      as optin_marketing,
        try_to_timestamp_ntz(updated_at)::timestamp_ntz(6)   as valid_from,
        _file_name,
        _load_ts
    from {{ source('raw', 'kyc_clients') }}
    where account_id is not null
    qualify row_number() over (partition by account_id, updated_at order by _load_ts desc, _file_row desc) = 1
)
select
    *,
    lead(valid_from) over (partition by account_id order by valid_from)  as valid_to
from src
