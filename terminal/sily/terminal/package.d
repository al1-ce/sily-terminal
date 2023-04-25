/// Utils to work with POSIX terminal
module sily.terminal;

version (Posix) {
    static this() {
        // version(windows) {
        //     import core.stdc.stdlib: exit;
        //     exit(2);
        // }

        // To prevent from killing terminal by calling reset before set
        tcgetattr(stdin.fileno, &originalTermios);
    }

    /* ------------------------------ TERMINAL SIZE ----------------------------- */
    import core.sys.posix.sys.ioctl: winsize, ioctl, TIOCGWINSZ;

    /// Returns bash terminal width
    int terminalWidth() {
        winsize w;
        ioctl(0, TIOCGWINSZ, &w);
        return w.ws_col;
    }

    /// Returns bash terminal height
    int terminalHeight() {
        winsize w;
        ioctl(0, TIOCGWINSZ, &w);
        return w.ws_row;
    }

    /* -------------------------------- RAW MODE -------------------------------- */
    import core.stdc.stdio: setvbuf, _IONBF, _IOLBF;
    import core.stdc.stdlib: atexit;
    import core.stdc.string: memcpy;
    import core.sys.posix.termios: termios, tcgetattr, tcsetattr, TCSANOW;
    import core.sys.posix.unistd: read;
    import core.sys.posix.sys.select: select, fd_set, FD_ZERO, FD_SET;
    import core.sys.posix.sys.time: timeval;

    import std.stdio: stdin, stdout;

    private extern(C) void cfmakeraw(termios *termios_p);

    private termios originalTermios;

    private bool __isTermiosRaw = false;

    /// Is terminal in raw mode (have `setTerminalModeRaw` been called yet?)
    bool isTerminalRaw() nothrow {
        return __isTermiosRaw;
    }

    /// Resets termios back to default and buffers stdout
    extern(C) alias terminalModeReset = function() {
        tcsetattr(0, TCSANOW, &originalTermios);
        setvbuf(stdout.getFP, null, _IOLBF, 1024);
        __isTermiosRaw = false;
    };

    /** 
    Creates new termios and unbuffers stdout. Required for `kbhit` and `getch`
    DO NOT USE IF YOU DON'T KNOW WHAT YOU'RE DOING

    Note that in raw mode CRLF (`\r\n`) newline will be 
    required instead of normal LF (`\n`)
    Params:
        removeStdoutBuffer = Sets stdout buffer to null allowing immediate render without flush()
    */
    void terminalModeSetRaw(bool removeStdoutBuffer = true) {
        import core.sys.posix.termios;
        termios newTermios;

        tcgetattr(stdin.fileno, &originalTermios);
        memcpy(&newTermios, &originalTermios, termios.sizeof);

        cfmakeraw(&newTermios);

        newTermios.c_lflag &= ~(ICANON | ECHO | ISIG | IEXTEN);
        // newTermios.c_lflag &= ~(ICANON | ECHO);
        newTermios.c_iflag &= ~(ICRNL | INLCR | OPOST);
        newTermios.c_cc[VMIN] = 1;
        newTermios.c_cc[VTIME] = 0;

        if (removeStdoutBuffer) setvbuf(stdout.getFP, null, _IONBF, 0);

        tcsetattr(stdin.fileno, TCSANOW, &newTermios);

        atexit(terminalModeReset);
        __isTermiosRaw = true;
    }

    /// Returns true if any key was pressed
    bool kbhit() {
        timeval tv = { 0, 0 };
        fd_set fds;
        FD_ZERO(&fds);
        FD_SET(stdin.fileno, &fds);
        return select(1, &fds, null, null, &tv) == 1;
    }

    /// Returns last pressed key
    int getch() {
        int r;
        uint c;

        if ((r = cast(int) read(stdin.fileno, &c, ubyte.sizeof)) < 0) {
            return r;
        } else {
            return c;
        }
    }
    
    /* ---------------------------------- MISC ---------------------------------- */
    import core.sys.posix.unistd: posixIsATTY = isatty;
    // import std.stdio: File;
    import core.stdc.stdio: FILE, cfileno = fileno;
    import core.stdc.errno;

    /// Returns true if file is a tty
    bool isatty(File file) {
        return cast(bool) posixIsATTY(file.fileno);
    }
    /// Ditto
    bool isatty(FILE* handle) {
        return cast(bool) posixIsATTY(handle.cfileno);
    }
    /// Ditto
    bool isatty(int fd_set) {
        return cast(bool) posixIsATTY(fd_set);
    }



    /* -------------------------- Terminal Capabilities --------------------------- */

    // import std.stdio: File;
    import std.file: readText;

    // TODO: read termcap and put it into struct

    struct Termcap {
        TermType termType = TermType.vt100;
        string capPath = "";
        // TODO: keys
        // TODO: commands
    }

    enum TermType {
        // TODO: flags
        vt,
        vt100,
        vt101
    }
}

import std.stdio: File;
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
