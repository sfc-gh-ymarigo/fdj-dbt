-- Mouvements portefeuille : montants à virgule, statuts hétérogènes, doublons, moyens inconnus.
-- Décisions des data stewards appliquées avant les contrôles (cf. dq_decisions_actives).
with parsed as (
    select
        transaction_id,
        account_id,
        try_to_timestamp_ntz(horodatage)::timestamp_ntz(6)        as horodatage_operation,
        upper(trim(type_operation))                                as type_operation,
        try_to_number(replace(montant, ',', '.'), 12, 2)           as montant_eur,
        regexp_like(montant, '.*,.*')                              as montant_format_virgule,
        devise,
        upper(trim(moyen_paiement))                                as moyen_paiement,
        upper(trim(statut))                                        as statut,
        (statut <> upper(statut))                                  as statut_format_non_standard,
        psp,
        _file_name,
        _file_row,
        _load_ts
    from {{ source('raw', 'wallet_transactions') }}
),

corrige as (
    select
        p.* exclude (montant_eur, moyen_paiement),
        coalesce(iff(d.decision = 'CORRIGER', d.montant_corrige, null), p.montant_eur)                 as montant_eur,
        coalesce(iff(d.decision = 'CORRIGER', upper(d.moyen_paiement_corrige), null), p.moyen_paiement) as moyen_paiement,
        p.montant_eur                                                                                  as montant_eur_recu,
        p.moyen_paiement                                                                               as moyen_paiement_recu,
        d.decision                                                                                     as decision_steward
    from parsed p
    left join {{ ref('dq_decisions_actives') }} d
        on d.source = 'WALLET' and d.cle_enregistrement = p.transaction_id
)

select
    p.*,
    row_number() over (partition by p.transaction_id order by p._load_ts, p._file_name, p._file_row) as rang_doublon,
    case
        when c.account_id is null then 'COMPTE_INCONNU'
        when p.montant_eur is null or p.montant_eur <= 0 then 'MONTANT_INVALIDE'
        when p.horodatage_operation is null then 'HORODATAGE_INVALIDE'
        when p.moyen_paiement not in ('CB', 'PAYPAL', 'VIREMENT_SEPA', 'APPLE_PAY', 'PROMO') then 'MOYEN_PAIEMENT_INCONNU'
        when rang_doublon > 1 then 'DOUBLON'
        when p.decision_steward = 'REJET_DEFINITIF' then 'REJET_STEWARD'
    end                                                                                              as motif_rejet
from corrige p
left join {{ ref('clients') }} c on c.account_id = p.account_id
