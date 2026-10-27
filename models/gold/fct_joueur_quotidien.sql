-- Vue joueur x jour : socle des features ML (jeu à risque, churn)
with paris as (
    select
        account_id,
        date_pari                                                     as date_activite,
        count(*)                                                      as nb_paris,
        sum(mise_eur)                                                 as mises_eur,
        sum(gain_eur)                                                 as gains_eur,
        count_if(heure_pari < 6)                                      as nb_paris_nuit,
        count(distinct code_produit)                                  as nb_produits_distincts,
        sum(iff(famille = 'PARIS_SPORTIFS', mise_eur, 0))             as mises_sport_eur,
        sum(iff(famille = 'PARIS_HIPPIQUES', mise_eur, 0))            as mises_hippique_eur,
        sum(iff(famille = 'TIRAGE', mise_eur, 0))                     as mises_tirage_eur,
        sum(iff(famille = 'GRATTAGE', mise_eur, 0))                   as mises_grattage_eur,
        max(mise_eur)                                                 as mise_max_eur,
        avg(cote)                                                     as cote_moyenne,
        count_if(canal = 'APP')                                       as nb_paris_app,
        0 as nb_depots, 0 as montant_depots_eur, 0 as nb_depots_refuses_limite, 0 as nb_depots_refuses_banque,
        0 as nb_retraits, 0 as montant_retraits_eur, 0 as nb_moyens_paiement,
        0 as nb_connexions, 0 as nb_alertes_jr, 0 as nb_limites_atteintes, 0 as nb_demandes_hausse_limite,
        0 as nb_contacts_sav, 0 as nb_contacts_sav_negatifs, 0 as nb_auto_exclusions, 0 as nb_reductions_limites
    from {{ ref('paris_en_ligne') }}
    group by 1, 2
),
wallet as (
    select
        account_id,
        date_operation,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, null, 0,
        count_if(type_operation = 'DEPOT' and statut = 'ACCEPTE'),
        sum(iff(type_operation = 'DEPOT' and statut = 'ACCEPTE', montant_eur, 0)),
        count_if(type_operation = 'DEPOT' and statut = 'REFUSE_LIMITE'),
        count_if(type_operation = 'DEPOT' and statut = 'REFUSE_BANQUE'),
        count_if(type_operation = 'RETRAIT'),
        sum(iff(type_operation = 'RETRAIT', montant_eur, 0)),
        count(distinct iff(type_operation = 'DEPOT', moyen_paiement, null)),
        0, 0, 0, 0, 0, 0, 0, 0
    from {{ ref('wallet_operations') }}
    group by 1, 2
),
crm as (
    select
        account_id,
        date_interaction,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, null, 0,
        0, 0, 0, 0, 0, 0, 0,
        count_if(type_interaction = 'CONNEXION'),
        count_if(type_interaction = 'ALERTE_JEU_RESPONSABLE'),
        count_if(type_interaction = 'LIMITE_DEPOT_ATTEINTE'),
        count_if(type_interaction = 'DEMANDE_HAUSSE_LIMITE'),
        count_if(canal in ('TELEPHONE', 'CHAT')),
        count_if(canal in ('TELEPHONE', 'CHAT') and sentiment = 'NEGATIF'),
        count_if(type_interaction = 'AUTO_EXCLUSION'),
        count_if(type_interaction = 'REDUCTION_VOLONTAIRE_LIMITES')
    from {{ ref('interactions_crm') }}
    group by 1, 2
),
unioned as (
    select * from paris
    union all select * from wallet
    union all select * from crm
)
select
    account_id,
    date_activite,
    sum(nb_paris)                     as nb_paris,
    sum(mises_eur)                    as mises_eur,
    sum(gains_eur)                    as gains_eur,
    sum(mises_eur) - sum(gains_eur)   as pbj_eur,
    sum(nb_paris_nuit)                as nb_paris_nuit,
    sum(nb_produits_distincts)        as nb_produits_distincts,
    sum(mises_sport_eur)              as mises_sport_eur,
    sum(mises_hippique_eur)           as mises_hippique_eur,
    sum(mises_tirage_eur)             as mises_tirage_eur,
    sum(mises_grattage_eur)           as mises_grattage_eur,
    max(mise_max_eur)                 as mise_max_eur,
    max(cote_moyenne)                 as cote_moyenne,
    sum(nb_paris_app)                 as nb_paris_app,
    sum(nb_depots)                    as nb_depots,
    sum(montant_depots_eur)           as montant_depots_eur,
    sum(nb_depots_refuses_limite)     as nb_depots_refuses_limite,
    sum(nb_depots_refuses_banque)     as nb_depots_refuses_banque,
    sum(nb_retraits)                  as nb_retraits,
    sum(montant_retraits_eur)         as montant_retraits_eur,
    sum(nb_moyens_paiement)           as nb_moyens_paiement,
    sum(nb_connexions)                as nb_connexions,
    sum(nb_alertes_jr)                as nb_alertes_jr,
    sum(nb_limites_atteintes)         as nb_limites_atteintes,
    sum(nb_demandes_hausse_limite)    as nb_demandes_hausse_limite,
    sum(nb_contacts_sav)              as nb_contacts_sav,
    sum(nb_contacts_sav_negatifs)     as nb_contacts_sav_negatifs,
    sum(nb_auto_exclusions)           as nb_auto_exclusions,
    sum(nb_reductions_limites)        as nb_reductions_limites
from unioned
group by 1, 2
