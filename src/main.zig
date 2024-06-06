const std = @import("std");
const c = @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("X11/XF86keysym.h");
    @cInclude("X11/keysym.h");
    @cInclude("X11/XKBlib.h");
    @cInclude("signal.h");
    @cInclude("unistd.h");
    @cInclude("stdlib.h");
});

const ChildProcess = std.ChildProcess;
const ArrayList = std.ArrayList;
const page_alloc = std.heap.page_allocator;

fn mod_clean(mask: u32) u32 {
    return (mask & (c.ShiftMask|c.ControlMask|c.Mod1Mask|c.Mod2Mask|c.Mod3Mask|c.Mod4Mask|c.Mod5Mask));
}

// TODO: parse a config file or whatever

const MOD = c.Mod4Mask;
const TOPGAP = 18;
const GAPSIZE = 6;
const MODE = Mode.tile;
// TODO: getenv for this
const CONFIGPATH = "/home/ren/.config/fuckwm/fuckwmrc &";

const Arg = struct {
    com: [*c]const [*c]const u8 = undefined,
    i: i32 = 0,
    m: Mode = MODE,
};

const Key = struct {
    mod: u32,
    key: c.KeySym,
    fun: *const fn (fuck: *Fuck, arg: Arg) anyerror!void,
    arg: Arg,
};

const term_cmd = [_][*c]const u8{ "kitty", 0 };
const menu_cmd = [_][*c]const u8{ "dmenu_run", 0 };

const keys = [_]Key{
    Key{ .mod = MOD,             .key = c.XK_Return, .fun = run,             .arg = Arg{ .com = &term_cmd } },
    Key{ .mod = MOD,             .key = c.XK_d,      .fun = run,             .arg = Arg{ .com = &menu_cmd } },

    Key{ .mod = MOD,             .key = c.XK_f,      .fun = win_full,        .arg = Arg{ .i = 0 } },
    Key{ .mod = MOD,             .key = c.XK_q,      .fun = win_kill,        .arg = Arg{ .i = 0 } },
    Key{ .mod = MOD,             .key = c.XK_c,      .fun = win_center,      .arg = Arg{ .i = 0 } },
    Key{ .mod = MOD|c.ShiftMask, .key = c.XK_space,  .fun = win_float,       .arg = Arg{ .i = 0 } },

    Key{ .mod = MOD,             .key = c.XK_h,      .fun = incmaster,       .arg = Arg{ .i = -10 } },
    Key{ .mod = MOD,             .key = c.XK_l,      .fun = incmaster,       .arg = Arg{ .i =  10 } },

    Key{ .mod = MOD,             .key = c.XK_Tab,    .fun = win_next,        .arg = Arg{ .i = 0 } },
    Key{ .mod = MOD|c.ShiftMask, .key = c.XK_Tab,    .fun = win_prev,        .arg = Arg{ .i = 0 } },
    Key{ .mod = MOD,             .key = c.XK_j,      .fun = win_prev,        .arg = Arg{ .i = 0 } },
    Key{ .mod = MOD,             .key = c.XK_k,      .fun = win_next,        .arg = Arg{ .i = 0 } },
    Key{ .mod = MOD|c.ShiftMask, .key = c.XK_j,      .fun = win_rotate_prev, .arg = Arg{ .i = 0 } },
    Key{ .mod = MOD|c.ShiftMask, .key = c.XK_k,      .fun = win_rotate_next, .arg = Arg{ .i = 0 } },

    Key{ .mod = MOD|c.ShiftMask, .key = c.XK_t,      .fun = tile_mode,       .arg = Arg{ .m = Mode.tile } },
    Key{ .mod = MOD|c.ShiftMask, .key = c.XK_m,      .fun = tile_mode,       .arg = Arg{ .m = Mode.monocle } },
    Key{ .mod = MOD|c.ShiftMask, .key = c.XK_f,      .fun = tile_mode,       .arg = Arg{ .m = Mode.float } },

    Key{ .mod = MOD,             .key = c.XK_1,      .fun = switch_ws,       .arg = Arg{ .i = 0 } },
    Key{ .mod = MOD|c.ShiftMask, .key = c.XK_1,      .fun = win_to_ws,       .arg = Arg{ .i = 0 } },
    Key{ .mod = MOD,             .key = c.XK_2,      .fun = switch_ws,       .arg = Arg{ .i = 1 } },
    Key{ .mod = MOD|c.ShiftMask, .key = c.XK_2,      .fun = win_to_ws,       .arg = Arg{ .i = 1 } },
    Key{ .mod = MOD,             .key = c.XK_3,      .fun = switch_ws,       .arg = Arg{ .i = 2 } },
    Key{ .mod = MOD|c.ShiftMask, .key = c.XK_3,      .fun = win_to_ws,       .arg = Arg{ .i = 2 } },
    Key{ .mod = MOD,             .key = c.XK_4,      .fun = switch_ws,       .arg = Arg{ .i = 3 } },
    Key{ .mod = MOD|c.ShiftMask, .key = c.XK_4,      .fun = win_to_ws,       .arg = Arg{ .i = 3 } },
    Key{ .mod = MOD,             .key = c.XK_5,      .fun = switch_ws,       .arg = Arg{ .i = 4 } },
    Key{ .mod = MOD|c.ShiftMask, .key = c.XK_5,      .fun = win_to_ws,       .arg = Arg{ .i = 4 } },
    Key{ .mod = MOD,             .key = c.XK_6,      .fun = switch_ws,       .arg = Arg{ .i = 5 } },
    Key{ .mod = MOD|c.ShiftMask, .key = c.XK_6,      .fun = win_to_ws,       .arg = Arg{ .i = 5 } },
    Key{ .mod = MOD,             .key = c.XK_7,      .fun = switch_ws,       .arg = Arg{ .i = 6 } },
    Key{ .mod = MOD|c.ShiftMask, .key = c.XK_7,      .fun = win_to_ws,       .arg = Arg{ .i = 6 } },
    Key{ .mod = MOD,             .key = c.XK_8,      .fun = switch_ws,       .arg = Arg{ .i = 7 } },
    Key{ .mod = MOD|c.ShiftMask, .key = c.XK_8,      .fun = win_to_ws,       .arg = Arg{ .i = 7 } },
    Key{ .mod = MOD,             .key = c.XK_9,      .fun = switch_ws,       .arg = Arg{ .i = 8 } },
    Key{ .mod = MOD|c.ShiftMask, .key = c.XK_9,      .fun = win_to_ws,       .arg = Arg{ .i = 8 } },
    Key{ .mod = MOD,             .key = c.XK_0,      .fun = switch_ws,       .arg = Arg{ .i = 9 } },
    Key{ .mod = MOD|c.ShiftMask, .key = c.XK_0,      .fun = win_to_ws,       .arg = Arg{ .i = 9 } },
};

