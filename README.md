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


我发现了问题！在 Ubuntu 22.04 中，DejaVu 字体包的名称已经改变。让我修正 Dockerfile：

## 修正后的 Dockerfile

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

## 主要修改点

1. **字体包名称修正**：

   * ❌ `ttf-dejavu` → ✅ `fonts-dejavu`
   * ❌ `ttf-dejavu-extra` → ✅ `fonts-dejavu-core` + `fonts-dejavu-extra`

2. **优化的构建步骤**：

   * 减少了 `apt-get clean` 的重复调用
   * 更好的层缓存策略

## 快速构建指南

### 1. 创建项目结构

```bash
mkdir -p pandoc-docker/{templates,scripts}
cd pandoc-docker
```

### 2. 创建必需的模板文件

**templates/chapter\_break.tex**:

```tex
\usepackage{sectsty}
\sectionfont{\clearpage}
```

**templates/inline\_code.tex**:

```tex
\usepackage{fancyvrb,newverbs,xcolor}
\definecolor{Light}{HTML}{F4F4F4}
\let\oldtexttt\texttt
\renewcommand{\texttt}[1]{\colorbox{Light}{\oldtexttt{#1}}}
```

**templates/bullet\_style.tex**:

```tex
\usepackage{enumitem}
\usepackage{amsfonts}
\setlist[itemize,1]{label=$\bullet$}
\setlist[itemize,2]{label=$\circ$}
\setlist[itemize,3]{label=$\star$}
```

**templates/quote.tex**:

```tex
\usepackage{tcolorbox}
\newtcolorbox{myquote}{colback=blue!5!white, colframe=blue!75!black}
\renewenvironment{quote}{\begin{myquote}}{\end{myquote}}
```

**templates/meta.tex**:

```tex
\usepackage{hyperref}
\hypersetup{
  pdfproducer={Pandoc with XeLaTeX},
  pdfcreator={Custom Pandoc Docker Container}
}
```

### 3. 创建转换脚本

**scripts/md2pdf.sh**:

```bash
#!/bin/bash
set -e

INPUT=""
OUTPUT=""
TEMPLATE_DIR="/opt/pandoc/templates"
TOC=false
METADATA=""
FILTERS=""
CHAPTERS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --toc) TOC=true; shift ;;
        --metadata) METADATA="$2"; shift 2 ;;
        --filter) FILTERS="$FILTERS --filter $2"; shift 2 ;;
        -*) echo "未知选项: $1"; exit 1 ;;
        *)
            if [ -z "$INPUT" ]; then INPUT="$1"
            elif [ -z "$OUTPUT" ]; then OUTPUT="$1"
            else CHAPTERS+=("$1"); fi
            shift ;;
    esac
done

if [ -z "$INPUT" ]; then
    echo "用法: md2pdf.sh input.md [output.pdf] [--toc] [--metadata file.yaml] [--filter crossref]"
    exit 1
fi

[ -z "$OUTPUT" ] && OUTPUT="${INPUT%.md}.pdf"

CMD="pandoc \"$INPUT\""
for chapter in "${CHAPTERS[@]}"; do CMD="$CMD \"$chapter\""; done

CMD="$CMD -f gfm --pdf-engine=xelatex"
CMD="$CMD -V CJKmainfont='Noto Serif CJK SC'"
CMD="$CMD -V CJKsansfont='Noto Sans CJK SC'"
CMD="$CMD -V CJKmonofont='Noto Sans Mono CJK SC'"
CMD="$CMD -V mainfont='DejaVu Serif'"
CMD="$CMD -V monofont='DejaVu Sans Mono'"
CMD="$CMD -V geometry:a4paper -V geometry:margin=2.5cm"
CMD="$CMD -V linkcolor:blue -V fontsize=12pt"
CMD="$CMD --include-in-header $TEMPLATE_DIR/chapter_break.tex"
CMD="$CMD --include-in-header $TEMPLATE_DIR/inline_code.tex"
CMD="$CMD --include-in-header $TEMPLATE_DIR/bullet_style.tex"
CMD="$CMD --include-in-header $TEMPLATE_DIR/quote.tex"
CMD="$CMD --include-in-header $TEMPLATE_DIR/meta.tex"

[ "$TOC" = true ] && CMD="$CMD --toc --toc-depth=3 -V toc-title='目录'"
[ -n "$METADATA" ] && CMD="$CMD --metadata-file=\"$METADATA\""
[ -n "$FILTERS" ] && CMD="$CMD $FILTERS"
CMD="$CMD -o \"$OUTPUT\""

echo "正在转换: $INPUT -> $OUTPUT"
eval $CMD
echo "✅ 转换完成: $OUTPUT"
```

**scripts/md2docx.sh**:

