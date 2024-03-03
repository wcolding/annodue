pub const XINPUT_DLL_A = "xinput1_4.dll";
pub const XINPUT_DLL_W = "xinput1_4.dll";
pub const XINPUT_DLL = "xinput1_4.dll";
pub const XINPUT_DEVTYPE_GAMEPAD = @as(u32, 1);
pub const XINPUT_DEVSUBTYPE_GAMEPAD = @as(u32, 1);
pub const XINPUT_DEVSUBTYPE_UNKNOWN = @as(u32, 0);
pub const XINPUT_DEVSUBTYPE_WHEEL = @as(u32, 2);
pub const XINPUT_DEVSUBTYPE_ARCADE_STICK = @as(u32, 3);
pub const XINPUT_DEVSUBTYPE_FLIGHT_STICK = @as(u32, 4);
pub const XINPUT_DEVSUBTYPE_DANCE_PAD = @as(u32, 5);
pub const XINPUT_DEVSUBTYPE_GUITAR = @as(u32, 6);
pub const XINPUT_DEVSUBTYPE_GUITAR_ALTERNATE = @as(u32, 7);
pub const XINPUT_DEVSUBTYPE_DRUM_KIT = @as(u32, 8);
pub const XINPUT_DEVSUBTYPE_GUITAR_BASS = @as(u32, 11);
pub const XINPUT_DEVSUBTYPE_ARCADE_PAD = @as(u32, 19);
pub const XINPUT_CAPS_VOICE_SUPPORTED = @as(u32, 4);
pub const XINPUT_CAPS_FFB_SUPPORTED = @as(u32, 1);
pub const XINPUT_CAPS_WIRELESS = @as(u32, 2);
pub const XINPUT_CAPS_PMD_SUPPORTED = @as(u32, 8);
pub const XINPUT_CAPS_NO_NAVIGATION = @as(u32, 16);
pub const XINPUT_GAMEPAD_DPAD_UP = @as(u32, 1);
pub const XINPUT_GAMEPAD_DPAD_DOWN = @as(u32, 2);
pub const XINPUT_GAMEPAD_DPAD_LEFT = @as(u32, 4);
pub const XINPUT_GAMEPAD_DPAD_RIGHT = @as(u32, 8);
pub const XINPUT_GAMEPAD_START = @as(u32, 16);
pub const XINPUT_GAMEPAD_BACK = @as(u32, 32);
pub const XINPUT_GAMEPAD_LEFT_THUMB = @as(u32, 64);
pub const XINPUT_GAMEPAD_RIGHT_THUMB = @as(u32, 128);
pub const XINPUT_GAMEPAD_LEFT_SHOULDER = @as(u32, 256);
pub const XINPUT_GAMEPAD_RIGHT_SHOULDER = @as(u32, 512);
pub const XINPUT_GAMEPAD_A = @as(u32, 4096);
pub const XINPUT_GAMEPAD_B = @as(u32, 8192);
pub const XINPUT_GAMEPAD_X = @as(u32, 16384);
pub const XINPUT_GAMEPAD_Y = @as(u32, 32768);
pub const XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE = @as(u32, 7849);
pub const XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE = @as(u32, 8689);
pub const XINPUT_GAMEPAD_TRIGGER_THRESHOLD = @as(u32, 30);
pub const XINPUT_FLAG_GAMEPAD = @as(u32, 1);
pub const BATTERY_DEVTYPE_GAMEPAD = @as(u32, 0);
pub const BATTERY_DEVTYPE_HEADSET = @as(u32, 1);
pub const BATTERY_TYPE_DISCONNECTED = @as(u32, 0);
pub const BATTERY_TYPE_WIRED = @as(u32, 1);
pub const BATTERY_TYPE_ALKALINE = @as(u32, 2);
pub const BATTERY_TYPE_NIMH = @as(u32, 3);
pub const BATTERY_TYPE_UNKNOWN = @as(u32, 255);
pub const BATTERY_LEVEL_EMPTY = @as(u32, 0);
pub const BATTERY_LEVEL_LOW = @as(u32, 1);
pub const BATTERY_LEVEL_MEDIUM = @as(u32, 2);
pub const BATTERY_LEVEL_FULL = @as(u32, 3);
pub const XUSER_MAX_COUNT = @as(u32, 4);
pub const XUSER_INDEX_ANY = @as(u32, 255);
pub const XINPUT_KEYSTROKE_KEYDOWN = @as(u32, 1);
pub const XINPUT_KEYSTROKE_KEYUP = @as(u32, 2);
pub const XINPUT_KEYSTROKE_REPEAT = @as(u32, 4);

