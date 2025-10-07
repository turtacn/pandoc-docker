# 高度定制化的 Pandoc 容器

这是一个生产级的 Pandoc 容器镜像，旨在提供一个功能强大、开箱即用的 Markdown 文档转换环境。

## ✨ 核心特性

- **全面的中文支持**: 内置多种高质量中文字体（思源黑体、思源宋体、文泉驿等），完美解决中文渲染问题。
- **Mermaid 图表渲染**: 自动将 Markdown 中的 Mermaid 代码块转换为矢量图并嵌入到 PDF、DOCX 等文件中。
- **优雅的格式转换**: 提供 `md2pdf`, `md2docx`, `md2pptx` 等便捷脚本，支持丰富的自定义选项。
- **GitHub 风格**: 为代码高亮和 CSS 样式提供类似 GitHub 的现代化外观。
- **生产级依赖**: 集成了最新版 Pandoc、XeLaTeX、Node.js、Python 过滤器和 LibreOffice，确保兼容性和稳定性。
- **高度可定制**: 所有模板、样式和脚本均可轻松修改和扩展。

## 🚀 快速开始

### 1. 构建镜像

在项目根目录下执行：

```bash
# 使用 Docker Compose 构建 (推荐)
docker-compose build

# 或者使用原生 Docker 命令
docker build -t my-pandoc:latest .
```

### 2\. 使用方法

推荐将你的 Markdown 文档放在项目根目录或子目录中，因为该目录已挂载到容器的 `/workspace`。

#### 方法一：交互式 Shell (推荐)

启动一个可以交互的容器，然后在其中执行转换命令。

```bash
docker-compose run --rm pandoc /bin/bash
```

进入容器后，你可以像在本地一样使用转换脚本：

```bash
# 在容器内执行:
# 基本的 PDF 转换
md2pdf.sh test/sample.md

# 生成带目录的 PDF
md2pdf.sh test/sample.md my-document.pdf --toc

# 转换成 DOCX
md2docx.sh test/sample.md
```

#### 方法二：直接执行命令

直接在宿主机上运行转换命令，容器执行完毕后会自动销毁。

```bash
# 转换 PDF
docker-compose run --rm pandoc md2pdf.sh test/sample.md --toc

# 转换 DOCX
docker-compose run --rm pandoc md2docx.sh test/sample.md my-document.docx

# 转换 PPTX
docker-compose run --rm pandoc md2pptx.sh test/sample.md
```

## 🛠️ 脚本使用详解

### `md2pdf.sh`

将 Markdown 转换为高质量的 PDF 文档。

**用法**: `md2pdf.sh <input.md> [output.pdf] [options]`

**选项**:

  - `--toc`: 生成文档目录。
  - `--cover`: 添加封面页 (需在元数据中定义 `title`, `author` 并提供 `cover.png`)。
  - `--metadata <file.yaml>`: 指定一个 YAML 元数据文件。
  - `--filter <filter-name>`: 添加一个 Pandoc 过滤器 (例如 `pandoc-crossref`)。

**示例**:

```bash
# 生成带目录和封面的 PDF
md2pdf.sh my-book.md --toc --cover

# 合并多个文件并使用元数据
md2pdf.sh chapter1.md book.pdf chapter2.md --toc --metadata meta.yaml
```

### `md2docx.sh`

将 Markdown 转换为 Word (`.docx`) 文档。

**用法**: `md2docx.sh <input.md> [output.docx] [options]`

**选项**:

  - `--toc`: 在 Word 文档开头插入目录。
  - `--metadata <file.yaml>`: 指定元数据文件。

**示例**:

```bash
md2docx.sh report.md --toc
```

### `md2pptx.sh`

将 Markdown 转换为 PowerPoint (`.pptx`) 演示文稿。

**用法**: `md2pptx.sh <input.md> [output.pptx]`

> **注意**: PPTX 转换遵循 Pandoc 的标准，每个一级标题 (`#`) 或二级标题 (`##`) 默认为一张新的幻灯片，具体取决于文档结构。

**示例**:

```bash
md2pptx.sh presentation.md
```

## 🎨 定制化

你可以通过修改 `templates` 目录下的文件来改变输出文档的外观。

  - **`templates/pygments.theme`**: JSON 格式的代码高亮主题。
  - **`templates/github.css`**: 用于 HTML 相关输出的 CSS 样式。
  - **`templates/*.tex`**: 用于 PDF 输出的 LaTeX 宏包和样式定义。例如，`quote.tex` 定义了引用块的样式。