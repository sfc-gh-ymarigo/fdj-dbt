select
    transaction_id,
    account_id,
    horodatage_operation,
    horodatage_operation::date as date_operation,
    type_operation,
    montant_eur,
    devise,
    moyen_paiement,
    statut,
    psp,
    montant_format_virgule,
    statut_format_non_standard,
    _load_ts
from {{ ref('int_wallet_qualifie') }}
where motif_rejet is null
