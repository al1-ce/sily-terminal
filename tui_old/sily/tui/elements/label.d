/// Label TUI Element
module sily.tui.elements.label;

import std.conv: to;

import sily.tui;
import sily.tui.render;
import sily.tui.elements.element;

import sily.color;
import sily.vector;
import sily.property;

/// Element implementing text render
class Label: Element {
    /// Label text
    private dstring _text = "";
    /// Label text color
    private col _front = Colors.black;
    /// Label background color
    private col _back = Colors.white;
    mixin property!_text;
    mixin property!_front;
    mixin property!_back;

    /**
    Creates new Label
    Params:
        _text = Text
        _pos = Position
        _front = Text color
        _back = Background color
    */
    public this(dstring _text, uvec2 _pos, col _front, col _back) {
        text = _text;
        pos = _pos;
        front = _front;
        back = _back;
    }

    /// Label rendering
    protected final override void _render() {
        Render.at(pos.x, pos.y).write(
            front.escape(false),
            back.escape(true),
            text,
            "\033[m"
        );
    }

    /// Returns label length
    public int length() { return text.length.to!uint; }
}