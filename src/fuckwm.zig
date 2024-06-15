const std = @import("std");
const c = @import("c.zig");
const config = @import("config.zig");

pub const ChildProcess = std.ChildProcess;
pub const ArrayList = std.ArrayList;
pub const page_alloc = std.heap.page_allocator;

pub fn mod_clean(mask: u32) u32 {
    return (mask & (c.ShiftMask|c.ControlMask|c.Mod1Mask|c.Mod2Mask|c.Mod3Mask|c.Mod4Mask|c.Mod5Mask));
}

pub const Mode = enum {
    master_stack,
    monocle,
    float,
};

pub const Desktop = struct {
    clients: ArrayList(Client),
    mode: Mode = config.MODE,
    last_mode: Mode = config.MODE,
    master_w: u32,
    cur: u64,
};

pub const FuckError = error {
    XOpenDisplayFail,
    NoClientForWindow,
    InvalidWindowSize,
};

pub const Fuck = struct {
    display: ?*c.Display,
    root: c.Window,
    mouse: c.XButtonEvent,
    hover_attr: c.XWindowAttributes,
    screen_w: u32,
    screen_h: u32,
    desktop: [10]Desktop,
    ws: u32,

    pub fn init() !Fuck {
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

    pub fn deinit(f: *Fuck) void {
        for (0..10) |i| {
            f.desktop[i].clients.deinit();
        }
    }

    pub fn client_from_window(f: *Fuck, w: c.Window) !u64 {
        for (f.desktop[f.ws].clients.items, 0..) |cur, i| {
            if (cur.window == w) {
                return i;
            }
        }
        return FuckError.NoClientForWindow;
    }
};

pub const Client = struct {
    window: c.Window,
    x: i32 = 0,
    y: i32 = 0,
    w: u32 = 0,
    h: u32 = 0,
    is_full: bool = false,
    is_float: bool = false,

    pub fn get_size(self: *Client, f: *Fuck) !void {
        var wa: c.XWindowAttributes = undefined;
        _ = c.XGetWindowAttributes(f.display, self.window, &wa);
        self.x = wa.x;
        self.y = wa.y;
        self.w = @as(u32, @intCast(wa.width));
        self.h = @as(u32, @intCast(wa.height));
        if (self.w == 0 or self.h == 0)
            return FuckError.InvalidWindowSize;
    }
};

pub fn win_focus(fuck: *Fuck, client: u64) void {
    if (fuck.desktop[fuck.ws].clients.items.len == 0) return;
    const cc = fuck.desktop[fuck.ws].clients.items[client];
    _ = c.XSetInputFocus(fuck.display, cc.window, c.RevertToParent, c.CurrentTime);
    _ = c.XRaiseWindow(fuck.display, cc.window);
    fuck.desktop[fuck.ws].cur = client;
    win_tile(fuck);
}

pub fn win_add(fuck: *Fuck, wn: c.Window) !void {
    if (wn == c.None) return;
    var client = Client{
        .window = wn,
        .is_full = false,
        .is_float = (fuck.desktop[fuck.ws].mode == Mode.float),
    };
    try client.get_size(fuck);
    try fuck.desktop[fuck.ws].clients.append(client);
}

pub fn win_del(fuck: *Fuck, wn: c.Window) !void {
    const client = try fuck.client_from_window(wn);
    const ws = &fuck.desktop[fuck.ws];
    _ = ws.clients.orderedRemove(client);
}

pub fn win_tile(fuck: *Fuck) void {
    const ws = fuck.desktop[fuck.ws];
    if (ws.clients.items.len == 0) return;
    if (ws.clients.items[ws.cur].is_full) return;

    const mode = if (ws.mode == Mode.float) ws.last_mode else ws.mode;
    switch (mode) {
        Mode.monocle => tile_monocle(fuck, &ws),
        Mode.master_stack => tile_master_stack(fuck, &ws),
        else => {},
    }
}

fn tile_monocle(fuck: *Fuck, ws: *const Desktop) void {
    for (ws.clients.items) |wn| {
        if (wn.is_float) continue;
        _ = c.XMoveResizeWindow(fuck.display, wn.window,
                config.GAPSIZE,
                config.GAPSIZE + config.TOPGAP,
                fuck.screen_w - config.GAPSIZE * 2,
                fuck.screen_h - config.TOPGAP - config.GAPSIZE * 2);
    }

    tile_float(fuck, ws);
}

fn tile_master_stack(fuck: *Fuck, ws: *const Desktop) void {
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
            config.GAPSIZE,
            config.GAPSIZE + config.TOPGAP,
            @as(u32, @intCast(master_w - config.GAPSIZE)),
            fuck.screen_h - config.TOPGAP - config.GAPSIZE * 2);

    var count: u32 = 0;
    const h = (fuck.screen_h - config.TOPGAP - config.GAPSIZE) / (sz-1);
    for ((master+1)..ws.clients.items.len) |i| {
        wn = ws.clients.items[i];
        if (wn.is_float) continue;

        _ = c.XMoveResizeWindow(fuck.display, wn.window,
                @as(i32, @intCast(master_w + config.GAPSIZE)),
                @as(i32, @intCast(count * h + config.GAPSIZE + config.TOPGAP)),
                @as(u32, @intCast(stack_w - config.GAPSIZE * 2)),
                @as(u32, @intCast(h - config.GAPSIZE)));
        count += 1;
    }

    tile_float(fuck, ws);
}

fn tile_float(fuck: *Fuck, ws: *const Desktop) void {
    // TODO: if i focus a tiled window, last focused window should remain on top
    for (ws.clients.items) |wn| {
        if (!wn.is_float) continue;
        _ = c.XRaiseWindow(fuck.display, wn.window);
    }
    // make sure focused window is on top
    if (ws.clients.items[ws.cur].is_float)
        _ = c.XRaiseWindow(fuck.display, ws.clients.items[ws.cur].window);
}

