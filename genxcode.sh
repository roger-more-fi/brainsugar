#!/bin/bash

#!
#!  genxcode.sh
#!  created by Harri Hilding Smatt on 2026-01-14
#!

mkdir -p xcode
cd xcode
cmake -G Xcode ..
