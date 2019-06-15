#! /bin/bash
dir=$(cd $(dirname $0)&&pwd)
cd $dir

date +%s
clang++ -fobjc-arc -O3 -std=c++17 -Wc++17-extensions -c -o Banana.o ./Banana.mm
ar rcs ./Banana.a Banana.o
date +%s