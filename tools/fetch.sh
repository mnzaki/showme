#!/bin/bash -e

while true; do
  original_file=$(ssh -p$2 $1 ./first.sh)
  echo Found to be converted file: $original_file
  esc=$(echo $original_file | sed -e 's/ /\\ /g')
  # \x27 is a single quote
  esc=$(echo $esc | sed -e "s/'/\\\'/g")
  echo $esc
  scp -P$2 "$1:./$esc" .
  transcoded_file=$(echo $(basename "$esc") | sed -e 's/\(mp4\|mkv\|avi\)/webm/')
  echo $transcoded_file
  #transcoded_file=$(echo $(basename "$esc") | sed -e 's/\(mp4\|mkv\|avi\)/webm/')

  echo First pass
  ffmpeg -loglevel error -hide_banner -stats -nostdin \
    -i "$(basename "$original_file")" \
    -c:v libvpx-vp9 -crf 33 -b:v 0 -threads 3 -speed 2 -tile-columns 6 -frame-parallel 1 \
    -an \
    -pass 1 \
    -f webm \
    -y /dev/null
  echo Second pass
  ffmpeg -loglevel error -hide_banner -stats -nostdin \
    -i "$(basename "$original_file")" \
    -c:v libvpx-vp9 -crf 33 -b:v 0 -threads 3 -speed 1 \
    -tile-columns 6 -frame-parallel 1 -auto-alt-ref 1 -lag-in-frames 25 \
    -c:a libopus -b:a 64k \
    -pass 2 \
    -f webm \
    -y "$transcoded_file"
  echo Done

  scp -P$2 "$transcoded_file" "$1:./$(dirname "$esc")/$transcoded_file"
  rm "$transcoded_file"
  rm "$(basename "$original_file")"
done