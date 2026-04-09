#!/bin/bash
curl http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer $(grep LITELLM_MASTER_KEY .env | cut -d= -f2)" \
  -H "Content-Type: application/json" \
  -d "{\"model\": \"$1\",\"messages\": [{\"role\": \"user\", \"content\": \"hi\"}]}"

