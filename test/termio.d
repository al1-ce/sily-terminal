#!/usr/bin/env dub
/+ dub.sdl:
name "termiotest"
dependency "sily" version="~>4"
dependency "sily-terminal:logger" path="../"
dependency "sily-terminal" path="../"
targetType "executable"
targetPath "../bin/"
+/
module test.termio;

import std.stdio: writef;
import std.conv: to;

import sily.terminal;
import sily.terminal.input;
import sily.logger;
import sily.bashfmt;
import sily.vector;
import sily.color;

void main() {

    writef("Preparing alternative buffer\n");
    sleep(100);
    eraseLines(2);
    writef("Preparing alternative buffer.\n");
    sleep(100);
    eraseLines(2);
    writef("Preparing alternative buffer..\n");
    sleep(100);
    eraseLines(2);
    writef("Preparing alternative buffer...\n");
    sleep(100);
    // info(getCursorPosition().toString);
    trace!(__LINE__, "termio")("Terminal mode set to raw");
    

    int key;
    setTitle("Test app cool");
    screenEnableAltBuffer();
    writef("Press key: \n");
    terminalModeSetRaw();

    mouseEnable();

    bool quit = false;
    bool isHeld = false;
    uvec2 pos;
    uvec2 ppos;
    while (!quit) {
        if (kbhit) pollEvent();
        if (!queueEmpty) {
            InputEvent e = peekEvent();
            // if (e.isKey(ikey(Key.mouse))) writef("mouse\n\r");
            if (e.isKey(ikey(Key.q, Mod.c))) { quit = true; }
            // writef("%s %s %s %s\r\n", e.key, e.ctrl, e.alt, e.shift);
            if (e.key < 256) {
                string mods = "";
                mods ~= e.hasMod(Mod.c) ? "^" : "";
                mods ~= e.hasMod(Mod.s) ? "+" : "";
                mods ~= e.hasMod(Mod.a) ? "!" : "";
                writef("%s%s\n\r", mods, e.key);
            } else {
                if (e.state == ButtonState.press && e.key != Key.mouseWheelDown && e.key != Key.mouseWheelUp) {
                    isHeld = true;
                }
                if (e.state == ButtonState.release && e.key != Key.mouseWheelDown && e.key != Key.mouseWheelUp) {
                    isHeld = false;
                }
                writef("%s %s at %s \n\r", e.key, e.state, mousePosition.toString);

            }

        }
        if (isHeld) pos = cursorGetPosition();
        if (isHeld && pos != ppos) {
            writef("%s\n\r", pos.toString);
            cursorMoveUp();
        }
        if (isHeld) ppos = pos;

    }

    mouseDisable();

    terminalModeReset();
    screenDisableAltBuffer();
    trace!(__LINE__, "termio")("Reset terminal mode");
}