//--------------------------------------------------------------------------------
// Section: Types (7)
//--------------------------------------------------------------------------------
pub const XINPUT_VIRTUAL_KEY = enum(u16) {
    A = 22528,
    B = 22529,
    X = 22530,
    Y = 22531,
    RSHOULDER = 22532,
    LSHOULDER = 22533,
    LTRIGGER = 22534,
    RTRIGGER = 22535,
    DPAD_UP = 22544,
    DPAD_DOWN = 22545,
    DPAD_LEFT = 22546,
    DPAD_RIGHT = 22547,
    START = 22548,
    BACK = 22549,
    LTHUMB_PRESS = 22550,
    RTHUMB_PRESS = 22551,
    LTHUMB_UP = 22560,
    LTHUMB_DOWN = 22561,
    LTHUMB_RIGHT = 22562,
    LTHUMB_LEFT = 22563,
    LTHUMB_UPLEFT = 22564,
    LTHUMB_UPRIGHT = 22565,
    LTHUMB_DOWNRIGHT = 22566,
    LTHUMB_DOWNLEFT = 22567,
    RTHUMB_UP = 22576,
    RTHUMB_DOWN = 22577,
    RTHUMB_RIGHT = 22578,
    RTHUMB_LEFT = 22579,
    RTHUMB_UPLEFT = 22580,
    RTHUMB_UPRIGHT = 22581,
    RTHUMB_DOWNRIGHT = 22582,
    RTHUMB_DOWNLEFT = 22583,
};
pub const VK_PAD_A = XINPUT_VIRTUAL_KEY.A;
pub const VK_PAD_B = XINPUT_VIRTUAL_KEY.B;
pub const VK_PAD_X = XINPUT_VIRTUAL_KEY.X;
pub const VK_PAD_Y = XINPUT_VIRTUAL_KEY.Y;
pub const VK_PAD_RSHOULDER = XINPUT_VIRTUAL_KEY.RSHOULDER;
pub const VK_PAD_LSHOULDER = XINPUT_VIRTUAL_KEY.LSHOULDER;
pub const VK_PAD_LTRIGGER = XINPUT_VIRTUAL_KEY.LTRIGGER;
pub const VK_PAD_RTRIGGER = XINPUT_VIRTUAL_KEY.RTRIGGER;
pub const VK_PAD_DPAD_UP = XINPUT_VIRTUAL_KEY.DPAD_UP;
pub const VK_PAD_DPAD_DOWN = XINPUT_VIRTUAL_KEY.DPAD_DOWN;
pub const VK_PAD_DPAD_LEFT = XINPUT_VIRTUAL_KEY.DPAD_LEFT;
pub const VK_PAD_DPAD_RIGHT = XINPUT_VIRTUAL_KEY.DPAD_RIGHT;
pub const VK_PAD_START = XINPUT_VIRTUAL_KEY.START;
pub const VK_PAD_BACK = XINPUT_VIRTUAL_KEY.BACK;
pub const VK_PAD_LTHUMB_PRESS = XINPUT_VIRTUAL_KEY.LTHUMB_PRESS;
pub const VK_PAD_RTHUMB_PRESS = XINPUT_VIRTUAL_KEY.RTHUMB_PRESS;
pub const VK_PAD_LTHUMB_UP = XINPUT_VIRTUAL_KEY.LTHUMB_UP;
pub const VK_PAD_LTHUMB_DOWN = XINPUT_VIRTUAL_KEY.LTHUMB_DOWN;
pub const VK_PAD_LTHUMB_RIGHT = XINPUT_VIRTUAL_KEY.LTHUMB_RIGHT;
pub const VK_PAD_LTHUMB_LEFT = XINPUT_VIRTUAL_KEY.LTHUMB_LEFT;
pub const VK_PAD_LTHUMB_UPLEFT = XINPUT_VIRTUAL_KEY.LTHUMB_UPLEFT;
pub const VK_PAD_LTHUMB_UPRIGHT = XINPUT_VIRTUAL_KEY.LTHUMB_UPRIGHT;
pub const VK_PAD_LTHUMB_DOWNRIGHT = XINPUT_VIRTUAL_KEY.LTHUMB_DOWNRIGHT;
pub const VK_PAD_LTHUMB_DOWNLEFT = XINPUT_VIRTUAL_KEY.LTHUMB_DOWNLEFT;
pub const VK_PAD_RTHUMB_UP = XINPUT_VIRTUAL_KEY.RTHUMB_UP;
pub const VK_PAD_RTHUMB_DOWN = XINPUT_VIRTUAL_KEY.RTHUMB_DOWN;
pub const VK_PAD_RTHUMB_RIGHT = XINPUT_VIRTUAL_KEY.RTHUMB_RIGHT;
pub const VK_PAD_RTHUMB_LEFT = XINPUT_VIRTUAL_KEY.RTHUMB_LEFT;
pub const VK_PAD_RTHUMB_UPLEFT = XINPUT_VIRTUAL_KEY.RTHUMB_UPLEFT;
pub const VK_PAD_RTHUMB_UPRIGHT = XINPUT_VIRTUAL_KEY.RTHUMB_UPRIGHT;
pub const VK_PAD_RTHUMB_DOWNRIGHT = XINPUT_VIRTUAL_KEY.RTHUMB_DOWNRIGHT;
pub const VK_PAD_RTHUMB_DOWNLEFT = XINPUT_VIRTUAL_KEY.RTHUMB_DOWNLEFT;

