/// Module that implements Terminal UI rendering
module sily.tui.render;

import sily.color;
static import sily.conv;

version (Have_speedy_stdio) import speedy.stdio: write, unsafe_stdout_flush;
else import std.stdio: write, stdout;

import std.string: format;
import std.conv: to;

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
    return escape(c, b, Render.colorMode);
}

/// Render color mode
enum ColorMode {
    ansi8, ansi256, truecolor
}

/// Renderer
public static class Render {
    private static ColorMode _colorMode = ColorMode.truecolor;

    private static dstring _screenBuffer = "";

    /// Returns current color mode
    public static ColorMode colorMode() {
        return _colorMode;
    }

    /// Sets color mode
    public static void colorMode(ColorMode c) {
        _colorMode = c;
    }

    /// Returns screen buffer contents
    public static dstring readBuffer() {
        return _screenBuffer;
    }

    /// Clears screen buffer
    public static void clearBuffer() {
        _screenBuffer = "";
    }

    /// Writes buffer into stdout and flushes stdout
    public static void flushBuffer() {
        // stdout.write(_screenBuffer);
        // stdout.flush(); // Eliminates flickering if used instead of no buffer
        .write(_screenBuffer);
        // version (Have_speedy_stdio) // unsafe_stdout_flush();
        version(Have_speedy_stdio) {} else stdout.flush(); // Eliminates flickering if used instead of no buffer
    }

    /// Replaces buffer contents with `content`
    public static void writeBuffer(dstring content) {
        _screenBuffer = content;
    }

    /// Formatted writes `args into buffer. Slow
    public static void writef(A...)(A args) if (args.length > 0) {
        _screenBuffer ~= .format(args).to!dstring;
    }

    /// Writes `args into buffer
    public static void write(A...)(A args) if (args.length > 0) {
        foreach (arg; args) {
            _screenBuffer ~= arg.to!dstring;
        }
    }

    /// Clears terminal screen
    public static void screenClearOnly() {
        write("\033[2J");
    }
    /// Moves cursor in terminal to `{0, 0}`
    public static void cursorMoveHome() {
        write("\033[H");
    }

    /**
    Moves cursor to pos. Allows for chaining
    Example:
    ---
    Render.at(12, 15).write("My pretty text");
    ---
    */
    public static Render at(uint x, uint y) {
        write("\033[", y + 1, ";", x + 1, "f");
        return null; // ... what
    }
}
