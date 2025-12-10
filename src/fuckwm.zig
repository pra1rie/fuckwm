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
    bottom_stack,
    monocle,
    float,
};

pub const Desktop = struct {
    clients: ArrayList(Client),
    mode: Mode = config.MODE,
    last_mode: Mode = config.MODE,
    master_w: u32,
    master_h: u32,
    prev: u64,
    cur: u64,
};

pub const FuckError = error {
    XOpenDisplayFail,
    NoClientForWindow,
    InvalidWindowSize,
    IndexOutOfBounds,
};

pub const Fuck = struct {
    display: ?*c.Display,
    root: c.Window,
    mouse: c.XButtonEvent,
    hover_attr: c.XWindowAttributes,
    border_normal: c.XColor,
    border_select: c.XColor,
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

        _ = c.XAllocNamedColor(f.display, c.DefaultColormap(f.display, s), config.BORDER_NORMAL, &f.border_normal, &f.border_normal);
        _ = c.XAllocNamedColor(f.display, c.DefaultColormap(f.display, s), config.BORDER_SELECT, &f.border_select, &f.border_select);

        for (0..10) |i| {
            f.desktop[i] = Desktop{
                .clients = ArrayList(Client).init(page_alloc),
                .master_w = f.screen_w / 2,
                .master_h = f.screen_h / 2,
                .prev = 0,
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
    var ws = &fuck.desktop[fuck.ws];
    if (ws.clients.items.len == 0) return;
    if (!ws.clients.items[ws.cur].is_float) ws.prev = ws.cur;
    const cc = ws.clients.items[client];
    _ = c.XSetInputFocus(fuck.display, cc.window, c.RevertToParent, c.CurrentTime);
    ws.cur = client;

    var attr: c.XSetWindowAttributes = undefined;
    var i = ws.clients.items.len;
    while (i > 0) {
        i -= 1;
        const wn = ws.clients.items[i];
        attr.border_pixel = if (i == ws.cur) fuck.border_select.pixel else fuck.border_normal.pixel;
        _ = c.XChangeWindowAttributes(fuck.display, wn.window, c.CWBorderPixel, &attr);
        if (i != ws.cur and i != ws.prev and !wn.is_float)
            _ = c.XLowerWindow(fuck.display, wn.window);
    }

    win_tile(fuck);
}

pub fn win_add(fuck: *Fuck, wn: c.Window) !void {
    if (wn == c.None) return;
    // Do not add client if it already exists
    if (fuck.client_from_window(wn) != FuckError.NoClientForWindow)
        return;

    var client = Client{
        .window = wn,
        .is_full = false,
        .is_float = (fuck.desktop[fuck.ws].mode == Mode.float),
    };
    try client.get_size(fuck);
    try fuck.desktop[fuck.ws].clients.append(client);
}

pub fn win_del(fuck: *Fuck, id: u64) !void {
    const ws = &fuck.desktop[fuck.ws];
    if (id >= ws.clients.items.len) return FuckError.IndexOutOfBounds;
    _ = ws.clients.orderedRemove(id);
}

pub fn win_tile(fuck: *Fuck) void {
    const ws = fuck.desktop[fuck.ws];
    if (ws.clients.items.len == 0) return;
    if (ws.clients.items[ws.cur].is_full) return;

    // make sure to delete every "zombie" client so you don't get
    // some weird transparent frames on your desktop with no content
    var i: u64 = 0;
    while (i < ws.clients.items.len) {
        if (ws.clients.items[i].window == c.None) {
            win_del(fuck, i) catch break;
            i -= 1; // start next iteration from the same spot it just free'd
        }
        i += 1;
    }

    const mode = if (ws.mode == Mode.float) ws.last_mode else ws.mode;
    switch (mode) {
        Mode.monocle => tile_monocle(fuck, &ws),
        Mode.master_stack => tile_master_stack(fuck, &ws),
        Mode.bottom_stack => tile_bottom_stack(fuck, &ws),
        else => {},
    }

    tile_float(fuck, &ws);
}

fn tile_monocle(fuck: *Fuck, ws: *const Desktop) void {
    const gap = (config.GAP_SIZE+config.BORDER_SIZE)*2;
    for (ws.clients.items) |wn| {
        if (wn.is_float) continue;
        _ = c.XMoveResizeWindow(fuck.display, wn.window,
                config.GAP_SIZE,
                config.GAP_SIZE + config.TOP_GAP,
                fuck.screen_w - gap,
                fuck.screen_h - config.TOP_GAP - gap);
    }
}

fn get_master_client(ws: *const Desktop) [2]u32 {
    var master: u32 = 0;
    var stack_sz: u32 = 0;
    for (ws.clients.items, 0..) |wn, i| {
        if (!wn.is_float) {
            if (master == 0 and ws.clients.items[master].is_float)
                master = @as(u32, @intCast(i));
            stack_sz += 1;
        }
    }
    return .{ master, stack_sz };
}

fn tile_master_stack(fuck: *Fuck, ws: *const Desktop) void {
    const gap = (config.GAP_SIZE+config.BORDER_SIZE)*2;
    const master_w = ws.master_w;
    const stack_w = fuck.screen_w - ws.master_w;
    const master, const stack_sz = get_master_client(ws);

    // only one tiled client
    if (ws.clients.items.len == 1 or stack_sz <= 1) {
        tile_monocle(fuck, ws);
        return;
    }

    var wn = ws.clients.items[master];
    _ = c.XMoveResizeWindow(fuck.display, wn.window,
            config.GAP_SIZE,
            config.GAP_SIZE + config.TOP_GAP,
            @as(u32, @intCast(master_w - config.GAP_SIZE - config.BORDER_SIZE)),
            fuck.screen_h - config.TOP_GAP - gap);

    var count: u32 = 0;
    const h = (fuck.screen_h - config.TOP_GAP - config.GAP_SIZE) / (stack_sz-1);
    for ((master+1)..ws.clients.items.len) |i| {
        wn = ws.clients.items[i];
        if (wn.is_float) continue;

        _ = c.XMoveResizeWindow(fuck.display, wn.window,
                @as(i32, @intCast(master_w + config.GAP_SIZE)),
                @as(i32, @intCast(count * h + config.GAP_SIZE + config.TOP_GAP)),
                @as(u32, @intCast(stack_w - gap)),
                @as(u32, @intCast(h - (config.BORDER_SIZE*2) - config.GAP_SIZE)));
        count += 1;
    }
}

fn tile_bottom_stack(fuck: *Fuck, ws: *const Desktop) void {
    const gap = (config.GAP_SIZE+config.BORDER_SIZE)*2;
    const master_h = ws.master_h;
    const stack_h = fuck.screen_h - master_h;
    const master, const stack_sz = get_master_client(ws);

    // only one tiled client
    if (ws.clients.items.len == 1 or stack_sz <= 1) {
        tile_monocle(fuck, ws);
        return;
    }

    var wn = ws.clients.items[master];
    _ = c.XMoveResizeWindow(fuck.display, wn.window,
            config.GAP_SIZE,
            config.GAP_SIZE + config.TOP_GAP,
            fuck.screen_w - gap,
            @as(u32, @intCast(master_h - config.TOP_GAP)));

    var count: u32 = 0;
    const w = (fuck.screen_w - config.GAP_SIZE - config.BORDER_SIZE) / (stack_sz-1);
    for ((master+1)..ws.clients.items.len) |i| {
        wn = ws.clients.items[i];
        if (wn.is_float) continue;

        _ = c.XMoveResizeWindow(fuck.display, wn.window,
                @as(i32, @intCast(count * w + config.GAP_SIZE)),
                @as(i32, @intCast(master_h + gap)),
                @as(u32, @intCast(w - config.GAP_SIZE - config.BORDER_SIZE)),
                @as(u32, @intCast(stack_h - config.GAP_SIZE - config.BORDER_SIZE - config.TOP_GAP)));
        count += 1;
    }
}

fn tile_float(fuck: *Fuck, ws: *const Desktop) void {
    // make sure focused window is on top
    if (ws.clients.items[ws.cur].is_float)
        _ = c.XRaiseWindow(fuck.display, ws.clients.items[ws.cur].window);
}

