#!/usr/bin/env dub
/+ dub.sdl:
name "pixelfont"
dependency "sily" version="~>4"
dependency "sily-terminal:logger" path="../"
dependency "sily-terminal" path="../"
targetType "executable"
targetPath "../bin/"
+/
import std.stdio: writeln;

import std.array: join;
import std.array: popFront;

import sily.logger.pixelfont: get3x4;

void main(string[] args) {
    args.popFront();
    writeln(get3x4(args.join()));
}

