-- Features joueur à date d'observation (instantané tous les 14 jours, fenêtres 7 / 30 / 90 jours).
-- Uniquement de l'information connue à snapshot_date (aucune fuite du futur).
-- Population : joueurs en ligne actifs dans les 30 derniers jours et non auto-exclus.
with bornes as (
    select min(date_activite) as d_min, max(date_activite) as d_max
    from {{ ref('fct_joueur_quotidien') }}
),
snapshots as (
    select c.date_key as snapshot_date
    from {{ ref('ref_calendrier') }} c
    cross join bornes b
    where mod(datediff('day', c.date_key, b.d_max), 14) = 0
      and c.date_key >= dateadd('day', 90, b.d_min)
      and c.date_key <= b.d_max
),
historique as (
    select
        s.snapshot_date,
        f.*,
        datediff('day', f.date_activite, s.snapshot_date) as anciennete_j
    from snapshots s
    join {{ ref('fct_joueur_quotidien') }} f
      on f.date_activite > dateadd('day', -90, s.snapshot_date)
     and f.date_activite <= s.snapshot_date
),
agg as (
    select
        account_id,
        snapshot_date,
        sum(iff(anciennete_j < 7, nb_paris, 0))                          as nb_paris_7j,
        sum(iff(anciennete_j < 30, nb_paris, 0))                         as nb_paris_30j,
        sum(nb_paris)                                                    as nb_paris_90j,
        sum(iff(anciennete_j < 7, mises_eur, 0))                         as mises_7j,
        sum(iff(anciennete_j < 30, mises_eur, 0))                        as mises_30j,
        sum(iff(anciennete_j >= 30 and anciennete_j < 60, mises_eur, 0)) as mises_30_60j,
        sum(mises_eur)                                                   as mises_90j,
        sum(iff(anciennete_j < 30, pbj_eur, 0))                          as pbj_30j,
        count_if(anciennete_j < 30 and nb_paris > 0)                     as jours_actifs_30j,
        count_if(nb_paris > 0)                                           as jours_actifs_90j,
        sum(iff(anciennete_j < 30, nb_paris_nuit, 0))                    as nb_paris_nuit_30j,
        max(iff(anciennete_j < 30, mise_max_eur, null))                  as mise_max_30j,
        sum(iff(anciennete_j < 30, mises_sport_eur + mises_hippique_eur, 0)) as mises_paris_30j,
        sum(iff(anciennete_j < 30, nb_depots, 0))                        as nb_depots_30j,
        sum(iff(anciennete_j < 7, nb_depots, 0))                         as nb_depots_7j,
        sum(iff(anciennete_j < 30, montant_depots_eur, 0))               as depots_30j,
        max(iff(anciennete_j < 30, nb_depots, 0))                        as max_depots_jour_30j,
        max(iff(anciennete_j < 30, nb_moyens_paiement, 0))               as max_moyens_paiement_jour_30j,
        sum(iff(anciennete_j < 30, nb_depots_refuses_limite, 0))         as nb_refus_limite_30j,
        sum(iff(anciennete_j < 30, nb_depots_refuses_banque, 0))         as nb_refus_banque_30j,
        sum(iff(anciennete_j < 30, nb_retraits, 0))                      as nb_retraits_30j,
        sum(iff(anciennete_j < 30, nb_connexions, 0))                    as nb_connexions_30j,
        sum(iff(anciennete_j < 30, nb_alertes_jr, 0))                    as nb_alertes_jr_30j,
        sum(nb_alertes_jr)                                               as nb_alertes_jr_90j,
        sum(iff(anciennete_j < 30, nb_limites_atteintes, 0))             as nb_limites_atteintes_30j,
        sum(nb_demandes_hausse_limite)                                   as nb_hausses_limite_90j,
        sum(iff(anciennete_j < 30, nb_contacts_sav, 0))                  as nb_contacts_sav_30j,
        sum(iff(anciennete_j < 30, nb_contacts_sav_negatifs, 0))         as nb_sav_negatifs_30j,
        min(iff(nb_paris > 0, anciennete_j, null))                       as jours_depuis_dernier_pari,
        sum(nb_auto_exclusions)                                          as nb_auto_exclusions_90j
    from historique
    group by 1, 2
)
select
    a.account_id,
    a.snapshot_date,
    -- activité
    a.nb_paris_7j,
    a.nb_paris_30j,
    a.nb_paris_90j,
    a.jours_actifs_30j,
    a.jours_actifs_90j,
    a.jours_depuis_dernier_pari,
    -- valeur et tendance
    a.mises_7j,
    a.mises_30j,
    a.mises_90j,
    a.pbj_30j,
    a.mise_max_30j,
    div0(a.mises_30j, a.mises_30_60j)                                     as tendance_mises_30j,
    div0(a.mises_7j * 30 / 7, a.mises_30j)                                as acceleration_mises_7j,
    div0(a.mises_30j, a.nb_paris_30j)                                     as mise_moyenne_30j,
    -- comportement
    div0(a.nb_paris_nuit_30j, a.nb_paris_30j)                             as part_paris_nuit_30j,
    div0(a.mises_paris_30j, a.mises_30j)                                  as part_paris_sportifs_hippiques_30j,
    -- portefeuille
    a.nb_depots_30j,
    a.nb_depots_7j,
    a.depots_30j,
    a.max_depots_jour_30j,
    a.max_moyens_paiement_jour_30j,
    a.nb_refus_limite_30j,
    a.nb_refus_banque_30j,
    a.nb_retraits_30j,
    div0(a.depots_30j, c.limite_depot_mensuelle)                          as taux_utilisation_limite_30j,
    -- relation / signaux jeu responsable
    a.nb_connexions_30j,
    a.nb_alertes_jr_30j,
    a.nb_alertes_jr_90j,
    a.nb_limites_atteintes_30j,
    a.nb_hausses_limite_90j,
    a.nb_contacts_sav_30j,
    a.nb_sav_negatifs_30j,
    -- profil
    c.age_a_la_maj                                                        as age,
    datediff('day', c.date_inscription, a.snapshot_date)                  as anciennete_compte_j,
    c.limite_depot_mensuelle
from agg a
join {{ ref('clients') }} c on c.account_id = a.account_id
where a.nb_paris_30j > 0
  and a.nb_auto_exclusions_90j = 0
