#!/usr/bin/env dub
/+ dub.sdl:
name "pixelfont"
dependency "sily" path="/g/sily-dlang/"
dependency "sily-terminal:logger" path="/g/sily-terminal/"
+/
import std.stdio: writeln;

import std.array: join;
import std.array: popFront;

import sily.logger.pixelfont: get3x4;

void main(string[] args) {
    args.popFront();
    writeln(get3x4(args.join()));
}

