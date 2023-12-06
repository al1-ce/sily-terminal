module sily.tui.event;

import io = sily.terminal.input;

private void delegate(io.InputEvent)[] _inputCallback;
private void delegate()[] _updateCallback;

/**
Contains event types.
---
EventType.input - will be triggered when new input is polled
EventType.update - will be triggered each frame
---
*/
enum EventType {
    input,
    update,
}
/// Ditto
alias EventInput = EventType.input;
/// Ditto
alias EventUpdate = EventType.update;

// TODO: rename
template addEventListener(EventType t) {
    static if (t == EventType.input) {
        void addEventListener(void delegate(io.InputEvent) f) {
            _inputCallback ~= f;
        }
    } else {
        void addEventListener(void delegate() f) {
            if (t == EventType.update) {
                _updateCallback ~= f;
            } else assert(0, "Unknown event type.");
        }
    }
}

size_t getListenerCount(EventType t)() {
    static if (t == EventType.input) {
        return _inputCallback.length;
    } else
    static if (t == EventType.update) {
        return _updateCallback.length;
    }
    else assert(0, "Unknown event type.");
}

/// Triggers generic events (that do not require arguments, i.e this will not trigger input)
void triggerEvent(EventType t)() if (t != EventType.input) {
    if (t == EventType.update) {
        foreach (f; _updateCallback) f();
    } else assert(0, "Unknown event type.");
}

// FIXME: shouldnt pollEvent pool event from queue and peek just show it?
void pollInputEvent() {
    io.pollEvent();
    while (!io.queueEmpty()) {
        io.InputEvent e = io.peekEvent();
        foreach (f; _inputCallback) {
            f(e);
        }
    }
}

void addTimer(bool repeating = false)(ulong time, void delegate() f) {

    // ADD LOGIC

    static if (repeating) {
        addTimer!true(time, f);
    }
}
