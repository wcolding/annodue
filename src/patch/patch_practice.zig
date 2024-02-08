pub const Self = @This();
const std = @import("std");

const mem = @import("util/memory.zig");
const input = @import("util/input.zig");
const r = @import("util/racer.zig");
const rc = r.constants;
const rf = r.functions;

const VirtualAlloc = std.os.windows.VirtualAlloc;
const VirtualFree = std.os.windows.VirtualFree;
const MEM_COMMIT = std.os.windows.MEM_COMMIT;
const MEM_RESERVE = std.os.windows.MEM_RESERVE;
const MEM_RELEASE = std.os.windows.MEM_RELEASE;
const PAGE_EXECUTE_READWRITE = std.os.windows.PAGE_EXECUTE_READWRITE;

const user32 = std.os.windows.user32;
const MessageBoxA = user32.MessageBoxA;
const MB_OK = user32.MB_OK;
const MB_ICONINFORMATION = user32.MB_ICONINFORMATION;

fn ErrMessage(label: []const u8, err: []const u8) void {
    var buf: [2047:0]u8 = undefined;
    _ = std.fmt.bufPrintZ(&buf, "[ERROR] {s}: {s}", .{ label, err }) catch return;
    _ = MessageBoxA(null, &buf, "annodue.dll", MB_OK);
}

const state = struct {
    var fps: f32 = 0;
};

const race = struct {
    const stat_x: u16 = 192;
    const stat_y: u16 = 48;
    const stat_h: u8 = 12;
    const stat_col: u8 = 255;
    var was_in_race: bool = false;
    var was_in_race_count: bool = false;
    var was_in_race_results: bool = false;
    var was_boosting: bool = false;
    var was_underheating: bool = true;
    var was_overheating: bool = false;
    var was_dead: bool = false;
    var total_deaths: u32 = 0;
    var total_boost_duration: f32 = 0;
    var total_boost_ratio: f32 = 0;
    var total_underheat: f32 = 0;
    var total_overheat: f32 = 0;
    var first_boost_time: f32 = 0;
    var fire_finish_duration: f32 = 0;
    var last_boost_started: f32 = 0;
    var last_boost_started_total: f32 = 0;
    var last_underheat_started: f32 = 0;
    var last_underheat_started_total: f32 = 0;
    var last_overheat_started: f32 = 0;
    var last_overheat_started_total: f32 = 0;
    var heat_rate: f32 = 0;
    var cool_rate: f32 = 0;
    var upgrades: bool = false;
    var upgrades_lv: [7]u8 = undefined;
    var upgrades_hp: [7]u8 = undefined;

    fn reset() void {
        was_in_race_count = false;
        was_in_race_results = false;
        was_boosting = false;
        was_underheating = true; // you start the race underheating
        was_overheating = false;
        was_dead = false;
        total_deaths = 0;
        total_boost_duration = 0;
        total_boost_ratio = 0;
        total_underheat = 0;
        total_overheat = 0;
        first_boost_time = 0;
        fire_finish_duration = 0;
        last_boost_started = 0;
        last_boost_started_total = 0;
        last_underheat_started = 0;
        last_underheat_started_total = 0;
        last_overheat_started = 0;
        last_overheat_started_total = 0;
        heat_rate = r.ReadEntityValue(.Test, 0, 0x8C, f32);
        cool_rate = r.ReadEntityValue(.Test, 0, 0x90, f32);
        const u: [14]u8 = mem.deref_read(&.{ 0x4D78A4, 0x0C, 0x41 }, [14]u8);
        upgrades_lv = u[0..7].*;
        upgrades_hp = u[7..14].*;
        var i: u8 = 0;
        upgrades = while (i < 7) : (i += 1) {
            if (u[i] > 0 and u[7 + i] > 0) break true;
        } else false;
    }

    fn set_last_boost_start(time: f32) void {
        last_boost_started_total = total_boost_duration;
        last_boost_started = time;
        if (first_boost_time == 0) first_boost_time = time;
    }

    fn set_total_boost(time: f32) void {
        total_boost_duration = last_boost_started_total + time - last_boost_started;
        total_boost_ratio = total_boost_duration / time;
    }

    fn set_last_underheat_start(time: f32) void {
        last_underheat_started_total = total_underheat;
        last_underheat_started = time;
    }

    fn set_total_underheat(time: f32) void {
        total_underheat = last_underheat_started_total + time - last_underheat_started;
    }

    fn set_last_overheat_start(time: f32) void {
        last_overheat_started_total = total_overheat;
        last_overheat_started = time;
    }

    fn set_total_overheat(time: f32) void {
        total_overheat = last_overheat_started_total + time - last_overheat_started;
    }

    fn set_fire_finish_duration(time: f32) void {
        fire_finish_duration = time - last_overheat_started;
    }
};

