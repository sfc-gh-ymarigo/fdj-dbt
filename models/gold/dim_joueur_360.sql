-- Player 360 (joueurs en ligne) : profil, valeur, comportement, signaux jeu responsable
with agg as (
    select
        account_id,
        min(iff(nb_paris > 0, date_activite, null))           as date_premier_pari,
        max(iff(nb_paris > 0, date_activite, null))           as date_dernier_pari,
        count_if(nb_paris > 0)                                as nb_jours_actifs,
        sum(nb_paris)                                         as nb_paris_total,
        sum(mises_eur)                                        as mises_totales_eur,
        sum(gains_eur)                                        as gains_totaux_eur,
        sum(pbj_eur)                                          as pbj_total_eur,
        sum(montant_depots_eur)                               as depots_totaux_eur,
        sum(montant_retraits_eur)                             as retraits_totaux_eur,
        sum(nb_paris_nuit)                                    as nb_paris_nuit,
        sum(nb_paris_app)                                     as nb_paris_app,
        sum(mises_sport_eur)                                  as mises_sport_eur,
        sum(mises_hippique_eur)                               as mises_hippique_eur,
        sum(mises_tirage_eur)                                 as mises_tirage_eur,
        sum(mises_grattage_eur)                               as mises_grattage_eur,
        sum(nb_alertes_jr)                                    as nb_alertes_jr,
        sum(nb_limites_atteintes)                             as nb_limites_atteintes,
        sum(nb_auto_exclusions)                               as nb_auto_exclusions,
        sum(nb_contacts_sav_negatifs)                         as nb_contacts_sav_negatifs
    from {{ ref('fct_joueur_quotidien') }}
    group by 1
)
select
    c.account_id,
    c.civilite,
    c.departement,
    c.age_a_la_maj                                                        as age,
    case
        when c.age_a_la_maj < 25 then '18-24'
        when c.age_a_la_maj < 35 then '25-34'
        when c.age_a_la_maj < 50 then '35-49'
        when c.age_a_la_maj < 65 then '50-64'
        else '65+'
    end                                                                   as tranche_age,
    c.date_inscription,
    c.statut_kyc,
    c.limite_depot_mensuelle,
    c.optin_marketing,
    a.date_premier_pari,
    a.date_dernier_pari,
    coalesce(a.nb_jours_actifs, 0)                                        as nb_jours_actifs,
    coalesce(a.nb_paris_total, 0)                                         as nb_paris_total,
    coalesce(a.mises_totales_eur, 0)                                      as mises_totales_eur,
    coalesce(a.gains_totaux_eur, 0)                                       as gains_totaux_eur,
    coalesce(a.pbj_total_eur, 0)                                          as pbj_total_eur,
    coalesce(a.depots_totaux_eur, 0)                                      as depots_totaux_eur,
    coalesce(a.retraits_totaux_eur, 0)                                    as retraits_totaux_eur,
    case greatest(coalesce(a.mises_sport_eur, 0), coalesce(a.mises_hippique_eur, 0),
                  coalesce(a.mises_tirage_eur, 0), coalesce(a.mises_grattage_eur, 0))
        when 0 then null
        when a.mises_sport_eur then 'PARIS_SPORTIFS'
        when a.mises_hippique_eur then 'PARIS_HIPPIQUES'
        when a.mises_tirage_eur then 'TIRAGE'
        else 'GRATTAGE'
    end                                                                   as famille_preferee,
    div0(a.nb_paris_app, a.nb_paris_total)                                as part_paris_app,
    div0(a.nb_paris_nuit, a.nb_paris_total)                               as part_paris_nuit,
    coalesce(a.nb_alertes_jr, 0)                                          as nb_alertes_jr,
    coalesce(a.nb_limites_atteintes, 0)                                   as nb_limites_atteintes,
    coalesce(a.nb_auto_exclusions, 0) > 0                                 as auto_exclu,
    coalesce(a.nb_contacts_sav_negatifs, 0)                               as nb_contacts_sav_negatifs
from {{ ref('clients') }} c
left join agg a on a.account_id = c.account_id
