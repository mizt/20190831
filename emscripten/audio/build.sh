#!/bin/bash
dir=$(cd $(dirname $0)&&pwd)
cd $dir
~/Development/emsdk-portable/emscripten/1.38.29/em++ \
	-O3 \
	-std=c++11 \
	-Wc++11-extensions \
	--memory-init-file 0 \
	-s VERBOSE=1 \
	-s WASM=0 \
	-s EXPORTED_FUNCTIONS="['_setup','_next']" \
	-s EXTRA_EXPORTED_RUNTIME_METHODS="['cwrap']" \
	-s TOTAL_MEMORY=16777216 \
	./libs.cpp \
	-o ./libs.js