const savestate = struct {
    const off_race: usize = 0;
    const off_test: usize = rc.RACE_DATA_SIZE;
    const off_hang: usize = off_test + rc.EntitySize(.Test);
    const off_cman: usize = off_hang + rc.EntitySize(.Hang);
    const size: usize = off_cman + rc.EntitySize(.cMan);
    const frames: usize = 128;
    var frame: usize = 0;
    var frame_total: usize = 0;
    var initialized: bool = false;
    var memory: ?std.os.windows.LPVOID = null;
    var data: []u8 = undefined;
    var ok: bool = false; // FIXME: probably unnecessary
    var track: ?u8 = null;
    var character: ?u8 = null;

    fn init() void {
        const mem_alloc = MEM_COMMIT | MEM_RESERVE;
        const mem_protect = PAGE_EXECUTE_READWRITE;
        memory = VirtualAlloc(null, size * frames, mem_alloc, mem_protect) catch unreachable;
        data = @as([*]u8, @ptrCast(memory))[0 .. size * frames];
        initialized = true;
    }

    fn reset() void {
        if (frame_total > 0) {
            ok = false;
            character = null;
            track = null;
            frame = 0;
            frame_total = 0;
        }
    }

    fn save_file() void {
        const file = std.fs.cwd().createFile("annodue/testdata.bin", .{}) catch |err| return ErrMessage("create file", @errorName(err));
        defer file.close();

        _ = file.write(data[frame * size .. frames * size]) catch return;
        _ = file.write(data[0 .. frame * size]) catch return;
    }

    fn saveable() bool {
        const in_race = mem.read(rc.ADDR_IN_RACE, u8) > 0;
        return in_race;
    }

    fn save() void {
        if (!initialized) init();
        if (saveable()) {
            ok = true;
            track = r.ReadEntityValue(.Hang, 0, 0x5D, u8);
            character = r.ReadEntityValue(.Hang, 0, 0x73, u8);
            var o = frame * size;
            r.ReadRaceDataValueBytes(0, &data[o + off_race], rc.RACE_DATA_SIZE);
            r.ReadEntityValueBytes(.Test, 0, 0, &data[o + off_test], rc.EntitySize(.Test));
            r.ReadEntityValueBytes(.Hang, 0, 0, &data[o + off_hang], rc.EntitySize(.Hang));
            r.ReadEntityValueBytes(.cMan, 0, 0, &data[o + off_cman], rc.EntitySize(.cMan));
            frame_total += 1;
            frame = (frame + 1) % frames;
        }
    }

    fn loadable() bool {
        const in_race = mem.read(rc.ADDR_IN_RACE, u8) > 0;
        const cur_track = r.ReadEntityValue(.Hang, 0, 0x5D, u8);
        const cur_character = r.ReadEntityValue(.Hang, 0, 0x73, u8);
        return in_race and cur_track == track and cur_character == character;
    }

    fn load() void {
        if (loadable()) {
            var o = ((frame + frames - 1) % frames) * size;
            r.WriteRaceDataValueBytes(0, &data[o + off_race], rc.RACE_DATA_SIZE);
            r.WriteEntityValueBytes(.Test, 0, 0, &data[o + off_test], rc.EntitySize(.Test));
            r.WriteEntityValueBytes(.Hang, 0, 0, &data[o + off_hang], rc.EntitySize(.Hang));
            r.WriteEntityValueBytes(.cMan, 0, 0, &data[o + off_cman], rc.EntitySize(.cMan));
        }
    }
};

fn RenderRaceResultStat1(i: u8, label: [*:0]const u8) void {
    var buf: [127:0]u8 = undefined;
    _ = std.fmt.bufPrintZ(&buf, "~F0~s~c{s}", .{label}) catch unreachable;
    rf.swrText_CreateEntry1(640 - race.stat_x, race.stat_y + i * race.stat_h, race.stat_col, race.stat_col, race.stat_col, 255, &buf);
}

fn RenderRaceResultStat2(i: u8, label: [*:0]const u8, value: [*:0]const u8) void {
    var bufl: [127:0]u8 = undefined;
    var bufv: [127:0]u8 = undefined;
    _ = std.fmt.bufPrintZ(&bufl, "~F0~s~r{s}", .{label}) catch unreachable;
    _ = std.fmt.bufPrintZ(&bufv, "~F0~s{s}", .{value}) catch unreachable;
    rf.swrText_CreateEntry1(640 - race.stat_x - 8, race.stat_y + i * race.stat_h, race.stat_col, race.stat_col, race.stat_col, 255, &bufl);
    rf.swrText_CreateEntry1(640 - race.stat_x + 8, race.stat_y + i * race.stat_h, race.stat_col, race.stat_col, race.stat_col, 255, &bufv);
}

