with source as (
    select * from {{ source('banking_raw', 'accounts') }}
),

cleaned as (
    select
        account_id,
        customer_id,
        lower(trim(account_type))   as account_type,
        coalesce(balance, 0.0)      as balance,
        upper(trim(currency))       as currency,
        lower(trim(status))         as status,
        opened_at,
        branch_id,

        -- Flag útil para filtrar en modelos downstream
        (lower(trim(status)) = 'active') as is_active

    from source
    where account_id  is not null
      and customer_id is not null
)

select * from cleaned
