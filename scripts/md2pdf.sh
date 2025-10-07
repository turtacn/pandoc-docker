#!/bin/bash
# ===============================================================
# md2pdf.sh
# Markdown -> PDF 转换脚本（自动检测 Mermaid；GitHub CSS；XeLaTeX）
# Usage:
#   md2pdf.sh input.md                  # 生成 input.pdf
#   md2pdf.sh input.md -o output.pdf    # 指定输出文件
#   md2pdf.sh input.md --toc=false      # 传递其他 pandoc 参数
# ===============================================================
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <input.md> [-o output.pdf] [extra pandoc args]"
  exit 1
fi

INPUT="$1"; shift || true
OUTPUT="${INPUT%.md}.pdf"

# check -o
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o) OUTPUT="$2"; shift 2;;
    --) shift; break;;
    *) break;;
  esac
done

# 自动检测 mermaid
FILTER_OPT=""
if grep -q --fixed-strings '```mermaid' "$INPUT" 2>/dev/null || grep -q --perl-regexp '(?s)```mermaid.*?```' "$INPUT" 2>/dev/null; then
  echo "🪄 Mermaid blocks found -> enabling pandoc-mermaid-filter"
  FILTER_OPT="--filter pandoc-mermaid-filter"
fi

TPL_DIR="/opt/pandoc/templates"
CSS_FILE="$TPL_DIR/github.css"
HIGHLIGHT="$TPL_DIR/pygments.theme"
TEMPLATE="$TPL_DIR/meta.tex"

echo "📄 Converting $INPUT -> $OUTPUT"
pandoc "$INPUT" \
  --from markdown+yaml_metadata_block+raw_html+smart \
  --to pdf \
  --pdf-engine=xelatex \
  --template="$TEMPLATE" \
  --highlight-style="$HIGHLIGHT" \
  --resource-path="$(dirname "$INPUT")" \
  --css="$CSS_FILE" \
  --toc \
  --metadata-file="meta.yaml" \
  $FILTER_OPT \
  "$@" \
  -o "$OUTPUT"

echo "✅ Done: $OUTPUT"

# Examples (for users):
# 1) Basic:
#    md2pdf.sh test/sample.md
# 2) Custom output:
#    md2pdf.sh test/sample.md -o out/report.pdf
# 3) Pass through pandoc options:
#    md2pdf.sh test/sample.md --variable mainfont="Noto Sans CJK SC"
