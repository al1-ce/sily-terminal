/// Terminal logging utilities
module sily.logger;

import std.datetime: DateTime, Clock;
import std.array: replace, split;
import std.string: capitalize;
import std.conv: to;
import std.format: format;
import std.traits: Unqual;
import std.stdio: writefln, writef;
import std.math: round;

import sily.terminal: terminalWidth;
import sily.string: splitStringWidth;
static import sily.conv;

private ubyte __loggingLevel = LogLevel.all;
private bool __logFormatEnabled = true;

// TODO: LogConfig?
// LogConfig logConfig;
// private struct LogConfig {
    // ubyte logLevel = LogLevel.all;
    // bool formattingEnabled = true;
    // File logFile = stdout;
// }

/** 
Sets global log level
Params:
  l = LogLevel
Example:
---
globalLogLevel(LogLevel.error);
globalLogLevel = LogLevel.all;
globalLogLevel = LogLevel.
---
*/
void globalLogLevel(ubyte l) {
    __loggingLevel = l;
}

/// Returns current global log level
ubyte globalLogLevel() {
    return __loggingLevel;
}

/** 
Enables/Disables formatting (colors, bold, dim...) in log messages
Params:
  state = bool
*/
void globalLogFormattingEnabled(bool state) {
    __logFormatEnabled = state;
}

/// Returns: is log formatting enabled
bool globalLogFormattingEnabled() {
    return __logFormatEnabled;
}

/** 
This function logs `args` to stdout
In order for the resulting log message to appear
LogLevel must be greater or equal then globalLogLevel
When using `log!LogLevel.off` or `message` it'll be
displayed no matter the level of globalLogLevel
Params:
  args = Data that should be logged
Example:
---
trace(true, " is true bool");
info(true, " is true bool");
warning(true, " is true bool");
error(true, " is true bool");
critical(true, " is true bool");
fatal(true, " is true bool");
log(true, " is true bool");
log!(LogLevel.error)(true, " is true bool");
log!(LogLevel.warning)(true, " is true bool");
---
*/
void message(int line = __LINE__, string file = __FILE__, S...)(S args) { log!(LogLevel.off, line, file)(args); }
/// Ditto
void trace(int line = __LINE__, string file = __FILE__, S...)(S args) { log!(LogLevel.trace, line, file)(args); }
/// Ditto
void info(int line = __LINE__, string file = __FILE__, S...)(S args) { log!(LogLevel.info, line, file)(args); }
/// Ditto
void warning(int line = __LINE__, string file = __FILE__, S...)(S args) { log!(LogLevel.warning, line, file)(args); }
/// Ditto
void error(int line = __LINE__, string file = __FILE__, S...)(S args) { log!(LogLevel.error, line, file)(args); }
/// Ditto
void critical(int line = __LINE__, string file = __FILE__, S...)(S args) { log!(LogLevel.critical, line, file)(args); }
/// Ditto
void fatal(int line = __LINE__, string file = __FILE__, S...)(S args) { log!(LogLevel.fatal, line, file)(args); }
/// Ditto
void log(LogLevel ll = LogLevel.trace, int line = __LINE__, string file = __FILE__, S...)(S args) {
    if (!__loggingLevel.hasFlag(ll.highestOneBit)) return;
    string lstring = "";
    if (__logFormatEnabled) {
        if (ll.hasFlag(LogLevel.traceOnly)) {
            lstring = "\033[90m%*-s\033[m".format(8, "Trace"); 
        } else
        if (ll.hasFlag(LogLevel.infoOnly)) { // set to 92 for green
            lstring = "\033[94m%*-s\033[m".format(8, "Info"); 
        } else
        if (ll.hasFlag(LogLevel.warningOnly)) {
            lstring = "\033[33m%*-s\033[m".format(8, "Warning"); 
        } else
        if (ll.hasFlag(LogLevel.errorOnly)) {
            lstring = "\033[1;91m%*-s\033[m".format(8, "Error"); 
        } else
        if (ll.hasFlag(LogLevel.criticalOnly)) {
            lstring = "\033[1;101;30m%*-s\033[m".format(8, "Critical"); 
        } else
        if (ll.hasFlag(LogLevel.fatalOnly)) {
            lstring = "\033[1;101;97m%*-s\033[m".format(8, "Fatal"); 
        } else {
            lstring = "%*-s".format(8, "Message"); 
        }
    } else {
        if (ll.hasFlag(LogLevel.traceOnly)) {
            lstring = "%*-s".format(8, "Trace"); 
        } else
        if (ll.hasFlag(LogLevel.infoOnly)) { // set to 92 for green
            lstring = "%*-s".format(8, "Info"); 
        } else
        if (ll.hasFlag(LogLevel.warningOnly)) {
            lstring = "%*-s".format(8, "Warning"); 
        } else
        if (ll.hasFlag(LogLevel.errorOnly)) {
            lstring = "%*-s".format(8, "Error"); 
        } else
        if (ll.hasFlag(LogLevel.criticalOnly)) {
            lstring = "%*-s".format(8, "Critical"); 
        } else
        if (ll.hasFlag(LogLevel.fatalOnly)) {
            lstring = "%*-s".format(8, "Fatal"); 
        } else {
            lstring = "%*-s".format(8, "Message"); 
        }
    }

    dstring messages = sily.conv.format!dstring(args);
    
    int msgMaxWidth = terminalWidth - ("[00:00:00] Critical  %s:%d".format(file, line).length).to!int;
    
    dstring[] msg = splitStringWidth(messages, msgMaxWidth);

    if (__logFormatEnabled) {
        writefln("\033[90m[%s]\033[m %s %*-s \033[m\033[90m%s:%d\033[m",
            to!DateTime(Clock.currTime).timeOfDay, 
            lstring, 
            msgMaxWidth, msg[0],
            file, line);
    } else {
        writefln("[%s] %s %*-s %s:%d",
            to!DateTime(Clock.currTime).timeOfDay, 
            lstring, 
            msgMaxWidth, msg[0],
            file, line);
    }
    for (int i = 1; i < msg.length; ++i) {
        if (__logFormatEnabled) {
            writefln("%*s%s\033[m", 20, " ", msg[i]); 
        } else {
            writefln("%*s%s", 20, " ", msg[i]); 
        }
    }
}

