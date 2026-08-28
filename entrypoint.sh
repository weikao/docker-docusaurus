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
#    依赖以镜像为准：不同步 package.json / package-lock.json，
#    这样升级镜像即升级 Docusaurus，宿主机的清单只影响 dev 服务
if [ -d "$SRC_DIR" ]; then
  echo "[entrypoint] syncing site source from ${SRC_DIR} ..."
  rsync -a --delete \
    --exclude node_modules \
    --exclude package.json \
    --exclude package-lock.json \
    --exclude .docusaurus \
    --exclude build \
    --exclude .build-out \
    "$SRC_DIR/" "$SITE_DIR/"
fi

# 2.5) 发布新文档版本（版本号与产品版本对应）：
#      业务人员零命令行 —— 复制 RELEASE.txt.example 为 RELEASE.txt、
#      填写产品版本号、重启容器即可，无需本地安装 Node/npm
RELEASE_FILE="$SRC_DIR/RELEASE.txt"
if [ -f "$RELEASE_FILE" ]; then
  # 取第一个非注释、非空行的第一个字段作为版本号（容忍 Windows CRLF 行尾）
  version=$(tr -d '\r' < "$RELEASE_FILE" | grep -v '^[[:space:]]*#' | awk 'NF {print $1; exit}')
  if echo "$version" | grep -Eq '^[A-Za-z0-9][A-Za-z0-9._-]*$'; then
    echo "[entrypoint] publishing docs version: ${version} ..."
    cd "$SITE_DIR"
    if "$SITE_DIR/node_modules/.bin/docusaurus" docs:version "$version"; then
      # 分版产物回写宿主机挂载目录（目标环境没有 Node/npm，一切在容器内完成）
      mkdir -p "$SRC_DIR/versioned_docs" "$SRC_DIR/versioned_sidebars"
      rsync -a "$SITE_DIR/versioned_docs/" "$SRC_DIR/versioned_docs/"
      rsync -a "$SITE_DIR/versioned_sidebars/" "$SRC_DIR/versioned_sidebars/"
      cp "$SITE_DIR/versions.json" "$SRC_DIR/versions.json"
      rm -f "$RELEASE_FILE"
      echo "[entrypoint] docs version ${version} published."
      echo "[entrypoint] frozen docs saved to: $SRC_DIR/versioned_docs/version-${version}/"
    else
      # 失败不阻断服务：改名保留现场，用户修正后重新发布即可
      mv -f "$RELEASE_FILE" "${RELEASE_FILE}.failed"
      echo "[entrypoint] WARNING: failed to publish version '${version}' (already exists?)." >&2
      echo "[entrypoint] WARNING: RELEASE.txt renamed to RELEASE.txt.failed, see logs above." >&2
    fi
  else
    mv -f "$RELEASE_FILE" "${RELEASE_FILE}.failed"
    echo "[entrypoint] WARNING: no valid version number in RELEASE.txt (expected e.g. 1.0)." >&2
    echo "[entrypoint] WARNING: RELEASE.txt renamed to RELEASE.txt.failed." >&2
  fi
fi

# 3) 编译站点（输出到容器内目录，.docusaurus 缓存卷可加速二次编译）
echo "[entrypoint] building site ..."
cd "$SITE_DIR"
npm run build -- --out-dir "$OUT_DIR"

# 4) 启动 nginx
echo "[entrypoint] starting nginx ..."
exec nginx -g 'daemon off;'