fn run(fuck: *Fuck, arg: Arg) !void {
    if (c.fork() != 0) return;
    if (fuck.display != null) {
        _ = c.close(c.ConnectionNumber(fuck.display));
    }
    _ = c.setsid();
    _ = c.execvp(arg.com[0], @ptrCast(arg.com));
}

fn tile_mode(fuck: *Fuck, arg: Arg) !void {
    if (fuck.desktop[fuck.ws].mode == arg.m) return;
    fuck.desktop[fuck.ws].last_mode = fuck.desktop[fuck.ws].mode;
    fuck.desktop[fuck.ws].mode = arg.m;
    win_tile(fuck);
}

fn win_kill(fuck: *Fuck, arg: Arg) !void {
    _ = arg;
    const ws = fuck.desktop[fuck.ws];
    if (ws.clients.items.len > 0) {
        _ = c.XKillClient(fuck.display, ws.clients.items[ws.cur].window);
    }
}

fn win_prev(fuck: *Fuck, arg: Arg) !void {
    _ = arg;
    const ws = &fuck.desktop[fuck.ws];
    if (ws.clients.items.len == 0) return;
    if (ws.clients.items[ws.cur].is_full) return;
    if (ws.cur == 0) {
        ws.cur = ws.clients.items.len - 1;
    } else {
        ws.cur -= 1;
    }
    win_focus(fuck, ws.cur);
}

fn win_next(fuck: *Fuck, arg: Arg) !void {
    _ = arg;
    const ws = &fuck.desktop[fuck.ws];
    if (ws.clients.items.len == 0) return;
    if (ws.clients.items[ws.cur].is_full) return;
    if (ws.cur == ws.clients.items.len - 1) {
        ws.cur = 0;
    } else {
        ws.cur += 1;
    }
    win_focus(fuck, ws.cur);
}

