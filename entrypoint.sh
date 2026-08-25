#!/bin/sh
# 自动编译模式入口：同步源码 -> 编译 -> 启动 nginx
set -e

SRC_DIR=/site-src
SITE_DIR=/app/site
OUT_DIR=/app/build

# 1) 同步挂载的源码到工作目录（保留镜像内预装的 node_modules）
if [ -d "$SRC_DIR" ]; then
  echo "[entrypoint] syncing site source from ${SRC_DIR} ..."
  rsync -a --delete \
    --exclude node_modules \
    --exclude .docusaurus \
    --exclude build \
    --exclude .build-out \
    "$SRC_DIR/" "$SITE_DIR/"
fi

# 2) 依赖清单变化时（如更换 Docusaurus 版本）重新安装
if ! diff -q "$SITE_DIR/package.json" /app/site.package.json.orig >/dev/null 2>&1; then
  echo "[entrypoint] package.json changed, installing dependencies ..."
  cd "$SITE_DIR" && npm install --no-audit --no-fund
  cp "$SITE_DIR/package.json" /app/site.package.json.orig
fi

# 3) 编译站点（输出到容器内目录，.docusaurus 缓存卷可加速二次编译）
echo "[entrypoint] building site ..."
cd "$SITE_DIR"
npm run build -- --out-dir "$OUT_DIR"

# 4) 启动 nginx
echo "[entrypoint] starting nginx ..."
exec nginx -g 'daemon off;'
