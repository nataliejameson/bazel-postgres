#!/bin/bash

while [ $# -ge 3 ]; do
    i="$1"; shift
    j="$1"; shift
    k="$1"; shift
    
    echo "i $i"
    echo "j $j"
    echo "k $k"
done
