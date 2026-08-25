---
sidebar_position: 1
---

# 简介

欢迎使用本文档站点。该站点通过 Docker 镜像部署，基于 Docusaurus 构建。

## 特性

- 文档内容使用 Markdown / MDX 编写，放在 `site/docs` 目录下
- 镜像采用多阶段构建：Node 构建 + Nginx 运行，体积小、速度快
- Docusaurus 版本随镜像发布，升级仅需拉取新镜像

## 快速开始

在左侧边栏浏览文档，或修改 `site/docs` 下的 Markdown 文件后重新构建镜像。