fn win_rotate_prev(fuck: *Fuck, arg: Arg) !void {
    _ = arg;
    const ws = &fuck.desktop[fuck.ws];
    if (ws.clients.items.len < 2) return;
    if (ws.clients.items[ws.cur].is_full) return;
    const l = if (ws.cur == 0) (ws.clients.items.len - 1) else (ws.cur - 1);
    const s = ws.clients.items[l];
    ws.*.clients.items[l] = ws.clients.items[ws.cur];
    ws.*.clients.items[ws.cur] = s;
    ws.cur = l;
    win_tile(fuck);
}

fn win_rotate_next(fuck: *Fuck, arg: Arg) !void {
    _ = arg;
    const ws = &fuck.desktop[fuck.ws];
    if (ws.clients.items.len < 2) return;
    if (ws.clients.items[ws.cur].is_full) return;
    const l = if (ws.cur == ws.clients.items.len - 1) (0) else (ws.cur + 1);
    const s = ws.clients.items[l];
    ws.*.clients.items[l] = ws.clients.items[ws.cur];
    ws.*.clients.items[ws.cur] = s;
    ws.cur = l;
    win_tile(fuck);
}

fn incmaster(fuck: *Fuck, arg: Arg) !void {
    // oh dear god, please forgive my utter foolishness.
    // i wanted to do something as simple as master_w += arg.i
    // but zig wouldn't let me do it with different integer types
    // so i got frustrated. please forgive this foolish creature.
    // i shall atone for my sins with my life.
    const bruh = @as(u32, @intCast(if (arg.i < 0) (0-arg.i) else (arg.i)));
    if (arg.i < 0) {
        if (fuck.desktop[fuck.ws].master_w <= 100)
            return;
        fuck.desktop[fuck.ws].master_w -= bruh;
    }
    else {
        if (fuck.desktop[fuck.ws].master_w >= fuck.screen_w - 200)
            return;
        fuck.desktop[fuck.ws].master_w += bruh;
    }
    win_tile(fuck);
}

fn win_full(fuck: *Fuck, arg: Arg) !void {
    _ = arg;
    const ws = &fuck.desktop[fuck.ws];
    if (ws.clients.items.len == 0) return;

    const cw = &ws.clients.items[ws.cur];
    cw.is_full = !cw.is_full;
    if (cw.is_full) {
        _ = c.XMoveResizeWindow(fuck.display, cw.window, 0, 0, fuck.screen_w, fuck.screen_h);
    } else {
        _ = c.XMoveResizeWindow(fuck.display, cw.window, cw.x, cw.y, cw.w, cw.h);
    }
    win_tile(fuck);
}

fn win_center(fuck: *Fuck, arg: Arg) !void {
    _ = arg;
    const ws = &fuck.desktop[fuck.ws];
    if (ws.clients.items.len == 0) return;
    var cw = ws.clients.items[ws.cur];
    if (cw.is_full or !cw.is_float) return;

    const x = @as(i32, @intCast((fuck.screen_w / 2) - (cw.w / 2)));
    const y = @as(i32, @intCast((fuck.screen_h / 2) - (cw.h / 2)));

    _ = c.XMoveResizeWindow(fuck.display, cw.window, x, y, cw.w, cw.h);
    try cw.get_size(fuck);
}

fn win_float(fuck: *Fuck, arg: Arg) !void {
    _ = arg;
    const ws = &fuck.desktop[fuck.ws];
    if (ws.clients.items.len == 0) return;
    var cw = &ws.clients.items[ws.cur];
    if (cw.is_full) return;
    cw.is_float = !cw.is_float;
    cw.float(fuck);
    win_tile(fuck);
}

fn win_to_ws(fuck: *Fuck, arg: Arg) !void {
    if (arg.i == fuck.ws) return;
    const cws = &fuck.desktop[fuck.ws];
    const ws = fuck.ws;
    const wn = cws.clients.items[cws.cur].window;

    _ = c.XUnmapWindow(fuck.display, wn);
    try win_del(fuck, wn);
    if (fuck.desktop[fuck.ws].cur > 0) {
        fuck.desktop[fuck.ws].cur -= 1;
    } else {
        fuck.desktop[fuck.ws].cur = 0;
    }
    if (fuck.desktop[fuck.ws].clients.items.len > 0) {
        win_focus(fuck, fuck.desktop[fuck.ws].cur);
    }
    fuck.ws = @as(u32, @intCast(arg.i));
    try win_add(fuck, wn);
    fuck.ws = ws;
    win_tile(fuck);
}

