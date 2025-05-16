const rl = @import("raylib");
const std = @import("std");

const Camera2D = rl.Camera2D;
const Vec2 = rl.Vector2;
const Rect = rl.Rectangle;

const Game = struct { gameSettings: *GameSettings, p1: *Paddle, p2: *Paddle, ball: *Ball };
const GameSettings = struct { screenW: i32, screenH: i32, p1Score: u8, p2Score: u8, gameStarted: bool, gameSpeed: i8 };
const Paddle = struct { body: rl.Rectangle, speed: f32 };
const Ball = struct { x: i32, y: i32, radius: f32, vel: Vec2 };

const playerWidth = 20;
const playerHeight = 65;

pub fn main() anyerror!void {
    var gameSettings = GameSettings{ .screenW = 800, .screenH = 450, .p1Score = 0, .p2Score = 0, .gameStarted = false, .gameSpeed = 3 };
    const screenWidth: f32 = @floatFromInt(gameSettings.screenW);
    const screenHeight: f32 = @floatFromInt(gameSettings.screenH);

    const playerOneStartPosX = 40.0;
    const playerTwoStartPosX: f32 = @floatFromInt(gameSettings.screenW - 70);
    const playerStartPosY = @divExact(screenHeight, 2);

    var playerOne = Paddle{ .body = Rect.init(playerOneStartPosX, playerStartPosY - playerHeight, playerWidth, playerHeight), .speed = 5.0 };
    var playerTwo = Paddle{ .body = Rect.init(playerTwoStartPosX, playerStartPosY - playerHeight, playerWidth, playerHeight), .speed = 5.0 };
    var ball = Ball{ .x = @divExact(gameSettings.screenW, 2), .y = @divExact(gameSettings.screenH, 2), .radius = 8.0, .vel = Vec2.init(0, 0) };
    var game = Game{ .gameSettings = &gameSettings, .p1 = &playerOne, .p2 = &playerTwo, .ball = &ball };

    rl.initWindow(gameSettings.screenW, gameSettings.screenH, "Pong");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    const camera: rl.Camera2D = .{
        .target = Vec2.init(screenWidth / 2.0, screenHeight / 2.0),
        .offset = Vec2.init(screenWidth / 2.0, screenHeight / 2.0),
        .rotation = 0,
        .zoom = 1,
    };

    try startingGame(&game, camera);
}

pub fn startingGame(game: *Game, camera: Camera2D) !void {
    while (!rl.windowShouldClose()) {
        update(game);
        try render(game, camera);
    }
}

pub fn update(game: *Game) void {
    const playerOne = game.p1.body;
    const playerTwo = game.p2.body;

    const ballXFloat = @as(f32, @floatFromInt(game.ball.x));
    const ballYFloat = @as(f32, @floatFromInt(game.ball.y));

    if (rl.isKeyDown(.w)) {
        if (playerOne.y <= 0) return;
        game.p1.body.y -= game.p1.speed;
    }

    if (rl.isKeyDown(.s)) {
        if (playerOne.y >= @as(f32, @floatFromInt(game.gameSettings.screenH)) - playerOne.height) return;
        game.p1.body.y += game.p1.speed;
    }

    if (rl.isKeyDown(.up)) {
        if (playerTwo.y <= 0) return;
        game.p2.body.y -= game.p2.speed;
    }

    if (rl.isKeyDown(.down)) {
        if (playerTwo.y >= @as(f32, @floatFromInt(game.gameSettings.screenH)) - playerTwo.height) return;
        game.p2.body.y += game.p2.speed;
    }

    if (!game.gameSettings.gameStarted) {
        const rand = std.crypto.random;
        const randBool = rand.boolean();
        if (randBool) {
            game.ball.vel.x = 1;
        } else {
            game.ball.vel.x = -1;
        }
        game.gameSettings.gameStarted = true;
    }

    std.debug.print("Ball Y: {d} \n", .{game.ball.y});
    std.debug.print("PlayerOne Y: {d} \n", .{playerOne.y});

    if (_ballHitsPlayer(playerOne, ballXFloat, ballYFloat)) {
        std.debug.print("Ball hit the PlayerOne \n", .{});
        game.ball.vel.x = 1;
    } else if (_ballHitsPlayer(playerTwo, ballXFloat, ballYFloat)) {
        game.ball.vel.x = -1;
    }
    // Move ball
    game.ball.x += @as(i32, @intFromFloat(game.ball.vel.x)) * 3;
    game.ball.y += @as(i32, @intFromFloat(game.ball.vel.y)) * 3;
}

pub fn render(game: *Game, camera: Camera2D) !void {
    // const deltaTime = rl.getFrameTime();

    rl.beginDrawing();
    defer rl.endDrawing();

    rl.clearBackground(.light_gray);

    {
        var buf: [20]u8 = undefined;
        const ballxstr = try _parseIntToString(game.ball.x, &buf);
        rl.beginMode2D(camera);
        defer rl.endMode2D();
        rl.drawRectangleRec(game.p1.body, .purple);
        rl.drawRectangleRec(game.p2.body, .purple);
        rl.drawCircle(game.ball.x, game.ball.y, game.ball.radius, .black);
        rl.drawText("Cery is cute", 20, 20, 10, .black);
        rl.drawText(ballxstr, 20, 40, 10, .black);
    }
}

fn _parseIntToString(num: i32, buf: []u8) ![:0]u8 {
    return std.fmt.bufPrintZ(buf, "{}", .{num});
}

fn _ballHitsPlayer(player: Rect, ballXFloat: f32, ballYFloat: f32) bool {
    return ballXFloat <= (player.x + playerWidth) and (ballYFloat > player.y and ballYFloat < player.y + playerHeight);
}
