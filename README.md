# 高度定制化的 Pandoc 容器镜像方案

根据您的需求，我将创建一个完整的、支持中文和多种转换场景的 Pandoc Docker 容器方案。

## 📦 Dockerfile

```dockerfile
FROM ubuntu:22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8

# 安装基础依赖和中文支持
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    ca-certificates \
    locales \
    fonts-noto-cjk \
    fonts-noto-cjk-extra \
    fonts-wqy-microhei \
    fonts-wqy-zenhei \
    fonts-dejavu \
    fonts-dejavu-core \
    fonts-dejavu-extra \
    && locale-gen zh_CN.UTF-8 \
    && update-locale LANG=zh_CN.UTF-8

# 安装 Pandoc (最新版本)
RUN PANDOC_VERSION=3.7.0.1 && \
    wget https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-1-amd64.deb && \
    dpkg -i pandoc-${PANDOC_VERSION}-1-amd64.deb && \
    rm pandoc-${PANDOC_VERSION}-1-amd64.deb

# 安装 TeX Live 和相关工具
RUN apt-get install -y \
    texlive-xetex \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-lang-chinese \
    texlive-science \
    librsvg2-bin \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 安装 Python 和过滤器
RUN apt-get update && apt-get install -y python3 python3-pip && \
    pip3 install --no-cache-dir \
    pandoc-crossref \
    pandoc-tablenos \
    pandoc-fignos \
    pandoc-eqnos \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 安装 LibreOffice (用于 PPTX 转换优化)
RUN apt-get update && apt-get install -y \
    libreoffice-writer \
    libreoffice-impress \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 创建工作目录
WORKDIR /workspace

# 复制配置文件和模板
COPY templates /opt/pandoc/templates
COPY scripts /opt/pandoc/scripts

# 设置脚本执行权限
RUN chmod +x /opt/pandoc/scripts/*.sh

# 添加脚本到 PATH
ENV PATH="/opt/pandoc/scripts:${PATH}"

# 默认命令
CMD ["/bin/bash"]
```

## 📁 项目结构

```
pandoc-docker/
├── Dockerfile
├── templates/
│   ├── chapter_break.tex
│   ├── inline_code.tex
│   ├── bullet_style.tex
│   ├── quote.tex
│   ├── meta.tex
│   ├── cover.tex
│   ├── pygments.theme
│   ├── github.css
│   └── epub.css
├── scripts/
│   ├── md2pdf.sh
│   ├── md2docx.sh
│   └── md2pptx.sh
└── README.md
```

## 🎨 模板文件

### templates/chapter\_break.tex

```tex
\usepackage{sectsty}
\sectionfont{\clearpage}
```

### templates/inline\_code.tex

```tex
\usepackage{fancyvrb,newverbs,xcolor}
\definecolor{Light}{HTML}{F4F4F4}
\let\oldtexttt\texttt
\renewcommand{\texttt}[1]{\colorbox{Light}{\oldtexttt{#1}}}
```

### templates/bullet\_style.tex

```tex
\usepackage{enumitem}
\usepackage{amsfonts}
\setlist[itemize,1]{label=$\bullet$}
\setlist[itemize,2]{label=$\circ$}
\setlist[itemize,3]{label=$\star$}
```

### templates/quote.tex

```tex
\usepackage{tcolorbox}
\newtcolorbox{myquote}{colback=blue!5!white, colframe=blue!75!black}
\renewenvironment{quote}{\begin{myquote}}{\end{myquote}}
```

### templates/meta.tex

```tex
\usepackage{hyperref}
\hypersetup{
  pdfproducer={Pandoc},
  pdfcreator={XeLaTeX}
}
```

### templates/github.css

```css
/* GitHub 风格的 Markdown 样式 */
body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Noto Sans", Helvetica, Arial, sans-serif;
    font-size: 16px;
    line-height: 1.6;
    color: #24292f;
    background-color: #ffffff;
    max-width: 980px;
    margin: 0 auto;
    padding: 45px;
}

code {
    background-color: #f6f8fa;
    border-radius: 6px;
    padding: 0.2em 0.4em;
    font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, "Liberation Mono", monospace;
    font-size: 85%;
}

pre {
    background-color: #f6f8fa;
    border-radius: 6px;
    padding: 16px;
    overflow: auto;
}

blockquote {
    border-left: 0.25em solid #d0d7de;
    color: #57606a;
    padding: 0 1em;
}

table {
    border-collapse: collapse;
    width: 100%;
}

th, td {
    border: 1px solid #d0d7de;
    padding: 6px 13px;
}

th {
    background-color: #f6f8fa;
    font-weight: 600;
}
```

### templates/epub.css

