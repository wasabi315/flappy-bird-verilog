`default_nettype none
`timescale 1 us / 1 us

`define STDIN 32'h8000_0000

module main;
    reg clk = 0;
    initial forever #50 clk <= ~clk;

    wire [7:0] inp;
    keyboard k(clk, inp);

    wire [1:0] scene;
    wire [8:0] bird;
    wire [24*3-1:0] gaps;
    controller c(clk, inp, scene, bird, gaps);
    view v(clk, scene, bird, gaps);
endmodule

module keyboard(clk, inp);
    input  wire clk;
    output reg [7:0] inp;

    initial inp = 0;
    always @(posedge clk) begin
        if ($feof(`STDIN)) $finish();
        inp <= $fgetc(`STDIN);
    end
endmodule

/*

# Data format
- scene: 2bit

- bird
    - altitude: 8bit
    - is_flapping: 1bit

- pipe_gap (x N)
    - position: 8bit
    - max_bnd: 8bit
    - min_bnd: 8bit


                              |   |                 |   |
                              |   |                 |   |
                              |   |                 |   |
                              |   |    max_bnd -->  =====
                              |   |
  max_bnd  ---------------->  =====

  altitude ----> <\\@>                 min_bnd -->  =====
                                                    |   |
  min_bnd  ---------------->  =====                 |   |
                              |   |                 |   |
                              |   |                 |   |
          ----------------------+---------------------+------------------------
                             position              position
*/

`define HEIGHT 40
`define WIDTH 80

`define SCENE_SPLASH   0
`define SCENE_PLAYING  1
`define SCENE_GAMEOVER 2

module controller(clk, inp, scene, bird, gaps);
    input  wire clk;
    input  wire [7:0] inp;
    output reg [1:0] scene;
    output wire [8:0] bird;
    output reg [24*3-1:0] gaps;

    reg is_flapping;
    reg [7:0] altitude;

    initial begin
        scene = `SCENE_SPLASH;
        is_flapping = 1'd0;
        altitude = 8'd20;
        gaps = {
            8'd20, 8'd30, 8'd20,
            8'd40, 8'd25, 8'd15,
            8'd60, 8'd35, 8'd25
        };
    end

    always @(posedge clk) begin
        if (scene == `SCENE_SPLASH && inp != 0) scene <= `SCENE_PLAYING;
        if (scene == `SCENE_PLAYING && inp == 120) scene <= `SCENE_GAMEOVER;
    end

    wire keypress = (inp == /* space */ 32);
    reg [4:0] kpbuf = 5'd0;
    always @(posedge clk) kpbuf <= {keypress, kpbuf[4:1]};

    always @(posedge clk) begin
        is_flapping <= |kpbuf;
        altitude <= (|kpbuf) ? altitude + 8'd1 : altitude;
    end
    assign bird = {altitude, is_flapping};
endmodule

module view(clk, scene, bird, pipes);
    input  wire clk;
    input  wire [1:0] scene;
    input  wire [8:0] bird;
    input  wire [24*3-1:0] pipes;

    wire is_flapping = bird[0];
    wire [7:0] altitude = bird[8:1];

    wire [23:0] pipes1 = pipes[71:48];
    wire [23:0] pipes2 = pipes[47:24];
    wire [23:0] pipes3 = pipes[23: 0];

    ANSI ansi();

    always @(posedge clk) begin
        ansi.clear();
        case (scene)
            `SCENE_SPLASH: begin
                draw_bird();
                draw_pipes();
                draw_splash();
            end

            `SCENE_PLAYING: begin
                draw_bird();
                draw_pipes();
            end

            `SCENE_GAMEOVER: begin
                $display("game over");
            end
        endcase
        ansi.flush();
    end

    task draw_splash;
        begin
            ansi.fg("yellow");
            ansi.goto(16, 16);
            $write("+----------------------------------------------+\n");
            ansi.goto(17, 16);
            $write("|  ___ _                       ___ _        _  |\n");
            ansi.goto(18, 16);
            $write("| | __| |__ _ _ __ _ __ _  _  | _ |_)_ _ __| | |\n");
            ansi.goto(19, 16);
            $write("| | _|| / _` | '_ \\ '_ \\ || | | _ \\ | '_/ _` | |\n");
            ansi.goto(20, 16);
            $write("| |_| |_\\__,_| .__/ .__/\\_, | |___/_|_| \\__,_| |\n");
            ansi.goto(21, 16);
            $write("|            |_|  |_|   |__/                   |\n");
            ansi.goto(22, 16);
            $write("+----------------------------------------------+\n");
            ansi.goto(24, 28);
            $write("press start to flap!!\n");
            ansi.reset();
        end
    endtask

    `define WING_UP   0
    `define WING_DOWN 1
    reg wing = `WING_UP;
    task draw_bird;
        begin
            if (is_flapping) wing <= ~wing;
            case (wing)
                `WING_UP: draw_bird_wing_up();
                `WING_DOWN: draw_bird_wing_down();
            endcase
        end
    endtask

    task draw_bird_wing_up;
        begin
            if (altitude >= 0 && altitude < `HEIGHT - 1) begin
                ansi.goto(`HEIGHT - altitude, 2);
                ansi.fg("yellow");
                $write("<\\\\");
                ansi.fg("white");
                $write("@");
                ansi.fg("red");
                $write(">");
                ansi.goto(`HEIGHT - altitude - 1, 2);
                ansi.fg("yellow");
                $write("\\\\");
                ansi.reset();
            end
        end
    endtask

    task draw_bird_wing_down;
        begin
            if (altitude > 0 && altitude < `HEIGHT) begin
                ansi.goto(`HEIGHT - altitude, 2);
                ansi.fg("yellow");
                $write("<//");
                ansi.fg("white");
                $write("@");
                ansi.fg("red");
                $write(">");
                ansi.goto(`HEIGHT - altitude + 1, 2);
                ansi.fg("yellow");
                $write("//");
                ansi.reset();
            end
        end
    endtask

    task draw_pipes;
        begin
            draw_pipe_pair(pipes1);
            draw_pipe_pair(pipes2);
            draw_pipe_pair(pipes3);
        end
    endtask

    task draw_pipe_pair(input [23:0] pipes);
        integer i;
        begin
            ansi.fg("green");
            for (i = 1; i <= `HEIGHT; i = i + 1) begin
                ansi.goto(i, pipes[23:16] - 2);
                if (i == pipes[15:8] || i == pipes[7:0]) $write("=====");
                else if (i > pipes[15:8] || i < pipes[7:0]) $write("|███|");
            end
            ansi.reset();
        end
    endtask
endmodule

module ANSI;
    task fg(input [8*8:1] color);
        case (color)
            "black":   $write("\033[1;30m");
            "red":     $write("\033[1;31m");
            "green":   $write("\033[1;32m");
            "yellow":  $write("\033[1;33m");
            "blue":    $write("\033[1;34m");
            "magenta": $write("\033[1;35m");
            "cyan":    $write("\033[1;36m");
            "white":   $write("\033[1;37m");
        endcase
    endtask

    task bg(input [8*8:1] color);
        case (color)
            "black":   $write("\033[1;40m");
            "red":     $write("\033[1;41m");
            "green":   $write("\033[1;42m");
            "yellow":  $write("\033[1;43m");
            "blue":    $write("\033[1;44m");
            "magenta": $write("\033[1;45m");
            "cyan":    $write("\033[1;46m");
            "white":   $write("\033[1;47m");
        endcase
    endtask

    task reset;
        $write("\033[0m");
    endtask

    task clear;
        $write("\033[2J\033[H");
    endtask

    task goto(input [7:0] row, input [7:0] col);
        $write("\033[%0d;%0dH", row, col);
    endtask

    task flush;
        $fflush();
    endtask
endmodule
