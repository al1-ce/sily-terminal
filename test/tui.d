#!/usr/bin/env dub
/+ dub.sdl:
name "tui-test"
dependency "sily" version="~>4"
dependency "sily-terminal:tui" path="../"
dependency "sily-terminal:logger" path="../"
dependency "sily-terminal" path="../"
// dependency "speedy-stdio" version="0.2.0"
targetType "executable"
targetPath "../bin/"
+/
module test.tui;

import sily.logger;
import sily.tui;
import sily.tui.event;
import sily.tui.input;
import sily.tui.node;
// import sily.bashfmt;
import sily.vector;
// import sily.terminal.input;
import std.stdio: write;
import std.conv: to;
import std.stdio;

/*
TODO: tui features
 -[ ] child on child overlap
 -[ ] mouse events
 -[ ] canvas functionality
 -[ ] string parser
 -[ ] auto sizing
 -[ ] containers
*/

void main() {
    log!(LogLevel.trace, __LINE__, "tui.d")("Starting application.");
    
    Node element = createNode();
    root.append(element);
    element.size(ivec2(44, 33))
        .pos(ivec2(5, 3))
        .bgcol(col(0.2f, 0.5f, 1.0f))
        .text("44x33,5x3: This is a test rectangle desu")
        .fgcol(col(1.0f, 0.8f, 0.4f))
        .halign(TextHAlign.center)
        .valign(TextVAlign.bottom)
        .border(Border.dotted);

    Node element2 = createNode(); 
    element.append(element2);
    element2.size(ivec2(24, 11))
        .pos(ivec2(1, 6))
        .bgcol(col(0.4f, 0.2f, 0.0f, 0))
        .text("24x11,1x6: Nice sub element with long description")
        .fgcol(col(1.0f, 0.8f, 0.4f))
        .halign(TextHAlign.right)
        .valign(TextVAlign.middle)
        .id("second")
        .addClass("super")
        .addClass("not_so")
        .priority(1);

    Node element3 = createNode();
    element.append(element3);
    element3.size(ivec2(22, 22))
        .pos(ivec2(10, 1))
        .text("22x11, 10x1: An element with painfully long\nand broken description that shouldnt fit")
        .addClass("super")
        .border(Border.thick)
        .bgcol(col(0.7f, 0.2f, 0, 1));

    Node fpspar = createNode().size(ivec2(10, 4));
    root.append(fpspar);
    Node fps = createNode();
    fpspar.append(fps);
    fps.size(ivec2(10, 4))
        .halign(TextHAlign.left);
    fps.id("fps");
    fps.addClass("one").addClass("two").addClass("three");
    fps.removeClass("two");
    fps.border(Border.none);

    addEventListener!EventInput(delegate void(InputEvent e) {
        if (e.key == Key.q) {
            stop();
        }
        if (e.key == Key.e) {
            element.text("New text");
        }
    });

    ivec2 elpos = element2.pos;

    // TODO: add timer

    addEventListener!EventUpdate(delegate void() {
        fps.text(fpsString() ~ "\n" ~ renderFrameNumber().to!string);

        import std.math;
        import sily.time;
        element2.pos(elpos + ivec2(4, 5) + ivec2(cast(int) (cos(currTime) * 5), cast(int) (sin(currTime) * 12)));
    });

    run();
    writeln(query!"#second");
    writeln(query!".super");
    writeln(query!"#second".text());
    writeln(root.toTreeString());

    log!(LogLevel.trace, __LINE__, "tui.d")("Stopping application.");
}

