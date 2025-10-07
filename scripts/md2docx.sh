#!/bin/bash
# ===============================================================
# md2docx.sh
# Markdown -> DOCX 转换脚本（自动检测 Mermaid；GitHub CSS）
# Usage:
#   md2docx.sh input.md
#   md2docx.sh input.md -o output.docx
# ===============================================================
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <input.md> [-o output.docx] [extra pandoc args]"
  exit 1
fi

INPUT="$1"; shift || true
OUTPUT="${INPUT%.md}.docx"

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
  echo "🪄 Mermaid blocks found -> enabling pandoc-mermaid-filter (mermaid will be embedded as images)"
  FILTER_OPT="--filter pandoc-mermaid-filter"
fi

TPL_DIR="/opt/pandoc/templates"
CSS_FILE="$TPL_DIR/github.css"
HIGHLIGHT="$TPL_DIR/pygments.theme"

echo "📘 Converting $INPUT -> $OUTPUT"
pandoc "$INPUT" \
  --from markdown+yaml_metadata_block+smart \
  --to docx \
  --resource-path="$(dirname "$INPUT")" \
  --css="$CSS_FILE" \
  --highlight-style="$HIGHLIGHT" \
  --toc \
  --metadata-file="meta.yaml" \
  $FILTER_OPT \
  "$@" \
  -o "$OUTPUT"

echo "✅ Done: $OUTPUT"

# Examples:
# 1) Basic:
#    md2docx.sh test/sample.md
# 2) Custom output:
#    md2docx.sh test/sample.md -o out/report.docx
