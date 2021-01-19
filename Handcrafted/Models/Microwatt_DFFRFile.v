/*
 * Microwatt DFFRFile
 *
 * 32x64 Register File with 3R1W ports and clock gating for SKY130A
 *
 * Author: Anton Blanchard <anton@linux.ibm.com>
 *
 * Based on DFFRFILE:
 * Author: Mohamed Shalan <mshalan@aucegypt.edu>
 */

`timescale 1ns / 1ps
`default_nettype none

module Microwatt_DFFRFile (
`ifdef USE_POWER_PINS
    input VPWR,
    input VGND,
`endif
    input [4:0]   R1, R2, R3, RW,
    input [63:0]  DW,
    output [63:0] D1, D2, D3,
    input CLK,
    input WE
);

    wire [31:0] sel1, sel2, sel3, selw;

    DEC5x32 DEC0 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
    `endif
        .A(R1),
        .SEL(sel1)
    );

    DEC5x32 DEC1 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
    `endif
        .A(R2),
        .SEL(sel2)
    );

    DEC5x32 DEC2 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
    `endif
        .A(R3),
        .SEL(sel3)
    );

    DEC5x32 DEC3 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
    `endif
        .A(RW),
        .SEL(selw)
    );

    generate
        genvar e;
        for (e=0; e<32; e=e+1)
            RFWORD RFW (
            `ifdef USE_POWER_PINS
                .VPWR(VPWR),
                .VGND(VGND),
            `endif
                .CLK(CLK),
                .WE(WE),
                .SEL1(sel1[e]),
                .SEL2(sel2[e]),
                .SEL3(sel3[e]),
                .SELW(selw[e]),
                .D1(D1),
                .D2(D2),
                .D3(D3),
                .DW(DW)
            );
    endgenerate

endmodule
module RFWORD (
`ifdef USE_POWER_PINS
    input VPWR,
    input VGND,
`endif
    input CLK,
    input WE,
    input SEL1, SEL2, SEL3, SELW,
    output [63:0] D1, D2, D3,
    input [63:0] DW
);

    wire [63:0] q_wire;
    wire we_wire;
    wire [7:0] SEL1_B, SEL2_B, SEL3_B;
    wire [7:0] GCLK;

    sky130_fd_sc_hd__inv_2 INV1[7:0] (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .Y(SEL1_B),
        .A(SEL1)
    );

    sky130_fd_sc_hd__inv_2 INV2[7:0] (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .Y(SEL2_B),
        .A(SEL2)
    );

    sky130_fd_sc_hd__inv_2 INV3[7:0] (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .Y(SEL3_B),
        .A(SEL3)
    );

    sky130_fd_sc_hd__and2_1 CGAND (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .A(SELW),
        .B(WE),
        .X(we_wire)
    );

    sky130_fd_sc_hd__dlclkp_1 CG[7:0] (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .CLK(CLK),
        .GCLK(GCLK),
        .GATE(we_wire)
    );

    generate
        genvar i;
        for (i=0; i<64; i=i+1) begin : BIT
            sky130_fd_sc_hd__dfxtp_1 FF (
            `ifdef USE_POWER_PINS
                .VPWR(VPWR),
                .VGND(VGND),
                .VPB(VPWR),
                .VNB(VGND),
            `endif
                .D(DW[i]),
                .Q(q_wire[i]),
                .CLK(GCLK[i/8])
            );

            sky130_fd_sc_hd__ebufn_2 OBUF1 (
            `ifdef USE_POWER_PINS
                .VPWR(VPWR),
                .VGND(VGND),
                .VPB(VPWR),
                .VNB(VGND),
            `endif
                .A(q_wire[i]),
                .Z(D1[i]),
                .TE_B(SEL1_B[i/8])
            );

            sky130_fd_sc_hd__ebufn_2 OBUF2 (
            `ifdef USE_POWER_PINS
                .VPWR(VPWR),
                .VGND(VGND),
                .VPB(VPWR),
                .VNB(VGND),
            `endif
                .A(q_wire[i]),
                .Z(D2[i]),
                .TE_B(SEL2_B[i/8])
            );

            sky130_fd_sc_hd__ebufn_2 OBUF3 (
            `ifdef USE_POWER_PINS
                .VPWR(VPWR),
                .VGND(VGND),
                .VPB(VPWR),
                .VNB(VGND),
            `endif
                .A(q_wire[i]),
                .Z(D3[i]),
                .TE_B(SEL3_B[i/8])
            );
        end
    endgenerate
