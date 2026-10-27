{{ config(external_volume='ICEBERG_SILO_VOLUME') }}
select
    pdv_id,
    enseigne,
    region,
    code_postal,
    ville,
    type_pdv,
    try_to_date(date_ouverture) as date_ouverture
from {{ source('raw', 'ref_pdv') }}
