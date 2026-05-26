with source as (
    select * from {{ source('banking_raw', 'merchants') }}
),

cleaned as (
    select
        merchant_id,
        trim(name)                  as name,
        lower(trim(category))       as category,
        initcap(trim(city))         as city,
        upper(trim(country))        as country,
        coalesce(is_online, false)  as is_online

    from source
    where merchant_id is not null
      and name        is not null
)

select * from cleaned