fn switch_ws(fuck: *Fuck, arg: Arg) !void {
    if (arg.i == fuck.ws) return;

    const cws = &fuck.desktop[fuck.ws];
    for (cws.clients.items) |client| {
        _ = c.XUnmapWindow(fuck.display, client.window);
    }

    fuck.ws = @as(u32, @intCast(arg.i));
    for (fuck.desktop[fuck.ws].clients.items) |client| {
        _ = c.XMapWindow(fuck.display, client.window);
    }
    win_focus(fuck, fuck.desktop[fuck.ws].cur);
    win_tile(fuck);
}

const Client = struct {
    window: c.Window,
    x: i32 = 0,
    y: i32 = 0,
    w: u32 = 0,
    h: u32 = 0,
    is_full: bool = false,
    is_float: bool = false,

    fn get_size(self: *Client, f: *Fuck) !void {
        var wa: c.XWindowAttributes = undefined;
        _ = c.XGetWindowAttributes(f.display, self.window, &wa);
        self.x = wa.x;
        self.y = wa.y;
        self.w = @as(u32, @intCast(wa.width));
        self.h = @as(u32, @intCast(wa.height));
        if (self.w == 0 or self.h == 0)
            return FuckError.InvalidWindowSize;
    }

    fn float(self: *Client, f: *Fuck) void {
        _ = c.XMoveResizeWindow(f.display, self.window, self.x, self.y, self.w, self.h);
    }
};

const Mode = enum {
    tile,
    monocle,
    float,
};

const Desktop = struct {
    clients: ArrayList(Client),
    mode: Mode = MODE,
    last_mode: Mode = MODE,
    master_w: u32,
    cur: u64,
};

const FuckError = error {
    XOpenDisplayFail,
    NoClientForWindow,
    InvalidTileMode,
    InvalidWindowSize,
};

const Fuck = struct {
    display: ?*c.Display,
    root: c.Window,
    mouse: c.XButtonEvent,
    hover_attr: c.XWindowAttributes,
    screen_w: u32,
    screen_h: u32,
    desktop: [10]Desktop,
    ws: u32,

    fn init() !Fuck {
        var f: Fuck = undefined;
        f.ws = 0;
        f.display = c.XOpenDisplay(0);
        if (f.display == null)
            return FuckError.XOpenDisplayFail;

        const s: c_int = c.DefaultScreen(f.display);
        f.root = @intCast(c.RootWindow(f.display, s));
        f.screen_w = @intCast(c.XDisplayWidth(f.display, s));
        f.screen_h = @intCast(c.XDisplayHeight(f.display, s));

        for (0..10) |i| {
            f.desktop[i] = Desktop{
                .clients = ArrayList(Client).init(page_alloc),
                .master_w = f.screen_w / 2,
                .cur = 0,
            };
        }

        return f;
    }

    fn deinit(f: *Fuck) void {
        for (0..10) |i| {
            f.desktop[i].clients.deinit();
        }
    }

    fn client_from_window(f: *Fuck, w: c.Window) !u64 {
        for (f.desktop[f.ws].clients.items, 0..) |cur, i| {
            if (cur.window == w) {
                return i;
            }
        }
        return FuckError.NoClientForWindow;
    }
};

fn win_tile(fuck: *Fuck) void {
    const ws = fuck.desktop[fuck.ws];
    if (ws.clients.items.len == 0) return;
    if (ws.clients.items[ws.cur].is_full) return;

    const mode = if (ws.mode == Mode.float) ws.last_mode else ws.mode;

    switch (mode) {
        Mode.monocle => tile_monocle(fuck, &ws),
        Mode.tile => tile_tile(fuck, &ws),
        else => {},
    }
}

fn tile_monocle(fuck: *Fuck, ws: *const Desktop) void {
    for (ws.clients.items) |wn| {
        if (wn.is_float) continue;
        _ = c.XMoveResizeWindow(fuck.display, wn.window,
                GAPSIZE,
                GAPSIZE + TOPGAP,
                fuck.screen_w - GAPSIZE * 2,
                fuck.screen_h - TOPGAP - GAPSIZE * 2);
    }

    tile_float(fuck, ws);
}

