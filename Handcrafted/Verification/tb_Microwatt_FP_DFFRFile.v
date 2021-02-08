/*
 * A testbench to verify Microwatt_DFFRFile
 * Author: Anton Blanchard <anton@linux.ibm.com>
 */

`define UNIT_DELAY #1
`define USE_POWER_PINS

`include "libs.ref/sky130_fd_sc_hd/verilog/primitives.v"
`include "libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v"

`include "Microwatt_FP_DFFRFile.v"

module tb_Microwatt_DFFRFile;
    reg CLK;
    reg [6:0] R1;
    reg [6:0] R2;
    reg [6:0] R3;
    reg [6:0] RW;
    wire [63:0] D1;
    wire [63:0] D2;
    wire [63:0] D3;
    reg [63:0] DW;
    reg WE;

    reg [7:0] HEX_DIG;
    reg [63:0] FMT_HEX_DIG;

    reg VPWR;
    reg VGND;

    Microwatt_FP_DFFRFile Microwatt_FP_DFFRFile (
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
        $dumpfile("tb_Microwatt_FP_DFFRFile.vcd");
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
        for (i=0; i<80; i=i+1) begin
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
        for (i=0; i<80; i=i+1) begin
            R1 = i%80;
            R2 = (i+1)%80;
            R3 = (i+2)%80;
            #1
            HEX_DIG = R1;
            FMT_HEX_DIG = {8{HEX_DIG}};
            if (D1 !== FMT_HEX_DIG) begin
                $display("R1 bad register read exp %x got %x", FMT_HEX_DIG, D1);
                //$fatal;
            end
            HEX_DIG = R2;
            FMT_HEX_DIG = {8{HEX_DIG}};
            if (D2 !== FMT_HEX_DIG) begin
                $display("R2 bad register read exp %x got %x", FMT_HEX_DIG, D2);
                //$fatal;
            end
            HEX_DIG = R3;
            FMT_HEX_DIG = {8{HEX_DIG}};
            if (D3 !== FMT_HEX_DIG) begin
                $display("R3 bad register read exp %x got %x", FMT_HEX_DIG, D3);
                //$fatal;
            end
        end

        // Test forwarding
        @(posedge CLK);
        HEX_DIG = 4'hF;
        FMT_HEX_DIG = {8{HEX_DIG}};
        RW = 11;
        DW = FMT_HEX_DIG;
        WE = 1'b1;
        R1 = 11;
        R2 = 10;
        R3 = 12;
        #1
        if (D1 !== FMT_HEX_DIG) begin
            $display("R3 bad register read exp %x got %x", FMT_HEX_DIG, D1);
            $fatal;
        end
        HEX_DIG = 4'hA;
        FMT_HEX_DIG = {8{HEX_DIG}};
        if (D2 !== FMT_HEX_DIG) begin
            $display("R3 bad register read exp %x got %x", FMT_HEX_DIG, D2);
            $fatal;
        end
        HEX_DIG = 4'hC;
        FMT_HEX_DIG = {8{HEX_DIG}};
        if (D3 !== FMT_HEX_DIG) begin
            $display("R3 bad register read exp %x got %x", FMT_HEX_DIG, D3);
            $fatal;
        end

        $finish;
    end
endmodule
