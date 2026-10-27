-- Aucune activité ne doit être enregistrée après la date de génération (J-1)
select date_activite from {{ ref('fct_activite_quotidienne') }} where date_activite > current_date()
