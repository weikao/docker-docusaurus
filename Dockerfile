########################################
# Docusaurus 生产镜像：容器启动时编译挂载的站点源码，然后由 Nginx 提供服务
# 用户修改 md 后只需 docker compose restart 即可发布新内容
########################################
ARG BASE_REGISTRY=docker.m.daocloud.io
FROM ${BASE_REGISTRY}/library/node:22-alpine

# 使用国内 alpine 源安装 nginx 与 rsync
RUN sed -i 's|dl-cdn.alpinelinux.org|mirrors.aliyun.com|g' /etc/apk/repositories \
    && apk add --no-cache nginx rsync wget

WORKDIR /app/site

# 使用国内 npm 源（淘宝镜像）
ENV NPM_CONFIG_REGISTRY=https://registry.npmmirror.com

# 预装站点依赖：依赖清单烘焙进镜像，升级镜像即升级 Docusaurus
# 注意：不要启用 corepack —— 其 yarn shim 会诱导部分包的安装后脚本（如
# postman-code-generators）改用 yarn，进而访问 registry.npmjs.org，国内网络下失败
COPY site/package.json site/package-lock.json ./
RUN npm install --no-audit --no-fund

# 烘焙一份站点源码，作为未挂载卷时的兜底内容
COPY site/ ./

# 烘焙一份样例站点（含配置）：挂载目录为空时，启动脚本会将其复制过去供用户参考修改
COPY site/ /usr/local/share/site-sample/

COPY nginx.conf /etc/nginx/http.d/default.conf
COPY entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh

EXPOSE 80

# 启动时需要先编译，放宽健康检查窗口
HEALTHCHECK --interval=15s --timeout=5s --start-period=180s --retries=6 \
  CMD wget -q --spider http://127.0.0.1/ || exit 1

ENTRYPOINT ["/entrypoint.sh"]
