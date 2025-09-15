const std = @import("std");
const stdin = std.io.getStdIn().reader(); // to read the use input
const stdout = std.io.getStdOut().writer(); // to put output

// the function for clearing the screen
fn clear_screen() !void {
    try stdout.print("\x1b[2J\x1b[H", .{});
}

// the mian struct that of tasks
const taskss = struct {
    name: []u8,
    toggled: bool,
};

pub fn main() !void {
    // a heap allocator
    var gpa = std.heap.page_allocator;
    // a vector that is going to store all the tasks
    var tasks = std.ArrayList(taskss).init(gpa);
    defer tasks.deinit();

    // the main loop
    while (true) {
        try stdout.print("> ", .{});
        var buf: [100]u8 = undefined; // the buffer that i will read from
        const input = try stdin.readUntilDelimiterOrEof(&buf, '\n'); // the use fill the buf string

        // checking commands and stuff
        if (input) |line| {
            if (std.mem.eql(u8, line, "exit")) {
                break; // quiting out of the loop and the app
            } else if (std.mem.eql(u8, line, "clear")) {
                try clear_screen(); // clearing the screen
            } else if (std.mem.eql(u8, line, "help")) {
                // the help commmand
                try stdout.print("__________________________________________________\n", .{});
                try stdout.print("clear               - To Clear The Screen \n", .{});
                try stdout.print("exit                - To Quit The Program \n", .{});
                try stdout.print("add (task name)     - To add a todo task\n", .{});
                try stdout.print("toggle (task index) - To a toggle task\n", .{});
                try stdout.print("__________________________________________________\n", .{});
            } else if (std.mem.startsWith(u8, line, "add ")) {
                const task_name = try gpa.dupe(u8, line[4..]);
                const new_task = taskss{ .name = task_name, .toggled = false };
                try tasks.append(new_task);
                try stdout.print("You added: {s}, to the tasks\n", .{task_name});
            } else if (std.mem.eql(u8, line, "list")) {
                for (tasks.items, 0..) |t, i| {
                    const status = if (t.toggled) "[x]" else "[ ]";
                    try stdout.print("{d}. {s} {s}\n", .{
                        i + 1,
                        t.name,
                        status,
                    });
                }
            } else if (std.mem.startsWith(u8, line, "toggle ")) {
                const raw = line[7..];
                const num_str = std.mem.trim(u8, raw, " \n\r\t");
                const index = try std.fmt.parseInt(usize, num_str, 10);

                if (index > 0 and index <= tasks.items.len) {
                    tasks.items[index - 1].toggled = !tasks.items[index - 1].toggled;
                    try stdout.print("Toggled task {d}\n", .{index});
                } else {
                    try stdout.print("No such task {d}\n", .{index});
                }
            } else if (std.mem.startsWith(u8, line, "delete ")) {
                const raw = line[7..];
                const num_str = std.mem.trim(u8, raw, " \n\r\t");
                const index = try std.fmt.parseInt(usize, num_str, 10);

                if (index > 0 and index <= tasks.items.len) {
                    _ = tasks.orderedRemove(index - 1);
                    try stdout.print("task Removed {d}\n", .{index});
                } else {
                    try stdout.print("No such task {d}\n", .{index});
                }
            } else {
                try stdout.print("Unknow command: {s}, type 'help' to see available commands\n", .{line});
            }
        } else {
            break;
        }
    }
}
