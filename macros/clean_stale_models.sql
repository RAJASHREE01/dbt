{% macro clean_stale_models(database=target.database, schema=target.schema, days=10, dry_run=True) %}

    {% set get_drop_commands_query %}
        select
            case when table_type = 'VIEW' then 'VIEW' else 'TABLE' end as drop_type,
            'drop ' || case when table_type = 'VIEW' then 'view' else 'table' end || ' {{ database | upper }}.' || table_schema || '.' || table_name || ';' as drop_query
        from {{ database }}.information_schema.tables
        where table_schema = upper('{{ schema }}')
          and last_altered <= current_date - {{ days }}
    {% endset %}

    {{ log('\nGenerating cleanup queries...\n', info=True) }}
    {% set results = run_query(get_drop_commands_query) %}
    {% set drop_queries = results.columns[1].values() if execute else [] %}

    {% for drop_query in drop_queries %}
        {% if execute and not dry_run %}
            {{ log('Dropping table/view with command: ' ~ drop_query, info=True) }}
            {% do run_query(drop_query) %}
        {% else %}
            {{ log(drop_query, info=True) }}
        {% endif %}
    {% endfor %}

{% endmacro %}
