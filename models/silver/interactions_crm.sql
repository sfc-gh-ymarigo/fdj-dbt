-- Interactions CRM / SAV / système (alertes jeu responsable, limites, auto-exclusion)
with parsed as (
    select try_parse_json(raw_json) as j, _load_ts
    from {{ source('raw', 'crm_interactions') }}
)
select
    j:interaction_id::string                               as interaction_id,
    j:account_id::string                                   as account_id,
    try_to_timestamp_ntz(j:timestamp::string)::timestamp_ntz(6) as horodatage_interaction,
    horodatage_interaction::date                           as date_interaction,
    j:type::string                                         as type_interaction,
    j:canal::string                                        as canal,
    j:details.sentiment::string                            as sentiment,
    j:details.agent_id::string                             as agent_id,
    (type_interaction in ('ALERTE_JEU_RESPONSABLE', 'LIMITE_DEPOT_ATTEINTE', 'DEMANDE_HAUSSE_LIMITE',
                          'AUTO_EXCLUSION', 'REDUCTION_VOLONTAIRE_LIMITES'))   as evenement_jeu_responsable,
    _load_ts
from parsed
where j:interaction_id is not null
