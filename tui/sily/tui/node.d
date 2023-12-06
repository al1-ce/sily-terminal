module sily.tui.node;

public import sily.color: col;
public import sily.vector: ivec2;

import std.algorithm.comparison: min, max;
import std.algorithm.searching: canFind, countUntil;
import std.algorithm.mutation: remove;
import std.algorithm.sorting: sort;
import std.conv: to;
import std.traits: isSomeString;

import sily.terminal: terminalWidth, terminalHeight;
import sily.string: splitStringWidth;

import sily.tui.render;

// alias Node = Element*;

private Node _root;

static this() {
    _root = Node(new Element(
                Node(),
                [],
                "root",
                [],
                Size.full,
                ivec2(0),
                col(0, 0, 0, 0),
                col(0, 0, 0, 0),
                ""d,
                TextHAlign.center,
                TextVAlign.middle,
                false,
                Border.none,
                false,
                col(0, 0, 0, 0),
                0,
                true
                ));
}

Node root() {
    return _root;
}

private const string _upperBlock = "\u2580";
private const string _lowerBlock = "\u2584";

/*
To class or not to class
If to make element a class then I'd be able to easily define everything
by inheriting main class
But structs are kind of more memory efficient

Needed elements (bare minimum):
    - Panel (box)
    - Label (text/paragraph/header)
    - Button (input?)
    - Canvas (hard rendering)

Logically they all can be a single element type which you can
Node n = get!("#myelement").add();
n.addEventListener(Evt.mousePress, function() {});
n.drawCurve(vec2()...)

Struct it is
*/

private struct Element {
    Node _parent;
    Node[] _children = [];
    string _id = "";
    string[] _classes = [];
    /// Style size, 0-inf - normal size, -1 - Fill, -2 - Auto
    ivec2 _size = Size.content;
    ivec2 _pos = ivec2(0, 0);
    col _backgroundColor = col(0.2f);
    col _textColor = col(1.0f);
    dstring _text = "";
    TextHAlign _halign = TextHAlign.center;
    TextVAlign _valign = TextVAlign.middle;
    bool _isEmpty = false;
    dchar[8] _borderChars = Border.normal;
    bool _drawBorderBackground = true;
    col _borderColor = col(0.8);
    // TODO: text decorations
    // TODO: padding?
    long _priority = 0;

    // Should be always true at start or forceRender at start
    bool _renderNeeded = true;


    /**
    Creates "tree" representation in format:
    ---
    Name: [Child, Child2: [Child3, Child 4]]
    ---
    */
    string toTreeString() {
        if (_children.length == 0) return (_id == "" ? "__NO_ID__" : _id);
        string _out = (_id == "" ? "__NO_ID__" : _id) ~ ": [";
        for (int i = 0; i < _children.length; ++i) {
            Element child = *(_children[i]);
            _out ~= child.toTreeString();
            if (i + 1 != _children.length) _out ~= ", ";
        }
        _out ~= ']';
        return _out;
    }

