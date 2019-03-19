#! /bin/bash
dir=$(cd $(dirname $0)&&pwd)
cd $dir
fn=`echo ${dir} | awk -F "/" '{ print $NF }'`
clang++ ./${fn}.mm -dynamiclib -std=c++14 -Wc++14-extensions -arch x86_64 -fobjc-arc -framework Cocoa -O3 -o ./${fn}.dylib
