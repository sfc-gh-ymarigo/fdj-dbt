{{ config(external_volume='ICEBERG_SILO_VOLUME') }}
select
    date_key::date                                   as date_key,
    try_to_number(jour_semaine)                      as jour_semaine,
    try_to_boolean(is_weekend)                       as is_weekend,
    try_to_boolean(tirage_loto)                      as tirage_loto,
    try_to_number(jackpot_loto_meur, 10, 1)          as jackpot_loto_meur,
    try_to_boolean(tirage_euromillions)              as tirage_euromillions,
    try_to_number(jackpot_euromillions_meur, 10, 1)  as jackpot_euromillions_meur,
    try_to_boolean(tirage_eurodreams)                as tirage_eurodreams,
    try_to_boolean(saison_ligue1)                    as saison_ligue1,
    try_to_boolean(soiree_ligue_champions)           as soiree_ligue_champions,
    try_to_boolean(coupe_du_monde_2026)              as coupe_du_monde_2026,
    try_to_boolean(roland_garros)                    as roland_garros,
    try_to_boolean(six_nations)                      as six_nations,
    try_to_boolean(prix_arc_triomphe)                as prix_arc_triomphe,
    try_to_boolean(periode_fetes)                    as periode_fetes
from {{ source('raw', 'ref_calendrier') }}
