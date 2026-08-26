# docusaurus-site

基于 [Docusaurus](https://docusaurus.io/) 的生产级文档站点镜像：
**容器启动时编译站点源码，然后由 Nginx 提供服务**。镜像内已预装全部
npm 依赖，首次启动约 60 秒（含编译），有缓存时约 10 秒。

- **改 md 即发布**：编辑文档后 `restart` 容器即可，无需重建镜像
- **版本即 tag**：镜像 tag = Docusaurus 版本号（如 `3.10.2`），另有 `latest`
- **开箱即用**：内置中文本地搜索、sitemap、OpenAPI 文档插件、图片放大等

## 镜像约定

| 项 | 说明 |
|----|------|
| Tag | `<Docusaurus 版本号>`（如 `3.10.2`）+ `latest` |
| 端口 | 容器内 `80`（Nginx） |
| 源码挂载点 | `/site-src`（挂载你的站点源码；挂载空目录会自动复制镜像内置样例站点；不挂载则直接用内置示例） |
| 编译缓存卷 | `/app/site/.docusaurus`（可选，加速二次编译约 30s → 7s） |

## 快速开始（docker 命令行）

### 1. 准备站点源码

镜像内置了一份示例站点，可以直接跑起来体验：

```bash
docker run -d --name docusaurus -p 8080:80 wkao/docusaurus-site:3.10.2
# 访问 http://localhost:8080
```

实际使用时，把你的 Docusaurus 站点源码目录（含 `docusaurus.config.js`、
`docs/`、`package.json` 的目录）挂载到 `/site-src`；如果挂载的是空目录，
容器会自动把镜像内置的样例站点（含配置）复制进去，便于参考修改：

```bash
# Linux / macOS
docker run -d --name docusaurus \
  --restart unless-stopped \
  -p 8080:80 \
  -v $(pwd)/site:/site-src \
  -v docusaurus_cache:/app/site/.docusaurus \
  wkao/docusaurus-site:3.10.2
```

```powershell
# Windows PowerShell（路径改为绝对路径）
docker run -d --name docusaurus `
  --restart unless-stopped `
  -p 8080:80 `
  -v D:\my\site:/site-src `
  -v docusaurus_cache:/app/site/.docusaurus `
  wkao/docusaurus-site:3.10.2
```

### 2. 日常发布内容

编辑挂载目录里的 Markdown 后，重启容器即可（启动时自动编译新内容）：

```bash
docker restart docusaurus
```

> 如果修改了 `site/package.json`（增删插件/依赖），重启时容器会自动重新安装依赖。

### 3. 版本升级

```bash
docker pull wkao/docusaurus-site:3.10.3
docker rm -f docusaurus
# 用上面的 docker run 命令重新创建（tag 换成 3.10.3）
```

## 部署（docker-compose，推荐）

创建 `docker-compose.yml`（`./site` 为你的站点源码目录）：

```yaml
services:
  docusaurus:
    image: wkao/docusaurus-site:3.10.2     # tag = Docusaurus 版本
    container_name: docusaurus
    restart: unless-stopped
    ports:
      - "8080:80"
    environment:
      # 站点元数据，全部可选，不设置用站点源码中的默认值
      SITE_TITLE: My Site                   # 站点标题
      SITE_TAGLINE: 我的文档站点             # 副标题 / 全局 description
      SITE_URL: https://example.com         # 部署域名（canonical / sitemap）
      SITE_BASE_URL: /                      # 部署子路径（如 /docs/）
      SITE_FAVICON: /img/favicon.ico        # 图标（放站点 static/img/ 下）
      SITE_LOCALE: zh-Hans                  # 站点语言
      SITE_KEYWORDS: 文档,教程              # SEO 关键词
    volumes:
      # 挂载站点源码：目录为空时自动复制镜像内置样例（含配置）供参考修改；
      # 修改 md 后 restart 即生效
      - ./site:/site-src
      # 编译缓存：加速二次编译（可选）
      - docusaurus_cache:/app/site/.docusaurus
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://127.0.0.1/"]
      interval: 15s
      timeout: 5s
      retries: 6
      start_period: 180s                    # 启动时需编译，放宽检查窗口

volumes:
  docusaurus_cache:
```

```bash
docker compose up -d              # 启动（首次拉取镜像 + 编译约 2 分钟）
docker compose ps                 # 等待状态变为 healthy 即编译完成
```

访问 `http://localhost:8080`。

### 常用运维命令

```bash
# 修改文档后发布（启动时自动编译新内容，约 10 秒）
docker compose restart docusaurus

# 修改 environment 站点配置后，重建容器生效
docker compose up -d docusaurus

# 升级 Docusaurus 版本：改 image tag → 拉取 → 重建
docker compose pull docusaurus && docker compose up -d docusaurus

# 查看编译日志
docker compose logs -f docusaurus
```

## 站点配置（环境变量）

以下环境变量在容器启动编译时读取，**全部可选**，不设置时使用站点源码
`docusaurus.config.js` 中的默认值：

| 环境变量 | 作用 |
|----------|------|
| `SITE_TITLE` | 站点标题（`<title>`、og:title、导航栏、页脚） |
| `SITE_TAGLINE` | 副标题（同时作为全局 description） |
| `SITE_URL` | 部署域名，canonical / sitemap.xml / og:url 均基于它生成 |
| `SITE_BASE_URL` | 部署子路径，如部署到 `https://x.com/docs/` 时设为 `/docs/` |
| `SITE_FAVICON` | 标签图标路径，指向站点 `static/` 下的文件 |
| `SITE_LOCALE` | 站点语言（默认 `zh-Hans`，影响 `<html lang>` 与界面文案） |
| `SITE_KEYWORDS` | SEO 关键词 |
| `SITE_NAVBAR_TITLE` | 导航栏标题（默认同 `SITE_TITLE`） |
| `SITE_FOOTER_COPYRIGHT` | 页脚版权文案 |

## 工作原理

容器启动时依次执行（见镜像内 `entrypoint.sh`）：

1. **空目录填充**：`/site-src` 为空时，把镜像内置的样例站点（含配置）复制进去，供参考修改
2. **同步源码**：把 `/site-src` 同步到工作目录（保留镜像内预装的 `node_modules`）
3. **依赖检测**：`package.json` 有变化时自动 `npm install`
4. **编译站点**：`npm run build`，输出到容器内目录
5. **启动 Nginx**：生产级配置（gzip + 静态资源缓存策略）

因此镜像是"运行时编译"模式：内容更新只需重启容器，无需重建镜像；
代价是启动需要几十秒编译时间（healthcheck 已放宽窗口）。

## 已集成插件

| 插件 | 功能 |
|------|------|
| @easyops-cn/docusaurus-search-local | 导航栏本地搜索，支持中文分词，离线可用 |
| sitemap（preset 内置） | 自动生成 `/sitemap.xml` |
| docusaurus-plugin-image-zoom | 文档图片点击放大 |
| docusaurus-plugin-llms | 构建时生成 `/llms.txt` 与 `/llms-full.txt`（面向 AI/LLM） |
| docusaurus-plugin-cookie-consent | Cookie 同意提示 |
| docusaurus-plugin-openapi-docs | 从 OpenAPI 规范生成交互式 API 文档 |
