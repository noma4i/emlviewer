#!/bin/bash
set -euo pipefail

mkdir -p AppStore/previews/en-US
/usr/bin/swift Scripts/appstore/preview.swift | ffmpeg -y -hide_banner -loglevel error \
    -f rawvideo -pixel_format bgra -video_size 1920x1080 -framerate 30 -i pipe:0 \
    -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=48000 \
    -t 17.5 -c:v libx264 -profile:v high -pix_fmt yuv420p \
    -c:a aac -b:a 256k -ar 48000 -ac 2 -movflags +faststart \
    AppStore/previews/en-US/preview.mp4
