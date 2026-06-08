const Tokenizer = @This();
const std = @import("std");

buffer: []const u8,
index: usize = 0,

const Token = struct {
    tag: Tag,
    loc: Loc,

    const Loc = struct {
        start: usize,
        end: usize,
    };

    const Tag = enum {
        invalid,
        identifier,
        int_literal,

        equals,
        semicolon,

        keyword_const,
    };

    const keywords: std.StaticStringMap(Tag) = .initComptime(.{
        .{ "const", .keyword_const },
    });
};

const State = enum {
    invalid,
    start,
    identifier,
    number,
    saw_equals,
};

fn nextChar(tokenizer: *Tokenizer) u8 {
    tokenizer.index += 1;
    if (tokenizer.index >= tokenizer.buffer.len) return 0;
    return tokenizer.buffer[tokenizer.index];
}

pub fn next(tokenizer: *Tokenizer) ?Token {
    if (tokenizer.index >= tokenizer.buffer.len) return null;
    var result: Token = .{
        .tag = undefined,
        .loc = .{
            .start = tokenizer.index,
            .end = undefined,
        },
    };
    state: switch (State.start) {
        .start => switch (tokenizer.buffer[tokenizer.index]) {
            ' ', '\n', '\r', '\t' => {
                tokenizer.index += 1;
                result.loc.start = tokenizer.index;
                continue :state .start;
            },
            'a'...'z', 'A'...'Z', '_' => {
                result.tag = .identifier;
                continue :state .identifier;
            },
            '0'...'9' => continue :state .number,
            '=' => continue :state .saw_equals,
            ';' => {
                tokenizer.index += 1;
                result.tag = .semicolon;
            },
            else => continue :state .invalid,
        },
        .invalid => {
            switch (tokenizer.nextChar()) {
                ' ', '\n', 0 => result.tag = .invalid,
                else => continue :state .invalid,
            }
        },
        .identifier => {
            switch (tokenizer.nextChar()) {
                'a'...'z', 'A'...'Z', '0'...'9', '_' => continue :state .identifier,
                else => {
                    const lexeme = tokenizer.buffer[result.loc.start..tokenizer.index];
                    if (Token.keywords.get(lexeme)) |tag| {
                        result.tag = tag;
                    }
                },
            }
        },
        .number => {
            switch (tokenizer.nextChar()) {
                '0'...'9' => continue :state .number,
                else => result.tag = .int_literal,
            }
        },
        .saw_equals => {
            tokenizer.index += 1;
            result.tag = .equals;
        },
    }
    result.loc.end = tokenizer.index;
    return result;
}
