#!/usr/bin/env python3
"""
Generador de datos sintéticos bancarios.

Produce clientes, cuentas, comercios y transacciones ficticias.
Los datos no contienen PII real — todo es generado con Faker + reglas propias.

Uso:
    python data/generate.py --customers 1000 --months 12
"""

import argparse
import json
import random
import uuid
from datetime import datetime, timedelta
from pathlib import Path

import pandas as pd
from faker import Faker

fake = Faker("es_ES")
random.seed(42)
Faker.seed(42)

ACCOUNT_TYPES = ["checking", "savings", "credit", "investment"]
CURRENCIES = ["USD", "EUR", "COP"]
SEGMENTS = ["retail", "premium", "corporate", "sme"]
TRANSACTION_TYPES = ["purchase", "transfer", "withdrawal", "deposit", "payment"]
CATEGORIES = [
    "groceries",
    "restaurants",
    "transport",
    "utilities",
    "entertainment",
    "healthcare",
    "education",
    "travel",
    "retail",
]
MERCHANT_CATEGORIES = [
    "supermarket",
    "restaurant",
    "gas_station",
    "pharmacy",
    "clothing",
    "electronics",
    "hotel",
    "airline",
    "streaming",
]


def generate_customers(n: int) -> pd.DataFrame:
    """Genera n clientes sintéticos."""
    records = [
        {
            "customer_id": str(uuid.uuid4()),
            "name": fake.name(),
            "email": fake.email(),
            "phone": fake.phone_number(),
            "birth_date": fake.date_of_birth(minimum_age=18, maximum_age=80),
            "address": fake.address().replace("\n", ", "),
            "city": fake.city(),
            "country": fake.country_code(),
            "segment": random.choice(SEGMENTS),
            "created_at": fake.date_time_between(start_date="-5y", end_date="now"),
        }
        for _ in range(n)
    ]
    return pd.DataFrame(records)


def generate_merchants(n: int = 200) -> pd.DataFrame:
    """Genera n comercios sintéticos."""
    records = [
        {
            "merchant_id": str(uuid.uuid4()),
            "name": fake.company(),
            "category": random.choice(MERCHANT_CATEGORIES),
            "city": fake.city(),
            "country": fake.country_code(),
            "is_online": random.random() < 0.3,
        }
        for _ in range(n)
    ]
    return pd.DataFrame(records)


def generate_accounts(customers: pd.DataFrame) -> pd.DataFrame:
    """Genera 1-3 cuentas por cliente."""
    records = []
    for customer_id in customers["customer_id"]:
        for _ in range(random.randint(1, 3)):
            records.append(
                {
                    "account_id": str(uuid.uuid4()),
                    "customer_id": customer_id,
                    "account_type": random.choice(ACCOUNT_TYPES),
                    "balance": round(random.uniform(-500, 100_000), 2),
                    "currency": random.choice(CURRENCIES),
                    "status": random.choices(
                        ["active", "inactive", "blocked"], weights=[80, 15, 5]
                    )[0],
                    "opened_at": fake.date_time_between(
                        start_date="-5y", end_date="now"
                    ),
                    "branch_id": f"BR-{random.randint(1, 50):03d}",
                }
            )
    return pd.DataFrame(records)


def generate_transactions(
    accounts: pd.DataFrame,
    merchants: pd.DataFrame,
    months: int = 12,
) -> pd.DataFrame:
    """Genera transacciones para las cuentas activas del período indicado."""
    active = accounts[accounts["status"] == "active"]
    merchant_ids = merchants["merchant_id"].tolist()
    end_date = datetime.now()
    start_date = end_date - timedelta(days=30 * months)

    records = []
    for account_id in active["account_id"]:
        for _ in range(random.randint(5, 50)):
            txn_date = fake.date_time_between(start_date=start_date, end_date=end_date)
            records.append(
                {
                    "transaction_id": str(uuid.uuid4()),
                    "account_id": account_id,
                    "merchant_id": random.choice(merchant_ids) if random.random() > 0.2 else None,
                    "amount": round(random.uniform(1, 5_000), 2),
                    "currency": "USD",
                    "transaction_type": random.choice(TRANSACTION_TYPES),
                    "category": random.choice(CATEGORIES),
                    "transaction_date": txn_date,
                    "description": fake.sentence(nb_words=6),
                    "status": random.choices(
                        ["completed", "pending", "failed"], weights=[90, 7, 3]
                    )[0],
                }
            )
    return pd.DataFrame(records)


def save_dataset(df: pd.DataFrame, output_dir: Path, name: str) -> None:
    """Guarda un DataFrame en CSV y Parquet."""
    output_dir.mkdir(parents=True, exist_ok=True)
    df.to_csv(output_dir / f"{name}.csv", index=False)

    # Pyarrow serializa datetime64[ns] como INT64-nanosegundos, que BigQuery no
    # reconoce como TIMESTAMP. Convertir a microsegundos UTC antes del Parquet.
    df_parquet = df.copy()
    for col in df_parquet.select_dtypes(include=["datetime64[ns]"]).columns:
        df_parquet[col] = df_parquet[col].dt.tz_localize("UTC").astype("datetime64[us, UTC]")

    df_parquet.to_parquet(output_dir / f"{name}.parquet", index=False)
    print(f"  ✓ {name:<14} {len(df):>8,} registros")


def main() -> None:
    parser = argparse.ArgumentParser(description="Genera datos sintéticos bancarios")
    parser.add_argument("--customers", type=int, default=500, help="Número de clientes")
    parser.add_argument("--months", type=int, default=12, help="Meses de historial de transacciones")
    parser.add_argument("--merchants", type=int, default=200, help="Número de comercios")
    parser.add_argument("--output", type=str, default="data/output", help="Directorio de salida")
    args = parser.parse_args()

    output_dir = Path(args.output)
    print(f"\nGenerando datos sintéticos bancarios...")
    print(f"  Clientes:  {args.customers}")
    print(f"  Comercios: {args.merchants}")
    print(f"  Historial: {args.months} meses")
    print(f"  Salida:    {output_dir}\n")

    customers = generate_customers(args.customers)
    save_dataset(customers, output_dir, "customers")

    merchants = generate_merchants(args.merchants)
    save_dataset(merchants, output_dir, "merchants")

    accounts = generate_accounts(customers)
    save_dataset(accounts, output_dir, "accounts")

    transactions = generate_transactions(accounts, merchants, args.months)
    save_dataset(transactions, output_dir, "transactions")

    summary = {
        "customers": len(customers),
        "merchants": len(merchants),
        "accounts": len(accounts),
        "transactions": len(transactions),
        "generated_at": datetime.now().isoformat(),
    }
    (output_dir / "summary.json").write_text(json.dumps(summary, indent=2))
    print(f"\n  Resumen guardado en {output_dir}/summary.json")
    print(f"\nTotal transacciones generadas: {len(transactions):,}")


if __name__ == "__main__":
    main()