    void render() {
        if (_id == "root") {
            screenClearOnly();
        }

        ivec2 pos = getPosition();
        // do render of itself
        ivec2 size = getSize();
        bool isTopEdge = pos.y % 2 == 1;
        bool isUnevenSize = size.y % 2 == 1;
        bool isBottomEdge = isTopEdge != isUnevenSize; // wierd XOR
        col pcolor = getParentColor();
        int height = size.y / 2;
        if (isTopEdge || isBottomEdge) height += 1;

        // TODO: calculate other children color overlap
        // Kinda fixed by border but still a thing
        // (A is not child of B but sill overlays with wrong color)

        // draw background
        if (_backgroundColor.a > 0.1) {
            for (int y = 0; y < height; ++y) {
                cursorMoveTo(pos.x, pos.y / 2 + y);
                bool isEdge = (isTopEdge && y == 0) || (isBottomEdge && y + 1 == height);
                if (isEdge) {
                    if (isEdge && pcolor.a > 0.1) write(pcolor.escape(true));
                    write(_backgroundColor.escape(false));
                } else {
                    write(_backgroundColor.escape(true));
                }
                for (int x = 0; x < size.x; ++x) {
                    if (isTopEdge && y == 0) {
                        write(_lowerBlock);
                    } else
                    if (isBottomEdge && y + 1 == height) {
                        write(_upperBlock);
                    } else {
                        write(" ");
                    }
                }
                write("\033[m");
            }
        }

        bool borderExists = false;
        foreach (c; _borderChars) {
            if (c != ' ') {
                borderExists = true;
                break;
            }
        }

        if (_textColor.a > 0.1 && _text.length > 0) {
            dstring[] t = splitStringWidth(_text, size.x - (borderExists ? 2 : 0));
            int yred = borderExists ? 2 : 0;
            if (isTopEdge) yred += 1;
            if (isBottomEdge) yred += 1;
            int borderRed = (borderExists ? 1 : 0);
            int maxY = max(min(t.length, height - yred), 0);
            for (int y = isTopEdge ? 1 : 0; y < maxY + isTopEdge ? 1 : 0; ++y) {
                ivec2 tp = ivec2(pos.x, pos.y / 2 + y);
                dstring line = t[y - (isTopEdge ? 1 : 0)];
                int len = cast(int) line.length;
                int lct = cast(int) t.length;
                if (_halign == TextHAlign.center) {
                    // offset it by (width - line width) / 2
                    tp.x = tp.x + (size.x - len) / 2 - borderRed;
                } else
                if (_halign == TextHAlign.right){ // right
                    // offset it by widht - line width
                    tp.x = tp.x + size.x - len - borderRed;
                }
                if (_valign == TextVAlign.middle) {
                    tp.y = tp.y + (height - lct) / 2 - borderRed;
                } else
                if (_valign == TextVAlign.bottom) {
                    tp.y = tp.y + height - lct - (isTopEdge ? 1 : 0) - borderRed;
                }

                cursorMoveTo(tp.x, tp.y);
                if (_backgroundColor.a > 0.1) {
                    write(_backgroundColor.escape(true));
                    write(_textColor.escape(false));
                    write(line);

                } else {
                    write(_textColor.escape(false));
                    for (int k = 0; k < line.length; ++k) {
                        dchar ch = line[k];
                        col c = getBackColorAt(tp + ivec2(k, 0));
                        write(c.escape(true));
                        write(ch);
                    }
                }
                write("\033[m");
            }
        }

        if (borderExists && _borderColor.a > 0.1) {
            // top
            for (int x = 0; x < size.x; ++x) {
                cursorMoveTo(pos.x + x, pos.y / 2);
                if (_drawBorderBackground && _backgroundColor.a > 0.1) {
                    write(_backgroundColor.escape(true));
                } else {
                    col c = getBackColorAt(pos + ivec2(x, 0));
                    write(c.escape(true));
                }
                write(_borderColor.escape(false));
                if (x == 0) {
                    write(_borderChars[0]);
                } else
                if (x + 1 == size.x) {
                    write(_borderChars[2]);
                } else {
                    write(_borderChars[1]);
                }
            }
            // side left
            for (int y = 1; y + 1 < height; ++y) {
                cursorMoveTo(pos.x, pos.y / 2 + y);
                if (_drawBorderBackground && _backgroundColor.a > 0.1) {
                    write(_backgroundColor.escape(true));
                } else {
                    col c = getBackColorAt(pos + ivec2(0, y));
                    write(c.escape(true));
                }

                write(_borderColor.escape(false));
                write(_borderChars[3]);
            }
            // side right
            for (int y = 1; y + 1 < height; ++y) {
                cursorMoveTo(pos.x + size.x - 1, pos.y / 2 + y);
                if (_drawBorderBackground && _backgroundColor.a > 0.1) {
                    write(_backgroundColor.escape(true));
                } else {
                    col c = getBackColorAt(pos + ivec2(size.x - 1, y));
                    write(c.escape(true));
                }

                write(_borderColor.escape(false));
                write(_borderChars[4]);
            }
            // bottom
            for (int x = 0; x < size.x; ++x) {
                cursorMoveTo(pos.x + x, pos.y / 2 + height - 1);
                if (_drawBorderBackground && _backgroundColor.a > 0.1) {
                    write(_backgroundColor.escape(true));
                } else {
                    col c = getBackColorAt(pos + ivec2(x, size.y - 1));
                    write(c.escape(true));
                }

                write(_borderColor.escape(false));
                if (x == 0) {
                    write(_borderChars[5]);
                } else
                if (x + 1 == size.x) {
                    write(_borderChars[7]);
                } else {
                    write(_borderChars[6]);
                }
            }

        }

        foreach (Node child; _children) {
            (*child).render();
        }

        // write("\033[mA");

        _renderNeeded = false;
    }

