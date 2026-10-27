{{ config(severity='warn') }}
-- Rapprochement wallet <-> jeu : solde reconstruit (dépôts + bonus + gains - retraits - mises) par joueur.
-- Un solde final négatif signale des mises acceptées sans provision (ex. dépôt refusé) -> à investiguer.
select account_id, sum(montant_depots_eur) + sum(gains_eur) - sum(montant_retraits_eur) - sum(mises_eur) as solde_reconstruit
from {{ ref('fct_joueur_quotidien') }}
group by 1
having solde_reconstruit < -50
