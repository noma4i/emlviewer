#!/bin/bash
set -euo pipefail

frames=$(mktemp -d)
trap 'rm -rf "$frames"' EXIT
/usr/bin/swift Scripts/appstore/preview.swift "$frames"
mkdir -p AppStore/previews/en-US
ffmpeg -y -hide_banner -loglevel error \
    -loop 1 -i "$frames/0.png" -loop 1 -i "$frames/1.png" \
    -loop 1 -i "$frames/2.png" -loop 1 -i "$frames/3.png" \
    -loop 1 -i "$frames/4.png" -loop 1 -i "$frames/5.png" \
    -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=48000 \
    -filter_complex '
        [0:v]zoompan=z=1+0.04*on/134:x=iw/2-iw/zoom/2:y=ih/2-ih/zoom/2:d=135:s=1920x1080:fps=30,setsar=1[v0];
        [1:v]zoompan=z=1+0.04*on/134:x=iw/2-iw/zoom/2:y=ih/2-ih/zoom/2:d=135:s=1920x1080:fps=30,setsar=1[v1];
        [2:v]zoompan=z=1+0.04*on/134:x=iw/2-iw/zoom/2:y=ih/2-ih/zoom/2:d=135:s=1920x1080:fps=30,setsar=1[v2];
        [3:v]zoompan=z=1+0.04*on/134:x=iw/2-iw/zoom/2:y=ih/2-ih/zoom/2:d=135:s=1920x1080:fps=30,setsar=1[v3];
        [4:v]zoompan=z=1+0.04*on/134:x=iw/2-iw/zoom/2:y=ih/2-ih/zoom/2:d=135:s=1920x1080:fps=30,setsar=1[v4];
        [5:v]zoompan=z=1+0.04*on/134:x=iw/2-iw/zoom/2:y=ih/2-ih/zoom/2:d=135:s=1920x1080:fps=30,setsar=1[v5];
        [v0][v1]xfade=transition=fade:duration=0.5:offset=4[a];
        [a][v2]xfade=transition=fade:duration=0.5:offset=8[b];
        [b][v3]xfade=transition=fade:duration=0.5:offset=12[c];
        [c][v4]xfade=transition=fade:duration=0.5:offset=16[d];
        [d][v5]xfade=transition=fade:duration=0.5:offset=20,format=yuv420p[video]' \
    -map '[video]' -map 6:a -t 24.5 -r 30 -c:v libx264 -profile:v high \
    -pix_fmt yuv420p -c:a aac -b:a 256k -ar 48000 -ac 2 -movflags +faststart \
    AppStore/previews/en-US/preview.mp4
