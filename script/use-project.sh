#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $(basename "$0") [MediaPlaybackSample|XXX]"
  exit 1
fi
project="$1"

case "$project" in
  MediaPlaybackSample)
    CMD=$(cat <<EOF
git sparse-checkout init --no-cone >/dev/null 2>&1 || true
git sparse-checkout set \
  "/.gitignore" \
  "/script/use-project.sh" \
  "/samples/MediaPlaybackSample/" \
  "/samples/MediaPlaybackSampleV2/"
EOF
)
    ;;

  *)
    CMD=$(cat <<EOF
git sparse-checkout disable
EOF
)
    ;;
esac

echo "${CMD}"
echo -n "🚀 Enter to Run: "
read -r -n 1 key
if [[ -z "$key" ]]; then  # User pressed Enter (empty input)
  eval "$CMD"
else
  echo " <CANCELLED>"
  exit 1
fi