    void forceRender() {
        render();
    }

    void requestRender() {
        if (_renderNeeded) {
            render();
        } else {
            foreach (Node child; _children) {
                (*child).requestRender();
            }
        }
    }

    void addChild(Node child) {
        _children ~= child;
        (*child)._parent = &this;
    }

    ivec2 getSize() {
        int tw = terminalWidth();
        int th = terminalHeight() * 2;
        if (_parent.isNull) return ivec2(tw, th);
        ivec2 s = _size;
        // -1 - full fill
        s.x = s.x == -1 ? tw : s.x;
        s.y = s.y == -1 ? th : s.y;
        // -2 - fill from content
        s.x = s.x == -2 ? tw : s.x;
        s.y = s.y == -2 ? th : s.y;

        ivec2 _parentSize = (*_parent).getSize();
        ivec2 _maxSize = _parentSize - _pos;
        s = s.min(_maxSize);

        // TODO: fix auto
        // TODO: limit to parent size
        return s;
    }

    ivec2 getPosition() {
        if (_parent.isNull) return _pos;
        ivec2 ppos = (*_parent).getPosition();
        return _pos + ppos;
    }

    col getParentColor() {
        if (_parent.isNull) return col(0.0f, 0.0f);
        return (*_parent)._backgroundColor;
    }

    col getBackColorAt(ivec2 pos) {
        if (_parent.isNull) return col(0.0f, 0.0f);
        Node[] el = (*_parent)._children;

        col _col = _parent.bgcol;
        long _pri = long.min;

        foreach (c; el) {
            if (c.ptr == &this) { continue; }
            if (isColliding(pos / ivec2(1, 2), c.getPosition / ivec2(1, 2), c.size / ivec2(1, 2))) {
                if (c.priority > _pri && c.bgcol.a > 0.1) {
                    _pri = c.priority;
                    _col = c.bgcol;
                }
                // _col = col(1, 0, 0);
            }
        }

        return _col;
    }

    void sortChildren() {
        _children.sort!((a, b) => (*a)._priority < (*b)._priority);
    }
}

public bool isColliding(ivec2 pos, ivec2 tl, ivec2 wh) {
    return pos.x >= tl.x &&
           pos.y >= tl.y &&
           pos.x <= tl.x + wh.x &&
           pos.y <= tl.y + wh.y;
}

void forceRender() {
    (*root).forceRender();
}

void requestRender() {
    (*root).requestRender();
}

/*
Style sizes
none - hidden
content - auto size
full - fill parent
wide - fill parent width, auto height
tall - fill parent height, auto width
*/
enum Size: ivec2 {
    none = ivec2(0, 0),
    content = ivec2(-2, -2),
    full = ivec2(-1, -1),
    wide = ivec2(-1, -2),
    tall = ivec2(-2, -1)
}

enum TextVAlign {
    middle,
    top,
    bottom
}

enum TextHAlign {
    center,
    left,
    right
}

enum Border: dchar[8] {
    none = "        ",
    normal = "┌─┐││└─┘",
    heavy = "┏━┓┃┃┗━┛",
    solid = "████████",
    thick = "▛▀▜▌▐▙▄▟",
    thickrev = "▗▄▖▐▌▝▀▘",
    dotted = "⡏⠉⢹⡇⢸⣇⣀⣸",
    doubled = "╔═╗║║╚═╝",
    dbVertical = "╒═╕║║╘═╛",
    dbHorizontal = "╓─╖║║╙─╜"
}

Node createNode() {
    return Node(new Element());
}

Node createNullNode() {
    return Node(null);
}

struct Node {
    Element* ptr = null;
    alias ptr this;

    private this(Element* p) {
        this.ptr = p;
    }

    bool isNull() {
        return ptr == null;
    }

    Node append(Node child) {
        (*ptr).addChild(child);
        (*ptr).sortChildren();
        return this;
    }

    Node bgcol(col bg) {
        (*ptr)._backgroundColor = bg;
        setRenderNeeded();
        return this;
    }

    col bgcol() {
        return (*ptr)._backgroundColor;
    }

