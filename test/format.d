#!/usr/bin/env dub
/+ dub.sdl:
name "testfmt"
dependency "sily" version="~>4"
dependency "sily-terminal:logger" path="../"
dependency "sily-terminal" path="../"
targetType "executable"
targetPath "../bin/"
+/

import std.stdio: writeln, write, readln;
import sily.bashfmt;

void main() {
    writeln();
    writeln("Couple of next lines will be erased");
    writeln("But you'll see this line");
    writeln("You should not see this line");
    eraseLines(2);
    writeln("And this one");
    writeln("And these two lines");
    writeln("Too");
    eraseLines(3);
    writeln("And this one too");
    fwriteln(FG.dkgray, BG.black, "Text");
    fwriteln(FM.blink, "Blinking", FR.fullreset);
    fwriteln(FM.bold, "Bold", FR.fullreset);
    fwriteln(FM.cline, "Curly line", FR.fullreset);
    fwriteln(FM.dim, "Dim", FR.fullreset);
    fwriteln(FM.dline, "Double lined", FR.fullreset);
    fwriteln(FM.inverse, "Inversed", FR.fullreset);
    fwriteln(FM.italics, "Italics", FR.fullreset);
    fwriteln(FM.striked, "Striked", FR.fullreset);
    fwriteln(FM.uline, "Underlined", FR.fullreset);
    fwriteln(FG.red, "Red", FM.blink, "Blink", BG.cyan, "ALl", FR.fullreset);
    cursorSavePosition();
    cursorMoveUp(3);
    cursorMoveDown();
    cursorMoveRight(22);
    cursorMoveLeft(2);
    fwrite(BG.ltblue, FG.black, ">this one is written out of sequence<", FR.fullreset);
    cursorRestorePosition();
    writeln();
}
