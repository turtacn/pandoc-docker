#!/bin/bash
#
# Pandoc Markdown to DOCX 转换脚本
# 功能: 自动处理 Mermaid 图表。
#

set -e

# --- 参数初始化 ---
INPUT=""
OUTPUT=""
TOC=false
METADATA=""
FILTERS=("--filter" "pandoc-mermaid-filter") # 默认启用 Mermaid 过滤器


# --- 解析用户输入参数 ---
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
            echo "错误: 未知选项: $1" >&2
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

# --- 校验参数 ---
if [ -z "$INPUT" ]; then
    echo "错误: 请指定输入 Markdown 文件。"
    echo "用法: md2docx.sh input.md [output.docx] [--toc] [--metadata file.yaml]"
    exit 1
fi

# 自动生成输出文件名
if [ -z "$OUTPUT" ]; then
    OUTPUT="${INPUT%.md}.docx"
fi

# --- 构建 Pandoc 命令 ---
CMD=(
    "pandoc"
    "$INPUT"
    "-f" "gfm"
    "-t" "docx"
    "--standalone"
)

# 目录
if [ "$TOC" = true ]; then
    CMD+=("--toc" "--toc-depth=3")
fi

# 元数据
if [ -n "$METADATA" ]; then
    CMD+=("--metadata-file=$METADATA")
fi

# 过滤器
CMD+=("${FILTERS[@]}")

# 输出
CMD+=("-o" "$OUTPUT")

# --- 执行命令 ---
echo "pandoc-docker > 正在转换: $INPUT -> $OUTPUT"
"${CMD[@]}"
echo "pandoc-docker > ✅ 转换完成: $OUTPUT"