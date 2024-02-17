const Self = @This();

const std = @import("std");
const win = std.os.windows;

// FIXME: move most of these out
// NOTE: most of the following should be passed into the plugins by reference,
// not hardcoded into the actual hooking stuff

const settings = @import("settings.zig");
const global = @import("global.zig");
const g = global.state;
const v = global.Version;
const general = @import("patch_general.zig");
const practice = @import("patch_practice.zig");
const savestate = @import("patch_savestate.zig");

const hook = @import("util/hooking.zig");
const msg = @import("util/message.zig");
const mem = @import("util/memory.zig");
const input = @import("util/input.zig");
const r = @import("util/racer.zig");
const rc = @import("util/racer_const.zig");
const rf = @import("util/racer_fn.zig");

// FIXME: figure out exactly where the patch gets executed on load, for
// documentation purposes

// SETUP

pub fn init(alloc: std.mem.Allocator, memory: usize) usize {
    _ = alloc;
    var off: usize = memory;

    off = HookGameSetup(off);
    off = HookGameLoop(off);
    off = HookEngineUpdate(off);
    off = HookTimerUpdate(off);
    off = HookInitRaceQuads(off);
    off = HookInitHangQuads(off);
    off = HookGameEnd(off);
    off = HookTextRender(off);
    off = HookMenuDrawing(off);

    return off;
}

// GAME SETUP

fn GameSetup() void {
    if (!g.initialized_late) {
        general.init_late();
        g.initialized_late = true;
    }
}

// last function call in successful setup path
fn HookGameSetup(memory: usize) usize {
    const addr: usize = 0x4240AD;
    const len: usize = 0x4240B7 - addr;
    const off_call: usize = 0x4240AF - addr;
    return hook.detour_call(memory, addr, off_call, len, null, &GameSetup);
}

// GAME LOOP

fn GameLoop_Before() void {
    input.update_kb();
}

fn GameLoop_After() void {}

fn HookGameLoop(memory: usize) usize {
    return hook.intercept_call(memory, 0x49CE2A, &GameLoop_Before, &GameLoop_After);
}

// ENGINE UPDATES

fn EarlyEngineUpdate_Before() void {
    general.EarlyEngineUpdate_Before();
    practice.EarlyEngineUpdate_Before();
}

fn EarlyEngineUpdate_After() void {
    global.EarlyEngineUpdate_After();
    savestate.EarlyEngineUpdate_After();
}

fn LateEngineUpdate_Before() void {}

fn LateEngineUpdate_After() void {}

fn HookEngineUpdate(memory: usize) usize {
    var off: usize = memory;

    // fn_445980 case 1
    // physics updates, etc.
    off = hook.intercept_call(off, 0x445991, &EarlyEngineUpdate_Before, null);
    off = hook.intercept_call(off, 0x445A00, null, &EarlyEngineUpdate_After);

    // fn_445980 case 2
    // text processing, etc. before the actual render
    off = hook.intercept_call(off, 0x445A10, &LateEngineUpdate_Before, null);
    off = hook.intercept_call(off, 0x445A40, null, &LateEngineUpdate_After);

    return off;
}

// GAME LOOP TIMER

fn TimerUpdate_Before() void {}

fn TimerUpdate_After() void {
    global.TimerUpdate_After();
}

fn HookTimerUpdate(memory: usize) usize {
    // fn_480540, in early engine update
    return hook.intercept_call(memory, 0x4459AF, &TimerUpdate_Before, &TimerUpdate_After);
}

// 'HANG' SETUP

fn InitHangQuads_Before() void {}

fn InitHangQuads_After() void {}

fn HookInitHangQuads(memory: usize) usize {
    const addr: usize = 0x454DCF;
    const len: usize = 0x454DD8 - addr;
    const off_call: usize = 0x454DD0 - addr;
    return hook.detour_call(memory, addr, off_call, len, &InitHangQuads_Before, &InitHangQuads_After);
}

// RACE SETUP

fn InitRaceQuads_Before() void {}

fn InitRaceQuads_After() void {}

