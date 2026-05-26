-- Limpieza de clientes: descarta registros sin ID y normaliza campos de texto.
with source as (
    select * from {{ source('banking_raw', 'customers') }}
),

cleaned as (
    select
        customer_id,
        trim(name)                              as name,
        lower(trim(email))                      as email,
        phone,
        birth_date,
        trim(address)                           as address,
        initcap(trim(city))                     as city,
        upper(trim(country))                    as country,
        lower(trim(segment))                    as segment,
        created_at,

        -- Edad calculada para segmentación posterior
        date_diff(current_date(), birth_date, year) as age_years

    from source
    where customer_id is not null
      and name is not null
)

select * from cleaned
