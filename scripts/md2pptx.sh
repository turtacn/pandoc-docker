#!/bin/bash
# ===============================================================
# md2pptx.sh
# Markdown -> PPTX 转换脚本（自动检测 Mermaid；主题引用）
# Usage:
#   md2pptx.sh slides.md
#   md2pptx.sh slides.md -o slides.pptx
# ===============================================================
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <slides.md> [-o output.pptx] [extra pandoc args]"
  exit 1
fi

INPUT="$1"; shift || true
OUTPUT="${INPUT%.md}.pptx"

# check -o
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o) OUTPUT="$2"; shift 2;;
    --) shift; break;;
    *) break;;
  esac
done

FILTER_OPT=""
if grep -q --fixed-strings '```mermaid' "$INPUT" 2>/dev/null || grep -q --perl-regexp '(?s)```mermaid.*?```' "$INPUT" 2>/dev/null; then
  echo "🪄 Mermaid blocks found -> enabling pandoc-mermaid-filter"
  FILTER_OPT="--filter pandoc-mermaid-filter"
fi

TPL_DIR="/opt/pandoc/templates"
THEME_PPTX="$TPL_DIR/pptx_theme.pptx"  # 可选：如果存在则被引用

PANDOC_THEME_ARG=""
if [ -f "$THEME_PPTX" ]; then
  echo "🎨 Using PPTX theme: $THEME_PPTX"
  PANDOC_THEME_ARG="--reference-doc=$THEME_PPTX"
fi

echo "🎞 Converting $INPUT -> $OUTPUT"
pandoc "$INPUT" \
  --from markdown+yaml_metadata_block+smart \
  --to pptx \
  --resource-path="$(dirname "$INPUT")" \
  --slide-level=2 \
  --toc \
  --metadata-file="meta.yaml" \
  $FILTER_OPT \
  $PANDOC_THEME_ARG \
  "$@" \
  -o "$OUTPUT"

echo "✅ Done: $OUTPUT"

# Examples:
# 1) Basic:
#    md2pptx.sh test/sample.md
# 2) With custom output:
#    md2pptx.sh test/sample.md -o out/presentation.pptx
