#!/usr/bin/env bash
# 用法: ./scripts/sync-dist.sh <dist_dir>
set -euo pipefail

DIST_DIR="${1:-dist}"
[ -d "$DIST_DIR" ] || { echo "[ERR] Dist '$DIST_DIR' 不存在"; exit 1; }
[ -n "${DEPLOY_REPO_TOKEN:-}" ] || { echo "[ERR] 环境变量 DEPLOY_REPO_TOKEN 缺失"; exit 1; }

TARGET_REPO="NJUPT-NAVI/njupt-navi.github.io"
CLONE_URL="https://x-access-token:${DEPLOY_REPO_TOKEN}@github.com/${TARGET_REPO}.git"
WORK_DIR="$(pwd)"
TEMP_DIR="${WORK_DIR}/_deploy_temp"

echo "[Info] Clone ${TARGET_REPO} -> ${TEMP_DIR}"
rm -rf "${TEMP_DIR}"
git clone --depth 1 "${CLONE_URL}" "${TEMP_DIR}"

# 清空（保留 .git）
cd "${TEMP_DIR}"
# 删除除 .git 以外全部（处理隐藏文件）
find . -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +

# 拷贝新产物
rsync -av "${WORK_DIR}/${DIST_DIR}/" "./"
touch .nojekyll

echo "[Debug] 文件数: $(find . -type f | wc -l)"
git status --short || true

if [[ -z "$(git status --porcelain)" ]]; then
  echo "[Info] 无变化，结束。"
  exit 0
fi

git config user.name "Page Build"
git config user.email "actions@users.noreply.github.com"

git add .
git commit -m "Deploy: ${GITHUB_SHA:-manual}${GITHUB_SHA:+ }($(date -u +'%Y-%m-%dT%H:%M:%SZ'))"

echo "[Info] Force push → main"
git push -f origin HEAD:main

echo "[OK] 部署完成。"