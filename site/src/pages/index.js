import Layout from '@theme/Layout';

export default function Home() {
  return (
    <Layout title="首页" description="Docusaurus 生产环境 Docker 镜像">
      <main className="hero-wrapper">
        <div className="hero">
          <h1>My Site</h1>
          <p>Docusaurus 生产环境 Docker 镜像 —— 拉取新镜像即可完成版本升级。</p>
          <a className="hero-button" href="/docs/intro">
            阅读文档
          </a>
        </div>
      </main>
    </Layout>
  );
}
