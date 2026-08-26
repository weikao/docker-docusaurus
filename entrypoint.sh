#!/bin/sh
# 自动编译模式入口：同步源码 -> 编译 -> 启动 nginx
set -e

SRC_DIR=/site-src
SITE_DIR=/app/site
OUT_DIR=/app/build
SAMPLE_DIR=/usr/local/share/site-sample

# 1) 挂载目录为空时，将镜像内的样例站点（含配置）复制过去，供用户参考修改
#    仅在目录为空时复制，绝不覆盖用户已有内容
if [ -d "$SRC_DIR" ] && [ -z "$(ls -A "$SRC_DIR" 2>/dev/null)" ]; then
  echo "[entrypoint] ${SRC_DIR} is empty, copying sample site from ${SAMPLE_DIR} ..."
  cp -a "$SAMPLE_DIR/." "$SRC_DIR/"
fi

# 2) 同步挂载的源码到工作目录（保留镜像内预装的 node_modules）
if [ -d "$SRC_DIR" ]; then
  echo "[entrypoint] syncing site source from ${SRC_DIR} ..."
  rsync -a --delete \
    --exclude node_modules \
    --exclude .docusaurus \
    --exclude build \
    --exclude .build-out \
    "$SRC_DIR/" "$SITE_DIR/"
fi

# 3) 依赖清单变化时（如更换 Docusaurus 版本）重新安装
if ! diff -q "$SITE_DIR/package.json" /app/site.package.json.orig >/dev/null 2>&1; then
  echo "[entrypoint] package.json changed, installing dependencies ..."
  cd "$SITE_DIR" && npm install --no-audit --no-fund
  cp "$SITE_DIR/package.json" /app/site.package.json.orig
fi

# 4) 编译站点（输出到容器内目录，.docusaurus 缓存卷可加速二次编译）
echo "[entrypoint] building site ..."
cd "$SITE_DIR"
npm run build -- --out-dir "$OUT_DIR"

# 5) 启动 nginx
echo "[entrypoint] starting nginx ..."
exec nginx -g 'daemon off;'