private uint highestOneBit(uint i) {
    i |= (i >>  1);
    i |= (i >>  2);
    i |= (i >>  4);
    i |= (i >>  8);
    i |= (i >> 16);
    return i - (i >>> 1);
}

private bool hasFlag(uint flags, uint flag) {
    return (flags & flag) == flag;
}

private bool hasFlags(uint flags, uint flag) {
    return (flags & flag) != 0;
}

/// LogLevel to use with `setGlobalLogLevel` and `log!LogLevel`
enum LogLevel: ubyte {
    off          = 0,

    fatal        = 0b000001,
    critical     = 0b000011,
    error        = 0b000111,
    warning      = 0b001111,
    info         = 0b011111,
    trace        = 0b111111,

    fatalOnly    = 0b000001,
    criticalOnly = 0b000010,
    errorOnly    = 0b000100,
    warningOnly  = 0b001000,
    infoOnly     = 0b010000,
    traceOnly    = 0b100000,

    all = ubyte.max,
}

/** 
Prints horizontal ruler
Params:
  pattern = Symbol to fill line with
  message = Message in middle of line
  lineFormat = Formatting string for line (!USE ONLY FOR FORMATTING)
  msgFormat = Formatting string for message (!USE ONLY FOR FORMATTING)
Example:
---
hr();
// ───────────────────────────────────────────
hr('~');
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
hr('-', "log trace");
// --------------- log trace -----------------
hr('=', "log", "\033[33m");
// prints = in yellow
// ================== log ====================
hr('#', "ERROR", "\033[91m", "\033[101m");
// prints # in red end ERROR in red background
// ################# ERROR ###################
---
*/
void hr(dchar pattern = '─', dstring message = "", string lineFormat = "", string msgFormat = "") {
    int tw = terminalWidth();
    if (message != "") {
        ulong llen = (tw - message.length - 2) / 2;
        ulong mmod = message.length % 2 + tw % 2;
        ulong rlen = llen + (mmod == 2 || mmod == 0 ? 0 : 1);
        if (__logFormatEnabled) {
            writef("%s%s%s %s%s%s %s%s%s", 
                lineFormat, pattern.repeat(llen), "\033[m", 
                msgFormat, message, "\033[m",
                lineFormat, pattern.repeat(rlen), "\033[m");
        } else {
            writef("%s %s %s", pattern.repeat(llen), message,pattern.repeat(rlen));
        }
    } else {
        if (__logFormatEnabled) {
            writef("%s%s%s", lineFormat, pattern.repeat(tw), "\033[m");
        } else {
            writef("%s", pattern.repeat(tw));
        }
    }
    writef("\n");
}

/** 
Params:
  title = Title of block
  message = Message to print in block
  width = Width of block. Set to -1 for auto
  _align = Block align. -1 - left, 0 - center, 1 - right 
*/
void block(dstring title, dstring message, int width = -1, int _align = -1) {
    ulong maxLen = title.length;

    if (width == -1) {
        dstring[] lines = message.split('\n');
        foreach (line; lines) {
            if (line.length + 2 > maxLen) maxLen = line.length + 2;
        }
    } else {
        maxLen = width;
    }

    int tw = terminalWidth;
    maxLen = maxLen > tw ? tw - 1 : maxLen;

    dstring[] titles = title.splitStringWidth(maxLen);
    dstring[] lines = message.splitStringWidth(maxLen);

    ulong _alignSize = 0;
    if (_align == 0) {
        _alignSize = (tw - maxLen - 1) / 2;
    } else
    if (_align == 1) {
        _alignSize = tw - maxLen - 1;
    }

    if (__logFormatEnabled) {
        foreach (line; titles) writef("%*s\033[1;7m %*-s\033[m\n", _alignSize, "", maxLen, line);
        foreach (line; lines) writef("%*s\033[3;7;2m %*-s\033[m\n", _alignSize, "", maxLen, line);
    } else {
        foreach (line; titles) writef("%*s %*-s\n", _alignSize, "", maxLen, line);
        foreach (line; lines) writef("%*s %*-s\n", _alignSize, "", maxLen, line);
    }
}

