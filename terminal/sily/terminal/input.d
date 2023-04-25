module sily.terminal.input;

import std.conv: to;

import sily.queue;
import sily.terminal;
import sily.vector: uvec2;

private Queue!Input inputQueue = Queue!Input();

/// Add normal discard?
/// Returns last element and removes it from queue if `remove` is true
Input peekEvent(bool remove = true)() {
    if (inputQueue.empty) return InputEvent();
    if (remove) {
        return inputQueue.pop();
    } else {
        return inputQueue.front;
    }
}

/// Returns true if there's still input in buffer
bool queueEmpty() {
    return inputQueue.empty;
}

/// Clears input queue
void discardAll() {
    inputQueue.clear();
}

bool queueHas(Input key) {
    Input[] events = inputQueue.toArray();
    foreach (e; events) {
        if (e.isKey(key)) {
            return true;
        }
    }
    return false;
}

/// Buffers input from getch
/// Returns: true if operation was sucessfull
bool pollEvent() {
    if (!kbhit()) return false;
    
    // 0: ctrl + 2
    // 1 - 26: ctrl + [a-z]
    // 8: ^H or ctrl + backspace
    // 9: ^I or tab
    // 13: ^M or enter
    // 27: esc, ctrl + [ 
    // 27+27: alt + esc
    // 28: ctrl + \
    // 29: ctrl + ]
    // 30: ctrl + shift + 6 (^^), ctrl + shift + ` (^~)
    // 31: ctrl + shift + - (^_)
    // 32 - 126: look ascii table
    // 127: del (backspace), ctrl + shift + /
    // 27 [65-90]: alt + shift + [a-z]
    // 27 [97-122]: alt + [a-z]

    // 27 91 [65-68]: U,D,R,L
    // 27 79 [80-83]: F[1-4]
    // 27 91 49 [53, 55-57] 126: F[5-8]
    // 27 91 50 [48,49,51,52] 126: F[9-12]
    // 27 91 49 50 [65-68]: Shift + U,D,R,L
    // 27 91 49 53 [65-68]: ^ + U,D,R,L
    // 27 91 49 54 [65-68]: ^ + shift + U,D,R,L
    // 27 91 51 126: del
    // 27 91 [70, 72]: end, home
    // 27 91 49 59 51 80: meta (win)
    // TODO: figure out ctrl+shift
    // TODO: figure out meta
    // TODO: figure out scroll and middle click?
    // TODO: figure out shift combos
    // TODO: mouse?
    // TODO: ctrl + numbers
    
    // \e[A: A-D UDRL

    // \e?: ?=97-122 alt + a-z
    // \e?: ?=1-26 ctrl + alt + a-z
    // \e?: ?=65-90 shift + alt + a-z
    // \e[X;6u: X=97-122 ctrl + shift + a-z
    // \e[X;8u: X=97-122 ctrl + shift + alt + a-z
    // \e[X;9u: same, win + a-z
    // \e[X;10u: same, win + shift + a-z
    // \e[X;11u: same, win + alt + a-z
    // \e[X;12u: same, win + alt + shift + a-z
    // \e[X;13u: same, win + ctrl + a-z
    // \e[X;14u: same, win + ctrl + shift + a-z
    // \e[X;15u: same, win + ctrl + alt + a-z
    // \e[X;16u: same, win + ctrl + shift + alt + a-z

    // \eOP: f1
    // \eOQ: f2
    // \eOR: f3
    // \eOS: f4
    // \e[1;XY: X=look combos, Y=PQRS

    // \e[X~: x=[15,17-21,23,24]: f5-12

    // \e[1;XA: A-D, X = 2!s, 3!a, 4!as, 5!c, 6!cs, 7!ca, 8!csa, for meta look normal keys

    // \e[96;x;yM - mouse wheel up
    // \e[97;x;yM - mouse wheel down
    // \e[32;x;yM - lmb
    // \e[33;x;yM - mmb
    // \e[34;x;yM - rmb
    // \e[160;x;yM - mbb
    // \e[161;x;yM - mfb
    string seq = "";
    while (kbhit()) {
        seq ~= cast(char) getch();
    }
    
    if (seq.length == 1) {
        int key = cast(int) seq[0];

        // Control letters / Control sequences
        if (key >= 1 && key <= 26) inputQueue.push(ikey(key + 96, Mod.c));
        // Shift letters
        if (key >= 65 && key <= 90) inputQueue.push(ikey(key + 32, Mod.s));
        // Normal letters
        if (key >= 97 && key <= 122) inputQueue.push(ikey(key));
        // Duplicates (same as some control seq)
        if (key == 8) inputQueue.push(ikey(Key.backspace, Mod.c));
        if (key == 9) inputQueue.push(ikey(Key.tab));
        if (key == 13) inputQueue.push(ikey(Key.enter));
        if (key == 27) {
            inputQueue.push(ikey(Key.escape));
            inputQueue.push(ikey(Key.leftBracket, Mod.c));
        }
        // Space
        if (key == 32) inputQueue.push(ikey(Key.space));
        // Numbers
        if (key >= 48 && key <= 57) inputQueue.push(ikey(key));
        // TODO: Symbols
        return true;
    }
    
    // sequence
    if (seq.length >= 2 && seq[0] == 27) {
        if (seq[1] == '[') {
            // normal sequence
            
        } else
        if (seq.length == 3 && seq[1] == 'O') {
            // f1-4
            switch (seq[2]) {
                case 'P': inputQueue.push(ikey(Key.f1)); break;
                case 'Q': inputQueue.push(ikey(Key.f2)); break;
                case 'R': inputQueue.push(ikey(Key.f3)); break;
                case 'S': inputQueue.push(ikey(Key.f4)); break;
                default: break;
            }
        } else {
            // letters
            int key = cast(int) seq[1];
            // Control letters / Control sequences
            if (key >= 1 && key <= 26) inputQueue.push(ikey(key + 96, Mod.ca));
            // Shift letters
            if (key >= 65 && key <= 90) inputQueue.push(ikey(key + 32, Mod.sa));
            // Normal letters
            if (key >= 97 && key <= 122) inputQueue.push(ikey(key, Mod.a));
        }
        return true;
    }


    return false;
}

