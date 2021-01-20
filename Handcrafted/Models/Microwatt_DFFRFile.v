/*
 * Microwatt DFFRFile
 *
 * 64x64bit register File with 3R and 1W ports and clock gating for SKY130A
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
    input [5:0]   R1, R2, R3, RW,
    input [63:0]  DW,
    output [63:0] D1, D2, D3,
    input CLK,
    input WE
);

    wire [63:0] sel1, sel2, sel3, selw;

    DEC6x64 DEC0 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
    `endif
        .A(R1),
        .SEL(sel1)
    );

    DEC6x64 DEC1 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
    `endif
        .A(R2),
        .SEL(sel2)
    );

    DEC6x64 DEC2 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
    `endif
        .A(R3),
        .SEL(sel3)
    );

    DEC6x64 DEC3 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
    `endif
        .A(RW),
        .SEL(selw)
    );

    generate
        genvar e;
        for (e=0; e<64; e=e+1)
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
    wire [63:0] fwd_wire;
    wire we_wire;
    wire [7:0] we_wire_buf;
    wire [7:0] SEL1_B, SEL2_B, SEL3_B;
    wire [7:0] GCLK;

    sky130_fd_sc_hd__inv_2 INV1[7:0] (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .A(SEL1),
        .Y(SEL1_B)
    );

    sky130_fd_sc_hd__inv_2 INV2[7:0] (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .A(SEL2),
        .Y(SEL2_B)
    );

    sky130_fd_sc_hd__inv_2 INV3[7:0] (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .A(SEL3),
        .Y(SEL3_B)
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

    sky130_fd_sc_hd__clkbuf_2 WIREBUF[7:0] (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .A(we_wire),
        .X(we_wire_buf)
    );

    sky130_fd_sc_hd__dlclkp_1 CG[7:0] (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .CLK(CLK),
        .GATE(we_wire),
        .GCLK(GCLK)
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
                .CLK(GCLK[i/8]),
                .D(DW[i]),
                .Q(q_wire[i])
            );

            sky130_fd_sc_hd__mux2_1 FWD_MUX (
            `ifdef USE_POWER_PINS
                .VPWR(VPWR),
                .VGND(VGND),
                .VPB(VPWR),
                .VNB(VGND),
            `endif
                .A0(q_wire[i]),
                .A1(DW[i]),
                .S(we_wire_buf[i/8]),
                .X(fwd_wire[i])
            );

            sky130_fd_sc_hd__ebufn_2 OBUF1 (
            `ifdef USE_POWER_PINS
                .VPWR(VPWR),
                .VGND(VGND),
                .VPB(VPWR),
                .VNB(VGND),
            `endif
                .TE_B(SEL1_B[i/8]),
                .A(fwd_wire[i]),
                .Z(D1[i])
            );

            sky130_fd_sc_hd__ebufn_2 OBUF2 (
            `ifdef USE_POWER_PINS
                .VPWR(VPWR),
                .VGND(VGND),
                .VPB(VPWR),
                .VNB(VGND),
            `endif
                .TE_B(SEL2_B[i/8]),
                .A(fwd_wire[i]),
                .Z(D2[i])
            );

            sky130_fd_sc_hd__ebufn_2 OBUF3 (
            `ifdef USE_POWER_PINS
                .VPWR(VPWR),
                .VGND(VGND),
                .VPB(VPWR),
                .VNB(VGND),
            `endif
                .TE_B(SEL3_B[i/8]),
                .A(fwd_wire[i]),
                .Z(D3[i])
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

module DEC6x64 (
`ifdef USE_POWER_PINS
    input VPWR,
    input VGND,
`endif
    input  [5:0]  A,
    output [63:0] SEL
);
    wire [7:0] EN;

    DEC3x8 D (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
    `endif
        .A(A[5:3]),
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

    DEC3x8 D4 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
    `endif
        .A(A[2:0]),
        .SEL(SEL[39:32]),
        .EN(EN[4])
    );

    DEC3x8 D5 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
    `endif
        .A(A[2:0]),
        .SEL(SEL[47:40]),
        .EN(EN[5])
    );

    DEC3x8 D6 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
    `endif
        .A(A[2:0]),
        .SEL(SEL[55:48]),
        .EN(EN[6])
    );

    DEC3x8 D7 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
    `endif
        .A(A[2:0]),
        .SEL(SEL[63:56]),
        .EN(EN[7])
    );
endmodule

module MUX2x1_32(
`ifdef USE_POWER_PINS
    input VPWR,
    input VGND,
`endif
    input   [31:0]      A0, A1,
    input   [0:0]       S,
    output  [31:0]      X
);
    sky130_fd_sc_hd__mux2_1 MUX[31:0] (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .A0(A0),
        .A1(A1),
        .S(S[0]),
        .X(X)
    );
endmodule
