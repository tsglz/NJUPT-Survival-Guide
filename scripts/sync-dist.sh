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

echo "[Info] 准备部署到 ${TARGET_REPO}"

rm -rf "${TEMP_DIR}"
GIT_TERMINAL_PROMPT=0 git clone --depth 1 --quiet "${CLONE_URL}" "${TEMP_DIR}"

cd "${TEMP_DIR}"

# 清空旧文件（保留 .git）
find . -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +

# 拷贝新产物
rsync -a "${WORK_DIR}/${DIST_DIR}/" "./"
touch .nojekyll

if [[ -z "$(git status --porcelain)" ]]; then
  echo "[Info] 无变化，跳过提交。"
  exit 0
fi

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

git add .
git commit -m "Deploy: ${GITHUB_SHA:-manual} ($(date -u +'%Y-%m-%dT%H:%M:%SZ'))" >/dev/null

# 强制推送最新快照
GIT_TERMINAL_PROMPT=0 git push -f origin HEAD:main >/dev/null

echo "[OK] 部署完成。"