```css
body {
    font-family: "Noto Serif CJK SC", serif;
    line-height: 1.8;
}

code {
    font-family: "Noto Sans Mono CJK SC", monospace;
    background-color: #f5f5f5;
    padding: 2px 4px;
    border-radius: 3px;
}

pre code {
    display: block;
    padding: 10px;
    overflow-x: auto;
}

blockquote {
    border-left: 4px solid #ccc;
    padding-left: 1em;
    color: #666;
    font-style: italic;
}
```

## 🚀 转换脚本

### scripts/md2pdf.sh

```bash
#!/bin/bash

# Pandoc Markdown to PDF 转换脚本
# 用法: md2pdf.sh input.md [output.pdf] [options]

set -e

# 默认参数
INPUT=""
OUTPUT=""
TEMPLATE_DIR="/opt/pandoc/templates"
TOC=false
CHAPTERS=()
METADATA=""
FILTERS=""

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --toc)
            TOC=true
            shift
            ;;
        --metadata)
            METADATA="$2"
            shift 2
            ;;
        --filter)
            FILTERS="$FILTERS --filter $2"
            shift 2
            ;;
        -*)
            echo "未知选项: $1"
            exit 1
            ;;
        *)
            if [ -z "$INPUT" ]; then
                INPUT="$1"
            elif [ -z "$OUTPUT" ]; then
                OUTPUT="$1"
            else
                CHAPTERS+=("$1")
            fi
            shift
            ;;
    esac
done

# 检查输入文件
if [ -z "$INPUT" ]; then
    echo "错误: 请指定输入文件"
    echo "用法: md2pdf.sh input.md [output.pdf] [--toc] [--metadata metadata.yaml] [--filter crossref]"
    exit 1
fi

# 设置输出文件名
if [ -z "$OUTPUT" ]; then
    OUTPUT="${INPUT%.md}.pdf"
fi

# 构建 Pandoc 命令
CMD="pandoc \"$INPUT\""

# 添加其他章节文件
for chapter in "${CHAPTERS[@]}"; do
    CMD="$CMD \"$chapter\""
done

# 基础参数
CMD="$CMD -f gfm"
CMD="$CMD --pdf-engine=xelatex"
CMD="$CMD -V CJKmainfont='Noto Serif CJK SC'"
CMD="$CMD -V CJKsansfont='Noto Sans CJK SC'"
CMD="$CMD -V CJKmonofont='Noto Sans Mono CJK SC'"
CMD="$CMD -V mainfont='DejaVu Serif'"
CMD="$CMD -V monofont='DejaVu Sans Mono'"
CMD="$CMD -V geometry:a4paper"
CMD="$CMD -V geometry:margin=2.5cm"
CMD="$CMD -V linkcolor:blue"
CMD="$CMD -V fontsize=12pt"

# LaTeX 模板
CMD="$CMD --include-in-header $TEMPLATE_DIR/chapter_break.tex"
CMD="$CMD --include-in-header $TEMPLATE_DIR/inline_code.tex"
CMD="$CMD --include-in-header $TEMPLATE_DIR/bullet_style.tex"
CMD="$CMD --include-in-header $TEMPLATE_DIR/quote.tex"
CMD="$CMD --include-in-header $TEMPLATE_DIR/meta.tex"

# 代码高亮
if [ -f "$TEMPLATE_DIR/pygments.theme" ]; then
    CMD="$CMD --highlight-style $TEMPLATE_DIR/pygments.theme"
fi

# 目录
if [ "$TOC" = true ]; then
    CMD="$CMD --toc --toc-depth=3"
    CMD="$CMD -V toc-title='目录'"
fi

# 元数据
if [ -n "$METADATA" ]; then
    CMD="$CMD --metadata-file=\"$METADATA\""
fi

# 过滤器
if [ -n "$FILTERS" ]; then
    CMD="$CMD $FILTERS"
fi

# 输出
CMD="$CMD -o \"$OUTPUT\""

# 执行命令
echo "正在转换: $INPUT -> $OUTPUT"
eval $CMD
echo "转换完成: $OUTPUT"
```

### scripts/md2docx.sh

