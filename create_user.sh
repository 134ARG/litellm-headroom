#!/usr/bin/env bash
#
# LiteLLM 创建用户脚本
# 用法: ./create_litellm_user.sh -e user@example.com [-r role] [-a alias] [-b budget] [-t team_id]
#

set -euo pipefail

# ============ 默认配置（按需修改） ============
PROXY_URL="${LITELLM_PROXY_URL:-http://114.212.189.33:4000}"
MASTER_KEY="${LITELLM_MASTER_KEY:-}"
DEFAULT_ROLE="internal_user"

usage() { echo "用法: $(basename "$0") -e <email> [-k master_key] [-u proxy_url]"; exit 1; }
 
while [[ $# -gt 0 ]]; do
    case "$1" in
        -e|--email) EMAIL="$2"; shift 2 ;;
        -k|--key)   MASTER_KEY="$2"; shift 2 ;;
        -u|--url)   PROXY_URL="$2"; shift 2 ;;
        *) usage ;;
    esac
done
 
[[ -z "${EMAIL:-}" || -z "$MASTER_KEY" ]] && usage
 
API="${PROXY_URL%/}"
 
# 1. 创建用户
USER_RESP=$(curl -s -X POST "$API/user/new" \
    -H "Authorization: Bearer $MASTER_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"user_email\":\"$EMAIL\",\"user_role\":\"internal_user\"}")
 
USER_ID=$(echo "$USER_RESP" | jq -r '.user_id // empty')
[[ -z "$USER_ID" ]] && { echo "创建失败: $USER_RESP"; exit 1; }
 
# 2. 生成邀请链接
INV_RESP=$(curl -s -X POST "$API/invitation/new" \
    -H "Authorization: Bearer $MASTER_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"user_id\":\"$USER_ID\"}")
 
INV_ID=$(echo "$INV_RESP" | jq -r '.id // empty')
[[ -z "$INV_ID" ]] && { echo "邀请创建失败: $INV_RESP"; exit 1; }
 
echo "$EMAIL $USER_ID ${API}/ui?invitation_id=${INV_ID}"
