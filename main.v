`timescale 1 us / 1 us

`define STDIN 32'h8000_0000

module main;
    reg clk = 0;
    initial forever #1 clk <= ~clk;

    wire [7:0] inp;
    keyboard k(clk, inp);

    wire [31:0] cnt;
    control c(clk, inp, cnt);
    view v(clk, cnt);
endmodule

module keyboard(clk, inp);
    input  wire clk;
    output reg [7:0] inp;

    always @(posedge clk) begin
        if ($feof(`STDIN)) $finish();
        inp <= $fgetc(`STDIN);
    end
endmodule

module control(clk, inp, cnt);
    input  wire clk;
    input  wire [7:0] inp;
    output reg [31:0] cnt = 0;

    always @(posedge clk) if (inp != 0) cnt <= cnt + 1;
    always @(posedge clk) if (cnt == 51) $finish();
endmodule

module view(clk, cnt);
    input  wire clk;
    input  wire [31:0] cnt;

    ANSI ansi();

    integer i;
    always @(posedge clk) begin
        ansi.clear();

        ansi.fg("black");
        ansi.bg("green");
        $write("[%3d%%]", cnt << 1);
        ansi.reset();

        $write(" [");
        for (i = 0; i < 50; i = i + 1)
            if (i < cnt) $write("#");
            else $write(".");
        $write("]");
        ansi.flush();
    end
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

    task flush;
        $display("");
    endtask
endmodule
