#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <delay_seconds>" >&2
  exit 1
fi

delay_seconds="$1"

if [[ ! "$delay_seconds" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "Error: delay_seconds must be a non-negative number." >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

sleep "$delay_seconds"

docker compose -f ./docker-compose.yaml down
docker compose -f ./docker-compose.yaml up -d --build

