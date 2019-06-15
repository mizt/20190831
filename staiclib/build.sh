#! /bin/bash
dir=$(cd $(dirname $0)&&pwd)
cd $dir

date +%s
clang++ -fobjc-arc -O3 -std=c++17 -Wc++17-extensions ./main.mm ./Banana/Banana.a -o main 
date +%s