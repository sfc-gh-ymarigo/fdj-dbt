{{ config(external_volume='ICEBERG_SILO_VOLUME') }}
-- Vue courante des clients en ligne, enrichie de contrôles de conformité (âge, e-mail, encodage)
select
    account_id,
    civilite,
    prenom,
    nom,
    email,
    telephone,
    date_naissance,
    code_postal,
    case
        when code_postal is null then null
        when left(code_postal, 2) = '97' then left(code_postal, 3)
        when left(code_postal, 2) = '20' then iff(try_to_number(code_postal) < 20200, '2A', '2B')
        else left(code_postal, 2)
    end                                                                        as departement,
    ville,
    date_inscription,
    statut_kyc,
    limite_depot_mensuelle,
    optin_marketing,
    valid_from                                                                 as derniere_maj,
    datediff('year', date_naissance, valid_from::date)
        - iff(dateadd('year', datediff('year', date_naissance, valid_from::date), date_naissance) > valid_from::date, 1, 0)
                                                                               as age_a_la_maj,
    regexp_like(email, '^[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,}$')             as email_valide,
    (age_a_la_maj < 18)                                                        as alerte_mineur,
    (contains(nom, 'Ã') or contains(ville, 'Ã'))                              as alerte_encodage
from {{ ref('int_clients_historique') }}
where valid_to is null
