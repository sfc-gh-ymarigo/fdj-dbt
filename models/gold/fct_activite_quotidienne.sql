-- Activité quotidienne consolidée en ligne + réseau, rattachée aux Business Units du dossier de presse
with en_ligne as (
    select
        b.date_pari                                   as date_activite,
        b.canal,
        b.code_produit,
        count(*)                                      as nb_transactions,
        count(distinct b.account_id)                  as nb_joueurs,
        sum(b.mise_eur)                               as mises_eur,
        sum(b.gain_eur)                               as gains_eur
    from {{ ref('paris_en_ligne') }} b
    group by 1, 2, 3
),
reseau as (
    select
        date_vente                                    as date_activite,
        'PDV'                                         as canal,
        code_produit,
        sum(nb_tickets)                               as nb_transactions,
        null::number                                  as nb_joueurs,
        sum(montant_ventes_eur)                       as mises_eur,
        sum(montant_gains_eur)                        as gains_eur
    from {{ ref('ventes_pdv') }}
    group by 1, 2, 3
),
unioned as (
    select * from en_ligne
    union all
    select * from reseau
)
select
    u.date_activite,
    date_trunc('month', u.date_activite)              as mois,
    u.canal,
    iff(u.canal = 'PDV', 'RESEAU', 'DIGITAL')         as type_canal,
    u.code_produit,
    p.libelle                                         as produit,
    p.famille,
    iff(u.canal = 'PDV', p.bu_pdv, p.bu_en_ligne)     as business_unit,
    u.nb_transactions,
    u.nb_joueurs,
    u.mises_eur,
    u.gains_eur,
    u.mises_eur - u.gains_eur                         as pbj_eur
from unioned u
join {{ ref('ref_produits') }} p on p.code_produit = u.code_produit
