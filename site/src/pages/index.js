import Layout from '@theme/Layout';

const features = [
  {
    title: '一键部署',
    description: '镜像内置完整站点与启动编译架构，挂载内容目录即可运行，无需本地构建环境。',
    icon: (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <path d="M4.5 16.5c-1.5 1.5-2 5-2 5s3.5-.5 5-2c.84-.84.8-2.16 0-3s-2.16-.84-3 0z" />
        <path d="m12 15-3-3a22 22 0 0 1 2-3.95A12.88 12.88 0 0 1 22 2c0 2.72-.78 7.5-6 11a22.35 22.35 0 0 1-4 2z" />
        <path d="M9 12H4s.55-3.03 2-4c1.62-1.08 5 0 5 0" />
        <path d="M12 15v5s3.03-.55 4-2c1.08-1.62 0-5 0-5" />
      </svg>
    ),
  },
  {
    title: '平滑升级',
    description: '拉取新版本镜像即可完成站点升级，文档数据通过挂载卷持久化，升级零风险。',
    icon: (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <path d="M21 12a9 9 0 1 1-2.64-6.36" />
        <path d="M21 3v6h-6" />
      </svg>
    ),
  },
  {
    title: '开箱即用的插件生态',
    description: '内置中文全文搜索、OpenAPI 文档、图片放大、SEO 与 Cookie 合规等插件。',
    icon: (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <path d="M12 2v6" />
        <path d="M12 16v6" />
        <path d="M2 12h6" />
        <path d="M16 12h6" />
        <rect x="8" y="8" width="8" height="8" rx="2" />
      </svg>
    ),
  },
  {
    title: '运行时可配置',
    description: '站点标题、标语、页脚备案号等均可通过环境变量注入，无需重新构建镜像。',
    icon: (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z" />
        <circle cx="12" cy="12" r="3" />
      </svg>
    ),
  },
];

const deployLines = [
  {code: '# 拉取镜像并启动站点', className: 'deploy-comment'},
  {code: 'docker run -d --name docs \\'},
  {code: '  -p 8080:80 \\'},
  {code: '  -v docs-content:/app/site/content \\'},
  {code: '  your-registry/docusaurus:latest'},
];

export default function Home() {
  return (
    <Layout title="首页" description="Docusaurus 生产环境 Docker 镜像">
      <main className="homepage">
        {/* Hero */}
        <section className="hero-section">
          <div className="hero-decoration" aria-hidden="true" />
          <div className="container">
            <div className="hero-content">
              <span className="hero-badge">
                <span className="hero-badge-dot" />
                Production Ready · Docker Image
              </span>
              <h1 className="hero-title">
                Docusaurus <span className="hero-title-gradient">生产环境镜像</span>
              </h1>
              <p className="hero-subtitle">
                开箱即用的文档站点 Docker 镜像 —— 挂载内容目录即可运行，
                拉取新镜像即可完成版本升级，环境变量驱动全部站点配置。
              </p>
              <div className="hero-actions">
                <a className="hero-button hero-button--primary" href="/docs/intro">
                  阅读文档
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                    <path d="M5 12h14" />
                    <path d="m12 5 7 7-7 7" />
                  </svg>
                </a>
                <a className="hero-button hero-button--secondary" href="/docs/getting-started">
                  快速上手
                </a>
              </div>
            </div>

            {/* 部署命令展示 */}
            <div className="deploy-terminal" aria-label="部署命令示例">
              <div className="deploy-terminal-header">
                <span className="terminal-dot terminal-dot--red" />
                <span className="terminal-dot terminal-dot--yellow" />
                <span className="terminal-dot terminal-dot--green" />
                <span className="deploy-terminal-title">bash</span>
              </div>
              <div className="deploy-terminal-body">
                {deployLines.map((line, index) => (
                  <div key={index} className={line.className || 'deploy-code'}>
                    {line.className === 'deploy-comment' ? line.code : (
                      <>
                        <span className="deploy-prompt">$ </span>
                        {line.code}
                      </>
                    )}
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        {/* 特性卡片 */}
        <section className="features-section">
          <div className="container">
            <h2 className="features-heading">为什么选择这个镜像</h2>
            <div className="features-grid">
              {features.map((feature) => (
                <div key={feature.title} className="feature-card">
                  <div className="feature-icon">{feature.icon}</div>
                  <h3 className="feature-title">{feature.title}</h3>
                  <p className="feature-description">{feature.description}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* 底部 CTA */}
        <section className="cta-section">
          <div className="container cta-content">
            <h2>开始编写你的文档</h2>
            <p>将 Markdown 放入挂载目录，侧边栏自动生成；OpenAPI 规范一键转成交互式 API 文档。</p>
            <div className="cta-actions">
              <a className="hero-button hero-button--primary" href="/docs/getting-started">
                快速上手
              </a>
              <a className="hero-button hero-button--secondary" href="/docs/api/示例-api">
                查看 API 示例
              </a>
            </div>
          </div>
        </section>
      </main>
    </Layout>
  );
}
