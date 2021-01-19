/*
 * A testbench to verify Microwatt_DFFRFile
 * Author: Anton Blanchard <anton@linux.ibm.com>
 */

`define UNIT_DELAY #1
`define USE_POWER_PINS

`include "libs.ref/sky130_fd_sc_hd/verilog/primitives.v"
`include "libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v"

`include "Microwatt_DFFRFile.v"

module tb_Microwatt_DFFRFile;
    reg CLK;
    reg [4:0] R1;
    reg [4:0] R2;
    reg [4:0] R3;
    reg [4:0] RW;
    wire [63:0] D1;
    wire [63:0] D2;
    wire [63:0] D3;
    reg [63:0] DW;
    reg WE;

    reg [7:0] HEX_DIG;
    reg [63:0] FMT_HEX_DIG;

    reg VPWR;
    reg VGND;

    Microwatt_DFFRFile Microwatt_DFFRFile (
        .VPWR(VPWR),
        .VGND(VGND),
        .CLK(CLK),
        .R1(R1),
        .R2(R2),
        .R3(R3),
        .RW(RW),
        .D1(D1),
        .D2(D2),
        .D3(D3),
        .DW(DW),
        .WE(WE)
    );

    initial begin
        $dumpfile("tb_Microwatt_DFFRFile.vcd");
        $dumpvars(0, tb_Microwatt_DFFRFile);
    end

    always #10 CLK = !CLK;

    integer i;

    initial begin
        CLK = 0;
        R1 = 0;
        R2 = 0;
        R3 = 0;
        DW = 0;
        RW = 0;
        WE = 0;

        VPWR = 0;
        VGND = 0;
        #50
        VPWR = 1;
        VGND = 0;

        // Initialize register file
        for (i=0; i<32; i=i+1) begin
            HEX_DIG = i;
            FMT_HEX_DIG = {8{HEX_DIG}};

            @(posedge CLK);
            RW = i;
            DW = FMT_HEX_DIG;
            WE = 1'b1;
            @(posedge CLK);
            WE = 1'b0;
        end

        // Read register file
        for (i=0; i<32; i=i+1) begin
            R1 = i%32;
            R2 = (i+1)%32;
            R3 = (i+2)%32;
            #1
            HEX_DIG = R1;
            FMT_HEX_DIG = {8{HEX_DIG}};
            if (D1 != FMT_HEX_DIG) begin
                $display("R1 bad register read exp %x got %x", R1, FMT_HEX_DIG);
                $fatal;
            end
            HEX_DIG = R2;
            FMT_HEX_DIG = {8{HEX_DIG}};
            if (D2 != FMT_HEX_DIG) begin
                $display("R2 bad register read exp %x got %x", R1, FMT_HEX_DIG);
                $fatal;
            end
            HEX_DIG = R3;
            FMT_HEX_DIG = {8{HEX_DIG}};
            if (D3 != FMT_HEX_DIG) begin
                $display("R3 bad register read exp %x got %x", R1, FMT_HEX_DIG);
                $fatal;
            end
        end
    end
endmodule
