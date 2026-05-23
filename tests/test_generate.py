"""Tests para el generador de datos sintéticos."""

import pandas as pd
import pytest

from data.generate import (
    generate_accounts,
    generate_customers,
    generate_merchants,
    generate_transactions,
)


def test_generate_customers_count():
    df = generate_customers(10)
    assert len(df) == 10


def test_generate_customers_unique_ids():
    df = generate_customers(50)
    assert df["customer_id"].nunique() == 50


def test_generate_customers_required_columns():
    df = generate_customers(5)
    required = {"customer_id", "name", "email", "segment", "created_at"}
    assert required.issubset(df.columns)


def test_generate_merchants():
    df = generate_merchants(20)
    assert len(df) == 20
    assert df["merchant_id"].nunique() == 20


def test_generate_accounts_min_one_per_customer():
    customers = generate_customers(10)
    accounts = generate_accounts(customers)
    assert len(accounts) >= 10


def test_generate_accounts_valid_customer_refs():
    customers = generate_customers(10)
    accounts = generate_accounts(customers)
    assert set(accounts["customer_id"]).issubset(set(customers["customer_id"]))


def test_generate_accounts_valid_status():
    customers = generate_customers(20)
    accounts = generate_accounts(customers)
    valid_statuses = {"active", "inactive", "blocked"}
    assert set(accounts["status"]).issubset(valid_statuses)


def test_generate_transactions_not_empty():
    customers = generate_customers(10)
    merchants = generate_merchants(20)
    accounts = generate_accounts(customers)
    transactions = generate_transactions(accounts, merchants, months=1)
    assert len(transactions) > 0


def test_generate_transactions_valid_account_refs():
    customers = generate_customers(10)
    merchants = generate_merchants(20)
    accounts = generate_accounts(customers)
    transactions = generate_transactions(accounts, merchants, months=1)
    active_ids = set(accounts[accounts["status"] == "active"]["account_id"])
    assert set(transactions["account_id"]).issubset(active_ids)