    Node fgcol(col fg) {
        (*ptr)._textColor = fg;
        setRenderNeeded();
        return this;
    }

    col fgcol() {
        return (*ptr)._textColor;
    }

    Node size(ivec2 size) {
        (*ptr)._size = size;
        setRenderNeeded();
        return this;
    }

    ivec2 size() {
        return (*ptr)._size;
    }

    Node pos(ivec2 _pos) {
        (*ptr)._pos = _pos;
        setRenderNeeded();
        return this;
    }

    ivec2 pos() {
        return (*ptr)._pos;
    }

    Node text(T)(T text) if (isSomeString!T) {
        static if (is(typeof(T) == dstring)) {
            (*ptr)._text = text;
        } else {
            (*ptr)._text = text.to!dstring;
        }
        setRenderNeeded();
        return this;
    }

    dstring text() {
        return (*ptr)._text;
    }

    Node halign(TextHAlign al) {
        (*ptr)._halign = al;
        setRenderNeeded();
        return this;
    }

    TextHAlign halign() {
        return (*ptr)._halign;
    }

    Node valign(TextVAlign al) {
        (*ptr)._valign = al;
        setRenderNeeded();
        return this;
    }

    TextVAlign valign() {
        return (*ptr)._valign;
    }

    /**
    Set/get border characters in format [LeftUp, Up, RightUp, Left, Right, LeftDown, Down, RightDown].
    */
    Node border(dchar[8] borderChars, bool drawBorderBackground = true) {
        (*ptr)._borderChars = borderChars;
        (*ptr)._drawBorderBackground = drawBorderBackground;
        setRenderNeeded();
        return this;
    }

    dchar[8] border() {
        return (*ptr)._borderChars;
    }

    Node borderColor(col c) {
        (*ptr)._borderColor = c;
        setRenderNeeded();
        return this;
    }

    col borderColor() {
        return (*ptr)._borderColor;
    }

    Node addClass(string _class) {
        (*ptr)._classes ~= _class;
        return this;
    }

    Node removeClass(string _class) {
        if (!hasClass(_class)) return this;
        size_t _pos = (*ptr)._classes.countUntil(_class);
        (*ptr)._classes = (*ptr)._classes.remove(_pos);
        return this;
    }

    bool hasClass(string _class) {
        return (*ptr)._classes.canFind(_class);
    }

    string[] classes() {
        return (*ptr)._classes;
    }

    Node id(string _id) {
        assert(_id != "root", "ID \"root\" is not permitted since it's used for app root.");
        (*ptr)._id = _id;
        return this;
    }

    string id() {
        return (*ptr)._id;
    }

    Node priority(long pr) {
        (*ptr)._priority = pr;
        (*ptr).sortChildren();
        setRenderNeeded();
        return this;
    }

    long priority() {
        return (*ptr)._priority;
    }

    private void setRenderNeeded() {
        (*ptr)._renderNeeded = true;
        if ((*ptr)._parent == null) return;
        (*((*ptr)._parent))._renderNeeded = true;
    }

    string toTreeString() {
        return (*ptr).toTreeString;
    }
}

// TODO: advanced query
// LINK: https://developer.mozilla.org/en-US/docs/Web/API/Document/querySelector

/**
Returns node based on selector, similar to CSS selectors.
Example:
Node bigPanel = query!"#nodeid";
Node[] labels = query!".label";
Node[] allNodes = query!"*";
*/
Node query(string selector)(Node from = root) if (selector.length > 0 && selector[0] == '#') {
    if ((*from.ptr)._id == selector[1..$]) return from;
    Node[] children = (*from.ptr)._children;
    foreach (Node child; children) {
        Node n = child.query!selector;
        if (!n.isNull) {
            return n;
        }
    }
    return createNullNode();
}
/// Ditto
Node[] query(string selector)(Node from = root) if (selector.length > 0 && selector[0] != '#') {
    Node[] ret;
    if (selector[0] == '.' && (*from.ptr)._classes.canFind(selector[1..$])) ret ~= from;
    if (selector[0] == '*') ret ~= from;
    Node[] children = (*from.ptr)._children;
    foreach (Node child; children) {
        Node[] n = child.query!selector;
        if (n.length > 0) {
            ret ~= n;
        }
    }
    return ret;
}

