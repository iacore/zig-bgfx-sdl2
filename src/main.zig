const std = @import("std");

const assert = std.debug.assert;
const meta = std.meta;
const builtin = @import("builtin");

const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("string.h");
    @cInclude("unistd.h");
    @cInclude("time.h");
    @cInclude("errno.h");
    @cInclude("stdintfix.h"); // NB: Required as zig is unable to process some macros

    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_syswm.h");

    @cInclude("GL/gl.h");
    @cInclude("GL/glx.h");
    @cInclude("GL/glext.h");

    @cInclude("bgfx/c99/bgfx.h");
});

fn sdlSetWindow(window: *c.SDL_Window) !void {
    var wmi: c.SDL_SysWMinfo = undefined;
    wmi.version.major = c.SDL_MAJOR_VERSION;
    wmi.version.minor = c.SDL_MINOR_VERSION;
    wmi.version.patch = c.SDL_PATCHLEVEL;
    if (c.SDL_GetWindowWMInfo(window, &wmi) == c.SDL_FALSE) {
        return error.SDL_FAILED_INIT;
    }

    var pd = std.mem.zeroes(c.bgfx_platform_data_t);

    if (builtin.os.tag == .linux) {
        pd.ndt = wmi.info.x11.display;
        pd.nwh = @ptrFromInt(wmi.info.x11.window);
    }
    if (builtin.os.tag == .freebsd) {
        pd.ndt = wmi.info.x11.display;
        pd.nwh = @ptrFromInt(wmi.info.x11.window);
    }
    if (builtin.os.tag == .macos) {
        pd.ndt = null;
        pd.nwh = wmi.info.cocoa.window;
    }
    if (builtin.os.tag == .windows) {
        pd.ndt = null;
        pd.nwh = wmi.info.win.window;
    }
    //if (builtin.os.tag == .steamlink) {
    //    pd.ndt = wmi.info.vivante.display;
    //    pd.nwh = wmi.info.vivante.window;
    //}
    pd.context = null;
    pd.backBuffer = null;
    pd.backBufferDS = null;
    c.bgfx_set_platform_data(&pd);
}

pub fn main() !void {
    _ = c.SDL_Init(0);
    defer c.SDL_Quit();
    const window = c.SDL_CreateWindow("bgfx", c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, 800, 600, c.SDL_WINDOW_SHOWN | c.SDL_WINDOW_RESIZABLE).?;
    defer c.SDL_DestroyWindow(window);
    try sdlSetWindow(window);

    var in = std.mem.zeroes(c.bgfx_init_t);
    in.type = c.BGFX_RENDERER_TYPE_COUNT; // Automatically choose a renderer.
    in.resolution.width = 800;
    in.resolution.height = 600;
    in.resolution.reset = c.BGFX_RESET_VSYNC;
    var success = c.bgfx_init(&in);
    defer c.bgfx_shutdown();
    assert(success);

    c.bgfx_set_debug(c.BGFX_DEBUG_TEXT);

    c.bgfx_set_view_clear(0, c.BGFX_CLEAR_COLOR | c.BGFX_CLEAR_DEPTH, 0x443355FF, 1.0, 0);
    c.bgfx_set_view_rect(0, 0, 0, 800, 600);

    var frame_number: u64 = 0;
    gameloop: while (true) {
        var event: c.SDL_Event = undefined;
        var should_exit = false;
        while (c.SDL_PollEvent(&event) == 1) {
            switch (event.type) {
                c.SDL_QUIT => should_exit = true,

                c.SDL_WINDOWEVENT => {
                    const wev = &event.window;
                    switch (wev.event) {
                        c.SDL_WINDOWEVENT_RESIZED, c.SDL_WINDOWEVENT_SIZE_CHANGED => {},

                        c.SDL_WINDOWEVENT_CLOSE => should_exit = true,

                        else => {},
                    }
                },

                else => {},
            }
        }
        if (should_exit) break :gameloop;

        c.bgfx_set_view_rect(0, 0, 0, 800, 600);
        c.bgfx_touch(0);
        c.bgfx_dbg_text_clear(0, false);
        c.bgfx_dbg_text_printf(0, 1, 0x4f, "Frame#:%d", frame_number);
        frame_number = c.bgfx_frame(false);
    }
}
