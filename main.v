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

`define SCENE_SPLASH   0
`define SCENE_PLAYING  1
`define SCENE_GAMEOVER 2

module controller(clk, inp, scene, bird, gaps);
    input  wire clk;
    input  wire [7:0] inp;
    output reg [1:0] scene;
    output reg [8:0] bird;
    output reg [24*3-1:0] gaps;

    initial begin
        scene = `SCENE_SPLASH;
        bird = {8'd20, 1'd0};
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
endmodule

module view(clk, scene, bird, gaps);
    input  wire clk;
    input  wire [1:0] scene;
    input  wire [8:0] bird;
    input  wire [24*3-1:0] gaps;

    ANSI ansi();

    always @(posedge clk) begin
        ansi.clear();
        case (scene)
            `SCENE_SPLASH: begin
                draw_splash();
            end

            `SCENE_PLAYING: begin
                draw_bird();
                draw_pipe();
            end

            `SCENE_GAMEOVER: begin
                $display("game over");
            end
        endcase
        ansi.flush();
    end

    task draw_splash;
        begin
            $write({
                " ___ _                       ___ _        _ \n",
                "| __| |__ _ _ __ _ __ _  _  | _ |_)_ _ __| |\n",
                "| _|| / _` | '_ \\ '_ \\ || | | _ \\ | '_/ _` |\n",
                "|_| |_\\__,_| .__/ .__/\\_, | |___/_|_| \\__,_|\n",
                "           |_|  |_|   |__/                  \n"
            });
        end
    endtask

    reg [7:0] cnt = 0;
    reg wing = 0;
    task draw_bird;
        begin
            cnt <= (cnt == 5) ? 0 : cnt + 1;
            if (cnt == 5) wing <= ~wing;
            case (wing)
                0: draw_bird_wing_up();
                1: draw_bird_wing_down();
            endcase
            ansi.reset();
        end
    endtask

    task draw_bird_wing_up;
        begin
            ansi.goto(40 - bird[8:1], 2);
            ansi.fg("yellow");
            $write("<\\\\");
            ansi.fg("white");
            $write("@");
            ansi.fg("red");
            $write(">");
            ansi.goto(40 - bird[8:1] - 1, 2);
            ansi.fg("yellow");
            $write("\\\\");
        end
    endtask

    task draw_bird_wing_down;
        begin
            ansi.goto(40 - bird[8:1], 2);
            ansi.fg("yellow");
            $write("<//");
            ansi.fg("white");
            $write("@");
            ansi.fg("red");
            $write(">");
            ansi.goto(40 - bird[8:1] + 1, 2);
            ansi.fg("yellow");
            $write("//");
        end
    endtask

    integer i;
    integer j;
    task draw_pipe;
        begin
            ansi.fg("green");

            for (i = 1; i <= 40; i = i + 1) begin
                ansi.goto(i, gaps[71:64] - 2);
                if (i == 20 || i == 30) $write("=====");
                else if (i < 20 || i > 30) $write("|███|");
            end

            for (i = 1; i <= 40; i = i + 1) begin
                ansi.goto(i, gaps[47:40] - 2);
                if (i == 15 || i == 25) $write("=====");
                else if (i < 15 || i > 25) $write("|███|");
            end

            for (i = 1; i <= 40; i = i + 1) begin
                ansi.goto(i, gaps[23:16] - 2);
                if (i == 25 || i == 35) $write("=====");
                else if (i < 25 || i > 35) $write("|███|");
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