endmodule

module DEC2x4 (
`ifdef USE_POWER_PINS
    input VPWR,
    input VGND,
`endif
    input           EN,
    input   [1:0]   A,
    output  [3:0]   SEL
);
    sky130_fd_sc_hd__nor3b_4 AND0 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .Y(SEL[0]),
        .A(A[0]),
        .B(A[1]),
        .C_N(EN)
    );

    sky130_fd_sc_hd__and3b_4 AND1 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .X(SEL[1]),
        .A_N(A[1]),
        .B(A[0]),
        .C(EN)
    );

    sky130_fd_sc_hd__and3b_4 AND2 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .X(SEL[2]),
        .A_N(A[0]),
        .B(A[1]),
        .C(EN)
    );

    sky130_fd_sc_hd__and3_4  AND3 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .X(SEL[3]),
        .A(A[1]),
        .B(A[0]),
        .C(EN)
    );

endmodule

module DEC3x8 (
`ifdef USE_POWER_PINS
    input VPWR,
    input VGND,
`endif
    input           EN,
    input [2:0]     A,
    output [7:0]    SEL
);
    sky130_fd_sc_hd__nor4b_2  AND0 ( // 000
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .Y(SEL[0]),
        .A(A[0]),
        .B(A[1]),
        .C(A[2]),
        .D_N(EN)
    );

    sky130_fd_sc_hd__and4bb_2 AND1 ( // 001
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .X(SEL[1]),
        .A_N(A[2]),
        .B_N(A[1]),
        .C(A[0]),
        .D(EN)
    );

    sky130_fd_sc_hd__and4bb_2 AND2 ( // 010
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .X(SEL[2]),
        .A_N(A[2]),
        .B_N(A[0]),
        .C(A[1]),
        .D(EN)
    );

    sky130_fd_sc_hd__and4b_2  AND3 ( // 011
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .X(SEL[3]),
        .A_N(A[2]),
        .B(A[1]),
        .C(A[0]),
        .D(EN)
    );

    sky130_fd_sc_hd__and4bb_2 AND4 ( // 100
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .X(SEL[4]),
        .A_N(A[0]),
        .B_N(A[1]),
        .C(A[2]),
        .D(EN)
    );

    sky130_fd_sc_hd__and4b_2  AND5 ( // 101
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .X(SEL[5]),
        .A_N(A[1]),
        .B(A[0]),
        .C(A[2]),
        .D(EN)
    );

    sky130_fd_sc_hd__and4b_2  AND6 ( // 110
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .X(SEL[6]),
        .A_N(A[0]),
        .B(A[1]),
        .C(A[2]),
        .D(EN)
    );

    sky130_fd_sc_hd__and4_2   AND7 ( // 111
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .X(SEL[7]),
        .A(A[0]),
        .B(A[1]),
        .C(A[2]),
        .D(EN)
    );
endmodule

module DEC5x32 (
`ifdef USE_POWER_PINS
    input VPWR,
    input VGND,
`endif
    input  [4:0]  A,
    output [31:0] SEL
);
    wire [3:0] EN;

    DEC2x4 D (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
    `endif
        .A(A[4:3]),
        .SEL(EN),
        .EN(1'b1)
    );

    DEC3x8 D0 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
    `endif
        .A(A[2:0]),
        .SEL(SEL[7:0]),
        .EN(EN[0])
    );

    DEC3x8 D1 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
    `endif
        .A(A[2:0]),
        .SEL(SEL[15:8]),
        .EN(EN[1])
    );

    DEC3x8 D2 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
    `endif
        .A(A[2:0]),
        .SEL(SEL[23:16]),
        .EN(EN[2])
    );

    DEC3x8 D3 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
    `endif
        .A(A[2:0]),
        .SEL(SEL[31:24]),
        .EN(EN[3])
    );
endmodule