/** 
Prints message centered in terminal
Params:
  message = Message to print
*/
void center(dstring message) {
    int tw = terminalWidth;
    dstring[] lines = message.split('\n');
    foreach (line; lines) if (line.length > 0) { 
        if (line.length <= tw) {
            writef("%*s%s\n", (tw - line.length) / 2, "", line);
        } else {
            dstring[] sublines = line.splitStringWidth(tw);
            foreach (subline; sublines) if (subline.length > 0) {
                writef("%*s%s\n", (tw - subline.length) / 2, "", subline);
            }
        }
    }
}

/** 
Prints compiler info in format:
Params:
  _center = Should info be printed in center (default true)
*/
void printCompilerInfo(bool _center = true) {
    dstring ver = __VERSION__.to!dstring;
    ver = (ver.length > 1 ? ver[0] ~ "."d ~ ver[1..$] : ver);
    dstring compilerInfo = "[" ~ __VENDOR__ ~ ": v" ~ ver ~ "] Compiled at: " ~ __DATE__ ~ ", " ~ __TIME__;
    if (_center) {
        center(compilerInfo);
    } else {
        writefln(compilerInfo);
    }
}

/** 
Params:
  b = ProgressBar struct
  width = Custom width. Set to `-1` for auto
*/
void progress(ProgressBar b, int width = -1) {
    int labelLen = b.label.length.to!int;

    if (labelLen > 0) {
        if (__logFormatEnabled) {
            writef("%s%s\033[m ", b.labelFormat, b.label);
        } else {
            writef("%s ", b.label);
        }
        labelLen += 1;
    }

    if (width < 0) {
        width = terminalWidth() - labelLen - " 100%".length.to!int;
    }

    width -= (b.before != '\0' ? 1 : 0) + (b.after != '\0' ? 1 : 0);

    float percentComplete = b.percent / 100.0f;

    int completeLen = cast(int) (width * percentComplete);
    int incompleteLen = width - completeLen - 1;

    string _col = b.colors[
        cast(int) round(percentComplete * (b.colors.length.to!int - 1))
    ];

    dstring completeBar = (b.complete == '\0' ? ' ' : b.complete).repeat(completeLen);
    dstring incompleteBar = (b.incomplete == '\0' ? ' ' : b.incomplete).repeat(incompleteLen);
    dchar breakChar = (b.break_ == '\0' ? ' ' : b.break_);

    if (__logFormatEnabled) {
        writef("%s%s%s\033[m", b.before, _col, completeBar);
        if (completeLen != width) {
            writef("%s%s", _col, breakChar);
        }
        if (incompleteLen > 0) {
            writef("\033[m\033[90m%s", incompleteBar);
        }
        writef("%s\033[m \033[90m%3d%%\033[m\n", b.after, b.percent);
    } else {
        writef("%s%s", b.before, completeBar);
        if (completeLen != width) {
            writef("%s", breakChar);
        }
        if (incompleteLen > 0) {
            writef("%s", incompleteBar);
        }
        writef("%s %3d%%\n", b.after, b.percent);
    }
}

/// Structure containing progress bar info
struct ProgressBar {
    int percent = 0;
    dstring label = "";
    string labelFormat = "";
    dchar incomplete = '\u2501';
    dchar break_ = '\u2578';
    dchar complete = '\u2501';
    dchar before = '\0';
    dchar after = '\0';
    string[] colors = ["\033[31m", "\033[91m", "\033[33m", "\033[93m", "\033[32m", "\033[92m"];
    
    /**
    Creates default progress bar with label
    Params:
        _label = Bar label
        _labelFormat = Bar label formatting
    */
    this(dstring _label, string _labelFormat = "") {
        label = _label;
        labelFormat = _labelFormat;
    }

    /// Increases completion percent to `amount`
    void advance(int amount) {
        percent += amount;
        if (percent > 100) percent = 100;
    }

    // Sets completion percent to 0
    void reset() {
        percent = 0;
    }

    /// Decreases completion percent to `amount`
    void reduce(int amount) {
        percent -= amount;
        if (percent < 0) percent = 0;
    }
}

private dstring repeat(dchar val, long amount){
    if (amount < 1) return "";
    dstring s = "";
    while (s.length < amount) s ~= val;
    // writef(" %d, %d ", s[amount - 1], s[amount - 2]);
    return s[0..amount];
}

/// NOT READY YET
struct RichText {
    private dstring _text;
    private dstring _textRaw;
    private dstring _textOnly;

    @disable this();

    this(dstring text_) {
        set(text_);
    }

    ulong length() {
        return _textOnly.length;
    }

    ulong lengthFormatted() {
        return _text.length;
    }

    ulong lengthRaw() {
        return _textRaw.length;
    }

    private void preprocess() {
        // TODO
    }

    void set(dstring text_) {
        _textRaw = text_;
        // TODO
    }

    dstring text() {
        return _text;
    }


}