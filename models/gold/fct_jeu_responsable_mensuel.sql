-- Indicateurs jeu responsable mensuels (comparables au dossier de presse :
-- "part du CA portée par des joueurs à risque élevé" = 1 % en loterie en ligne France en 2024)
with mensuel as (
    select
        account_id,
        date_trunc('month', date_activite)          as mois,
        sum(mises_eur)                              as mises_eur,
        sum(pbj_eur)                                as pbj_eur,
        sum(nb_paris_nuit)                          as nb_paris_nuit,
        sum(nb_paris)                               as nb_paris,
        sum(nb_alertes_jr)                          as nb_alertes_jr,
        sum(nb_limites_atteintes)                   as nb_limites_atteintes,
        sum(nb_demandes_hausse_limite)              as nb_demandes_hausse_limite,
        sum(nb_auto_exclusions)                     as nb_auto_exclusions
    from {{ ref('fct_joueur_quotidien') }}
    group by 1, 2
)
select
    mois,
    count_if(nb_paris > 0)                                                    as nb_joueurs_actifs,
    count_if(nb_alertes_jr > 0)                                               as nb_joueurs_alertes,
    count_if(nb_limites_atteintes > 0)                                        as nb_joueurs_limite_atteinte,
    sum(nb_auto_exclusions)                                                   as nb_auto_exclusions,
    -- règle métier (avant ML) : joueur "à risque élevé" sur le mois
    count_if(nb_limites_atteintes >= 2 or nb_alertes_jr >= 3 or nb_demandes_hausse_limite > 0)  as nb_joueurs_risque_eleve_regle,
    sum(iff(nb_limites_atteintes >= 2 or nb_alertes_jr >= 3 or nb_demandes_hausse_limite > 0, mises_eur, 0)) as mises_joueurs_risque_eleve_eur,
    sum(mises_eur)                                                            as mises_total_eur,
    sum(pbj_eur)                                                              as pbj_total_eur,
    -- part des mises (plus stable que le PBJ, sensible aux gros gains ponctuels)
    div0(mises_joueurs_risque_eleve_eur, mises_total_eur)                     as part_mises_risque_eleve,
    div0(sum(nb_paris_nuit), sum(nb_paris))                                   as part_paris_nuit
from mensuel
group by 1
