/// Utils to work with terminal
module sily.terminal;

public import sily.terminal.windows;
public import sily.terminal.posix;

import std.stdio: stdin, stdout, File;
import std.process: spawnProcess, wait;
import std.conv: to;
import std.file: tempDir, remove, exists, readText;
import std.array: popBack;

import core.stdc.stdlib: getenv;

import sily.path: fixPath;

ColorSupport terminalColorSupport(ColorSupport defaultColor = ColorSupport.ansi8) {
    string env = getenv("COLORTERM").to!string;

    if (env == "truecolor") {
        return ColorSupport.truecolor;
    } else
    if (env == "24bit") {
        return ColorSupport.ansi256;
    } else 
    if (env == "8bit") {
        return ColorSupport.ansi8;
    }
    
    string fp = (tempDir ~ "/sily-dlang-terminal-temp.txt").fixPath();
    
    // TODO: rewrite with execute
    File tf = File(fp, "w+");
    wait(spawnProcess(["tput", "colors"], stdin, tf));
    tf.close();
    string _out = fp.readText();
    if (fp.exists()) fp.remove();
    _out.popBack();

    if (_out == "256") return ColorSupport.ansi256;
    if (_out == "8") return ColorSupport.ansi8;

    return defaultColor;
}

enum ColorSupport {
     ansi8, ansi256, truecolor
}

import core.stdc.stdlib: cexit = exit;
import core.thread: Thread;
import core.time: dmsecs = msecs;

/// Forcefully closes application
void exit(ErrorCode code = ErrorCode.general) {
    cexit(cast(int) code);
}

/// Alias to ErrorCode enum
alias ExitCode = ErrorCode;

/// Enum containing common exit codes
enum ErrorCode {
    /// Program completed correctly
    success = 0,
    /// Catchall for general errors (misc errors, such as `x / 0`)
    general = 1,
    /// Operation not permitted (missing keyword/command or permission problem)
    noperm = 2,
    /// Command invoked cannot execute (permission problem or command is not executable)
    noexec = 126,
    /// Command not found (possible problem with `$PATH` or typo)
    notfound = 127,
    /// Invalid argument to exit (see ErrorCode.nocode)
    noexit = 128,
    /// Fatal error (further execution is not possible or might harm the OS)
    fatal = 129,
    /// Terminated with `Ctrl-C`
    sigint = 130,
    /// Exit status out of range (maximal exit code)
    nocode = 255
}

/// Sleeps for set amount of msecs
void sleep(uint msecs) {
    Thread.sleep(msecs.dmsecs);
}
