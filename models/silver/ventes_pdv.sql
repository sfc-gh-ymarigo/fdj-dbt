select
    date_vente,
    id_pdv,
    region,
    code_produit,
    famille,
    nb_tickets,
    montant_ventes_eur,
    montant_gains_eur,
    montant_ventes_eur - montant_gains_eur as pbj_eur,
    _load_ts
from {{ ref('int_ventes_pdv_qualifiees') }}
where motif_rejet is null
