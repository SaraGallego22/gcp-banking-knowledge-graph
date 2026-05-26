-- Dimensión cliente: enriquece cada cliente con métricas de sus cuentas.
with customers as (
    select * from {{ ref('stg_customers') }}
),

accounts as (
    select * from {{ ref('stg_accounts') }}
),

account_metrics as (
    select
        customer_id,
        count(*)                                        as total_accounts,
        countif(is_active)                              as active_accounts,
        round(sum(balance), 2)                          as total_balance,
        round(avg(balance), 2)                          as avg_balance,
        min(opened_at)                                  as first_account_opened_at,
        array_agg(distinct account_type order by account_type) as account_types

    from accounts
    group by customer_id
),

final as (
    select
        c.customer_id,
        c.name,
        c.email,
        c.phone,
        c.birth_date,
        c.age_years,
        c.city,
        c.country,
        c.segment,
        c.created_at,

        coalesce(m.total_accounts,  0)    as total_accounts,
        coalesce(m.active_accounts, 0)    as active_accounts,
        coalesce(m.total_balance,   0.0)  as total_balance,
        coalesce(m.avg_balance,     0.0)  as avg_balance,
        m.first_account_opened_at,
        m.account_types

    from customers c
    left join account_metrics m using (customer_id)
)

select * from final
