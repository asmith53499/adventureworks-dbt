{#
    ISO day of week: 1 = Monday ... 7 = Sunday.

    DuckDB and Snowflake disagree on dayofweek()/dayname() (Sunday = 0 vs
    session-dependent week start, 'Monday' vs 'Mon'), so dispatch to each
    engine's ISO-specific function instead.
#}

{% macro day_of_week_iso(date_expr) %}
    {{ return(adapter.dispatch('day_of_week_iso', 'adventureworks')(date_expr)) }}
{% endmacro %}

{% macro default__day_of_week_iso(date_expr) %}
    extract(isodow from {{ date_expr }})
{% endmacro %}

{% macro duckdb__day_of_week_iso(date_expr) %}
    isodow({{ date_expr }})
{% endmacro %}

{% macro snowflake__day_of_week_iso(date_expr) %}
    dayofweekiso({{ date_expr }})
{% endmacro %}
