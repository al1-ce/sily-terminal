module sily.tui.app;

import std.array : popFront;
import std.conv : to;
import std.stdio : stdout;
import std.string : format;

import sily.bashfmt;
import sily.logger : fatal;
import sily.terminal;
import sily.time;
import sily.vector;

import sily.tui.elements;
import sily.tui.render;

/// Terminal UI application
class App {
    private Element _rootElement = null;

    private float _fpsTarget = 30.0f;
    public float getFpsTarget() {
        return _fpsTarget;
    }

    public void setFpsTarget(float t) {
        _fpsTarget = t;
    }

    private bool _isRunning = false;

    private float _frameTime;
    private int _frames;
    private int _fps;

    private InputEvent[] _unprocessedInput = [];

    /** 
    Public create method. Can be overriden. 
    Called when app is created, but before all elements created
    */
    public void create() {
    }
    /** 
    Public destroy method. Can be overriden. 
    Called when app is destroyed, but after all elements destroyed
    */
    public void destroy() {
    }
    /** 
    Public update method. Can be overriden. 
    Called each frame after all elements have been updated
    */
    public void update(float delta) {
    }
    /** 
    Public update method. Can be overriden. 
    Called each frame if there's input available 
    after all elements have processed input
    */
    public void input(InputEvent e) {
    }
    /** 
    Public render method. Can be overriden. 
    Called each frame after all elements have rendered 
    */
    public void render() {
    }

    /** 
    Starts application and goes into raw alt terminal mode
    
    Application runs in this order:
    ---
    app.create();
    elements.create();
    while (isRunning) {
        elements.input();
        app.input();

        elements.update();
        app.update();

        elements.render();
        app.render();
    }
    elements.destroy();
    app.destroy();
    ---
    All those methods are overridable and intended to be
    used to create custom app logic
    */
    public final void run() {
        if (!stdout.isatty) {
            fatal("STDOUT is not a tty");
            exit(ErrorCode.noperm);
            return;
        }

        screenEnableAltBuffer();
        screenClearOnly();
        // must be false to allow stdout.flush
        version (Have_speedy_stdio)
            terminalModeSetRaw(true);
        else
            terminalModeSetRaw(false);
        cursorMoveHome();
        cursorHide();

        if (_rootElement is null) {
            Element el = new Element();
            el.setApp(this);
            el.setRoot();
            _rootElement = el;
        }

        _isRunning = true;

        create();
        _rootElement.propagateCreate();

        loop();

        cleanup();

        _rootElement.propagateDestroy();
        destroy();
    }

    /// Requests application to be stopped
    public final void stop() {
        _isRunning = false;
    }

    private void loop() {
        _frameTime = 1.0f / _fpsTarget;
        _frames = 0;
        _fps = 60;

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
                doNeedRender = true;

                unprocessedTime -= _frameTime;

                // Might be some closing logic

                _input();

                // TODO: Input.update();
                foreach (key; _unprocessedInput) {
                    // For each input
                    _rootElement.propagateInput(key);
                    // Custom app update logic
                    if (!key.isProcessed)
                        input(key);

                    _unprocessedInput.popFront();
                }

                _rootElement.propagateUpdate(_frameTime.to!float);
                // Custom app update logic
                update(_frameTime.to!float);

                if (frameCounter >= 1.0) {
                    _fps = _frames;
                    _frames = 0;
                    frameCounter = 0;
                }
            }

            if (doNeedRender) {
                Render.screenClearOnly();
                Render.cursorMoveHome();
                _rootElement.propagateRender();
                // Custom app render logic
                render();
                Render.flushBuffer();
                Render.clearBuffer();
                ++_frames;
                sleep(1);
            } else {
                sleep(1);
            }

            scope (failure) {
                cleanup();
                fatal("Fatal error have occured");
            }
        }
    }

    private void _input() {
        while (kbhit()) {
            int key = getch();
            InputEvent e = InputEvent(InputEvent.Type.keyboard, key);
            _unprocessedInput ~= e;
        }
    }

    private void cleanup() {
        terminalModeReset();
        screenDisableAltBuffer();
        cursorShow();
    }

    /// Sets app title
    public void setTitle(string title) {

        

            .setTitle(title);
    }

    /// Returns app width/height
    public uint width() {
        return terminalWidth();
    }
    /// Ditto
    public uint height() {
        return terminalHeight();
    }
    /// Ditto
    public uvec2 size() {
        return uvec2(width, height);
    }

    /// Returns current FPS
    public int fps() {
        return _fps;
    }

    /// Returns current FPS as string
    public string fpsString() {
        return _fps.to!string;
    }

    /// Returns true if app is running
    public bool isRunning() {
        return _isRunning;
    }

    /// Returns aspect ratio (w / h)
    public float aspectRatio() {
        return width.to!float / height.to!float;
    }

    /// Returns root element
    public Element rootElement() {
        return _rootElement;
    }
}
