-- Tabla de hechos central del knowledge graph: une transacciones con todas sus dimensiones.
with transactions as (
    select * from {{ ref('stg_transactions') }}
),

accounts as (
    select account_id, customer_id, account_type, currency, branch_id
    from {{ ref('stg_accounts') }}
),

final as (
    select
        -- Claves
        t.transaction_id,
        t.account_id,
        a.customer_id,
        t.merchant_id,

        -- Métricas
        t.amount,
        t.currency,
        t.transaction_type,
        t.category,

        -- Tiempo
        t.transaction_date,
        t.transaction_day,
        extract(year  from t.transaction_date) as transaction_year,
        extract(month from t.transaction_date) as transaction_month,
        extract(dayofweek from t.transaction_date) as transaction_dow,

        -- Atributos de cuenta (denormalizados para evitar joins en consultas)
        a.account_type,
        a.branch_id,

        t.description

    from transactions t
    left join accounts a using (account_id)
)

select * from final
