/// Formatting and util to work with BASH
module sily.bashfmt;

import std.conv : to;
version (Have_speedy_stdio) import speedy.stdio: write, writef;
else import std.stdio : write, writef;

// static this() {
//     version(windows) {
//         import core.stdc.stdlib: exit;
//         exit(2);
//     }
// }

// LINK: https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797

/// Contains escape sequences for foreground colors
static struct FG {
    @disable this();
    public static const:
    string RESET      = "\033[39m";
    string BLACK      = "\033[30m";
    string RED        = "\033[31m";
    string GREEN      = "\033[32m";
    string YELLOW     = "\033[33m";
    string BLUE       = "\033[34m";
    string MAGENTA    = "\033[35m";
    string CYAN       = "\033[36m";
    string LT_GRAY    = "\033[37m";
    string DK_GRAY    = "\033[90m";
    string LT_RED     = "\033[91m";
    string LT_GREEN   = "\033[92m";
    string LT_YELLOW  = "\033[93m";
    string LT_BLUE    = "\033[94m";
    string LT_MAGENTA = "\033[95m";
    string LT_CYAN    = "\033[96m";
    string WHITE      = "\033[97m";
}

/// Contains escape sequences for background colors
static struct BG {
    @disable this();
    public static const:
    string RESET      = "\033[49m";
    string BLACK      = "\033[40m";
    string RED        = "\033[41m";
    string GREEN      = "\033[42m";
    string YELLOW     = "\033[43m";
    string BLUE       = "\033[44m";
    string MAGENTA    = "\033[45m";
    string CYAN       = "\033[46m";
    string LT_GRAY    = "\033[47m";
    string DK_GRAY    = "\033[100m";
    string LT_RED     = "\033[101m";
    string LT_GREEN   = "\033[102m";
    string LT_YELLOW  = "\033[103m";
    string LT_BLUE    = "\033[104m";
    string LT_MAGENTA = "\033[105m";
    string LT_CYAN    = "\033[106m";
    string WHITE      = "\033[107m";
}

/// Contains escape sequences for string formatting (bold, italics)
static struct FORMAT {
    @disable this();
    public static const:
    string BOLD             = "\033[1m";
    string DIM              = "\033[2m";
    string ITALICS          = "\033[3m";
    string UNDERLINE        = "\033[4m";
    string BLINK            = "\033[5m";
    string INVERSE          = "\033[7m";
    string HIDDEN           = "\033[8m";
    string STRIKED          = "\033[9m";
    string DOUBLE_UNDERLINE = "\033[21m";
}

/// Contains escape sequences to reset string formatting
static struct FRESET {
    @disable this();
    public static const:
    string ALL              = "\033[0m";
    string FULL             = "\033[m";
    string FOREGROUND       = "\033[39m";
    string BACKGROUND       = "\033[49m";

    string BOLD             = "\033[21m";
    string DIM              = "\033[22m";
    string ITALICS          = "\033[22m";
    string UNDERLINE        = "\033[24m";
    string BLINK            = "\033[25m";
    string INVERSE          = "\033[27m";
    string HIDDEN           = "\033[28m";
    string STRIKED          = "\033[29m";
    string DOUBLE_UNDERLINE = "\033[24m";
}

/* ------------------------------- LINE ERASE ------------------------------- */

/**
Erases `num` lines in terminal starting with current.
Params:
  num = Number of lines to erase
*/
void eraseLines(int num) {
    if (num < 1) return;
    eraseCurrentLine();
    --num;

    while (num) {
        cursorMoveUpScroll();
        eraseCurrentLine();
        --num;
    }
}

/// Fully erases current line
void eraseCurrentLine() {
    write("\033[2K");
}

/// Erases text from start of current line to cursor
void eraseLineLeft() {
    write("\033[1K");
}

/// Erases text from cursor to end of current line
void eraseLineRight() {
    write("\033[K");
}

/* --------------------------------- CURSOR --------------------------------- */

import sily.vector: uvec2;

version(Posix) {
    import sily.terminal: terminalModeSetRaw, terminalModeReset, getch, isTerminalRaw;

    /// Returns cursor position
    uvec2 cursorGetPosition() {
        uvec2 v;
        char[] buf = new char[](30);
        int i, pow;
        char ch;
        bool wasTerminalRaw = isTerminalRaw();
        // FIXME: make checks for if terminal is raw already
        if (!wasTerminalRaw) terminalModeSetRaw();
        writef("\033[6n");

        for (i = 0, ch = 0; ch != 'R'; i++) {
            int r = getch(); ch = cast(char) r;
            // in case of getting stuck
            if (r == 17) {
                if (!wasTerminalRaw) terminalModeReset();
                return v;
            }
            if (!r) {
                // error("Error reading response"); moveCursorTo(0);
                if (!wasTerminalRaw) terminalModeReset();
                return v;
            }
            buf[i] = ch;
            // if (i != 0) {
            //     import std.format: format;
            //     trace("buf[%d]: %c %d".format(i, ch, ch)); moveCursorTo(0);
            // }
        }
        if (i < 2) {
            if (!wasTerminalRaw) terminalModeReset();
            // error("Incorrect response size"); moveCursorTo(0);
            return v;
        }

        for (i -= 2, pow = 1; buf[i] != ';'; --i, pow *= 10) {
            v.x = v.x + (buf[i] - '0') * pow;
        }
        for (--i, pow = 1; buf[i] != '['; --i, pow *= 10) {
            v.y = v.y + (buf[i] - '0') * pow;
        }

        if (!wasTerminalRaw) terminalModeReset();
        return v;
    }
}

