const std = @import("std");
const za = @import("zalgebra");
const Vec3 = za.Vec3;
const Mat4 = za.Mat4;
const gl = @import("webgl.zig");
const keys = @import("keys.zig");
const print = @import("wasmglue.zig").print;

program: c_uint = undefined,
mvp_loc: c_int = undefined,
color_loc: c_int = undefined,
cam_x: f32 = 0,
cam_y: f32 = 0,
frame: usize = 0,

const Self = @This();

pub fn onInit(logo_data: []const f32) Self {
    print("init LogoRenderer", .{});

    gl.glEnable(gl.GL_DEPTH_TEST);

    const vert_src = @embedFile("shaders/transform.vert");
    const frag_src = @embedFile("shaders/color.frag");
    const vert_shader = gl.glInitShader(vert_src, vert_src.len, gl.GL_VERTEX_SHADER);
    const frag_shader = gl.glInitShader(frag_src, frag_src.len, gl.GL_FRAGMENT_SHADER);
    const program = gl.glLinkShaderProgram(vert_shader, frag_shader);
    gl.glUseProgram(program);
    const mvp_loc = gl.glGetUniformLocation(program, "mvp", 3);
    const color_loc = gl.glGetUniformLocation(program, "color", 5);

    var buf: c_uint = undefined;
    gl.glGenBuffers(1, &buf);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, buf);

    const vertex_data: []const f32 = logo_data;
    gl.glBufferData(gl.GL_ARRAY_BUFFER, vertex_data.len * @sizeOf(f32), @ptrCast(vertex_data.ptr), gl.GL_STATIC_DRAW);

    return Self{
        .program = program,
        .mvp_loc = mvp_loc,
        .color_loc = color_loc,
    };
}

pub fn onKeyDown(self: *Self, key: c_uint) void {
    print("ZIG: ONKEYDOWN {any}", .{key});

    switch (key) {
        keys.KEY_LEFT => self.cam_x -= 0.1,
        keys.KEY_RIGHT => self.cam_x += 0.1,
        keys.KEY_DOWN => self.cam_y -= 0.1,
        keys.KEY_UP => self.cam_y += 0.1,
        else => {},
    }
}

pub fn onAnimationFrame(self: *Self, video_width: f32, video_height: f32) void {
    const projection = za.perspective(45.0, video_width / video_height, 0.1, 10.0);
    const view = Mat4.fromTranslate(Vec3.new(self.cam_x, self.cam_y, -4));
    const model = Mat4.fromRotation(@floatFromInt(2 * self.frame), Vec3.up());

    gl.glUseProgram(self.program);

    const mvp = projection.mul(view.mul(model));
    gl.glUniformMatrix4fv(self.mvp_loc, 1, gl.GL_FALSE, &mvp.data[0]);

    gl.glEnableVertexAttribArray(0);
    gl.glVertexAttribPointer(0, 3, gl.GL_FLOAT, gl.GL_FALSE, 0, null);

    gl.glUniform4f(self.color_loc, 0.97, 0.64, 0.11, 1);
    gl.glDrawArrays(gl.GL_TRIANGLES, 0, 120);
    gl.glUniform4f(self.color_loc, 0.98, 0.82, 0.6, 1);
    gl.glDrawArrays(gl.GL_TRIANGLES, 120, 66);
    gl.glUniform4f(self.color_loc, 0.6, 0.35, 0.02, 1);
    gl.glDrawArrays(gl.GL_TRIANGLES, 186, 90);

    self.frame += 1;
}
