// @ts-check
// Note: type annotations allow type checking and IDE autocompletion

const {themes} = require('prism-react-renderer');
const fs = require('fs');
const path = require('path');

// 站点元数据支持通过环境变量覆盖（在 docker-compose.yml 的 environment 中配置），
// 未设置时使用下方默认值
const SITE_TITLE = process.env.SITE_TITLE || 'My Site';
const SITE_TAGLINE =
  process.env.SITE_TAGLINE || 'Docusaurus 生产环境 Docker 镜像';
// 站点 Logo（导航栏标题左侧），指向 site/static/ 下的文件（如 /img/logo.png）；
// 留空或不设置则不显示 Logo
const SITE_LOGO = process.env.SITE_LOGO || '';

// -------- 文档版本管理（详见 README「文档版本管理」） --------
// 默认「当前版本即最新版」：site/docs/ 始终发布在 /docs，分版后的冻结版本
// 发布在 /docs/<版本号> —— 契合本项目「改 md 即发布」的工作流。
// 若 site/docs/ 代表「下一版开发中」内容，将 SITE_DOCS_LAST_VERSION 设为
// versions.json 中最新的分版名（Docusaurus 原生默认模式：/docs 指向冻结版，
// /docs/next 指向开发版）。未分版时 current 本就是最新版，此配置无副作用。
const SITE_DOCS_LAST_VERSION = process.env.SITE_DOCS_LAST_VERSION || 'current';
// 当前版本（site/docs/）尚未定稿、暂不对外发布时设为 false
// 注意：未分版时设为 false 会导致没有任何可发布版本，构建会失败
const SITE_DOCS_INCLUDE_CURRENT =
  process.env.SITE_DOCS_INCLUDE_CURRENT !== 'false';