fn HookInitRaceQuads(memory: usize) usize {
    const addr: usize = 0x466D76;
    const len: usize = 0x466D81 - addr;
    const off_call: usize = 0x466D79 - addr;
    return hook.detour_call(memory, addr, off_call, len, &InitRaceQuads_Before, &InitRaceQuads_After);
}

// GAME END; executable closing

fn GameEnd() void {
    settings.deinit();
}

fn HookGameEnd(memory: usize) usize {
    const exit1_off: usize = 0x49CE31;
    const exit2_off: usize = 0x49CE3D;
    const exit1_len: usize = exit2_off - exit1_off - 1; // excluding retn
    const exit2_len: usize = 0x49CE48 - exit2_off - 1; // excluding retn
    var offset: usize = memory;

    offset = hook.detour(offset, exit1_off, exit1_len, null, &GameEnd);
    offset = hook.detour(offset, exit2_off, exit2_len, null, &GameEnd);

    return offset;
}

// MENU DRAW CALLS in 'Hang' callback0x14

fn MenuTitleScreen_Before() void {
    var buf_name: [127:0]u8 = undefined;
    _ = std.fmt.bufPrintZ(&buf_name, "~F0~sAnnodue {d}.{d}.{d}    {d}", .{
        v.major,
        v.minor,
        v.patch,
        v.build,
    }) catch return;
    rf.swrText_CreateEntry1(36, 480 - 24, 255, 255, 255, 255, &buf_name);

    global.MenuTitleScreen_Before();
}

fn MenuVehicleSelect_Before() void {}

fn MenuStartRace_Before() void {
    global.MenuStartRace_Before();
}

fn MenuJunkyard_Before() void {}

fn MenuRaceResults_Before() void {
    global.MenuRaceResults_Before();
}

fn MenuWattosShop_Before() void {}

fn MenuHangar_Before() void {}

fn MenuTrackSelect_Before() void {}

fn MenuTrack_Before() void {
    global.MenuTrack_Before();
}

fn MenuCantinaEntry_Before() void {}

fn HookMenuDrawing(memory: usize) usize {
    var off: usize = memory;

    // see fn_457620 @ 0x45777F
    off = hook.intercept_jumptable(off, rc.ADDR_DRAW_MENU_JUMPTABLE, 1, &MenuTitleScreen_Before);
    off = hook.intercept_jumptable(off, rc.ADDR_DRAW_MENU_JUMPTABLE, 3, &MenuStartRace_Before);
    off = hook.intercept_jumptable(off, rc.ADDR_DRAW_MENU_JUMPTABLE, 4, &MenuJunkyard_Before);
    off = hook.intercept_jumptable(off, rc.ADDR_DRAW_MENU_JUMPTABLE, 5, &MenuRaceResults_Before);
    off = hook.intercept_jumptable(off, rc.ADDR_DRAW_MENU_JUMPTABLE, 7, &MenuWattosShop_Before);
    off = hook.intercept_jumptable(off, rc.ADDR_DRAW_MENU_JUMPTABLE, 8, &MenuHangar_Before);
    off = hook.intercept_jumptable(off, rc.ADDR_DRAW_MENU_JUMPTABLE, 9, &MenuVehicleSelect_Before);
    off = hook.intercept_jumptable(off, rc.ADDR_DRAW_MENU_JUMPTABLE, 12, &MenuTrackSelect_Before);
    off = hook.intercept_jumptable(off, rc.ADDR_DRAW_MENU_JUMPTABLE, 13, &MenuTrack_Before);
    off = hook.intercept_jumptable(off, rc.ADDR_DRAW_MENU_JUMPTABLE, 18, &MenuCantinaEntry_Before);

    return off;
}

// TEXT RENDER QUEUE FLUSHING

fn TextRender_Before() void {
    general.TextRender_Before();
    practice.TextRender_Before();
    savestate.TextRender_Before();
}

fn HookTextRender(memory: usize) usize {
    return hook.intercept_call(memory, 0x483F8B, null, &TextRender_Before);
}