fn tile_tile(fuck: *Fuck, ws: *const Desktop) void {
    const master_w = ws.master_w;
    const stack_w = fuck.screen_w - ws.master_w;
    var sz: u32 = 0;
    var master: u32 = 0;

    for (ws.clients.items, 0..) |wn, i| {
        if (!wn.is_float) {
            if (master == 0 and ws.clients.items[master].is_float)
                master = @as(u32, @intCast(i));
            sz += 1;
        }
    }

    // only one tiled client
    if (ws.clients.items.len == 1 or sz <= 1) {
        tile_monocle(fuck, ws);
        return;
    }

    var wn = ws.clients.items[master];
    _ = c.XMoveResizeWindow(fuck.display, wn.window,
            GAPSIZE,
            GAPSIZE + TOPGAP,
            @as(u32, @intCast(master_w - GAPSIZE)),
            fuck.screen_h - TOPGAP - GAPSIZE * 2);

    var count: u32 = 0;
    const h = (fuck.screen_h - TOPGAP - GAPSIZE) / (sz-1);
    for ((master+1)..ws.clients.items.len) |i| {
        wn = ws.clients.items[i];
        if (wn.is_float) continue;

        _ = c.XMoveResizeWindow(fuck.display, wn.window,
                @as(i32, @intCast(master_w + GAPSIZE)),
                @as(i32, @intCast(count * h + GAPSIZE + TOPGAP)),
                @as(u32, @intCast(stack_w - GAPSIZE * 2)),
                @as(u32, @intCast(h - GAPSIZE)));
        count += 1;
    }

    tile_float(fuck, ws);
}

fn tile_float(fuck: *Fuck, ws: *const Desktop) void {
    for (ws.clients.items) |wn| {
        if (!wn.is_float) continue;
        _ = c.XRaiseWindow(fuck.display, wn.window);
    }
    // make sure focused window is on top
    if (ws.clients.items[ws.cur].is_float)
        _ = c.XRaiseWindow(fuck.display, ws.clients.items[ws.cur].window);
}

fn win_focus(fuck: *Fuck, client: u64) void {
    if (fuck.desktop[fuck.ws].clients.items.len == 0) return;
    const cc = fuck.desktop[fuck.ws].clients.items[client];
    _ = c.XSetInputFocus(fuck.display, cc.window, c.RevertToParent, c.CurrentTime);
    _ = c.XRaiseWindow(fuck.display, cc.window);
    fuck.desktop[fuck.ws].cur = client;
    win_tile(fuck);
}

fn win_add(fuck: *Fuck, wn: c.Window) !void {
    var client = Client{
        .window = wn,
        .is_full = false,
        .is_float = (fuck.desktop[fuck.ws].mode == Mode.float),
    };
    try client.get_size(fuck);
    try fuck.desktop[fuck.ws].clients.append(client);
}

fn win_del(fuck: *Fuck, wn: c.Window) !void {
    const client = try fuck.client_from_window(wn);
    const ws = &fuck.desktop[fuck.ws];
    _ = ws.clients.orderedRemove(client);
}

fn map_request(fuck: *Fuck, ev: *c.XEvent) !void {
    const wn = ev.*.xmap.window;
    if (wn == c.None) return;

    _ = c.XSelectInput(fuck.display, wn, c.StructureNotifyMask|c.EnterWindowMask);
    try win_add(fuck, wn);
    _ = c.XMapWindow(fuck.display, wn);
    win_focus(fuck, fuck.desktop[fuck.ws].clients.items.len - 1);
    try win_center(fuck, .{});
    win_tile(fuck);
}

fn notify_destroy(fuck: *Fuck, ev: *c.XEvent) !void {
    const cl = fuck.client_from_window(ev.*.xunmap.window);
    if (cl == FuckError.NoClientForWindow) return;
    try win_del(fuck, ev.*.xdestroywindow.window);
    if (fuck.desktop[fuck.ws].cur > 0) {
        fuck.desktop[fuck.ws].cur -= 1;
    } else {
        fuck.desktop[fuck.ws].cur = 0;
    }
    _ = c.XSetInputFocus(fuck.display, fuck.root, c.RevertToParent, c.CurrentTime);
    if (fuck.desktop[fuck.ws].clients.items.len > 0) {
        win_focus(fuck, fuck.desktop[fuck.ws].cur);
        win_tile(fuck);
    }
}

