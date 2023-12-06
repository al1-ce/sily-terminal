module sily.tui.render;

version (Have_speedy_stdio) static import stdio = speedy.stdio;
else static import stdio = std.stdio;

import std.string: format;
import std.conv: to;

import sily.color;
import sily.bashfmt;
import sily.vector;

private dstring _screenBuffer = "";

/**
Escapes color into bash sequence according to selected color mode
Params:
    c = Color
    b = Is color background
    m = ColorMode (ansi8, ansi256, truecolor)
Returns: Escaped color
*/
string escape(Color c, bool b, ColorMode m) {
    switch (m) {
        case ColorMode.truecolor: return c.toTrueColorString(b);
        case ColorMode.ansi256: return c.toAnsiString(b);
        case ColorMode.ansi8:
        default: return c.toAnsi8String(b);
    }
}

/// Ditto
string escape(Color c, bool b) {
    return escape(c, b, colorMode);
}

/// Render color mode
enum ColorMode {
    ansi8, ansi256, truecolor
}

private ColorMode _colorMode = ColorMode.truecolor;

/// Returns current color mode
ColorMode colorMode() {
    return _colorMode;
}

/// Sets color mode
void colorMode(ColorMode c) {
    _colorMode = c;
}

/// Returns screen buffer contents
dstring readBuffer() {
    return _screenBuffer;
}

/// Clears screen buffer
void clearBuffer() {
    _screenBuffer = "";
}

size_t sizeofBuffer() {
    return _screenBuffer.length;
}

/// Writes buffer into stdout and flushes stdout
void flushBuffer() {
    // stdout.write(_screenBuffer);
    // stdout.flush(); // Eliminates flickering if used instead of no buffer
    stdio.write(_screenBuffer);
    // version (Have_speedy_stdio) // unsafe_stdout_flush();
    version(Have_speedy_stdio) {} else stdio.stdout.flush(); // Eliminates flickering if used instead of no buffer
}

/// Replaces buffer contents with `content`
void writeBuffer(dstring content) {
    _screenBuffer = content;
}

/// Formatted writes `args into buffer. Slow
void writef(A...)(A args) if (args.length > 0) {
    _screenBuffer ~= format(args).to!dstring;
}

/// Writes `args into buffer
void write(A...)(A args) if (args.length > 0) {
    foreach (arg; args) {
        _screenBuffer ~= arg.to!dstring;
    }
}

/// Clears terminal screen
void screenClearOnly() {
    write("\033[2J");
}
/// Moves cursor in terminal to `{0, 0}`
void cursorMoveHome() {
    write("\033[H");
}

/**
Moves cursor to pos. Allows for chaining
Example:
---
Render.at(12, 15).write("My pretty text");
---
*/
void cursorMoveTo(uint x, uint y) {
    write("\033[", y + 1, ";", x + 1, "f");
}
/// Ditto
void cursorMoveTo(uvec2 pos) {
    cursorMoveTo(pos.x, pos.y);
}
/// Ditto
void cursorMoveTo(ivec2 pos) {
    cursorMoveTo(cast(uint) pos.x, cast(uint) pos.y);
}

// TODO:
void clearRect(uvec2 pos, uvec2 size) {
    assert(0, "clearRect not yet implemented");
}


