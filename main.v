`timescale 1 us / 1 us

module main;
    wire clk;
    engine #(.FPS(60)) e(clk);

    reg [31:0] cnt = 0;
    always @(posedge clk) begin
        $display("%d: tictoc", cnt);
        cnt <= cnt + 1;
    end
endmodule

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

