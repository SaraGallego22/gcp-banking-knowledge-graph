with merchants as (
    select * from {{ ref('stg_merchants') }}
),

txn_metrics as (
    select
        merchant_id,
        count(*)            as total_transactions,
        round(sum(amount), 2)  as total_volume,
        round(avg(amount), 2)  as avg_ticket,
        min(transaction_date)  as first_transaction_at,
        max(transaction_date)  as last_transaction_at

    from {{ ref('stg_transactions') }}
    where merchant_id is not null
    group by merchant_id
),

final as (
    select
        m.merchant_id,
        m.name,
        m.category,
        m.city,
        m.country,
        m.is_online,

        coalesce(t.total_transactions, 0)   as total_transactions,
        coalesce(t.total_volume,       0.0) as total_volume,
        coalesce(t.avg_ticket,         0.0) as avg_ticket,
        t.first_transaction_at,
        t.last_transaction_at

    from merchants m
    left join txn_metrics t using (merchant_id)
)

select * from final
