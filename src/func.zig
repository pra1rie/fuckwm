const std = @import("std");
const c = @import("c.zig");
const fuckwm = @import("fuckwm.zig");
const config = @import("config.zig");

pub const Arg = struct {
    com: [*c]const [*c]const u8 = undefined,
    i: i32 = 0,
    m: fuckwm.Mode = config.MODE,
};

pub const Key = struct {
    mod: u32,
    key: c.KeySym,
    fun: *const fn (fuck: *fuckwm.Fuck, arg: Arg) anyerror!void,
    arg: Arg,
};

pub fn run(fuck: *fuckwm.Fuck, arg: Arg) !void {
    if (c.fork() != 0) return;
    if (fuck.display != null) {
        _ = c.close(c.ConnectionNumber(fuck.display));
    }
    _ = c.setsid();
    _ = c.execvp(arg.com[0], @ptrCast(arg.com));
}

pub fn tile_mode(fuck: *fuckwm.Fuck, arg: Arg) !void {
    if (fuck.desktop[fuck.ws].mode == arg.m) return;
    fuck.desktop[fuck.ws].last_mode = fuck.desktop[fuck.ws].mode;
    fuck.desktop[fuck.ws].mode = arg.m;
    fuckwm.win_tile(fuck);
}

pub fn win_kill(fuck: *fuckwm.Fuck, arg: Arg) !void {
    _ = arg;
    const ws = fuck.desktop[fuck.ws];
    if (ws.clients.items.len > 0) {
        _ = c.XKillClient(fuck.display, ws.clients.items[ws.cur].window);
    }
}

pub fn win_prev(fuck: *fuckwm.Fuck, arg: Arg) !void {
    _ = arg;
    const ws = &fuck.desktop[fuck.ws];
    if (ws.clients.items.len == 0) return;
    if (ws.clients.items[ws.cur].is_full) return;
    if (ws.cur == 0) {
        ws.cur = ws.clients.items.len - 1;
    } else {
        ws.cur -= 1;
    }
    fuckwm.win_focus(fuck, ws.cur);
}

pub fn win_next(fuck: *fuckwm.Fuck, arg: Arg) !void {
    _ = arg;
    const ws = &fuck.desktop[fuck.ws];
    if (ws.clients.items.len == 0) return;
    if (ws.clients.items[ws.cur].is_full) return;
    if (ws.cur == ws.clients.items.len - 1) {
        ws.cur = 0;
    } else {
        ws.cur += 1;
    }
    fuckwm.win_focus(fuck, ws.cur);
}

pub fn win_rotate_prev(fuck: *fuckwm.Fuck, arg: Arg) !void {
    _ = arg;
    const ws = &fuck.desktop[fuck.ws];
    if (ws.clients.items.len < 2) return;
    if (ws.clients.items[ws.cur].is_full) return;
    const l = if (ws.cur == 0) (ws.clients.items.len - 1) else (ws.cur - 1);
    const s = ws.clients.items[l];
    ws.*.clients.items[l] = ws.clients.items[ws.cur];
    ws.*.clients.items[ws.cur] = s;
    ws.cur = l;
    fuckwm.win_tile(fuck);
}

pub fn win_rotate_next(fuck: *fuckwm.Fuck, arg: Arg) !void {
    _ = arg;
    const ws = &fuck.desktop[fuck.ws];
    if (ws.clients.items.len < 2) return;
    if (ws.clients.items[ws.cur].is_full) return;
    const l = if (ws.cur == ws.clients.items.len - 1) (0) else (ws.cur + 1);
    const s = ws.clients.items[l];
    ws.*.clients.items[l] = ws.clients.items[ws.cur];
    ws.*.clients.items[ws.cur] = s;
    ws.cur = l;
    fuckwm.win_tile(fuck);
}

fn incmastersz(master_sz: u64, screen_sz: u64, i: i32) !u32 {
    const too_small = (master_sz <= 100);
    const too_big = (master_sz >= screen_sz - 100);
    if ((i < 0 and too_small) or (i > 0 and too_big))
        return fuckwm.FuckError.InvalidWindowSize;
    return @as(u32, @intCast(@as(i32, @intCast(master_sz)) + i));
}

