#!/bin/bash
set -euo pipefail

mkdir -p AppStore/previews/en-US
/usr/bin/swift Scripts/appstore/preview.swift | ffmpeg -y -hide_banner -loglevel error \
    -f rawvideo -pixel_format bgra -video_size 1920x1080 -framerate 30 -i pipe:0 \
    -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=48000 \
    -t 17.5 -c:v libx264 -profile:v high -pix_fmt yuv420p \
    -c:a aac -b:a 256k -ar 48000 -ac 2 -movflags +faststart \
    AppStore/previews/en-US/preview.mp4
ffmpeg -y -hide_banner -loglevel error -i AppStore/previews/en-US/preview.mp4 \
    -filter_complex "fps=12,scale=960:-1:flags=lanczos,split[frames][palette];[palette]palettegen=stats_mode=diff[colors];[frames][colors]paletteuse=dither=bayer:bayer_scale=5" \
    -loop 0 AppStore/previews/en-US/preview.gif
