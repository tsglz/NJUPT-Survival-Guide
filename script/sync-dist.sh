#!/usr/bin/env bash
# 用法: ./scripts/sync-dist.sh <dist_dir> <target_dir>
# 例:  ./scripts/sync-dist.sh dist target
set -euo pipefail

DIST_DIR="${1:-dist}"
TARGET_DIR="${2:-target}"

if [ ! -d "$DIST_DIR" ]; then
  echo "Dist directory '$DIST_DIR' not found."
  exit 1
fi
if [ ! -d "$TARGET_DIR/.git" ]; then
  echo "Target directory '$TARGET_DIR' is not a git repo."
  exit 1
fi

rsync -av --delete "${DIST_DIR}/" "${TARGET_DIR}/"
touch "${TARGET_DIR}/.nojekyll"
# 如需自定义域名:
# echo "example.domain.com" > "${TARGET_DIR}/CNAME"

cd "$TARGET_DIR"

if [[ -z "$(git status --porcelain)" ]]; then
  echo "No changes to publish."
  exit 0
fi

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add .
git commit -m "Deploy: ${GITHUB_SHA::7} ($(date -u +'%Y-%m-%dT%H:%M:%SZ'))"
git push origin main
echo "Deployment commit pushed."