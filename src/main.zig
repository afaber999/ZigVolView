const std = @import("std");
const za = @import("zalgebra");
const Vec3 = za.Vec3;
const Mat4 = za.Mat4;
const gl = @import("webgl.zig");
const keys = @import("keys.zig");
const glue = @import("wasmglue.zig");
const LogoRenderer = @import("LogoRenderer.zig");
const QuadRenderer = @import("QuadRenderer.zig");
const print = glue.print;

var video_width: f32 = 1280;
var video_height: f32 = 720;
var video_scale: f32 = 1;

var logo_renderer: LogoRenderer = undefined;
var quad_renderer: QuadRenderer = undefined;

const c = @cImport({
    //@cDefine("STBI_NO_STDIO", {});
    //@cDefine("STBI_ONLY_JPEG", {});
    @cInclude("stb_image_tmp.h");
});

var logo_data: std.ArrayList(u8) = std.ArrayList(u8).init(std.heap.wasm_allocator);
pub export var global_chunk: [16384]u8 = undefined;

pub export fn pushDataSize() usize {
    return global_chunk.len;
}

pub export fn pushImage(ptr: [*]const u8, len: usize) void {
    print("PUSH IMAGE: {}", .{len});

    // Decode the JPEG data using stb_image
    var width: c_int = 0;
    var height: c_int = 0;
    var channels: c_int = 0;
    const decodedData = c.stbi_load_from_memory(ptr, @intCast(len), &width, &height, &channels, 4);

    _ = decodedData;

    print("WIDTH: {} HEIGHT: {} CHANNELS: {}", .{ width, height, channels });

    // if (decodedData == null) {
    //     //std.debug.print("Failed to decode JPEG image\n", .{});
    //     return;
    // }
}

pub export fn pushData(len: usize) void {
    logo_data.appendSlice(global_chunk[0..len]) catch unreachable;
    print("LOGO SIZE: {}", .{logo_data.items.len});
}

export fn onInit() void {
    print("MAIN ZIG: ONINT", .{});
    const logo: []const f32 = @alignCast(std.mem.bytesAsSlice(f32, logo_data.items));
    gl.glEnable(gl.GL_DEPTH_TEST);
    logo_renderer = LogoRenderer.onInit(logo);
    quad_renderer = QuadRenderer.onInit();
}

export fn onResize(w: c_uint, h: c_uint, s: f32) void {
    video_width = @floatFromInt(w);
    video_height = @floatFromInt(h);
    video_scale = s;
    gl.glViewport(0, 0, @intFromFloat(s * video_width), @intFromFloat(s * video_height));
}

export fn onKeyDown(key: c_uint) void {
    logo_renderer.onKeyDown(key);
    quad_renderer.onKeyDown(key);
}

export fn onAnimationFrame() void {
    gl.glClearColor(0.5, 0.5, 0.5, 1);
    gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT);
    logo_renderer.onAnimationFrame(video_width, video_height);
    quad_renderer.onAnimationFrame();
}
