#!/bin/bash

rm ./zig-out/bin/Pong
zig build
./zig-out/bin/Pong
