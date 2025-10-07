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
