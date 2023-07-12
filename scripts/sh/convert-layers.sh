OUT_DIR=${SPWASHI_OUTPUT_DIRNAME:-composited}
magick mogrify -format webP -path ./out/${OUT_DIR}/webp -quality 80 -define webp:lossless=true out/${OUT_DIR}/frames/*
