#!/usr/bin/env python3
"""
Ingesta de datos sintéticos a GCP.

Flujo:
    data/output/*.parquet  →  GCS (raw/)  →  BigQuery (banking_raw.*)

Las tablas en BigQuery ya existen (creadas por Terraform).
Este script solo carga datos; no modifica esquemas.

Uso:
    python data/upload.py
    python data/upload.py --project mi-proyecto --input data/output
    python data/upload.py --dry-run   # muestra qué haría sin ejecutar nada
"""

import argparse
import logging
import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from google.cloud import bigquery, storage
from google.cloud.bigquery import LoadJobConfig, SourceFormat, WriteDisposition

load_dotenv(".env.local")

logging.basicConfig(
    format="%(asctime)s  %(levelname)-8s %(message)s",
    datefmt="%H:%M:%S",
    level=logging.INFO,
)
log = logging.getLogger(__name__)

# Tablas que existen en Terraform → no cambiar nombres sin actualizar bigquery.tf
TABLES = ["customers", "merchants", "accounts", "transactions"]

# Prefijo dentro del bucket donde se guardan los Parquet crudos
GCS_PREFIX = "raw"


def upload_to_gcs(
    bucket_name: str,
    input_dir: Path,
    tables: list[str],
    dry_run: bool = False,
) -> dict[str, str]:
    """Sube los archivos Parquet al bucket de GCS y devuelve los URIs por tabla."""
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    uris: dict[str, str] = {}

    for table in tables:
        local_path = input_dir / f"{table}.parquet"
        if not local_path.exists():
            log.error("No encontrado: %s — ejecuta data/generate.py primero", local_path)
            sys.exit(1)

        blob_name = f"{GCS_PREFIX}/{table}.parquet"
        uri = f"gs://{bucket_name}/{blob_name}"

        if dry_run:
            log.info("[DRY-RUN] subiría %s → %s", local_path, uri)
        else:
            log.info("Subiendo %s → %s", local_path.name, uri)
            bucket.blob(blob_name).upload_from_filename(str(local_path))
            log.info("  ✓ subido (%s MB)", round(local_path.stat().st_size / 1e6, 1))

        uris[table] = uri

    return uris


def load_to_bigquery(
    project_id: str,
    dataset_id: str,
    uris: dict[str, str],
    dry_run: bool = False,
) -> None:
    """Carga los Parquet desde GCS a las tablas de BigQuery (WRITE_TRUNCATE)."""
    client = bigquery.Client(project=project_id)

    for table, uri in uris.items():
        destination = f"{project_id}.{dataset_id}.{table}"

        if dry_run:
            log.info("[DRY-RUN] cargaría %s → %s", uri, destination)
            continue

        log.info("Cargando %s → %s", uri, destination)

        job_config = LoadJobConfig(
            source_format=SourceFormat.PARQUET,
            write_disposition=WriteDisposition.WRITE_TRUNCATE,  # reemplaza en cada carga
            autodetect=False,  # el esquema ya existe en BQ; no inferir
        )

        job = client.load_table_from_uri(uri, destination, job_config=job_config)
        job.result()  # espera a que termine

        dest_table = client.get_table(destination)
        log.info("  ✓ %s — %d filas", table, dest_table.num_rows)


def main() -> None:
    parser = argparse.ArgumentParser(description="Sube datos sintéticos a GCS y BigQuery")
    parser.add_argument(
        "--project",
        default=os.getenv("GCP_PROJECT_ID"),
        help="GCP project ID (o env var GCP_PROJECT_ID)",
    )
    parser.add_argument(
        "--bucket",
        default=os.getenv("DATA_LAKE_BUCKET"),
        help="Nombre del bucket GCS (o env var DATA_LAKE_BUCKET)",
    )
    parser.add_argument(
        "--dataset",
        default="banking_raw",
        help="Dataset de BigQuery destino (default: banking_raw)",
    )
    parser.add_argument(
        "--input",
        default="data/output",
        help="Directorio con los Parquet generados (default: data/output)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Muestra qué haría sin ejecutar ninguna operación GCP",
    )
    args = parser.parse_args()

    # Validar argumentos obligatorios
    if not args.project:
        log.error("Falta GCP_PROJECT_ID — pásalo con --project o en .env.local")
        sys.exit(1)

    # Si no se pasa bucket, inferir del project_id (convención Terraform)
    bucket = args.bucket or f"{args.project}-data-lake"

    input_dir = Path(args.input)
    if not input_dir.exists():
        log.error("Directorio '%s' no existe — ejecuta data/generate.py primero", input_dir)
        sys.exit(1)

    log.info("=== Ingesta bancaria ===")
    log.info("Proyecto : %s", args.project)
    log.info("Bucket   : gs://%s/%s/", bucket, GCS_PREFIX)
    log.info("Dataset  : %s.%s", args.project, args.dataset)
    if args.dry_run:
        log.info("Modo     : DRY-RUN (sin cambios reales)")

    uris = upload_to_gcs(bucket, input_dir, TABLES, dry_run=args.dry_run)
    load_to_bigquery(args.project, args.dataset, uris, dry_run=args.dry_run)

    log.info("=== Ingesta completada ===")


if __name__ == "__main__":
    main()
