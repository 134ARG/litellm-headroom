# litellm-headroom

LiteLLM proxy with [Headroom](https://github.com/chopratejas/headroom) prompt compression, deployed via Docker Compose.

Headroom automatically compresses long context (tool outputs, RAG chunks, conversation history) before it hits the LLM — same answers, fewer tokens.

## Quick start

```bash
cp .env.example .env
# Edit .env — set LITELLM_MASTER_KEY and OLLAMA_API_BASE

docker compose up --build -d
```

Wait ~20 seconds for Prisma migrations, then:

- Admin UI: http://localhost:4000/ui (login with your `LITELLM_MASTER_KEY`)
- API: http://localhost:4000/v1/chat/completions
- Health: http://localhost:4000/health

## Test it

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer $(grep LITELLM_MASTER_KEY .env | cut -d= -f2)" \
  -H "Content-Type: application/json" \
  -d '{"model": "ollama/qwen3.5:4b", "messages": [{"role": "user", "content": "hi"}]}'
```

## Database

Postgres data is stored on the host at `./data/postgres/` (bind mount, not a Docker volume). This directory is created automatically on first run and is gitignored.

All runtime state lives here — users, API keys, teams, budgets, spend logs, and models added via the UI.

Backup:
```bash
docker compose exec db pg_dump -U llmproxy litellm > backup.sql
```

Restore:
```bash
docker compose exec -T db psql -U llmproxy litellm < backup.sql
```

To wipe and start fresh, stop the containers and delete the directory:
```bash
docker compose down
rm -rf data/postgres
docker compose up -d
```

## Network modes

**Bridge network** (default) — for machines with iptables enabled (servers, CI):
- `ports` + `extra_hosts` are active in `docker-compose.yaml`
- `OLLAMA_API_BASE=http://host.docker.internal:11434`

**Host network** — for machines with Docker iptables disabled:
- Uncomment `network_mode: host`, comment out `ports`/`extra_hosts`/`environment` block
- `OLLAMA_API_BASE=http://127.0.0.1:11434`

See comments in `docker-compose.yaml` for details.

## Files

| File / Directory | Purpose |
|---|---|
| `Dockerfile` | Extends official LiteLLM image, adds `headroom-ai` |
| `start_litellm.py` | Registers Headroom callback, delegates to LiteLLM CLI |
| `config.yaml` | Model definitions with custom pricing |
| `docker-compose.yaml` | LiteLLM + Postgres |
| `.env.example` | Template for environment variables |
| `data/postgres/` | Postgres data directory (auto-created, gitignored) |

## How Headroom works here

`start_litellm.py` registers a `CompatHeadroomCallback` that wraps Headroom's `HeadroomCallback` to match LiteLLM proxy's hook signature. On every completion request, Headroom's `async_pre_call_hook` compresses the messages before they're sent to the provider.

Compression kicks in on long context (500+ tokens). Short prompts pass through unchanged.

## Adding cloud providers

Uncomment the provider blocks in `config.yaml` and add the API keys to `.env`:

```yaml
- model_name: gpt-4o
  litellm_params:
    model: openai/gpt-4o
    api_key: os.environ/OPENAI_API_KEY
```

## Logs

```bash
docker compose logs -f litellm
docker compose logs -f litellm 2>&1 | grep "\[Headroom\]"
```
