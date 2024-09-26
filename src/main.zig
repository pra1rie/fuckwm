const std = @import("std");
const c = @import("c.zig");
const fuckwm = @import("fuckwm.zig");
const config = @import("config.zig");
const func = @import("func.zig");

// TODO: (maybe) parse a config file or whatever

fn map_request(fuck: *fuckwm.Fuck, ev: *c.XEvent) !void {
    const wn = ev.*.xmap.window;
    const ws = &fuck.desktop[fuck.ws];
    if (wn == c.None) return;
    if (ws.clients.items.len != 0)
        ws.clients.items[ws.cur].is_full = false;

    _ = c.XSelectInput(fuck.display, wn, c.StructureNotifyMask|c.EnterWindowMask);
    try fuckwm.win_add(fuck, wn);
    _ = c.XMapWindow(fuck.display, wn);
    fuckwm.win_focus(fuck, ws.clients.items.len - 1);
    try func.win_center(fuck, .{});
    fuckwm.win_tile(fuck);
}

fn notify_destroy(fuck: *fuckwm.Fuck, ev: *c.XEvent) !void {
    const cl = fuck.client_from_window(ev.*.xunmap.window);
    if (cl == fuckwm.FuckError.NoClientForWindow) return;
    try fuckwm.win_del(fuck, ev.*.xdestroywindow.window);
    if (fuck.desktop[fuck.ws].cur > 0) {
        fuck.desktop[fuck.ws].cur -= 1;
    } else {
        fuck.desktop[fuck.ws].cur = 0;
    }
    _ = c.XSetInputFocus(fuck.display, fuck.root, c.RevertToParent, c.CurrentTime);
    if (fuck.desktop[fuck.ws].clients.items.len > 0) {
        fuckwm.win_focus(fuck, fuck.desktop[fuck.ws].cur);
        fuckwm.win_tile(fuck);
    }
}

fn notify_unmap(fuck: *fuckwm.Fuck, ev: *c.XEvent) !void {
    const cl = fuck.client_from_window(ev.*.xunmap.window);
    if (cl == fuckwm.FuckError.NoClientForWindow) return;
    try fuckwm.win_del(fuck, ev.*.xunmap.window);
    if (fuck.desktop[fuck.ws].cur > 0) {
        fuck.desktop[fuck.ws].cur -= 1;
    } else {
        fuck.desktop[fuck.ws].cur = 0;
    }
    _ = c.XSetInputFocus(fuck.display, fuck.root, c.RevertToParent, c.CurrentTime);
    if (fuck.desktop[fuck.ws].clients.items.len > 0) {
        fuckwm.win_focus(fuck, fuck.desktop[fuck.ws].cur);
        fuckwm.win_tile(fuck);
    }
}

fn button_press(fuck: *fuckwm.Fuck, ev: *c.XEvent) !void {
    const wn = ev.*.xbutton.subwindow;
    if (wn == c.None) return;
    const client = try fuck.client_from_window(wn);
    try fuck.desktop[fuck.ws].clients.items[client].get_size(fuck);

    _ = c.XRaiseWindow(fuck.display, wn);
    fuckwm.win_focus(fuck, client);
    fuck.mouse = ev.*.xbutton;
    _ = c.XGetWindowAttributes(fuck.display, wn, &fuck.hover_attr);
}

fn button_release(fuck: *fuckwm.Fuck) !void {
    fuck.mouse.subwindow = c.None;
}

fn notify_motion(fuck: *fuckwm.Fuck, ev: *c.XEvent) !void {
    if (fuck.mouse.subwindow == c.None) return;
    const client = try fuck.client_from_window(fuck.mouse.subwindow);
    const cw = &fuck.desktop[fuck.ws];
    var cc = &cw.clients.items[client];
    if (cc.is_full) return;
    cc.is_float = true;

    const ha = fuck.hover_attr;
    const xd = ev.xbutton.x_root - fuck.mouse.x_root;
    const yd = ev.xbutton.y_root - fuck.mouse.y_root;

    _ = c.XMoveResizeWindow(fuck.display, fuck.mouse.subwindow,
            ha.x + (if (fuck.mouse.button == 1) xd else 0),
            ha.y + (if (fuck.mouse.button == 1) yd else 0),
            @max(100, ha.width + (if (fuck.mouse.button == 3) xd else 0)),
            @max(100, ha.height + (if (fuck.mouse.button == 3) yd else 0)));
    try cc.get_size(fuck);
    fuckwm.win_tile(fuck);
}

