/++
Windows specific terminal utils. Made only to handle unicode page and get terminal size.
It is not in any means stable or finished or should be used in production.
Please just use linux, it's so much better in that regard
+/
module sily.terminal.windows;

version(Windows):

static this() {
    // To prevent from killing terminal by calling reset before set
    GetConsoleMode(GetStdHandle(STD_INPUT_HANDLE), &originalMode);

    import core.sys.windows.windows : SetConsoleOutputCP;
    SetConsoleOutputCP(65_001);
}

/* ------------------------------ TERMINAL SIZE ----------------------------- */

import core.sys.windows.windows;

/// Returns bash terminal width
int terminalWidth() {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), &csbi);
    return csbi.srWindow.Bottom - csbi.srWindow.Top + 1;
}

/// Returns bash terminal height
int terminalHeight() {
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), &csbi);
    return csbi.srWindow.Right - csbi.srWindow.Left + 1;
}

/* -------------------------------- RAW MODE -------------------------------- */
import core.stdc.stdio: setvbuf, _IONBF, _IOLBF;
import core.stdc.stdlib: atexit;
import core.stdc.string: memcpy;

import std.stdio: stdin, stdout, File;

private uint originalMode;

private bool __isTermiosRaw = false;

/// Is terminal in raw mode (have `setTerminalModeRaw` been called yet?)
bool isTerminalRaw() nothrow {
    // HANDLE h = GetStdHandle(STD_INPUT_HANDLE);
    // uint mr = ENABLE_ECHO_INPUT | ENABLE_LINE_INPUT | ENABLE_PROCESSED_INPUT;
    // uint mc;
    // GetConsoleMode(h, &mc);
    // return !(mc & mr);
    return false;
}

/// Resets termios back to default and buffers stdout
extern(C) alias terminalModeReset = function() {
    HANDLE h = GetStdHandle(STD_INPUT_HANDLE);
    SetConsoleMode(h, originalMode);
    __isTermiosRaw = false;
};

/** 
Creates new termios and unbuffers stdout. Required for `kbhit` and `getch`
DO NOT USE IF YOU DON'T KNOW WHAT YOU'RE DOING

Note that in raw mode CRLF (`\r\n`) newline will be 
required instead of normal LF (`\n`)
Params:
    removeStdoutBuffer = Does nothing on windows
*/
void terminalModeSetRaw(bool removeStdoutBuffer = true) {
    // HANDLE h = GetStdHandle(STD_INPUT_HANDLE);
    // uint mr = originalMode;
    // mr &= ENABLE_ECHO_INPUT | ENABLE_LINE_INPUT | ENABLE_PROCESSED_INPUT | ENABLE_INSERT_MODE ;
    // SetConsoleMode(h, mr);

    // atexit(terminalModeReset);
    // __isTermiosRaw = true;
}

/// Returns true if any key was pressed
bool kbhit() {
	// HANDLE stdIn = GetStdHandle(STD_INPUT_HANDLE);
	// DWORD saveMode;

	// GetConsoleMode(stdIn, &saveMode);
	// SetConsoleMode(stdIn, ENABLE_PROCESSED_INPUT);

	// bool ret = false;

	// if (WaitForSingleObject(stdIn, INFINITE) == WAIT_OBJECT_0) {
	// 	uint num;
	// 	char ch;

	// 	ReadConsoleA(stdIn, &ch, 1, &num, cast(void *) 0L);
	// 	ret = true;
	// }

	// SetConsoleMode(stdIn, saveMode);
	// return ret;
    return false;
}

/// Returns last pressed key
int getch() {
    // int r;
    // uint c;
    // stdin.readf!"%d"(r);
    // if (r < 0) {
    //     return r;
    // } else {
    //     return c;
    // }
    return 0;
}

/* ---------------------------------- MISC ---------------------------------- */
// import core.sys.posix.unistd: posixIsATTY = isatty;
// import std.stdio: File;
import core.stdc.stdio: FILE, cfileno = fileno;
import core.stdc.errno;

/// Returns true if file is a tty (can't promice it'll work on windows properly)
bool isatty(File file) {
    return false;
    // return cast(bool) posixIsATTY(file.fileno);
}
/// Ditto
bool isatty(FILE* handle) {
    return false;
    // return cast(bool) posixIsATTY(handle.cfileno);
}
/// Ditto
bool isatty(int fd_set) {
    return false;
    // return cast(bool) posixIsATTY(fd_set);
}
