-- Solo transacciones completadas: pending y failed se excluyen del knowledge graph.
with source as (
    select * from {{ source('banking_raw', 'transactions') }}
),

completed as (
    select
        transaction_id,
        account_id,
        merchant_id,
        amount,
        upper(trim(currency))           as currency,
        lower(trim(transaction_type))   as transaction_type,
        lower(trim(category))           as category,
        transaction_date,
        date(transaction_date)          as transaction_day,
        trim(description)               as description,
        lower(trim(status))             as status

    from source
    where status      = 'completed'
      and transaction_id is not null
      and account_id     is not null
      and amount         > 0
)

select * from completed