fn configure_request(fuck: *fuckwm.Fuck, ev: *c.XEvent) !void {
    const cr = &ev.*.xconfigurerequest;
    var wc = c.XWindowChanges{
        .x = cr.x,
        .y = cr.y,
        .width = cr.width,
        .height = cr.height,
        .sibling = cr.above,
        .stack_mode = cr.detail
    };

    if (cr.width == 0 or cr.height == 0 or cr.window == c.None) return;
    _ = c.XConfigureWindow(fuck.display, cr.window, @as(u32, @intCast(cr.value_mask)), &wc);
    fuckwm.win_tile(fuck);
}

fn key_press(fuck: *fuckwm.Fuck, ev: *c.XEvent) !void {
    const keysym = c.XkbKeycodeToKeysym(fuck.display, @truncate(ev.xkey.keycode), 0, 0);

    for (config.keys) |key| {
        if (key.key == keysym and fuckwm.mod_clean(key.mod) == fuckwm.mod_clean(ev.xkey.state)) {
            try key.fun(fuck, key.arg);
        }
    }
}

fn input_grab(fuck: *fuckwm.Fuck) void {
    _ = c.XUngrabKey(fuck.display, c.AnyKey, c.AnyModifier, fuck.root);

    var code: c.KeyCode = undefined;
    for (config.keys, 0..) |_, i| {
        code = c.XKeysymToKeycode(fuck.display, config.keys[i].key);
        if (code != 0) {
            _ = c.XGrabKey(fuck.display, code, config.keys[i].mod,
                fuck.root, c.True, c.GrabModeAsync, c.GrabModeAsync);
        }
    }

    _ = c.XGrabButton(fuck.display, 1, config.MOD, fuck.root, c.True,
            c.ButtonPressMask|c.ButtonReleaseMask|c.PointerMotionMask,
            c.GrabModeAsync, c.GrabModeAsync, c.None, c.None);
    _ = c.XGrabButton(fuck.display, 3, config.MOD, fuck.root, c.True,
            c.ButtonPressMask|c.ButtonReleaseMask|c.PointerMotionMask,
            c.GrabModeAsync, c.GrabModeAsync, c.None, c.None);
}

fn handle_events(fuck: *fuckwm.Fuck, ev: *c.XEvent) !void {
    switch (ev.type) {
        c.MapRequest       => try map_request(fuck, ev),
        c.DestroyNotify    => try notify_destroy(fuck, ev),
        c.UnmapNotify      => try notify_unmap(fuck, ev),
        c.ButtonPress      => try button_press(fuck, ev),
        c.ButtonRelease    => try button_release(fuck),
        c.MotionNotify     => try notify_motion(fuck, ev),
        c.ConfigureRequest => try configure_request(fuck, ev),
        c.KeyPress         => try key_press(fuck, ev),
        else => {},
    }
}

fn xerror(display: ?*c.Display, event: [*c]c.XErrorEvent) callconv(.C) c_int {
    _ = display;
    _ = event;
    return 0;
}

pub fn main() !void {
    var ev: c.XEvent = undefined;
    var fuck = try fuckwm.Fuck.init();
    defer fuck.deinit();
    _ = c.XSetErrorHandler(&xerror);
    _ = c.XSelectInput(fuck.display, fuck.root, c.SubstructureRedirectMask);
    _ = c.XDefineCursor(fuck.display, fuck.root, c.XCreateFontCursor(fuck.display, 68));
    input_grab(&fuck);

    while (true) {
        _ = c.XNextEvent(fuck.display, &ev);
        handle_events(&fuck, &ev) catch {};
    }
}
