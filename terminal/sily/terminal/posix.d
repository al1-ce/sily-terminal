/// Posix specific terminal utils
module sily.terminal.posix;

version(Posix):

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