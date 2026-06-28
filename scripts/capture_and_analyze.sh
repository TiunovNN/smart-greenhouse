#!/usr/bin/env bash
# Greenhouse CV — Pi-side script (Raspberry Pi 5 / Home Assistant).
# Input: JPEG snapshots already delivered from Radxa edge SBC to local inbox.
# Action: upload to Yandex Object Storage + call Yandex AI Studio (Foundation Models).
#
# Do NOT deploy this script or Yandex credentials on Radxa (.13). Edge is local-only;
# see docs/05-computer-vision.md and edge_capture.sh (reference on Radxa).
#
# Required env (from HA shell_command / secrets — Pi only):
#   YC_FOLDER_ID          — Yandex Cloud folder ID
#   YC_API_KEY            — API key (service account) OR YC_IAM_TOKEN
#   YC_S3_BUCKET          — Object Storage bucket name
#   YC_S3_ACCESS_KEY      — Static access key ID
#   YC_S3_SECRET_KEY      — Static secret access key
#
# Optional env:
#   YC_S3_ENDPOINT        — default https://storage.yandexcloud.net
#   YC_S3_PREFIX          — default greenhouse-cv
#   YC_FM_MODEL           — default yandexgpt/latest  (URI: gpt://${YC_FOLDER_ID}/yandexgpt/latest)
#   GREENHOUSE_PLANT_PROFILE — default Огурцы
#   CV_DIR                — default /config/greenhouse_cv/inbox (edge delivery directory)
#
# Usage:
#   ./scripts/capture_and_analyze.sh [/config/greenhouse_cv/inbox]
#
# Dependencies: curl, jq, aws cli (recommended for Yandex S3) — on Pi only
# Exit 0 on success; prints merged JSON to stdout for HA input_text.greenhouse_cv_last_report

set -euo pipefail

CV_DIR="${1:-${CV_DIR:-/config/greenhouse_cv/inbox}}"
YC_S3_ENDPOINT="${YC_S3_ENDPOINT:-https://storage.yandexcloud.net}"
YC_S3_PREFIX="${YC_S3_PREFIX:-greenhouse-cv}"
YC_FM_URL="${YC_FM_URL:-https://llm.api.cloud.yandex.net/foundationModels/v1/completion}"
YC_FM_MODEL="${YC_FM_MODEL:-yandexgpt/latest}"
PLANT_PROFILE="${GREENHOUSE_PLANT_PROFILE:-Огурцы}"
FOLDER_ID="${YC_FOLDER_ID:-}"
API_KEY="${YC_API_KEY:-}"
IAM_TOKEN="${YC_IAM_TOKEN:-}"
BUCKET="${YC_S3_BUCKET:-}"
S3_KEY="${YC_S3_ACCESS_KEY:-}"
S3_SECRET="${YC_S3_SECRET_KEY:-}"

auth_header() {
  if [[ -n "$IAM_TOKEN" ]]; then
    echo "Authorization: Bearer ${IAM_TOKEN}"
  elif [[ -n "$API_KEY" ]]; then
    echo "Authorization: Api-Key ${API_KEY}"
  else
    echo ""
  fi
}

missing=()
[[ -z "$FOLDER_ID" ]] && missing+=("YC_FOLDER_ID")
[[ -z "$BUCKET" ]] && missing+=("YC_S3_BUCKET")
[[ -z "$S3_KEY" ]] && missing+=("YC_S3_ACCESS_KEY")
[[ -z "$S3_SECRET" ]] && missing+=("YC_S3_SECRET_KEY")
if [[ -z "$API_KEY" && -z "$IAM_TOKEN" ]]; then
  missing+=("YC_API_KEY or YC_IAM_TOKEN")
fi

