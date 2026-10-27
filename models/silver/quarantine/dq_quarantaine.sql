-- Quarantaine : tous les enregistrements rejetés, avec leur motif (volume on-prem, schéma DQ).
-- type_rejet       : REFERENTIEL (se résorbe seul à l'arrivée de la référence) | CONTENU (décision steward) | DOUBLON
-- statut_traitement : A_TRAITER | AUTO_RESORPTION | CORRIGE_TOUJOURS_REJETE | REJET_DEFINITIF | CLOS_DOUBLON
-- Une ligne corrigée et devenue conforme sort de la quarantaine : elle est alors dans SILVER.
with rejets as (
    select 'PARIS_EN_LIGNE' as source, bet_id as cle_enregistrement, motif_rejet, horodatage_brut as valeur_controlee,
           left(raw_json, 2000) as enregistrement_brut, decision_steward, _file_name, _load_ts
    from {{ ref('int_paris_qualifies') }}
    where motif_rejet is not null

    union all

    select 'WALLET', transaction_id, motif_rejet,
           coalesce(montant_eur::string, 'NULL') || ' / ' || coalesce(moyen_paiement, 'NULL'),
           object_construct('transaction_id', transaction_id, 'account_id', account_id, 'montant', montant_eur_recu,
                            'moyen_paiement', moyen_paiement_recu, 'statut', statut)::string,
           decision_steward, _file_name, _load_ts
    from {{ ref('int_wallet_qualifie') }}
    where motif_rejet is not null

    union all

    select 'VENTES_PDV', id_pdv || '|' || coalesce(date_vente::string, '?') || '|' || code_produit, motif_rejet,
           coalesce(montant_ventes_eur::string, 'NULL'),
           object_construct('date_vente', date_vente, 'id_pdv', id_pdv, 'code_produit', code_produit,
                            'montant_ventes', montant_ventes_eur_recu)::string,
           decision_steward, _file_name, _load_ts
    from {{ ref('int_ventes_pdv_qualifiees') }}
    where motif_rejet is not null
)

select
    source,
    cle_enregistrement,
    motif_rejet,
    case
        when motif_rejet = 'DOUBLON' then 'DOUBLON'
        when motif_rejet in ('COMPTE_INCONNU', 'PRODUIT_INCONNU', 'PDV_INCONNU') then 'REFERENTIEL'
        else 'CONTENU'
    end                                                     as type_rejet,
    case
        when motif_rejet = 'DOUBLON' then 'CLOS_DOUBLON'
        when decision_steward = 'REJET_DEFINITIF' then 'REJET_DEFINITIF'
        when decision_steward is not null then 'CORRIGE_TOUJOURS_REJETE'
        when motif_rejet in ('COMPTE_INCONNU', 'PRODUIT_INCONNU', 'PDV_INCONNU') then 'AUTO_RESORPTION'
        else 'A_TRAITER'
    end                                                     as statut_traitement,
    decision_steward,
    valeur_controlee,
    enregistrement_brut,
    _file_name,
    _load_ts
from rejets
