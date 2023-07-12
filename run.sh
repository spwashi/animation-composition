#!/bin/bash
#
export SPWASHI_OUTPUT_DIRNAME="composited-3_test"
export SPWASHI_PSD_LAYER_DIRNAME="psd-extracted/4"
export SPWASHI_COMPOSITE_DEPTH=3
export SPWASHI_INPUT_PSD_NAME="input.rgb.psd"

./scripts/sh/make-dirs.sh || { echo 'Error: Could not make necessary directories' ; exit 1; }
python3 ./scripts/python/build_input.py || { echo 'Error: Could not build input from PSD' ; exit 1; }
python3 ./scripts/python/generate-layers.py || { echo 'Error: Could not generate layers from input' ; exit 1; }
./scripts/sh/generate-movies.sh || { echo 'Error: Could not generate movies' ; exit 1; }