/// Returns new InputKey with set mod keys
Input ikey(uint key, uint mod = Mod.n) {
    Key enumKey = to!Key(key);
    return ikey(enumKey, mod);
}
/// Ditto
Input ikey(Key key, uint mod = Mod.n) {
    // return Input(key, mod.hasFlag(Mod.c), mod.hasFlag(Mod.s), mod.hasFlag(Mod.a), mod.hasFlag(Mod.m));
    return Input(key, mod);
} 

private bool hasFlag(uint flags, uint flag) {
    return (flags & flag) == flag;
}

/// Input mod keys (ctrl, shift, alt)
alias Mod = InputMod;
/// Ditto
enum InputMod: uint {
    /// No key
    none  = 0b0000,
    /// Ditto
    n     = 0b0000,
    /// Control
    ctrl  = 0b0001,
    /// Ditto
    c     = 0b0001,
    /// Shift
    shift = 0b0010,
    /// Ditto
    s     = 0b0010,
    /// Alt (command)
    alt   = 0b0100,
    /// Ditto
    a     = 0b0100,
    /// Meta (win/option)
    meta  = 0b1000,
    /// Ditto
    m     = 0b1000,
    /// Control + Shift
    cs    = 0b0011,
    /// Control + Alt (command)
    ca    = 0b0101,
    /// Shift + Alt (command)
    sa    = 0b0110,
    /// Control + Shift + Alt (command)
    csa   = 0b0111,
    /// Meta + Control
    mc    = 0b1001,
    /// Meta + Alt
    ma    = 0b1100,
    /// Meta + Shift
    ms    = 0b1010,
    /// Meta + Control + Shift
    mcs   = 0b1011,
    /// Meta + Control + Alt
    mca   = 0b1101,
    /// Meta + Shift + Alt
    msa   = 0b1110,
    /// Meta + Control + Shift + Alt
    mcsa  = 0b1111,
    /// All modifiers
    all   = 0b1111
}

/// Input event (keypress)
alias Input = InputEvent;
/// Ditto
struct InputEvent {
    /// Pressed key
    public Key key = Key.none;
    // /// Control pressed
    // public bool ctrl = false;
    // /// Shift pressed
    // public bool shift = false;
    // /// Alt (command) pressed
    // public bool alt = false;
    // /// Meta (win/option) pressed
    // public bool meta = false;
    public uint mod = Mod.n;

    bool opEquals()(in Input b) const {
        // return key == b.key && ctrl == b.ctrl && shift == b.shift && alt == b.alt && meta == b.meta;
        return key == b.key && mod == b.mod;
    }

    /// Returns hash 
    size_t toHash() const @safe nothrow {
        return typeid(this).getHash(&this);
    }
    
    /// Checks if two inputs are same
    bool isKey(Input b) {
        return this == b;
    }
    
    /// Checks if key has modifier m
    bool hasMod(Mod m) {
        return mod.hasFlag(m);
    }
}

// 0 - released, 1 - pressing, 2 - pressed, 3 - releasing
// wheels always on 0:1
private ubyte[Button] mouseState;

static this() {
    mouseState = [
        Button.left: 0,
        Button.middle: 0,
        Button.right: 0,
        Button.wheelUp: 0,
        Button.wheelDown: 0,
        Button.forward: 0,
        Button.backward: 0
    ];
}

private uvec2 lastMousePos = uvec2(1);

/// Mouse buttons
alias Button = MouseButton;
/// Ditto
enum MouseButton {
    left, middle, right, wheelUp, wheelDown, forward, backward
}

/// Normal input keys
alias Key = InputKey;
/// Ditto
enum InputKey {
    none = -1,
    quote, equals, comma, minus, slash, colon, period, leftBracket, rightBracket,
    backslash, grave, up, down, left, right, meta,
    f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12,
    enter, tab, backspace, escape,

    space = 32,
    num0 = 48, num1, num2, num3, num4, num5, num6, num7, num8, num9,
    a = 97, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z

}

import std.stdio: write;

/// Enables/disables mouse input capture
void mouseEnable() {
    write("\033[?1000;1006;1015h");
}
/// Ditto
void mouseDisable() {
    write("\033[?1000;1006;1015l");
}


