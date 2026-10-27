-- Labels à 30 jours (futur strict après snapshot_date) = "spine" d'entraînement.
--   label_risque_jeu_30j : auto-exclusion, réduction volontaire des limites, ou >= 3 alertes jeu responsable
--   label_churn_30j      : aucun pari dans les 30 jours (hors joueurs auto-exclus / limités)
-- Les snapshots des 30 derniers jours n'ont pas encore de label (label_disponible = false) : ce sont
-- les populations à scorer.
with bornes as (
    select max(date_activite) as d_max from {{ ref('fct_joueur_quotidien') }}
),
futur as (
    select
        s.account_id,
        s.snapshot_date,
        sum(f.nb_paris)                                                          as nb_paris_futur_30j,
        sum(f.nb_alertes_jr)                                                     as nb_alertes_futur_30j,
        max(iff(f.nb_auto_exclusions > 0 or f.nb_reductions_limites > 0, 1, 0))  as evenement_rg_futur_30j
    from {{ ref('feat_joueur_snapshot') }} s
    join {{ ref('fct_joueur_quotidien') }} f
      on f.account_id = s.account_id
     and f.date_activite > s.snapshot_date
     and f.date_activite <= dateadd('day', 30, s.snapshot_date)
    group by 1, 2
)
select
    s.account_id,
    s.snapshot_date,
    (s.snapshot_date <= dateadd('day', -30, b.d_max))                            as label_disponible,
    iff(label_disponible,
        iff(coalesce(fu.evenement_rg_futur_30j, 0) = 1 or coalesce(fu.nb_alertes_futur_30j, 0) >= 3, 1, 0),
        null)                                                                    as label_risque_jeu_30j,
    iff(label_disponible,
        iff(coalesce(fu.nb_paris_futur_30j, 0) = 0 and coalesce(fu.evenement_rg_futur_30j, 0) = 0, 1, 0),
        null)                                                                    as label_churn_30j
from {{ ref('feat_joueur_snapshot') }} s
cross join bornes b
left join futur fu
  on fu.account_id = s.account_id
 and fu.snapshot_date = s.snapshot_date
