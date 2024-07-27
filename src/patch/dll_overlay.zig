const Self = @This();

const std = @import("std");

const GlobalSt = @import("appinfo.zig").GLOBAL_STATE;
const GlobalFn = @import("appinfo.zig").GLOBAL_FUNCTION;
const COMPATIBILITY_VERSION = @import("appinfo.zig").COMPATIBILITY_VERSION;
const VERSION_STR = @import("appinfo.zig").VERSION_STR;

const debug = @import("core/Debug.zig");

const rrd = @import("racer").RaceData;
const rete = @import("racer").Entity.Test;
const rt = @import("racer").Text;
const rto = rt.TextStyleOpts;

const mem = @import("util/memory.zig");
const timing = @import("util/timing.zig");

const SettingHandle = @import("core/ASettings.zig").Handle;
const SettingValue = @import("core/ASettings.zig").ASettingSent.Value;

// TODO: passthrough to annodue's panic via global function vtable; same for logging
pub const panic = debug.annodue_panic;

// Usable in Practice Mode only

// FEATURES
// - Show individual lap times during race
// - Show time to overheat/underheat
// - SETTINGS:
//   enable     bool

// TODO: finish porting overlay features from original practice tool
// TODO: settings for individual elements, hot-reloadable, with local settings change handling

const PLUGIN_NAME: [*:0]const u8 = "Overlay";
const PLUGIN_VERSION: [*:0]const u8 = "0.0.1";

const Overlay = struct {
    var h_s_section: ?SettingHandle = null;
    var h_s_enable: ?SettingHandle = null;
    var s_enable: bool = false;
};

fn settingsInit(gf: *GlobalFn) void {
    const section = gf.ASettingSectionOccupy(SettingHandle.getNull(), "overlay", null);
    Overlay.h_s_section = section;

    Overlay.h_s_enable =
        gf.ASettingOccupy(section, "enable", .B, .{ .b = false }, null, null);
}

// HOUSEKEEPING

export fn PluginName() callconv(.C) [*:0]const u8 {
    return PLUGIN_NAME;
}

export fn PluginVersion() callconv(.C) [*:0]const u8 {
    return PLUGIN_VERSION;
}

export fn PluginCompatibilityVersion() callconv(.C) u32 {
    return COMPATIBILITY_VERSION;
}

export fn OnInit(_: *GlobalSt, gf: *GlobalFn) callconv(.C) void {
    settingsInit(gf);
}

export fn OnInitLate(_: *GlobalSt, _: *GlobalFn) callconv(.C) void {}

export fn OnDeinit(_: *GlobalSt, _: *GlobalFn) callconv(.C) void {}

// HOOKS

const style_heat = rt.MakeTextHeadStyle(.Small, false, .Gray, .Right, .{rto.ToggleShadow}) catch "";
const style_heat_up = rt.MakeTextHeadStyle(.Small, false, .Red, .Right, .{rto.ToggleShadow}) catch "";
const style_heat_dn = rt.MakeTextHeadStyle(.Small, false, .Blue, .Right, .{rto.ToggleShadow}) catch "";
const style_laptime = rt.MakeTextHeadStyle(.Unk2, true, null, null, .{rto.ToggleShadow}) catch "";

const lbx: i16 = 64;
const lby: i16 = 480 - 32;
const sty: i16 = -10;

export fn Draw2DB(gs: *GlobalSt, gf: *GlobalFn) callconv(.C) void {
    // TODO: change practice mode check to 'show overlay' (core setting, not plugin) check
    // FIXME: port setting to new system
    if (!gs.practice_mode or !gf.SettingGetB("overlay", "enable").?) return;

    if (gs.in_race.on() and !gf.GHideRaceUIIsOn()) {
        const lap: u32 = rrd.PLAYER.*.lap;
        const lap_times: []const f32 = &rrd.PLAYER.*.time.lap;

        if (gs.race_state == .Racing or (gs.race_state_new and gs.race_state == .PostRace)) {
            // draw heat timer
            const heat_s: f32 = gs.player.heat / gs.player.heat_rate;
            const cool_s: f32 = (100 - gs.player.heat) / gs.player.cool_rate;
            const heat_timer: f32 = if (gs.player.boosting.on()) heat_s else cool_s;
            const heat_style = if (gs.player.boosting.on()) style_heat_up else if (gs.player.heat < 100) style_heat_dn else style_heat;
            _ = gf.GDrawText(
                .OverlayP,
                rt.MakeText(256, 170, "{d:0>5.3}", .{heat_timer}, null, heat_style) catch null,
            );

            // draw lap times
            for (lap_times, 0..) |t, i| {
                if (t < 0) break;
                const x1: u8 = 48;
                const x2: u8 = 64;
                const y: u8 = 128 + @as(u8, @truncate(i)) * 16;
                const col: u32 = if (lap == i) 0xFFFFFFBE else 0xAAAAAABE;
                _ = gf.GDrawText(.Overlay, rt.MakeText(x1, y + 6, "{d}", .{i + 1}, col, null) catch null);
                const lt = timing.RaceTimeFromFloat(lap_times[i]);
                _ = gf.GDrawText(.Overlay, rt.MakeText(x2, y, "{d}:{d:0>2}.{d:0>3}", .{
                    lt.min, lt.sec, lt.ms,
                }, col, style_laptime) catch null);
            }

            // FPS
            _ = gf.GDrawText(.Overlay, rt.MakeText(lbx, lby + sty * 0, "{d:>2.0}  {d:>5.2}  {d:>5.3}~rFPS  ", .{
                gs.fps_avg, gs.fps, gs.dt_f,
            }, null, null) catch null);

            // DEATH counter
            if (gs.player.deaths > 0)
                _ = gf.GDrawText(
                    .Overlay,
                    rt.MakeText(lbx, lby + sty * 1, "{d}~rDETH  ", .{gs.player.deaths}, null, null) catch null,
                );

            // FALL timer
            //const oob_timer = r.ReadPlayerValue(0x2C8, f32);
            const oob_timer = rete.PLAYER.*.fallTimer;
            if (oob_timer > 0)
                _ = gf.GDrawText(
                    .OverlayP,
                    rt.MakeText(lbx, lby + sty * 2, "{d:0>5.3}~rFall  ", .{oob_timer}, null, null) catch null,
                );
        }
    }
}
