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
