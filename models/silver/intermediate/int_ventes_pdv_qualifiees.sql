-- Ventes PDV (anonymes) : date FR, décimales à virgule, contrôles référentiels
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
)
select
    p.*,
    case
        when p.date_vente is null then 'DATE_INVALIDE'
        when v.pdv_id is null then 'PDV_INCONNU'
        when r.code_produit is null then 'PRODUIT_INCONNU'
        when p.montant_ventes_eur is null or p.montant_ventes_eur < 0 then 'MONTANT_NEGATIF'
    end as motif_rejet,
    r.famille
from parsed p
left join {{ ref('ref_pdv') }} v on v.pdv_id = p.id_pdv
left join {{ ref('ref_produits') }} r on r.code_produit = p.code_produit