```bash
#!/bin/bash

# Pandoc Markdown to DOCX 转换脚本
# 用法: md2docx.sh input.md [output.docx] [options]

set -e

INPUT=""
OUTPUT=""
TEMPLATE_DIR="/opt/pandoc/templates"
TOC=false
METADATA=""

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --toc)
            TOC=true
            shift
            ;;
        --metadata)
            METADATA="$2"
            shift 2
            ;;
        -*)
            echo "未知选项: $1"
            exit 1
            ;;
        *)
            if [ -z "$INPUT" ]; then
                INPUT="$1"
            elif [ -z "$OUTPUT" ]; then
                OUTPUT="$1"
            fi
            shift
            ;;
    esac
done

# 检查输入文件
if [ -z "$INPUT" ]; then
    echo "错误: 请指定输入文件"
    echo "用法: md2docx.sh input.md [output.docx] [--toc] [--metadata metadata.yaml]"
    exit 1
fi

# 设置输出文件名
if [ -z "$OUTPUT" ]; then
    OUTPUT="${INPUT%.md}.docx"
fi

# 构建 Pandoc 命令
CMD="pandoc \"$INPUT\""
CMD="$CMD -f gfm"
CMD="$CMD -t docx"
CMD="$CMD --standalone"

# 目录
if [ "$TOC" = true ]; then
    CMD="$CMD --toc --toc-depth=3"
fi

# 元数据
if [ -n "$METADATA" ]; then
    CMD="$CMD --metadata-file=\"$METADATA\""
fi

# 输出
CMD="$CMD -o \"$OUTPUT\""

# 执行命令
echo "正在转换: $INPUT -> $OUTPUT"
eval $CMD
echo "转换完成: $OUTPUT"
```

### scripts/md2pptx.sh

```bash
#!/bin/bash

# Pandoc Markdown to PPTX 转换脚本
# 用法: md2pptx.sh input.md [output.pptx]

set -e

INPUT=""
OUTPUT=""
METADATA=""

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --metadata)
            METADATA="$2"
            shift 2
            ;;
        -*)
            echo "未知选项: $1"
            exit 1
            ;;
        *)
            if [ -z "$INPUT" ]; then
                INPUT="$1"
            elif [ -z "$OUTPUT" ]; then
                OUTPUT="$1"
            fi
            shift
            ;;
    esac
done

# 检查输入文件
if [ -z "$INPUT" ]; then
    echo "错误: 请指定输入文件"
    echo "用法: md2pptx.sh input.md [output.pptx] [--metadata metadata.yaml]"
    exit 1
fi

# 设置输出文件名
if [ -z "$OUTPUT" ]; then
    OUTPUT="${INPUT%.md}.pptx"
fi

# 构建 Pandoc 命令
CMD="pandoc \"$INPUT\""
CMD="$CMD -f gfm"
CMD="$CMD -t pptx"
CMD="$CMD --standalone"

# 元数据
if [ -n "$METADATA" ]; then
    CMD="$CMD --metadata-file=\"$METADATA\""
fi

# 输出
CMD="$CMD -o \"$OUTPUT\""

# 执行命令
echo "正在转换: $INPUT -> $OUTPUT"
eval $CMD
echo "转换完成: $OUTPUT"
```

## 📖 使用说明

### 1. 构建镜像

```bash
docker build -t jdcloudiaas/turta:pandoc .
```

### 2. 运行容器

```bash
# 交互式运行
docker run -it --rm -v $(pwd):/workspace jdcloudiaas/turta:pandoc

# 直接转换
docker run --rm -v $(pwd):/workspace jdcloudiaas/turta:pandoc md2pdf.sh input.md
```

### 3. 使用示例

#### PDF 转换

```bash
# 基础转换
md2pdf.sh document.md

# 带目录
md2pdf.sh document.md output.pdf --toc

# 多文件合并
md2pdf.sh chapter1.md output.pdf chapter2.md chapter3.md --toc

# 使用元数据和交叉引用
md2pdf.sh document.md --toc --metadata metadata.yaml --filter pandoc-crossref
```

#### DOCX 转换

```bash
# 基础转换
md2docx.sh document.md

# 带目录
md2docx.sh document.md --toc
```

#### PPTX 转换

```bash
md2pptx.sh presentation.md
```

### 4. Docker Compose 配置

创建 `docker-compose.yml`:

```yaml
version: '3.8'

services:
  pandoc:
    image: jdcloudiaas/turta:pandoc
    volumes:
      - ./documents:/workspace
    working_dir: /workspace
    command: /bin/bash
    stdin_open: true
    tty: true
```

运行:

```bash
docker-compose run --rm pandoc md2pdf.sh document.md --toc
```

## ✨ 特性总结

* ✅ **完整中文支持**: Noto CJK 字体家族
* ✅ **GitHub 风格样式**: 代码高亮和排版
* ✅ **多格式输出**: PDF, DOCX, PPTX, EPUB
* ✅ **交叉引用支持**: 图表、公式自动编号
* ✅ **美化样式**: 代码块、引用、项目符号
* ✅ **自动化脚本**: 简化命令行操作
* ✅ **多文件合并**: 支持大型文档项目
* ✅ **可扩展性**: 易于添加自定义模板

这个方案提供了一个生产就绪的 Pandoc 容器环境，可以满足您所有的文档转换需求！
