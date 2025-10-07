#!/bin/bash
#
# Pandoc Markdown to PDF 转换脚本
# 功能: 自动处理中文、Mermaid图表、封面、目录等。
#

set -e

# --- 参数初始化 ---
INPUT=""
OUTPUT=""
declare -a CHAPTERS=()
TEMPLATE_DIR="/opt/pandoc/templates"
TOC=false
COVER=false
METADATA=""
declare -a FILTERS=("--filter" "pandoc-mermaid") # 默认启用 Mermaid 过滤器

# --- 解析用户输入参数 ---
while [[ $# -gt 0 ]]; do
    case $1 in
        --toc)
            TOC=true
            shift
            ;;
        --cover)
            COVER=true
            shift
            ;;
        --metadata)
            METADATA="$2"
            shift 2
            ;;
        --filter)
            FILTERS+=("--filter" "$2")
            shift 2
            ;;
        -*)
            echo "错误: 未知选项: $1" >&2
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

# --- 校验参数 ---
if [ -z "$INPUT" ]; then
    echo "错误: 请指定输入 Markdown 文件。"
    echo "用法: md2pdf.sh input.md [output.pdf] [--toc] [--cover] [--metadata file.yaml] [--filter name]"
    exit 1
fi

# 如果未指定输出文件, 自动生成
if [ -z "$OUTPUT" ]; then
    OUTPUT="${INPUT%.md}.pdf"
fi

# --- 构建 Pandoc 命令 ---
CMD=(
    "pandoc"
    "$INPUT"
)

# 添加其他章节
for chapter in "${CHAPTERS[@]}"; do
    CMD+=("$chapter")
done

# 基础转换参数
CMD+=(
    "-f" "gfm"  # 从 GitHub Flavored Markdown 读取
    "--pdf-engine=xelatex" # 使用 XeLaTeX 支持中文
    "--standalone"
)

# 字体设置
CMD+=(
    "-V" "CJKmainfont=Noto Serif CJK SC"      # 中文衬线字体 (正文)
    "-V" "CJKsansfont=Noto Sans CJK SC"      # 中文无衬线字体 (标题)
    "-V" "CJKmonofont=Noto Sans Mono CJK SC"  # 中文等宽字体 (代码)
    "-V" "mainfont=DejaVu Serif"             # 西文衬线字体
    "-V" "monofont=DejaVu Sans Mono"         # 西文等宽字体
    "-V" "fontsize=12pt"
)

# 页面布局
CMD+=(
    "-V" "geometry:a4paper"
    "-V" "geometry:margin=2.5cm"
    "-V" "linkcolor:blue"
)

# 加载自定义 LaTeX 模板
CMD+=(
    "--include-in-header" "$TEMPLATE_DIR/meta.tex"
    "--include-in-header" "$TEMPLATE_DIR/inline_code.tex"
    "--include-in-header" "$TEMPLATE_DIR/quote.tex"
    "--include-in-header" "$TEMPLATE_DIR/bullet_style.tex"
    "--include-in-header" "$TEMPLATE_DIR/chapter_break.tex"
)

# 代码高亮
if [ -f "$TEMPLATE_DIR/pygments.theme" ]; then
    CMD+=("--highlight-style" "$TEMPLATE_DIR/pygments.theme")
fi

# 目录
if [ "$TOC" = true ]; then
    CMD+=(
        "--toc"
        "--toc-depth=3"
        "-V" "toc-title=目录"
    )
fi

# 封面
if [ "$COVER" = true ]; then
    CMD+=("--include-before-body" "$TEMPLATE_DIR/cover.tex")
fi

# 元数据文件
if [ -n "$METADATA" ]; then
    CMD+=("--metadata-file=$METADATA")
fi

# 添加过滤器
CMD+=("${FILTERS[@]}")

# 输出文件
CMD+=("-o" "$OUTPUT")

# --- 执行命令 ---
echo "pandoc-docker > 正在转换: $INPUT -> $OUTPUT"
# 使用 "${CMD[@]}" 以正确处理带空格的参数
"${CMD[@]}"
echo "pandoc-docker > ✅ 转换完成: $OUTPUT"