// 导航栏版本下拉菜单：未分版时无意义，默认自动隐藏；分版后自动显示。
// 显式设置 true / false 可强制覆盖
const SITE_DOCS_VERSION_DROPDOWN = process.env.SITE_DOCS_VERSION_DROPDOWN;
const hasVersionedDocs = fs.existsSync(path.join(__dirname, 'versions.json'));
const showVersionDropdown =
  SITE_DOCS_VERSION_DROPDOWN === 'true' ||
  (SITE_DOCS_VERSION_DROPDOWN !== 'false' && hasVersionedDocs);

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: SITE_TITLE,
  tagline: SITE_TAGLINE,

  // SEO 相关：canonical / og:url / sitemap.xml 均基于以下两项生成
  // 部署到子路径/子域名时设置 SITE_BASE_URL（如 /docs/）
  url: process.env.SITE_URL || 'https://example.com',
  baseUrl: process.env.SITE_BASE_URL || '/',

  // 浏览器标签图标，指向 site/static/ 下的文件
  favicon: process.env.SITE_FAVICON || '/img/favicon.ico',

  // 站点语言（影响 <html lang> 与搜索分词）
  i18n: {
    defaultLocale: process.env.SITE_LOCALE || 'zh-Hans',
    locales: [process.env.SITE_LOCALE || 'zh-Hans'],
  },

  onBrokenLinks: 'throw',

  // Docusaurus Faster：用 Rspack + SWC + LightningCSS 替代 webpack + Babel + Terser，
  // 显著降低编译内存占用与耗时（3.10 起为稳定特性，需依赖 @docusaurus/faster）
  // 注意：不用 faster: true 简写 —— 其含 ssgWorkerThreads，要求同时开启 v4 future flags；
  // 此处仅逐项启用降低内存的项，不引入 v4 破坏性变更
  future: {
    faster: {
      swcJsLoader: true,         // SWC 替代 Babel 转译 JS
      swcJsMinimizer: true,      // SWC 替代 Terser 压缩 JS
      swcHtmlMinimizer: true,    // SWC 压缩 HTML
      lightningCssMinimizer: true, // LightningCSS 替代 cssnano/clean-css
      rspackBundler: true,       // Rspack 替代 webpack 打包（降内存的关键）
      rspackPersistentCache: true, // Rspack 持久缓存，加速二次编译
      mdxCrossCompilerCache: true, // MDX 只编译一次（浏览器/Node 共用）
    },
  },

  markdown: {
    hooks: {
      onBrokenMarkdownLinks: 'throw',
    },
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: './sidebars.js',
          // OpenAPI 文档使用 openapi-docs 主题的文档渲染组件
          docItemComponent: '@theme/ApiItem',
          // 版本管理：最新版本指向（当前版本即最新版 = /docs 指向 site/docs/）
          lastVersion: SITE_DOCS_LAST_VERSION,
          includeCurrentVersion: SITE_DOCS_INCLUDE_CURRENT,
          versions: {
            current: {
              // 当前版本在下拉菜单 / 徽章中的显示标签
              // （Docusaurus 原生默认为 Next，改 md 即发布模式下 Current 更直观）
              label: process.env.SITE_DOCS_CURRENT_LABEL || 'Current',
              // 留空则自动：当前版本为最新版时占 /docs，否则占 /docs/next
              ...(process.env.SITE_DOCS_CURRENT_PATH && {
                path: process.env.SITE_DOCS_CURRENT_PATH,
              }),
            },
          },
        },
        blog: false,
        // sitemap.xml 由官方 plugin-sitemap 生成（preset 内置）
        sitemap: {
          lastmod: 'date',
          changefreq: 'weekly',
          priority: 0.5,
        },
        theme: {
          customCss: './src/css/custom.css',
        },
      }),
    ],
  ],

  plugins: [
    // Sass 支持（openapi-docs 主题的样式依赖）
    'docusaurus-plugin-sass',
    // 文档图片点击放大
    'docusaurus-plugin-image-zoom',
    // 生成 llms.txt / llms-full.txt（面向 LLM 的文档输出，仅 build 时生效）
    'docusaurus-plugin-llms',
    // Cookie 同意弹窗
    [
      'docusaurus-plugin-cookie-consent',
      {
        title: 'Cookie 使用声明',
        description:
          '我们使用 Cookie 来提升您的浏览体验并分析站点流量。您可以选择接受全部，或仅保留必要 Cookie。',
        acceptAllText: '接受全部',
        rejectText: '仅必要 Cookie',
        toastMode: true,
      },
    ],
    // 从 OpenAPI 规范生成 API 文档（MDX 由 gen-api-docs 命令生成，见 README）
    [
      'docusaurus-plugin-openapi-docs',
      {
        id: 'apiDocs',
        docsPluginId: 'classic',
        config: {
          sample: {
            specPath: 'openapi/sample.json',
            outputDir: 'docs/api',
            sidebarOptions: {
              groupPathsBy: 'tag',
            },
          },
        },
      },
    ],
  ],

  themes: [
    // OpenAPI 文档渲染主题
    'docusaurus-theme-openapi-docs',
    // 本地离线搜索（支持中文分词，无需外部服务）
    [
      require.resolve('@easyops-cn/docusaurus-search-local'),
      /** @type {import('@easyops-cn/docusaurus-search-local').PluginOptions} */
      ({
        hashed: true,
        language: ['en', 'zh'],
        indexBlog: false,
        highlightSearchTermsOnTargetPage: true,
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      // 全局 SEO 元信息（description / og 标签）
      metadata: [
        {
          name: 'description',
          content: SITE_TAGLINE,
        },
        {
          name: 'keywords',
          content: process.env.SITE_KEYWORDS || 'Docusaurus,文档',
        },
      ],
      navbar: {
        title: process.env.SITE_NAVBAR_TITLE || SITE_TITLE,
        // SITE_LOGO 非空时才显示 Logo
        ...(SITE_LOGO && {logo: {alt: `${SITE_TITLE} Logo`, src: SITE_LOGO}}),
        items: [
          {
            type: 'docSidebar',
            sidebarId: 'tutorialSidebar',
            position: 'left',
            label: '文档',
          },
          // 文档版本切换：分版后自动出现（SITE_DOCS_VERSION_DROPDOWN 可强制开/关），
          // 自动跟随用户当前浏览的版本
          ...(showVersionDropdown
            ? [
                {
                  type: 'docsVersionDropdown',
                  position: 'left',
                },
              ]
            : []),
        ],
      },
      footer: {
        style: 'dark',
        copyright:
          process.env.SITE_FOOTER_COPYRIGHT ||
          `Copyright © ${new Date().getFullYear()} ${SITE_TITLE}. Built with Docusaurus.`,
      },
      prism: {
        theme: themes.github,
        darkTheme: themes.dracula,
      },
      // 图片放大插件配置
      zoom: {
        selector: '.markdown :not(em) > img',
        background: {
          light: 'rgb(255, 255, 255)',
          dark: 'rgb(50, 50, 50)',
        },
      },
    }),
};

module.exports = config;
