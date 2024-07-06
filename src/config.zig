const c = @import("c.zig");
const fuckwm = @import("fuckwm.zig");
const func = @import("func.zig");

pub const MOD = c.Mod4Mask;
pub const TOPGAP = 18;
pub const GAPSIZE = 6;
pub const MODE = fuckwm.Mode.master_stack;

const term_cmd = [_][*c]const u8{ "kitty", 0 };
const menu_cmd = [_][*c]const u8{ "dmenu_run", 0 };

pub const keys = [_]func.Key{
    func.Key{ .mod = MOD,               .key = c.XK_Return, .fun = func.run,             .arg = func.Arg{ .com = &term_cmd } },
    func.Key{ .mod = MOD,               .key = c.XK_d,      .fun = func.run,             .arg = func.Arg{ .com = &menu_cmd } },

    func.Key{ .mod = MOD,               .key = c.XK_f,      .fun = func.win_full,        .arg = func.Arg{ .i = 0 } },
    func.Key{ .mod = MOD,               .key = c.XK_q,      .fun = func.win_kill,        .arg = func.Arg{ .i = 0 } },
    func.Key{ .mod = MOD,               .key = c.XK_c,      .fun = func.win_center,      .arg = func.Arg{ .i = 0 } },
    func.Key{ .mod = MOD|c.ShiftMask,   .key = c.XK_space,  .fun = func.win_float,       .arg = func.Arg{ .i = 0 } },

    func.Key{ .mod = MOD,               .key = c.XK_h,      .fun = func.incmaster,       .arg = func.Arg{ .i = -20 } },
    func.Key{ .mod = MOD,               .key = c.XK_l,      .fun = func.incmaster,       .arg = func.Arg{ .i =  20 } },

    func.Key{ .mod = MOD,               .key = c.XK_Tab,    .fun = func.win_next,        .arg = func.Arg{ .i = 0 } },
    func.Key{ .mod = MOD|c.ShiftMask,   .key = c.XK_Tab,    .fun = func.win_prev,        .arg = func.Arg{ .i = 0 } },
    func.Key{ .mod = MOD,               .key = c.XK_j,      .fun = func.win_prev,        .arg = func.Arg{ .i = 0 } },
    func.Key{ .mod = MOD,               .key = c.XK_k,      .fun = func.win_next,        .arg = func.Arg{ .i = 0 } },
    func.Key{ .mod = MOD|c.ShiftMask,   .key = c.XK_j,      .fun = func.win_rotate_prev, .arg = func.Arg{ .i = 0 } },
    func.Key{ .mod = MOD|c.ShiftMask,   .key = c.XK_k,      .fun = func.win_rotate_next, .arg = func.Arg{ .i = 0 } },

    func.Key{ .mod = MOD|c.ShiftMask,   .key = c.XK_t,      .fun = func.tile_mode,       .arg = func.Arg{ .m = fuckwm.Mode.master_stack } },
    func.Key{ .mod = MOD|c.ShiftMask,   .key = c.XK_b,      .fun = func.tile_mode,       .arg = func.Arg{ .m = fuckwm.Mode.bottom_stack } },
    func.Key{ .mod = MOD|c.ShiftMask,   .key = c.XK_m,      .fun = func.tile_mode,       .arg = func.Arg{ .m = fuckwm.Mode.monocle } },
    func.Key{ .mod = MOD|c.ShiftMask,   .key = c.XK_f,      .fun = func.tile_mode,       .arg = func.Arg{ .m = fuckwm.Mode.float } },

    // where are my macros????
    func.Key{ .mod = MOD,               .key = c.XK_1,      .fun = func.switch_ws,       .arg = func.Arg{ .i = 0 } },
    func.Key{ .mod = MOD|c.ShiftMask,   .key = c.XK_1,      .fun = func.win_to_ws,       .arg = func.Arg{ .i = 0 } },
    func.Key{ .mod = MOD,               .key = c.XK_2,      .fun = func.switch_ws,       .arg = func.Arg{ .i = 1 } },
    func.Key{ .mod = MOD|c.ShiftMask,   .key = c.XK_2,      .fun = func.win_to_ws,       .arg = func.Arg{ .i = 1 } },
    func.Key{ .mod = MOD,               .key = c.XK_3,      .fun = func.switch_ws,       .arg = func.Arg{ .i = 2 } },
    func.Key{ .mod = MOD|c.ShiftMask,   .key = c.XK_3,      .fun = func.win_to_ws,       .arg = func.Arg{ .i = 2 } },
    func.Key{ .mod = MOD,               .key = c.XK_4,      .fun = func.switch_ws,       .arg = func.Arg{ .i = 3 } },
    func.Key{ .mod = MOD|c.ShiftMask,   .key = c.XK_4,      .fun = func.win_to_ws,       .arg = func.Arg{ .i = 3 } },
    func.Key{ .mod = MOD,               .key = c.XK_5,      .fun = func.switch_ws,       .arg = func.Arg{ .i = 4 } },
    func.Key{ .mod = MOD|c.ShiftMask,   .key = c.XK_5,      .fun = func.win_to_ws,       .arg = func.Arg{ .i = 4 } },
    func.Key{ .mod = MOD,               .key = c.XK_6,      .fun = func.switch_ws,       .arg = func.Arg{ .i = 5 } },
    func.Key{ .mod = MOD|c.ShiftMask,   .key = c.XK_6,      .fun = func.win_to_ws,       .arg = func.Arg{ .i = 5 } },
    func.Key{ .mod = MOD,               .key = c.XK_7,      .fun = func.switch_ws,       .arg = func.Arg{ .i = 6 } },
    func.Key{ .mod = MOD|c.ShiftMask,   .key = c.XK_7,      .fun = func.win_to_ws,       .arg = func.Arg{ .i = 6 } },
    func.Key{ .mod = MOD,               .key = c.XK_8,      .fun = func.switch_ws,       .arg = func.Arg{ .i = 7 } },
    func.Key{ .mod = MOD|c.ShiftMask,   .key = c.XK_8,      .fun = func.win_to_ws,       .arg = func.Arg{ .i = 7 } },
    func.Key{ .mod = MOD,               .key = c.XK_9,      .fun = func.switch_ws,       .arg = func.Arg{ .i = 8 } },
    func.Key{ .mod = MOD|c.ShiftMask,   .key = c.XK_9,      .fun = func.win_to_ws,       .arg = func.Arg{ .i = 8 } },
    func.Key{ .mod = MOD,               .key = c.XK_0,      .fun = func.switch_ws,       .arg = func.Arg{ .i = 9 } },
    func.Key{ .mod = MOD|c.ShiftMask,   .key = c.XK_0,      .fun = func.win_to_ws,       .arg = func.Arg{ .i = 9 } },
};

