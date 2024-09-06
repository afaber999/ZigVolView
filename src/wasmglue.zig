const std = @import("std");

pub extern fn logWasm(s: [*]const u8, len: usize) void;

pub fn print(comptime fmt: []const u8, args: anytype) void {
    var buf: [4096]u8 = undefined;
    const slice = std.fmt.bufPrint(&buf, fmt, args) catch unreachable;
    logWasm(slice.ptr, slice.len);
}

pub export fn malloc(size: usize) ?[*]u8 {
    const tot_size = size + @sizeOf(usize);
    const ptr = std.heap.wasm_allocator.allocWithOptions(u8, tot_size, 4, null) catch {
        return null;
    };
    print("mem_alloc: {any} size: {}", .{ ptr.ptr, tot_size });
    @memcpy(ptr[0..@sizeOf(usize)], std.mem.asBytes(&tot_size));
    return ptr[@sizeOf(usize)..].ptr;
}

pub export fn free(ptr: ?[*]u8) void {
    if (ptr) |ptr_val| {
        const real_ptr = ptr_val - @sizeOf(usize);
        const tot_size = std.mem.bytesToValue(usize, real_ptr[0..@sizeOf(usize)]);
        print("mem_free: {any} size: {}", .{ real_ptr, tot_size });
        std.heap.wasm_allocator.free(real_ptr[0..tot_size]);
    } else {
        print("mem_free: null", .{});
    }
}

pub export fn realloc(ptr: ?[*]u8, size: usize) ?[*]u8 {

    if (ptr) |ptr_val| {
        const old_ptr = ptr_val - @sizeOf(usize);
        const old_size = std.mem.bytesToValue(usize, old_ptr[0..@sizeOf(usize)]);
        const new_size = size + @sizeOf(usize);
        const new_ptr = std.heap.wasm_allocator.realloc(old_ptr[0..old_size], new_size) catch {
            return null;
        };
        @memcpy(new_ptr[0..@sizeOf(usize)], std.mem.asBytes(&new_size));
        print("mem_realloc: {any} old_size: {} new_size: {}", .{ new_ptr.ptr, old_size, new_size });
        return new_ptr[@sizeOf(usize)..].ptr;
    } else {
        return malloc(size);
    }
}

pub export fn __assert_fail(_: i32, _: i32, _: i32, _: i32) void {
    @panic("PANIC: __assert_fail");
}
