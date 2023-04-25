module sily.tui;

import std.conv: to;
import std.stdio: stdout;

import sily.tui.node;
import sily.tui.event;
import sily.tui.input;
import sily.tui.render;

import sily.vector: uvec2;
import sily.terminal;
import sily.terminal.input;
import sily.bashfmt: screenEnableAltBuffer, cursorHide, screenDisableAltBuffer, cursorShow;
import sily.logger: fatal;
import sily.time;

private float _fpsTarget = 30.0f;
private bool _isRunning = false;
private float _frameTime;
private int _frames;
private int _fps;

void run() {
    if (!stdout.isatty) {
        fatal("STDOUT is not a tty");
        exit(ErrorCode.noperm);
        return;
    }

    screenEnableAltBuffer();
    screenClearOnly();
    version (Have_speed_stdio) {
        terminalModeSetRaw(true);
    } else {
        terminalModeSetRaw(false);
    }
    cursorMoveHome();
    cursorHide();

    _isRunning = true;

    loop();

    cleanup();
}

void stop() {
    _isRunning = false;
}

void loop() {
    _frameTime = 1.0f / _fpsTarget;
    _frames = 0;
    _fps = _fpsTarget.to!int; // 30 by default

    double frameCounter = 0;
    double lastTime = Time.currTime;
    double unprocessedTime = 0;

    while (_isRunning) {
        bool doNeedRender = false;
        double startTime = Time.currTime;
        double passedTime = startTime - lastTime;
        lastTime = startTime;

        unprocessedTime += passedTime;
        frameCounter += passedTime;

        while (unprocessedTime > _frameTime) {
            // write(unprocessedTime, " ", _frameTime, " ", frameCounter, " ", _frames, "\n");
            doNeedRender = true;
            unprocessedTime -= _frameTime;

            // PROCESS LOGIC HERE
            pollInputEvent();
            triggerEvent!EventUpdate;
            // propagate update

            if (frameCounter >= 1.0) {
                _fps = _frames;
                _frames = 0;
                frameCounter = 0;
            }
        }

        if (doNeedRender) {
            // Process Render
            render();
            ++_frames;
        }
        sleep(1);

        scope (failure) {
            cleanup();
            fatal("Fatal error have occured. Aborting execution.");
        }
    }
}

private size_t _drawFrameNumber = 0;
size_t renderFrameNumber() {
    return _drawFrameNumber;
}

void render() {
    // root updates entire screen
    // update steps
    // updates in parent polls updates in children
    // updates in children polls update in direct parent
    // updates are polled only if there are changes in something like position
    // i.e if position of parent/child is changed parent will update
    // and so all the children of parent
    // this way it is ensured that there's no flashing or too much updates

    // We shouldn't use force render here
    // forceRender();
    requestRender();
    
    if (sizeofBuffer != 0) {
        flushBuffer();
        clearBuffer();

        ++_drawFrameNumber;
    }
}

void cleanup() {
    terminalModeReset();
    screenDisableAltBuffer();
    cursorShow();
}

void setTitle(string title) {
    .setTitle(title);
}

/// Returns app width/height
uint width() {
    return terminalWidth();
}
/// Ditto
uint height() {
    return terminalHeight() * 2;
}
/// Ditto
uvec2 size() {
    return uvec2(width, height);
}

/// Returns current FPS
int fps() {
    return _fps;
}

/// Returns current FPS as string
string fpsString() {
    return _fps.to!string;
}

/// Returns true if app is running
bool isRunning() {
    return _isRunning;
}

/// Returns aspect ratio (w / h)
float aspectRatio() {
    return width.to!float / height.to!float;
}
