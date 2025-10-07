# pandoc-docker

> 镜像：`jdcloudiaas/turta:pandoc`

这是一个高度集成、支持中文与 Mermaid 的 Pandoc 容器镜像工程。镜像支持将 Markdown 转换为 PDF / DOCX / PPTX，包含：

- 中文渲染（XeLaTeX + Noto CJK 等字体）
- Mermaid 图表自动检测与渲染（使用 mermaid-cli + pandoc-mermaid-filter）
- GitHub 风格 CSS 支持（用于 HTML/epub 风格渲染）
- Pandoc 常用 filters（crossref、fignos、eqnos、tablenos）
- LibreOffice（增强 DOCX/PPTX 兼容）

## 目录结构

````

pandoc-docker/
├── Dockerfile
├── LICENSE
├── README.md
├── docker-compose.yml
├── scripts
│   ├── md2docx.sh
│   ├── md2pdf.sh
│   └── md2pptx.sh
├── templates
│   ├── bullet_style.tex
│   ├── chapter_break.tex
│   ├── cover.tex
│   ├── epub.css
│   ├── github.css
│   ├── inline_code.tex
│   ├── meta.tex
│   ├── pygments.theme
│   └── quote.tex
└── test
└── sample.md

````

## 为什么有这个项目

很多团队需要将技术文档或报告从 Markdown 转换为不同格式（PDF / DOCX / PPTX），同时希望：

- 保持 GitHub 风格的 Markdown 渲染
- 支持中文、公式和 SVG/mermaid 图
- 在 CI 环境或容器中一键完成转换

本镜像将所有必要工具打包，方便在 CI/CD、容器集群或本地进行统一转换。

## 如何使用

### 1) 构建镜像

```bash
docker build -t jdcloudiaas/turta:pandoc .
````

或者使用 docker-compose:

```bash
docker compose up --build -d
# 之后进入容器：
docker exec -it pandoc-turta /bin/bash
```

### 2) 将脚本与模板拷贝到容器（本仓库组织后已包含）

确保 `scripts/` 与 `templates/` 已复制到镜像内的 `/opt/pandoc/scripts` 与 `/opt/pandoc/templates`：
（如果你使用 `docker build`，可以在 Dockerfile 构建时 `COPY` 这些文件；上面的 Dockerfile 为骨架，建议在你的项目 Dockerfile 中加入 `COPY templates /opt/pandoc/templates` 与 `COPY scripts /opt/pandoc/scripts`）

### 3) 在项目根目录运行示例

本仓库包含示例 `test/sample.md`：

生成 PDF（自动检测 Mermaid）：

```bash
./scripts/md2pdf.sh test/sample.md
# 或者在容器中：
md2pdf.sh test/sample.md
```

生成 DOCX：

```bash
./scripts/md2docx.sh test/sample.md
```

生成 PPTX（slide-level=2）：

```bash
./scripts/md2pptx.sh test/sample.md
```

### 4) 参数说明（脚本通用）

* `-o <file>`：指定输出文件名
* 额外的 Pandoc 参数可直接追加到脚本命令后，例如 `--variable mainfont="Noto Sans CJK SC"`，或 `--toc=false` 取消目录。

### 5) Mermaid 支持说明

脚本会自动检测文件中是否包含 ```mermaid 块。如果有，脚本会启用 `pandoc-mermaid-filter`，该 filter 会调用 `mmdc`（mermaid-cli）生成图片并在生成文档时嵌入。

### 6) 常见问题

* **中文字体缺失或显示异常**：请确认容器中安装了 Noto CJK 系列字体，或在 `--variable mainfont` 中指定可用字体。
* **Mermaid 图未显示**：检查 `pandoc-mermaid-filter` 是否存在（镜像中已安装），以及 `mmdc` 是否可用；在转换时可加 `--log` 查看详细信息。
* **pptx 样式想自定义**：将自定义 PPTX 模板 `pptx_theme.pptx` 放入 `templates/`，脚本会自动引用（若存在）。

