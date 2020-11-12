`timescale 1 us / 1 us

module main;
    wire clk;
    wire [31:0] cnt;

    engine #(.FPS(60)) e(clk);
    control c(clk, cnt);
    view v(clk, cnt);
endmodule

// TODO: use timescale instead of busy loop
module engine(clk);
    parameter FPS = 60.0;
    output reg clk = 0;

    reg [31:0] cnt = 0;
    initial forever #1 begin
        if (cnt * FPS > 499999) begin
            cnt <= 0;
            clk <= ~clk;
        end else begin
            cnt <= cnt + 1;
        end
    end
endmodule

module control(clk, cnt);
    input  wire clk;
    output reg [31:0] cnt;

    initial cnt = 0;
    always @(posedge clk) cnt <= cnt + 1;
endmodule

module view(clk, cnt);
    input  wire clk;
    input  wire [31:0] cnt;

    always @(posedge clk) begin
        // clear entire screen
        $write("\033[2J\033[H");

        $display("%d", cnt);
    end
endmodule