pub fn incmaster(fuck: *fuckwm.Fuck, arg: Arg) !void {
    if (fuck.desktop[fuck.ws].mode == fuckwm.Mode.bottom_stack) {
        const mh = &fuck.desktop[fuck.ws].master_h;
        mh.* = try incmastersz(mh.*, fuck.screen_h, arg.i);
    }
    else {
        const mw = &fuck.desktop[fuck.ws].master_w;
        mw.* = try incmastersz(mw.*, fuck.screen_w, arg.i);
    }
    fuckwm.win_tile(fuck);
}

pub fn win_full(fuck: *fuckwm.Fuck, arg: Arg) !void {
    _ = arg;
    const ws = &fuck.desktop[fuck.ws];
    if (ws.clients.items.len == 0) return;

    const cw = &ws.clients.items[ws.cur];
    cw.is_full = !cw.is_full;
    if (cw.is_full) {
        _ = c.XMoveResizeWindow(fuck.display, cw.window, -config.BORDER_SIZE, -config.BORDER_SIZE, fuck.screen_w, fuck.screen_h);
    } else {
        _ = c.XMoveResizeWindow(fuck.display, cw.window, cw.x, cw.y, cw.w, cw.h);
    }
    fuckwm.win_tile(fuck);
}

pub fn win_center(fuck: *fuckwm.Fuck, arg: Arg) !void {
    _ = arg;
    const ws = &fuck.desktop[fuck.ws];
    if (ws.clients.items.len == 0) return;
    var cw = &ws.clients.items[ws.cur];
    if (cw.is_full or !cw.is_float) return;

    cw.x = @as(i32, @intCast((fuck.screen_w / 2) - (cw.w / 2)));
    cw.y = @as(i32, @intCast(((fuck.screen_h+config.TOP_GAP) / 2) - (cw.h / 2)));

    _ = c.XMoveResizeWindow(fuck.display, cw.window, cw.x, cw.y, cw.w, cw.h);
    try cw.get_size(fuck);
}

pub fn win_float(fuck: *fuckwm.Fuck, arg: Arg) !void {
    _ = arg;
    const ws = &fuck.desktop[fuck.ws];
    if (ws.clients.items.len == 0) return;
    var cw = &ws.clients.items[ws.cur];
    if (cw.is_full) return;
    cw.is_float = !cw.is_float;
    _ = c.XMoveResizeWindow(fuck.display, cw.window, cw.x, cw.y, cw.w, cw.h);
    fuckwm.win_tile(fuck);
}

pub fn win_to_ws(fuck: *fuckwm.Fuck, arg: Arg) !void {
    if (arg.i == fuck.ws) return;
    const cws = &fuck.desktop[fuck.ws];
    const ws = fuck.ws;
    const wn = cws.clients.items[cws.cur].window;

    _ = c.XUnmapWindow(fuck.display, wn);
    try fuckwm.win_del(fuck, wn);
    if (fuck.desktop[fuck.ws].cur > 0) {
        fuck.desktop[fuck.ws].cur -= 1;
    } else {
        fuck.desktop[fuck.ws].cur = 0;
    }
    if (fuck.desktop[fuck.ws].clients.items.len > 0) {
        fuckwm.win_focus(fuck, fuck.desktop[fuck.ws].cur);
    }

    fuck.ws = @as(u32, @intCast(arg.i));
    try fuckwm.win_add(fuck, wn);
    fuck.ws = ws;
    fuckwm.win_tile(fuck);
}

pub fn switch_ws(fuck: *fuckwm.Fuck, arg: Arg) !void {
    if (arg.i == fuck.ws) return;
    const cws = &fuck.desktop[fuck.ws];

    for (cws.clients.items) |client| {
        _ = c.XUnmapWindow(fuck.display, client.window);
    }

    fuck.ws = @as(u32, @intCast(arg.i));
    for (fuck.desktop[fuck.ws].clients.items) |client| {
        _ = c.XMapWindow(fuck.display, client.window);
    }

    fuckwm.win_focus(fuck, fuck.desktop[fuck.ws].cur);
    fuckwm.win_tile(fuck);
}

