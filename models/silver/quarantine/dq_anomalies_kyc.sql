-- Contrôles de conformité KYC (pas des rejets : le compte existe, mais doit être traité)
select
    account_id,
    derniere_maj,
    case
        when alerte_mineur then 'COMPTE_MINEUR'
        when not email_valide then 'EMAIL_INVALIDE'
        when code_postal is null then 'CODE_POSTAL_MANQUANT'
        when alerte_encodage then 'ENCODAGE_CASSE'
    end as anomalie_kyc
from {{ ref('clients') }}
where alerte_mineur or not email_valide or code_postal is null or alerte_encodage