fn RenderRaceResultStatU(i: u8, label: [*:0]const u8, value: u32) void {
    var buf: [23:0]u8 = undefined;
    _ = std.fmt.bufPrintZ(&buf, "{d: <7}", .{value}) catch unreachable;
    RenderRaceResultStat2(i, label, &buf);
}

fn RenderRaceResultStatF(i: u8, label: [*:0]const u8, value: f32) void {
    var buf: [23:0]u8 = undefined;
    _ = std.fmt.bufPrintZ(&buf, "{d:4.3}", .{value}) catch unreachable;
    RenderRaceResultStat2(i, label, &buf);
}

fn RenderRaceResultStatTime(i: u8, label: [*:0]const u8, time: f32) void {
    const t_ms: u32 = @as(u32, @intFromFloat(@round(time * 1000)));
    const sec: u32 = (t_ms / 1000);
    const ms: u32 = t_ms % 1000;
    var buf: [23:0]u8 = undefined;
    _ = std.fmt.bufPrintZ(&buf, "{d}.{d:0>3}", .{ sec, ms }) catch unreachable;
    RenderRaceResultStat2(i, label, &buf);
}

fn RenderRaceResultStatUpgrade(i: u8, cat: u8, lv: u8, hp: u8) void {
    var buf: [23:0]u8 = undefined;
    const hp_col = if (hp < 255) "~5" else "~4";
    _ = std.fmt.bufPrintZ(&buf, "{s}{d:0>3} ~1{s}", .{ hp_col, hp, rc.UpgradeNames[cat * 6 + lv] }) catch unreachable;
    RenderRaceResultStat2(i, rc.UpgradeCategories[cat], &buf);
}

pub fn GameLoop_Before() void {
    // FIXME: runs before the ingame time calc at the top of the frame
    const dt_f: f32 = mem.deref_read(&.{0xE22A50}, f32);
    const fps_res: f32 = 1 / dt_f * 2;
    state.fps = (state.fps * (fps_res - 1) + (1 / dt_f)) / fps_res;
}

// FIXME: more appropriate hook point to run this
// after Test functions run but before rendering, so that nothing changes the loaded data
pub fn GameLoop_After(practice_mode: bool) void {
    if (practice_mode) {
        const in_race = mem.read(rc.ADDR_IN_RACE, u8) > 0;
        if (in_race) {
            const flags1: u32 = r.ReadEntityValue(.Test, 0, 0x60, u32);
            const cannot_use: bool = (flags1 & (1 << 0)) > 0 or (flags1 & (1 << 5)) == 0;

            if (!cannot_use and input.get_kb_pressed(.@"1"))
                savestate.save();

            if (!cannot_use and input.get_kb_pressed(.@"2") and savestate.frame_total > 0)
                savestate.load();
        }
    }
}

pub fn MenuStartRace_Before() void {
    savestate.reset();
}

