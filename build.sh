#!/usr/bin/env bash
# ============================================================
# 构建 Docusaurus 生产镜像（国内源）
# 用法:
#   ./build.sh <版本号> [镜像名] [push]
# 示例:
#   ./build.sh 3.10.2
#   ./build.sh 3.10.2 registry.example.com/docs-site push
# ============================================================
set -euo pipefail

VERSION="${1:-}"
IMAGE="${2:-docusaurus-site}"
PUSH="${3:-}"

if [[ -z "$VERSION" ]]; then
  echo "用法: ./build.sh <版本号> [镜像名] [push]"
  echo "示例: ./build.sh 3.10.2"
  exit 1
fi

echo "[1/4] 同步 Docusaurus 版本 ${VERSION} 到 site/package.json ..."
sed -i -E "s/\"@docusaurus\/([A-Za-z0-9_-]+)\": \"[^\"]+\"/\"@docusaurus\/\1\": \"${VERSION}\"/g" site/package.json

echo "[2/4] 构建镜像 ${IMAGE}:${VERSION} (Docusaurus ${VERSION}) ..."
docker build \
  -t "${IMAGE}:${VERSION}" \
  -t "${IMAGE}:latest" \
  .

echo "[3/4] 构建完成:"
docker images "${IMAGE}"

if [[ "$PUSH" == "push" ]]; then
  echo "[4/4] 推送镜像到仓库 ..."
  docker push "${IMAGE}:${VERSION}"
  docker push "${IMAGE}:latest"
  echo "推送完成。使用者升级命令: docker compose pull && docker compose up -d"
else
  echo "[4/4] 跳过推送。如需发布请追加参数: ./build.sh ${VERSION} ${IMAGE} push"
fi
