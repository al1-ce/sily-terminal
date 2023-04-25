module sily.tui.elements.element;

import std.conv: to;
import std.array: insertInPlace;
import std.algorithm: remove, countUntil, canFind;

import sily.tui;

import sily.vector;
import sily.property;

/// Input event struct
struct InputEvent {
    enum Type {keyboard, mouse, mouseMotion}
    Type type = Type.keyboard;
    int key = 0; 
    bool isProcessed = false;
}

/// Element style
struct Style {

}

/**
Should be used to inherit constructor, since D doesn't do that

Inserts `this(A...)(A args) { super(args); }` in place of mixin.
If you'd to supply incorrect args compilation will fail, so
it's fairly safe way to solve that problem
Usage:
---
class NewElement: Element {
    // inherits constructors of Element
    mixin inheritConstructor;
    // your constructors
    this(string thing, int notthing) { /+ ... +/ }
}
---
*/
mixin template inheritConstructor( ) {
    this(A...)(A args) { super(args); }
}

/// Base for all TUI elements
class Element {
    private App _app;
    private Element _parent = null;
    private Element[] _children = [];
    private bool _isRoot = false;
    private bool _isInit = false;
    private uvec2 _pos;

    /// Returns App element is attached to
    mixin getter!_app;
    /// Returns current parent
    mixin getter!_parent;
    /// Returns array of children
    mixin getter!_children;
    /// Returns true if element is root
    mixin getter!_isRoot;
    /// Returns true if Element was initialized
    mixin getter!_isInit;
    /// Element position property
    mixin property!_pos;

    this() {}

    /// Adds child to element
    public final void addChild(Element child) {
        _children ~= child;
        if (!child.isInit) {
            child.setApp(app);
            child.propagateCreate();
        }
    }

    /// Removes child from element
    public final void removeChild(Element child) {
        if (!hasChild(child)) return;
        size_t p = children.countUntil(child);
        children.remove(p);
    }

    /// Moves child to position
    public final void moveChild(Element child, size_t index) {
        if (!hasChild(child)) return;
        removeChild(child);
        _children.insertInPlace(index, child);
    }

    /// Returns true if this has child
    public final bool hasChild(Element child) {
        if (children.length == 0) return false;
        return children.canFind(child);
    }

    /// Returns amount of children element has
    public final size_t childCount() {
        return children.length;
    }

    /// Returns child at pos
    public final Element getChild(size_t index) {
        return children[index];
    }

    /// Returns child at pos
    public final long getChildPos(Element child) {
        if (!hasChild(child)) return -1;
        return children.countUntil(child);
    }
    
    /// Reparents element if it's not root
    public final void setParent(Element p_parent) {
        if (isRoot) return;
        if (_parent !is null) _parent.removeChild(this);
        p_parent.addChild(this);
        _parent = p_parent;
    }

    /// Sets element as root if there's no root already
    public final void setRoot() {
        if (app is null) return;
        if (app.rootElement !is null) return;
        _isRoot = true;
    }

    /// Sets App element attached to if it's not already defined
    public final void setApp(App p_app) {
        if (app !is null) return;
        _app = p_app;
    }

    /// Propagates internal function calls
    public final void propagateCreate() {
        _create();
        create();
        foreach (child; children) if (!child.isInit) { child.propagateCreate(); }
        _isInit = true;
    }

    /// Ditto
    public final void propagateDestroy() {
        _destroy();
        destroy();
        foreach (child; children) child.propagateDestroy();
        if (_parent !is null) _parent.removeChild(this);
    }
    
    /// Ditto
    public final void propagateUpdate(float delta) {
        _update(delta);
        update(delta);
        foreach (child; children) child.propagateUpdate(delta);
    }
    
    /// Ditto
    public final void propagateInput(InputEvent e) {
        if (e.isProcessed) return;
        _input(e);
        if (e.isProcessed) return;
        input(e);
        if (e.isProcessed) return;
        foreach (child; children) {
            child.propagateInput(e);
            if (e.isProcessed) return;
        }
    }
    
    /// Ditto
    public final void propagateRender() {
        _render();
        render();
        foreach (child; children) child.propagateRender();
    }
    
    /**
    Public create method. Can be overriden. 
    Called when element is first added as child
    */
    public void create() {}
    /**
    Public destroy method. Can be overriden. 
    Called when element is queued for deletion or 
    when App is being closed
    */
    public void destroy() {}
    /**
    Public update method. Can be overriden.
    Called each frame
    */
    public void update(float delta) {}
    /**
    Public input method. Can be overriden.
    Called each frame if there's unprocessed
    input event
    */
    public void input(InputEvent e) {}
    /**
    Public render method. Can be overriden.
    Called each frame if render is needed
    */
    public void render() {}

    /**
    Private create method. Used for internal logic
    Called when element is first added as child
    */
    protected void _create() {}
    /**
    Private destroy method. Used for internal logic
    Called when element is queued for deletion or 
    when App is being closed
    */
    protected void _destroy() {}
    /**
    Private update method. Used for internal logic
    Called each frame
    */
    protected void _update(float delta) {}
    /**
    Private input method. Used for internal logic
    Called each frame if there's unprocessed
    input event
    */
    protected void _input(InputEvent e) {}
    /**
    Private render method. Used for internal logic
    Called each frame if render is needed
    */
    protected void _render() {}
}