if [[ ${#missing[@]} -gt 0 ]]; then
  jq -n \
    --arg err "missing env: ${missing[*]}" \
    '{health:"skipped",error:$err}'
  exit 0
fi

latest_entrance="$(find "$CV_DIR" -name '*entrance*.jpg' -type f 2>/dev/null | sort -r | head -1 || true)"
latest_far="$(find "$CV_DIR" -name '*far*.jpg' -type f 2>/dev/null | sort -r | head -1 || true)"

if [[ -z "$latest_entrance" && -z "$latest_far" ]]; then
  jq -n '{health:"skipped",error:"no snapshots found"}'
  exit 1
fi

upload_s3() {
  local file="$1"
  local key="$2"
  # AWS CLI v2 with --endpoint-url is the simplest stub; fallback to curl if unavailable
  if command -v aws >/dev/null 2>&1; then
    AWS_ACCESS_KEY_ID="$S3_KEY" AWS_SECRET_ACCESS_KEY="$S3_SECRET" \
      aws s3 cp "$file" "s3://${BUCKET}/${key}" \
        --endpoint-url "$YC_S3_ENDPOINT" \
        --region ru-central1 \
        --only-show-errors
  else
    # Minimal PUT via curl (requires pre-signed URL in production — use aws cli or boto3)
    echo "WARN: aws cli not found; skipping S3 upload for ${key}" >&2
    return 0
  fi
}

analyze_image() {
  local img="$1"
  local cam_id="$2"
  local s3_key="$3"
  local b64
  b64="$(base64 < "$img" | tr -d '\n')"
  local model_uri="gpt://${FOLDER_ID}/${YC_FM_MODEL}"
  local prompt
  prompt="$(cat <<EOF
Ты — ассистент теплицы в средней полосе России. Культура: ${PLANT_PROFILE}.
Камера: ${cam_id}. Проанализируй снимок П-образных грядок. Верни ТОЛЬКО JSON:
{"health":"healthy|stressed|diseased|uncertain","findings":[{"class":"...","confidence":0.0,"location":"left_arm|right_arm|corridor"}],
"likely_issues":["powdery_mildew","downy_mildew","water_stress","late_blight"],"max_confidence":0.0,"recommendation_ru":"..."}
Если кадр тёмный — health=uncertain.
EOF
)"

  local payload
  payload="$(jq -n \
    --arg modelUri "$model_uri" \
    --arg text "$prompt" \
    --arg b64 "$b64" \
    '{
      modelUri: $modelUri,
      completionOptions: { stream: false, temperature: 0.2, maxTokens: 800 },
      messages: [{
        role: "user",
        text: $text,
        images: [{ image: { data: $b64, mimeType: "image/jpeg" } }]
      }]
    }')"

  local auth
  auth="$(auth_header)"
  local resp
  resp="$(curl -sfS --max-time 90 \
    -H "$auth" \
    -H "Content-Type: application/json" \
    -H "x-folder-id: ${FOLDER_ID}" \
    -d "$payload" \
    "$YC_FM_URL" 2>/dev/null || echo '{}')"

  local text
  text="$(echo "$resp" | jq -r '.result.alternatives[0].message.text // empty' 2>/dev/null || true)"
  if [[ -z "$text" ]]; then
    jq -n --arg cam "$cam_id" --arg sk "$s3_key" \
      '{health:"uncertain",camera_id:$cam,s3_key:$sk,error:"api_failed"}'
    return
  fi
  # Strip markdown fences if model wraps JSON
  text="${text//\`\`\`json/}"
  text="${text//\`\`\`/}"
  echo "$text" | jq -c . 2>/dev/null || \
    jq -n --arg cam "$cam_id" --arg sk "$s3_key" --arg raw "$text" \
      '{health:"uncertain",camera_id:$cam,s3_key:$sk,raw:$raw}'
}

results=()
date_path="$(date -u +%Y/%m/%d 2>/dev/null || date +%Y/%m/%d)"
time_part="$(date +%H%M)"

for pair in "entrance:${latest_entrance}" "far:${latest_far}"; do
  cam="${pair%%:*}"
  path="${pair#*:}"
  [[ -n "$path" && -f "$path" ]] || continue
  s3_key="${YC_S3_PREFIX}/${date_path}/${time_part}_${cam}.jpg"
  upload_s3 "$path" "$s3_key" || true
  results+=("$(analyze_image "$path" "$cam" "$s3_key")")
done

# Merge: worst health wins
merged_health="healthy"
for r in "${results[@]}"; do
  h="$(echo "$r" | jq -r '.health // "uncertain"')"
  case "$h" in
    diseased) merged_health="diseased" ;;
    stressed) [[ "$merged_health" != "diseased" ]] && merged_health="stressed" ;;
    uncertain) [[ "$merged_health" == "healthy" ]] && merged_health="uncertain" ;;
  esac
done

max_conf="$(printf '%s\n' "${results[@]}" | jq -s '[.[].max_confidence // 0] | max // 0')"

jq -n \
  --arg health "$merged_health" \
  --argjson max_conf "${max_conf:-0}" \
  --arg profile "$PLANT_PROFILE" \
  --arg bucket "$BUCKET" \
  --argjson cameras "$(printf '%s\n' "${results[@]}" | jq -s '.')" \
  '{
    health: $health,
    max_confidence: $max_conf,
    plant_profile: $profile,
    storage: { provider: "yandex_object_storage", bucket: $bucket },
    cameras: $cameras
  }'