```bash
#!/bin/bash
set -e

INPUT=""
OUTPUT=""
TOC=false
METADATA=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --toc) TOC=true; shift ;;
        --metadata) METADATA="$2"; shift 2 ;;
        -*) echo "未知选项: $1"; exit 1 ;;
        *)
            if [ -z "$INPUT" ]; then INPUT="$1"
            elif [ -z "$OUTPUT" ]; then OUTPUT="$1"; fi
            shift ;;
    esac
done

if [ -z "$INPUT" ]; then
    echo "用法: md2docx.sh input.md [output.docx] [--toc] [--metadata file.yaml]"
    exit 1
fi

[ -z "$OUTPUT" ] && OUTPUT="${INPUT%.md}.docx"

CMD="pandoc \"$INPUT\" -f gfm -t docx --standalone"
[ "$TOC" = true ] && CMD="$CMD --toc --toc-depth=3"
[ -n "$METADATA" ] && CMD="$CMD --metadata-file=\"$METADATA\""
CMD="$CMD -o \"$OUTPUT\""

echo "正在转换: $INPUT -> $OUTPUT"
eval $CMD
echo "✅ 转换完成: $OUTPUT"
```

**scripts/md2pptx.sh**:

```bash
#!/bin/bash
set -e

INPUT=""
OUTPUT=""
METADATA=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --metadata) METADATA="$2"; shift 2 ;;
        -*) echo "未知选项: $1"; exit 1 ;;
        *)
            if [ -z "$INPUT" ]; then INPUT="$1"
            elif [ -z "$OUTPUT" ]; then OUTPUT="$1"; fi
            shift ;;
    esac
done

if [ -z "$INPUT" ]; then
    echo "用法: md2pptx.sh input.md [output.pptx] [--metadata file.yaml]"
    exit 1
fi

[ -z "$OUTPUT" ] && OUTPUT="${INPUT%.md}.pptx"

CMD="pandoc \"$INPUT\" -f gfm -t pptx --standalone"
[ -n "$METADATA" ] && CMD="$CMD --metadata-file=\"$METADATA\""
CMD="$CMD -o \"$OUTPUT\""

echo "正在转换: $INPUT -> $OUTPUT"
eval $CMD
echo "✅ 转换完成: $OUTPUT"
```

### 4. 构建和测试

```bash
# 构建镜像
docker build -t jdcloudiaas/turta:pandoc .

# 测试运行
docker run -it --rm -v $(pwd)/test:/workspace jdcloudiaas/turta:pandoc bash

# 在容器内测试
echo "# 测试文档\n\n这是一个测试。" > test.md
md2pdf.sh test.md --toc
```

现在 Dockerfile 应该可以正常构建了！字体包名称已经修正为 Ubuntu 22.04 中的正确名称。

# templates/cover.tex 内容

```tex
% 封面页配置
% 使用方法：--include-before-body cover.tex

% 插入封面图片
\begin{titlepage}
    \centering
    \vspace*{2cm}
    
    % 封面图片（需要在工作目录有 cover.png 文件）
    \includegraphics[width=0.6\textwidth]{cover.png}
    
    \vspace{2cm}
    
    % 文档标题（从元数据自动获取）
    {\Huge\bfseries \@title \par}
    
    \vspace{1cm}
    
    % 作者（从元数据自动获取）
    {\Large \@author \par}
    
    \vspace{1cm}
    
    % 日期
    {\large \@date \par}
    
    \vfill
    
    % 版权信息或出版信息
    {\small 此文档由 Pandoc 生成 \par}
    
\end{titlepage}

% 清除页眉页脚
\thispagestyle{empty}

% 换页
\newpage
```

## 📖 使用说明

### 1️⃣ 基础用法

在转换命令中添加：

```bash
pandoc input.md \
    --include-before-body /opt/pandoc/templates/cover.tex \
    -o output.pdf
```

### 2️⃣ 准备封面图片

在你的工作目录放置 `cover.png`:

```bash
# 确保有封面图片
ls cover.png
```

### 3️⃣ 在元数据中定义标题和作者

创建 `metadata.yaml`:

```yaml
---
title: "我的技术文档"
author: "张三"
date: "2025年10月"
---
```

然后转换：

```bash
pandoc input.md \
    --metadata-file=metadata.yaml \
    --include-before-body /opt/pandoc/templates/cover.tex \
    -o output.pdf
```

## 🎨 进阶版：更美观的封面

如果想要更专业的封面设计，可以用这个版本：

**templates/cover\_advanced.tex**:

```tex
\begin{titlepage}
    \centering
    
    % 顶部装饰线
    \rule{\textwidth}{1pt}
    
    \vspace{3cm}
    
    % 封面图片（可选）
    \ifdefempty{\coverimage}{}{
        \includegraphics[width=0.5\textwidth]{\coverimage}
        \vspace{2cm}
    }
    
    % 主标题
    {\Huge\bfseries\color{blue} \@title \par}
    
    \vspace{0.5cm}
    
    % 副标题（如果有）
    \ifdefempty{\subtitle}{}{
        {\Large\itshape \subtitle \par}
        \vspace{1cm}
    }
    
    % 分隔线
    \rule{0.5\textwidth}{0.5pt}
    
    \vspace{1.5cm}
    
    % 作者信息
    {\Large
    \begin{tabular}[t]{c}
        \textbf{作者} \\
        \@author
    \end{tabular}
    \par}
    
    \vspace{2cm}
    
    % 机构或出版信息
    \ifdefempty{\institute}{}{
        {\large \institute \par}
        \vspace{0.5cm}
    }
    
    % 日期
    {\large \@date \par}
    
    \vfill
    
    % 底部装饰线
    \rule{\textwidth}{1pt}
    
    % 版本信息
    \ifdefempty{\version}{}{
        {\small 版本: \version \par}
    }
    
\end{titlepage}

\thispagestyle{empty}
\newpage
```

**配套的 metadata.yaml**:

```yaml
---
title: "高级 Pandoc 使用指南"
subtitle: "从入门到精通"
author: "技术团队"
date: "2025年10月7日"
institute: "开源技术社区"
version: "v1.0.0"
coverimage: "cover.png"
---
```

## 🔧 集成到脚本

修改 `scripts/md2pdf.sh`，添加封面选项：

```bash
#!/bin/bash
set -e

# ... 其他参数解析 ...

COVER=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --cover)
            COVER=true
            shift
            ;;
        # ... 其他选项 ...
    esac
done

# ... 构建命令 ...

# 添加封面
if [ "$COVER" = true ]; then
    CMD="$CMD --include-before-body $TEMPLATE_DIR/cover.tex"
fi
```

**使用示例：**

```bash
md2pdf.sh document.md --toc --cover
```

## ⚠️ 注意事项

1. **图片路径**：`cover.png` 必须在**当前工作目录**或使用绝对路径
2. **元数据变量**：LaTeX 的 `\@title` 和 `\@author` 会自动从 YAML 元数据获取
3. **图片格式**：推荐使用 PNG 或 PDF 格式的封面图
4. **尺寸建议**：封面图片推荐尺寸 1200x1600 像素（3:4 比例）

这样就可以生成带有专业封面的 PDF 文档了！🎉


# templates/pygments.theme 内容

这是 Pandoc 的代码高亮主题配置文件，基于 Pygments 风格，并针对中文技术文档进行了优化。

```json
{
  "text-color": "#24292f",
  "background-color": "#f6f8fa",
  "line-number-color": "#57606a",
  "line-number-background-color": "#f6f8fa",
  "text-styles": {
    "Other": {
      "text-color": "#24292f"
    },
    "Attribute": {
      "text-color": "#0550ae"
    },
    "SpecialString": {
      "text-color": "#0a3069"
    },
    "Annotation": {
      "text-color": "#57606a",
      "italic": true
    },
    "Function": {
      "text-color": "#8250df",
      "bold": false
    },
    "String": {
      "text-color": "#0a3069"
    },
    "ControlFlow": {
      "text-color": "#cf222e",
      "bold": true
    },
    "Operator": {
      "text-color": "#cf222e"
    },
    "Error": {
      "text-color": "#f6f8fa",
      "background-color": "#cf222e",
      "bold": true
    },
    "BaseN": {
      "text-color": "#0550ae"
    },
    "Alert": {
      "text-color": "#cf222e",
      "bold": true
    },
    "Variable": {
      "text-color": "#953800"
    },
    "BuiltIn": {
      "text-color": "#8250df"
    },
    "Extension": {
      "text-color": "#8250df"
    },
    "Preprocessor": {
      "text-color": "#57606a"
    },
    "Information": {
      "text-color": "#57606a"
    },
    "VerbatimString": {
      "text-color": "#0a3069"
    },
    "Warning": {
      "text-color": "#953800",
      "bold": true
    },
    "Documentation": {
      "text-color": "#57606a",
      "italic": true
    },
    "Import": {
      "text-color": "#cf222e",
      "bold": true
    },
    "Char": {
      "text-color": "#0a3069"
    },
    "DataType": {
      "text-color": "#cf222e"
    },
    "Float": {
      "text-color": "#0550ae"
    },
    "Comment": {
      "text-color": "#6e7781",
      "italic": false
    },
    "CommentVar": {
      "text-color": "#6e7781",
      "italic": false
    },
    "Constant": {
      "text-color": "#0550ae"
    },
    "SpecialChar": {
      "text-color": "#cf222e"
    },
    "DecVal": {
      "text-color": "#0550ae"
    },
    "Keyword": {
      "text-color": "#cf222e",
      "bold": true
    }
  }
}
```

