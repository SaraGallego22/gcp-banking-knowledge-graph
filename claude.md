# Knowledge Banking Graph — Claude Context

## Project overview
Educational GCP project for a knowledge data engineer portfolio. Builds a full
banking knowledge graph with embeddings, GraphRAG, and an AI agent. All
infrastructure is deployed via Terraform + GitHub Actions.

## Repo structure
knowledge-banking-graph/
├── infra/                  # Terraform: GCP resources
├── data/                   # Synthetic data generation scripts
├── pipelines/              # Dataflow + dbt pipelines
├── embeddings/             # Vertex AI embedding jobs
├── graph/                  # Knowledge graph model + loaders
├── rag/                    # RAG + GraphRAG logic
├── agent/                  # LangGraph agent + tools
├── api/                    # FastAPI backend (Cloud Run)
├── ui/                     # Streamlit frontend
├── .github/workflows/      # CI/CD GitHub Actions
└── notebooks/              # Educational Jupyter notebooks

## Tech stack
- **Cloud**: GCP (BigQuery, Cloud Storage, Vertex AI, Cloud Run, Pub/Sub)
- **IaC**: Terraform
- **Data**: dbt, Apache Beam / Dataflow, Python
- **AI/ML**: Vertex AI Embeddings, Vector Search, Gemini API
- **Graph**: Neo4j (or Spanner Graph), Cypher queries
- **Agent**: LangGraph, LangChain
- **CI/CD**: GitHub Actions → GCP via Workload Identity Federation

## Domain: synthetic banking data
Entities: customers, accounts, transactions, merchants, branches
Key relationships:
- Customer OWNS Account
- Account HAS Transaction
- Transaction AT Merchant
- Customer LIVES_IN Branch region

No real PII. All data generated with Faker + custom rules.

## Coding conventions
- Python 3.11+
- Type hints everywhere
- Docstrings on all public functions
- Each module has a README.md explaining what it does and why
- Notebooks are educational first — explain concepts before code

## Environment variables
Never hardcode. Use:
- `.env.local` for local dev (gitignored)
- GCP Secret Manager for production
- GitHub Secrets for CI/CD

Key vars: `GCP_PROJECT_ID`, `GCP_REGION`, `BQ_DATASET`, `NEO4J_URI`,
`NEO4J_PASSWORD`, `VERTEX_LOCATION`

## GCP project conventions
- Region: `us-central1` (or your preferred)
- All resources tagged with `env=dev|prod` and `project=knowledge-banking-graph`
- Service accounts follow principle of least privilege
- Workload Identity Federation for GitHub Actions (no JSON keys)

## Current phase
Phase 1 — Foundations: GCP setup, synthetic data, BigQuery schema, CI/CD.

## Commands
```bash
# Local setup
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# Generate synthetic data
python data/generate.py --customers 1000 --months 12

# Terraform
cd infra && terraform init && terraform plan

# Run tests
pytest tests/ -v

# dbt
cd pipelines/dbt && dbt run --profiles-dir .
```

## Learning goals (educational context)
This is a portfolio project. Prioritize:
1. Clear explanations in code comments and notebooks
2. Best practices over shortcuts
3. Each phase should be independently understandable
4. Commit messages explain *why*, not just *what*

## When helping with this project
- Suggest GCP-native solutions first
- Flag anything that would cost money at scale
- Keep notebooks bilingual (code in English, comments/markdown in Spanish)
- Always include error handling and logging
- Remind about Secret Manager instead of hardcoded credentials