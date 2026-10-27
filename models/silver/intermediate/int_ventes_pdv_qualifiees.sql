-- Ventes PDV (anonymes) : date FR, décimales à virgule, contrôles référentiels.
-- Décisions des data stewards appliquées avant les contrôles (cf. dq_decisions_actives) ;
-- ACCEPTER_EN_L_ETAT lève le contrôle de montant négatif (annulation / remboursement légitime).
with parsed as (
    select
        try_to_date(date_vente, 'DD/MM/YYYY')                      as date_vente,
        id_pdv,
        region,
        code_produit,
        try_to_number(nb_tickets)                                  as nb_tickets,
        try_to_number(replace(montant_ventes, ',', '.'), 14, 2)    as montant_ventes_eur,
        try_to_number(replace(montant_gains_payes, ',', '.'), 14, 2) as montant_gains_eur,
        _file_name,
        _file_row,
        _load_ts
    from {{ source('raw', 'pos_ventes') }}
),

corrige as (
    select
        p.* exclude (montant_ventes_eur),
        coalesce(iff(d.decision = 'CORRIGER', d.montant_corrige, null), p.montant_ventes_eur) as montant_ventes_eur,
        p.montant_ventes_eur                                                                  as montant_ventes_eur_recu,
        d.decision                                                                            as decision_steward
    from parsed p
    left join {{ ref('dq_decisions_actives') }} d
        on d.source = 'VENTES_PDV'
       and d.cle_enregistrement = p.id_pdv || '|' || coalesce(p.date_vente::string, '?') || '|' || p.code_produit
)
select
    p.*,
    case
        when p.date_vente is null then 'DATE_INVALIDE'
        when v.pdv_id is null then 'PDV_INCONNU'
        when r.code_produit is null then 'PRODUIT_INCONNU'
        when p.montant_ventes_eur is null then 'MONTANT_NEGATIF'
        when p.montant_ventes_eur < 0 and coalesce(p.decision_steward, '') <> 'ACCEPTER_EN_L_ETAT' then 'MONTANT_NEGATIF'
        when p.decision_steward = 'REJET_DEFINITIF' then 'REJET_STEWARD'
    end as motif_rejet,
    r.famille
from corrige p
left join {{ ref('ref_pdv') }} v on v.pdv_id = p.id_pdv
left join {{ ref('ref_produits') }} r on r.code_produit = p.code_produit
