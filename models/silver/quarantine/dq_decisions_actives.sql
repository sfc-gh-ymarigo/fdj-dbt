-- Dernière décision du data steward par ligne en quarantaine (le journal complet reste dans la source)
select
    source,
    cle_enregistrement,
    decision,
    code_produit_corrige,
    montant_corrige,
    moyen_paiement_corrige,
    origine,
    corrige_par,
    corrige_le
from {{ source('dq', 'corrections_quarantaine') }}
where decision in ('CORRIGER', 'ACCEPTER_EN_L_ETAT', 'REJET_DEFINITIF')
qualify row_number() over (partition by source, cle_enregistrement order by corrige_le desc, correction_id desc) = 1
