# pipelines/dbt — Capa Curated (Medallion)

Transforma los datos crudos de `banking_raw` en modelos limpios y enriquecidos en `banking_curated`.

## Arquitectura

```
banking_raw.*          →   staging (vistas)   →   marts (tablas)   →   banking_curated.*
customers                  stg_customers          dim_customers
accounts                   stg_accounts           dim_merchants
transactions               stg_transactions       fact_transactions
merchants                  stg_merchants
```

## Setup local

```bash
cd pipelines/dbt

# Instalar dependencias dbt (ya están en requirements.txt)
pip install dbt-bigquery

# Autenticar con GCP
gcloud auth application-default login

# Verificar conexión
dbt debug --profiles-dir .

# Ejecutar todos los modelos
dbt run --profiles-dir .

# Ejecutar solo staging
dbt run --profiles-dir . --select staging

# Ejecutar tests de calidad
dbt test --profiles-dir .
```

## Variables de entorno requeridas

| Variable | Descripción |
|----------|-------------|
| `GCP_PROJECT_ID` | ID del proyecto GCP |
| `GCP_REGION` | Región BigQuery (default: us-central1) |

## Modelos

### Staging
Vistas ligeras que limpian y normalizan los datos crudos. No hacen joins ni cálculos pesados.

| Modelo | Fuente | Transformaciones |
|--------|--------|-----------------|
| `stg_customers` | `banking_raw.customers` | Trim, lower/upper, calcula edad |
| `stg_accounts` | `banking_raw.accounts` | Trim, coalesce balance nulo a 0, flag is_active |
| `stg_merchants` | `banking_raw.merchants` | Trim, normaliza booleans |
| `stg_transactions` | `banking_raw.transactions` | Filtra solo `status=completed` y `amount>0` |

### Marts
Tablas físicas con lógica de negocio y métricas agregadas.

| Modelo | Descripción |
|--------|-------------|
| `dim_customers` | Cliente + métricas de cuentas (total, balance, tipos) |
| `dim_merchants` | Comercio + métricas de volumen transaccional |
| `fact_transactions` | Tabla de hechos con customer_id denormalizado para evitar joins |
