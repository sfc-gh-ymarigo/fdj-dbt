-- Quarantaine : tous les enregistrements rejetés, avec leur motif (volume on-prem, schéma DQ)
select 'PARIS_EN_LIGNE' as source, bet_id as cle_enregistrement, motif_rejet, horodatage_brut as valeur_controlee,
       left(raw_json, 2000) as enregistrement_brut, _file_name, _load_ts
from {{ ref('int_paris_qualifies') }}
where motif_rejet is not null

union all

select 'WALLET', transaction_id, motif_rejet, coalesce(montant_eur::string, 'NULL') || ' / ' || coalesce(moyen_paiement, 'NULL'),
       object_construct('transaction_id', transaction_id, 'account_id', account_id, 'montant', montant_eur,
                        'moyen_paiement', moyen_paiement, 'statut', statut)::string,
       _file_name, _load_ts
from {{ ref('int_wallet_qualifie') }}
where motif_rejet is not null

union all

select 'VENTES_PDV', id_pdv || '|' || coalesce(date_vente::string, '?') || '|' || code_produit, motif_rejet,
       coalesce(montant_ventes_eur::string, 'NULL'),
       object_construct('date_vente', date_vente, 'id_pdv', id_pdv, 'code_produit', code_produit,
                        'montant_ventes', montant_ventes_eur)::string,
       _file_name, _load_ts
from {{ ref('int_ventes_pdv_qualifiees') }}
where motif_rejet is not null