version(Windows) {
    import core.sys.windows.windows;

    uvec2 cursorGetPosition() {
        HANDLE hConsoleOutput = GetStdHandle(STD_OUTPUT_HANDLE);
        CONSOLE_SCREEN_BUFFER_INFO cbsi;
        if (GetConsoleScreenBufferInfo(hConsoleOutput, &cbsi)) {
            COORD c =  cbsi.dwCursorPosition;
            return uvec2(c.X, c.Y);
        } else {
            // The function failed. Call GetLastError() for details.
            return uvec2(0);
        }
    }
}

/**
Moves cursor in terminal to `{x, y}` or to `x`. **COORDINATES START FROM 1**
Params:
  x = Column to move to
  y = Row to move to
*/
void cursorMoveTo(int x, int y) {
    writef("\033[%d;%df", y, x);
}
/// Ditto
void cursorMoveTo(uvec2 pos) {
    writef("\033[%d;%df", pos.y, pos.x);
}
/// Ditto
void cursorMoveTo(int x) {
    writef("\033[%dG", x);
}

/// Moves cursor in terminal to `{1, 1}`
void cursorMoveHome() {
    writef("\033[H");
}

// TODO: add cursorMoveRel()

/**
Moves cursor in terminal up by `lineAmount`
Params:
  lineAmount = int
*/
void cursorMoveUp(int lineAmount = 1) {
    writef("\033[%dA", lineAmount);
}

/// Moves cursor in terminal up by 1 and scrolls if needed
void cursorMoveUpScroll() {
    writef("\033M");
}

/**
Moves cursor in terminal up by`lineAmount` and sets cursor X to 1
Params:
  lineAmount = int
*/
void cursorMoveUpStart(int lineAmount = 1) {
    writef("\033[%dF", lineAmount);
}

/**
Moves cursor in terminal down by `lineAmount`
Params:
  lineAmount = int
 */
void cursorMoveDown(int lineAmount = 1) {
    writef("\033[%dB", lineAmount);
}

/**
Moves cursor in terminal down by`lineAmount` and sets cursor X to 1
Params:
  lineAmount = int
*/
void cursorMoveDownStart(int lineAmount = 1) {
    writef("\033[%dE", lineAmount);
}

/**
Moves cursor in terminal right by `columnAmount`
Params:
  columnAmount = int
*/
void cursorMoveRight(int columnAmount = 1) {
    writef("\033[%dC", columnAmount);
}

/**
Moves cursor in terminal left by `columnAmount`
Params:
  columnAmount = int
*/
void cursorMoveLeft(int columnAmount = 1) {
    writef("\033[%dD", columnAmount);
}

/// Saves/Restores cursor position to be restored later (DEC)
void cursorSavePosition() {
    write("\0337");
}

/// Ditto
void cursorRestorePosition() {
    write("\0338");
}

/// Saves/Restores cursor position to be restored later (SCO). **PREFER DEC (`saveCursorPosition`) VERSION INSTEAD.**
void cursorSavePositionSCO() {
    write("\033[s");
}

/// Ditto
void cursorRestorePositionSCO() {
    write("\033[u");
}

/// Hides cursor. Does not reset position
void cursorHide() {
    write("\033[?25l");
}

/// Shows cursor. Does not reset position
void cursorShow() {
    write("\033[?25h");
}

/* --------------------------------- SCREEN --------------------------------- */

/// Clears terminal screen and resets cursor position
void screenClear() {
    write("\033[2J");
    cursorMoveHome();
}

/// Clears terminal screen
void screenClearOnly() {
    write("\033[2J");
}

/// Enabled/Disables Alt Buffer. **PREFER `screenEnableAltBuffer` OR `screenDisableAltBuffer` INSTEAD.**
void screenSave() {
    write("\033[?47h");
}
/// Ditto
void screenRestore() {
    write("\033[?47l");
}

/// Enabled/Disables alternative screen buffer.
void screenEnableAltBuffer() {
    write("\033[?1049h");
}
/// Ditto
void screenDisableAltBuffer() {
    write("\033[?1049l");
}

/// Hard resets terminal. Not recommended to use
void screenHardReset() {
    write("\033c");
}

/// Sets terminal title that's going to last until program termination
void setTitle(string title) {
    write("\033]0;" ~ title ~ "\007");
}

/// Rings audio bell
void bell() {
    write("\a");
}

/**
Intended to be used in SIGINT callback
Resets all formatting and shows cursor
*/
void cleanTerminalState() nothrow @nogc @system {
    import core.stdc.stdio: printf;
    printf("\033[?1049l\033[?25h\033[m\033[?1000;1006;1015l");
}
