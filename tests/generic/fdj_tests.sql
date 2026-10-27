{% test fdj_valeur_positive(model, column_name) %}
select {{ column_name }} from {{ model }} where {{ column_name }} <= 0
{% endtest %}

{% test fdj_unicite_combinee(model, colonnes) %}
select {{ colonnes | join(', ') }}, count(*) as n
from {{ model }}
group by {{ colonnes | join(', ') }}
having count(*) > 1
{% endtest %}