fn notify_unmap(fuck: *Fuck, ev: *c.XEvent) !void {
    const cl = fuck.client_from_window(ev.*.xunmap.window);
    if (cl == FuckError.NoClientForWindow) return;
    try win_del(fuck, ev.*.xunmap.window);
    if (fuck.desktop[fuck.ws].cur > 0) {
        fuck.desktop[fuck.ws].cur -= 1;
    } else {
        fuck.desktop[fuck.ws].cur = 0;
    }
    _ = c.XSetInputFocus(fuck.display, fuck.root, c.RevertToParent, c.CurrentTime);
    if (fuck.desktop[fuck.ws].clients.items.len > 0) {
        win_focus(fuck, fuck.desktop[fuck.ws].cur);
        win_tile(fuck);
    }
}

fn button_press(fuck: *Fuck, ev: *c.XEvent) !void {
    const wn = ev.*.xbutton.subwindow;
    if (wn == c.None) return;
    const client = try fuck.client_from_window(wn);
    try fuck.desktop[fuck.ws].clients.items[client].get_size(fuck);

    _ = c.XRaiseWindow(fuck.display, wn);
    win_focus(fuck, client);
    fuck.mouse = ev.*.xbutton;
    _ = c.XGetWindowAttributes(fuck.display, wn, &fuck.hover_attr);
}

fn button_release(fuck: *Fuck) !void {
    fuck.mouse.subwindow = c.None;
}

fn notify_motion(fuck: *Fuck, ev: *c.XEvent) !void {
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
    win_tile(fuck);
}

fn configure_request(fuck: *Fuck, ev: *c.XEvent) !void {
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
    win_tile(fuck);
}

fn key_press(fuck: *Fuck, ev: *c.XEvent) !void {
    const keysym = c.XkbKeycodeToKeysym(fuck.display, @truncate(ev.xkey.keycode), 0, 0);

    for (keys) |key| {
        if (key.key == keysym and mod_clean(key.mod) == mod_clean(ev.xkey.state)) {
            try key.fun(fuck, key.arg);
        }
    }
}

fn input_grab(fuck: *Fuck) !void {
    _ = c.XUngrabKey(fuck.display, c.AnyKey, c.AnyModifier, fuck.root);

    var code: c.KeyCode = undefined;
    for (keys, 0..) |_, i| {
        code = c.XKeysymToKeycode(fuck.display, keys[i].key);
        if (code != 0) {
            _ = c.XGrabKey(fuck.display, code, keys[i].mod, fuck.root, c.True, c.GrabModeAsync, c.GrabModeAsync);
        }
    }

    _ = c.XGrabButton(fuck.display, 1, MOD, fuck.root, c.True,
            c.ButtonPressMask|c.ButtonReleaseMask|c.PointerMotionMask,
            c.GrabModeAsync, c.GrabModeAsync, c.None, c.None);
    _ = c.XGrabButton(fuck.display, 3, MOD, fuck.root, c.True,
            c.ButtonPressMask|c.ButtonReleaseMask|c.PointerMotionMask,
            c.GrabModeAsync, c.GrabModeAsync, c.None, c.None);
}

fn xerror(display: ?*c.Display, event: [*c]c.XErrorEvent) callconv(.C) c_int {
    _ = display;
    _ = event;
    return 0;
}

pub fn handle_events(fuck: *Fuck, ev: *c.XEvent) !void {
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

pub fn main() !void {
    var ev: c.XEvent = undefined;
    var fuck = try Fuck.init();
    defer fuck.deinit();
    _ = c.XSetErrorHandler(&xerror);
    _ = c.XSelectInput(fuck.display, fuck.root, c.SubstructureRedirectMask);
    _ = c.XDefineCursor(fuck.display, fuck.root, c.XCreateFontCursor(fuck.display, 68));
    try input_grab(&fuck);
    _ = c.system(CONFIGPATH);

    while (true) {
        _ = c.XNextEvent(fuck.display, &ev);
        handle_events(&fuck, &ev) catch {};
    }
}
