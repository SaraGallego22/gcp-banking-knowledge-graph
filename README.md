# Banking Knowledge Graph on GCP

Proyecto de portafolio educativo que construye un **knowledge graph bancario** completo sobre Google Cloud Platform, integrando embeddings, GraphRAG y un agente de IA.

## Arquitectura

```
Synthetic Data → BigQuery (3 capas) → Embeddings → Knowledge Graph → RAG Agent → API → UI
     (Faker)        (dbt)           (Vertex AI)    (Neo4j / Spanner)  (LangGraph) (Cloud Run) (Streamlit)
```

## Stack tecnológico

| Capa | Tecnología |
|------|-----------|
| Cloud | GCP (BigQuery, Cloud Storage, Vertex AI, Cloud Run) |
| IaC | Terraform + GitHub Actions |
| Data | dbt, Apache Beam / Dataflow |
| AI/ML | Vertex AI Embeddings, Vector Search, Gemini |
| Graph | Neo4j (Cypher) |
| Agent | LangGraph + LangChain |
| CI/CD | GitHub Actions → GCP via Workload Identity Federation |

## Fases del proyecto

- [x] **Fase 1** — Foundations: GCP setup, datos sintéticos, BigQuery schema, CI/CD
- [ ] **Fase 2** — Pipelines: dbt models, Dataflow, transformaciones
- [ ] **Fase 3** — Graph: modelo de grafo, carga en Neo4j, consultas Cypher
- [ ] **Fase 4** — Embeddings: Vertex AI Embeddings, Vector Search
- [ ] **Fase 5** — RAG + Agent: GraphRAG, LangGraph agent
- [ ] **Fase 6** — API + UI: FastAPI en Cloud Run, Streamlit frontend

## Inicio rápido

### 1. Setup local

```bash
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env.local
```

### 2. Generar datos sintéticos

```bash
python data/generate.py --customers 1000 --months 12
```

### 3. Bootstrap de infraestructura GCP (primera vez)

```bash
# Autentícate con gcloud
gcloud auth application-default login

# Crea el bucket de estado de Terraform + habilita APIs
bash scripts/bootstrap.sh

# Copia y edita el archivo de variables
cp infra/terraform.tfvars.example infra/terraform.tfvars
```

### 4. Desplegar infraestructura con Terraform

```bash
cd infra
terraform init
terraform plan
terraform apply
```

### 5. Configurar GitHub Actions

Después del `terraform apply`, copia los outputs a **GitHub → Settings → Secrets and variables → Actions**:

| Secret | Valor (de terraform output) |
|--------|-----------------------------|
| `WIF_PROVIDER` | `terraform output -raw wif_provider` |
| `GCP_SA_EMAIL` | `terraform output -raw github_actions_sa_email` |
| `GCP_PROJECT_ID` | `evident-healer-459022-g0` |

## Estructura del repositorio

```
├── .github/workflows/   # CI (lint+test+plan) y CD (terraform apply)
├── infra/               # Terraform: BigQuery, GCS, IAM, WIF
├── data/                # Generador de datos sintéticos
├── pipelines/           # dbt + Apache Beam / Dataflow
├── graph/               # Modelo y cargador del knowledge graph
├── embeddings/          # Jobs de Vertex AI Embeddings
├── rag/                 # Lógica RAG + GraphRAG
├── agent/               # Agente LangGraph
├── api/                 # FastAPI (Cloud Run)
├── ui/                  # Streamlit frontend
├── notebooks/           # Jupyter notebooks educativos
├── scripts/             # Scripts de utilidad (bootstrap, etc.)
└── tests/               # Tests unitarios
```

## Convenciones

- Python 3.11+ con type hints y docstrings en todas las funciones públicas
- Nunca hardcodear credenciales — usar `.env.local` en local, Secret Manager en prod
- Terraform gestiona 100% de la infraestructura (no clicks en la consola)
- GitHub Actions despliega via Workload Identity Federation (sin JSON keys)
- Recursos etiquetados con `env` y `project` para control de costos

---

> **Dominio**: datos bancarios sintéticos (clientes, cuentas, transacciones, comercios, sucursales). Sin PII real.
