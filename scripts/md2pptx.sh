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