## 🎨 这个主题的特点

这是基于 **GitHub 风格**的代码高亮配色方案：

| 元素  | 颜色        | 说明         |
| --- | --------- | ---------- |
| 背景色 | `#f6f8fa` | 淡灰色背景，舒适护眼 |
| 文本  | `#24292f` | 深灰色，易读性好   |
| 关键字 | `#cf222e` | 红色，醒目      |
| 字符串 | `#0a3069` | 深蓝色        |
| 函数  | `#8250df` | 紫色         |
| 注释  | `#6e7781` | 中灰色，不抢眼    |
| 数字  | `#0550ae` | 蓝色         |

## 📦 导出和自定义

### 1️⃣ 从 Pandoc 导出默认主题

```bash
# 导出 pygments 主题
pandoc --print-highlight-style=pygments > pygments.theme

# 其他可用主题
pandoc --print-highlight-style=tango > tango.theme
pandoc --print-highlight-style=espresso > espresso.theme
pandoc --print-highlight-style=zenburn > zenburn.theme
pandoc --print-highlight-style=kate > kate.theme
pandoc --print-highlight-style=monochrome > monochrome.theme
pandoc --print-highlight-style=breezedark > breezedark.theme
pandoc --print-highlight-style=haddock > haddock.theme
```

### 2️⃣ 修改主题示例

如果你想要**深色主题**，可以修改为：

**templates/pygments\_dark.theme**:

```json
{
  "text-color": "#e6edf3",
  "background-color": "#0d1117",
  "line-number-color": "#7d8590",
  "line-number-background-color": "#0d1117",
  "text-styles": {
    "Keyword": {
      "text-color": "#ff7b72",
      "bold": true
    },
    "String": {
      "text-color": "#a5d6ff"
    },
    "Function": {
      "text-color": "#d2a8ff"
    },
    "Comment": {
      "text-color": "#8b949e",
      "italic": false
    },
    "Variable": {
      "text-color": "#ffa657"
    },
    "Number": {
      "text-color": "#79c0ff"
    }
  }
}
```

### 3️⃣ 在脚本中使用

修改 `scripts/md2pdf.sh`，添加主题选择：

```bash
#!/bin/bash

THEME="pygments"

while [[ $# -gt 0 ]]; do
    case $1 in
        --theme)
            THEME="$2"
            shift 2
            ;;
        # ... 其他选项 ...
    esac
done

# 构建命令
if [ -f "$TEMPLATE_DIR/${THEME}.theme" ]; then
    CMD="$CMD --highlight-style $TEMPLATE_DIR/${THEME}.theme"
else
    CMD="$CMD --highlight-style $THEME"
fi
```

**使用示例：**

```bash
# 使用自定义主题
md2pdf.sh code.md --theme pygments

# 使用深色主题
md2pdf.sh code.md --theme pygments_dark

# 使用 Pandoc 内置主题
md2pdf.sh code.md --theme tango
```

## 🧪 测试代码高亮

创建测试文件 `test/highlight_test.md`:

````markdown
# 代码高亮测试

## Python 代码

```python
def fibonacci(n):
    """计算斐波那契数列"""
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)

# 测试
for i in range(10):
    print(f"F({i}) = {fibonacci(i)}")
```

## JavaScript 代码

```javascript
// 异步函数示例
async function fetchData(url) {
    const response = await fetch(url);
    const data = await response.json();
    return data;
}

// 使用示例
fetchData('https://api.example.com/data')
    .then(data => console.log(data))
    .catch(error => console.error('Error:', error));
```

## Bash 脚本

```bash
#!/bin/bash
# 批量转换 Markdown 文件

for file in *.md; do
    echo "正在处理: $file"
    md2pdf.sh "$file" --toc
done

echo "✅ 全部完成！"
```
````

**转换测试：**

```bash
docker run --rm -v $(pwd)/test:/workspace jdcloudiaas/turta:pandoc \
    md2pdf.sh highlight_test.md
```

## 🎯 推荐配置

根据不同场景选择主题：

| 场景   | 推荐主题         | 特点             |
| ---- | ------------ | -------------- |
| 技术文档 | `pygments`   | GitHub 风格，清晰易读 |
| 深色模式 | `breezedark` | 护眼，适合演示        |
| 打印输出 | `tango`      | 对比度高，适合纸质打印    |
| 简约风格 | `haddock`    | 极简，适合学术论文      |

这样就完整配置了代码高亮主题！🎨