pub fn TextRender_Before(practice_mode: bool) void {
    const in_race: bool = mem.read(rc.ADDR_IN_RACE, u8) > 0;
    const in_race_new: bool = race.was_in_race != in_race;
    race.was_in_race = in_race;

    if (in_race) {
        if (in_race_new) race.reset();

        const flags1: u32 = r.ReadEntityValue(.Test, 0, 0x60, u32);
        const in_race_count: bool = (flags1 & (1 << 0)) > 0;
        const in_race_count_new: bool = race.was_in_race_count != in_race_count;
        race.was_in_race_count = in_race_count;
        const in_race_results: bool = (flags1 & (1 << 5)) == 0;
        const in_race_results_new: bool = race.was_in_race_results != in_race_results;
        race.was_in_race_results = in_race_results;

        const lap: u8 = mem.deref_read(&.{ rc.ADDR_RACE_DATA, 0x78 }, u8);
        const race_times: [6]f32 = mem.deref_read(&.{ rc.ADDR_RACE_DATA, 0x60 }, [6]f32);
        const lap_times: []const f32 = race_times[0..5];
        const total_time: f32 = race_times[5];

        if (practice_mode) {
            var flash: u8 = 255;
            if (total_time <= 0) {
                const timer: f32 = r.ReadEntityValue(.Jdge, 0, 0x0C, f32);
                const flash_range: u8 = 128;
                const flash_cycle: f32 = std.math.clamp((std.math.cos(timer * std.math.pi * 12) * 0.5 + 0.5) * std.math.pow(f32, timer / 3, 3), 0, 3);
                flash -= @intFromFloat(flash_range * flash_cycle);
            }
            rf.swrText_CreateEntry1(640 - 16, 480 - 16, flash, flash, flash, 190, "~F0~s~rPractice Mode");
        }

        if (in_race_count) {
            if (in_race_count_new) {
                // ...
            }
        } else if (in_race_results) {
            if (in_race_results_new) {
                if (race.was_boosting) race.set_total_boost(total_time);
                if (race.was_underheating) race.set_total_underheat(total_time);
                if (race.was_overheating) {
                    race.set_fire_finish_duration(total_time);
                    race.set_total_overheat(total_time);
                }
            }

            var buf_tfps: [63:0]u8 = undefined;
            _ = std.fmt.bufPrintZ(&buf_tfps, "{d:>2.0}/{s}", .{ state.fps, rc.UpgradeNames[race.upgrades_lv[0]] }) catch unreachable;
            RenderRaceResultStat1(0, &buf_tfps);

            var buf_upg: [63:0]u8 = undefined;
            _ = std.fmt.bufPrintZ(&buf_upg, "{s}Upgrades", .{if (race.upgrades) "" else "NO "}) catch unreachable;
            RenderRaceResultStat1(1, &buf_upg);

            var i: u8 = 0;
            while (i < 7) : (i += 1) {
                RenderRaceResultStatUpgrade(3 + i, i, race.upgrades_lv[i], race.upgrades_hp[i]);
            }

            RenderRaceResultStatU(11, "Deaths", race.total_deaths);
            RenderRaceResultStatTime(12, "Boost Time", race.total_boost_duration);
            RenderRaceResultStatF(13, "Boost Ratio", race.total_boost_ratio);
            RenderRaceResultStatTime(14, "First Boost", race.first_boost_time);
            RenderRaceResultStatTime(15, "Underheat Time", race.total_underheat);
            RenderRaceResultStatTime(16, "Fire Finish", race.fire_finish_duration);
            RenderRaceResultStatTime(17, "Overheat Time", race.total_overheat);
        } else {
            const dead: bool = (flags1 & (1 << 14)) > 0;
            const dead_new: bool = race.was_dead != dead;
            race.was_dead = dead;
            if (dead and dead_new) race.total_deaths += 1;

            const heat: f32 = r.ReadEntityValue(.Test, 0, 0x218, f32);
            const engine: [6]u32 = r.ReadEntityValue(.Test, 0, 0x2A0, [6]u32);

            const boosting: bool = (flags1 & (1 << 23)) > 0;
            const boosting_new: bool = race.was_boosting != boosting;
            race.was_boosting = boosting;
            if (boosting and boosting_new) race.set_last_boost_start(total_time);
            if (boosting) race.set_total_boost(total_time);
            if (!boosting and boosting_new) race.set_total_boost(total_time);

            const underheating: bool = heat >= 100;
            const underheating_new: bool = race.was_underheating != underheating;
            race.was_underheating = underheating;
            if (underheating and underheating_new) race.set_last_underheat_start(total_time);
            if (underheating) race.set_total_underheat(total_time);
            if (!underheating and underheating_new) race.set_total_underheat(total_time);

            var j: u8 = 0;
            const overheating: bool = while (j < 6) : (j += 1) {
                if (engine[j] & (1 << 3) > 0) break true;
            } else false;
            const overheating_new: bool = race.was_overheating != overheating;
            race.was_overheating = overheating;
            if (overheating and overheating_new) race.set_last_overheat_start(total_time);
            if (overheating) race.set_total_overheat(total_time);
            if (!overheating and overheating_new) race.set_total_overheat(total_time);

            if (practice_mode) {
                const heat_s: f32 = heat / race.heat_rate;
                const cool_s: f32 = (100 - heat) / race.cool_rate;
                const heat_timer: f32 = if (boosting) heat_s else cool_s;
                const heat_color: []const u8 = if (boosting) "~5" else if (heat < 100) "~2" else "~7";
                var buf: [63:0]u8 = undefined;
                _ = std.fmt.bufPrintZ(&buf, "~F0{s}~s~r{d:0>5.3}", .{ heat_color, heat_timer }) catch unreachable;
                rf.swrText_CreateEntry1((320 - 68) * 2, 168 * 2, 255, 255, 255, 190, &buf);

                var i: u8 = 0;
                while (i < lap_times.len and lap_times[i] >= 0) : (i += 1) {
                    const t_ms: u32 = @as(u32, @intFromFloat(@round(lap_times[i] * 1000)));
                    const min: u32 = (t_ms / 1000) / 60;
                    const sec: u32 = (t_ms / 1000) % 60;
                    const ms: u32 = t_ms % 1000;
                    const col: u8 = if (lap == i) 255 else 170;
                    var buf_lap: [63:0]u8 = undefined;
                    _ = std.fmt.bufPrintZ(&buf_lap, "~F1~s{d}  {d}:{d:0>2}.{d:0>3}", .{ i + 1, min, sec, ms }) catch unreachable;
                    rf.swrText_CreateEntry1(48, 128 + i * 16, col, col, col, 190, &buf_lap);
                }
            }
        }
    }
}