pub const XINPUT_GAMEPAD_BUTTON = enum(u16) {
    DPAD_UP = 0x0001,
    DPAD_DOWN = 0x0002,
    DPAD_LEFT = 0x0004,
    DPAD_RIGHT = 0x0008,
    START = 0x0010,
    BACK = 0x0020,
    LEFT_THUMB = 0x0040,
    RIGHT_THUMB = 0x0080,
    LEFT_SHOULDER = 0x0100,
    RIGHT_SHOULDER = 0x0200,
    A = 0x1000,
    B = 0x2000,
    X = 0x4000,
    Y = 0x8000,
};

pub const XINPUT_GAMEPAD = extern struct {
    wButtons: u16,
    bLeftTrigger: u8,
    bRightTrigger: u8,
    sThumbLX: i16,
    sThumbLY: i16,
    sThumbRX: i16,
    sThumbRY: i16,
};

pub const XINPUT_STATE = extern struct {
    dwPacketNumber: u32,
    Gamepad: XINPUT_GAMEPAD,
};

pub const XINPUT_VIBRATION = extern struct {
    wLeftMotorSpeed: u16,
    wRightMotorSpeed: u16,
};

pub const XINPUT_CAPABILITIES = extern struct {
    Type: u8,
    SubType: u8,
    Flags: u16,
    Gamepad: XINPUT_GAMEPAD,
    Vibration: XINPUT_VIBRATION,
};

pub const XINPUT_BATTERY_INFORMATION = extern struct {
    BatteryType: u8,
    BatteryLevel: u8,
};

pub const XINPUT_KEYSTROKE = extern struct {
    VirtualKey: XINPUT_VIRTUAL_KEY,
    Unicode: u16,
    Flags: u16,
    UserIndex: u8,
    HidCode: u8,
};

//--------------------------------------------------------------------------------
// Section: Functions (7)
//--------------------------------------------------------------------------------
pub extern "xinput1_4" fn XInputGetState(
    dwUserIndex: u32,
    pState: ?*XINPUT_STATE,
) callconv(@import("std").os.windows.WINAPI) u32;

pub extern "xinput1_4" fn XInputSetState(
    dwUserIndex: u32,
    pVibration: ?*XINPUT_VIBRATION,
) callconv(@import("std").os.windows.WINAPI) u32;

pub extern "xinput1_4" fn XInputGetCapabilities(
    dwUserIndex: u32,
    dwFlags: u32,
    pCapabilities: ?*XINPUT_CAPABILITIES,
) callconv(@import("std").os.windows.WINAPI) u32;

pub extern "xinput1_4" fn XInputEnable(
    enable: BOOL,
) callconv(@import("std").os.windows.WINAPI) void;

pub extern "xinput1_4" fn XInputGetAudioDeviceIds(
    dwUserIndex: u32,
    pRenderDeviceId: ?[*:0]u16,
    pRenderCount: ?*u32,
    pCaptureDeviceId: ?[*:0]u16,
    pCaptureCount: ?*u32,
) callconv(@import("std").os.windows.WINAPI) u32;

pub extern "xinput1_4" fn XInputGetBatteryInformation(
    dwUserIndex: u32,
    devType: u8,
    pBatteryInformation: ?*XINPUT_BATTERY_INFORMATION,
) callconv(@import("std").os.windows.WINAPI) u32;

pub extern "xinput1_4" fn XInputGetKeystroke(
    dwUserIndex: u32,
    dwReserved: u32,
    pKeystroke: ?*XINPUT_KEYSTROKE,
) callconv(@import("std").os.windows.WINAPI) u32;

//--------------------------------------------------------------------------------
// Section: Imports (1)
//--------------------------------------------------------------------------------
const BOOL = @import("std").os.windows.BOOL;

test {
    @setEvalBranchQuota(comptime @import("std").meta.declarations(@This()).len * 3);

    // reference all the pub declarations
    if (!@import("builtin").is_test) return;
    inline for (comptime @import("std").meta.declarations(@This())) |decl| {
        _ = @field(@This(), decl.name);
    }
}
