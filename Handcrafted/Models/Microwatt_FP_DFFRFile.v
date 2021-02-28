/*
 * Microwatt FP DFFRFile
 *
 * 80x64bit register file (32 GPRs, 32 FPRs, 16 SPRs) with 3R and 1W ports and clock gating for SKY130A
 *
 * Author: Anton Blanchard <anton@linux.ibm.com>
 *
 * Based on DFFRFILE:
 * Author: Mohamed Shalan <mshalan@aucegypt.edu>
 */

`timescale 1ns / 1ps
`default_nettype none

module Microwatt_FP_DFFRFile (
`ifdef USE_POWER_PINS
    input VPWR,
    input VGND,
`endif
    input [6:0]   R1, R2, R3, RW,
    input [63:0]  DW,
    output [63:0] D1, D2, D3,
    input CLK,
    input WE
);

    wire [80-1:0] sel1, sel2, sel3, selw;

    DEC7x80 DEC0 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
    `endif
        .A(R1),
        .SEL(sel1)
    );

    DEC7x80 DEC1 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
    `endif
        .A(R2),
        .SEL(sel2)
    );

    DEC7x80 DEC2 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
    `endif
        .A(R3),
        .SEL(sel3)
    );

    DEC7x80 DEC3 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
    `endif
        .A(RW),
        .SEL(selw)
    );

    generate
        genvar e;
        for (e=0; e<80; e=e+1)
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

            sky130_fd_sc_hd__ebufn_2 OBUF1 (
            `ifdef USE_POWER_PINS
                .VPWR(VPWR),
                .VGND(VGND),
                .VPB(VPWR),
                .VNB(VGND),
            `endif
                .TE_B(SEL1_B[i/8]),
                .A(q_wire[i]),
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
                .A(q_wire[i]),
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
                .A(q_wire[i]),
                .Z(D3[i])
            );
        end
    endgenerate
endmodule

module DEC3x8 (
`ifdef USE_POWER_PINS
    input VPWR,
    input VGND,
`endif
    input        EN,
    input [2:0]  A,
    output [7:0] SEL
);

    wire [2:0]  A_buf;
    wire        EN_buf;

    sky130_fd_sc_hd__clkbuf_1 ABUF[2:0] (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .X(A_buf),
        .A(A)
    );

    sky130_fd_sc_hd__clkbuf_2 ENBUF (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .X(EN_buf),
        .A(EN)
    );

    sky130_fd_sc_hd__nor4b_2   AND0 ( // 000
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .Y(SEL[0]),
        .A(A_buf[0]),
        .B(A_buf[1]),
        .C(A_buf[2]),
        .D_N(EN_buf)
    );

    sky130_fd_sc_hd__and4bb_2   AND1 ( // 001
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .X(SEL[1]),
        .A_N(A_buf[2]),
        .B_N(A_buf[1]),
        .C(A_buf[0]),
        .D(EN_buf)
    );

    sky130_fd_sc_hd__and4bb_2   AND2 ( // 010
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .X(SEL[2]),
        .A_N(A_buf[2]),
        .B_N(A_buf[0]),
        .C(A_buf[1]),
        .D(EN_buf)
    );

    sky130_fd_sc_hd__and4b_2    AND3 ( // 011
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .X(SEL[3]),
        .A_N(A_buf[2]),
        .B(A_buf[1]),
        .C(A_buf[0]),
        .D(EN_buf)
    );

    sky130_fd_sc_hd__and4bb_2   AND4 ( // 100
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .X(SEL[4]),
        .A_N(A_buf[0]),
        .B_N(A_buf[1]),
        .C(A_buf[2]),
        .D(EN_buf)
    );

    sky130_fd_sc_hd__and4b_2    AND5 ( // 101
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .X(SEL[5]),
        .A_N(A_buf[1]),
        .B(A_buf[0]),
        .C(A_buf[2]),
        .D(EN_buf)
    );

    sky130_fd_sc_hd__and4b_2    AND6 ( // 110
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .X(SEL[6]),
        .A_N(A_buf[0]),
        .B(A_buf[1]),
        .C(A_buf[2]),
        .D(EN_buf)
    );

    sky130_fd_sc_hd__and4_2     AND7 ( // 111
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .X(SEL[7]),
        .A(A_buf[0]),
        .B(A_buf[1]),
        .C(A_buf[2]),
        .D(EN_buf)
    );
endmodule

module DEC4x10(
`ifdef USE_POWER_PINS
    input VPWR,
    input VGND,
`endif
    input [3:0] A,
    output [9:0] SEL
);

    wire _00_;
    wire _01_;
    wire _02_;
    wire _03_;
    wire _04_;
    wire _05_;
    wire _06_;

    sky130_fd_sc_hd__inv_1 comb0 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .A(A[3]),
        .Y(_00_)
    );
    sky130_fd_sc_hd__nand2b_1 comb1 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .A_N(A[0]),
        .B(A[2]),
        .Y(_01_)
    );
    sky130_fd_sc_hd__a21oi_1 comb2 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .A1(A[3]),
        .A2(A[2]),
        .B1(A[1]),
        .Y(_02_)
    );
    sky130_fd_sc_hd__nand2b_1 comb3 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .A_N(A[1]),
        .B(A[0]),
        .Y(_03_)
    );
    sky130_fd_sc_hd__nand2_1 comb4 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .A(A[1]),
        .B(A[0]),
        .Y(_04_)
    );
    sky130_fd_sc_hd__nand2b_1 comb5 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .A_N(A[3]),
        .B(A[2]),
        .Y(_05_)
    );
    sky130_fd_sc_hd__nand2b_1 comb6 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .A_N(A[2]),
        .B(A[3]),
        .Y(_06_)
    );

    sky130_fd_sc_hd__nor4_1 sel0 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .A(A[1]),
        .B(A[0]),
        .C(A[3]),
        .D(A[2]),
        .Y(SEL[0])
    );
    sky130_fd_sc_hd__nor3_1 sel1 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .A(A[3]),
        .B(A[2]),
        .C(_03_),
        .Y(SEL[1])
    );
    sky130_fd_sc_hd__nor4b_1 sel2 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .A(A[0]),
        .B(A[3]),
        .C(A[2]),
        .D_N(A[1]),
        .Y(SEL[2])
    );
    sky130_fd_sc_hd__nor3_1 sel3 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .A(A[3]),
        .B(A[2]),
        .C(_04_),
        .Y(SEL[3])
    );
    sky130_fd_sc_hd__nor3_1 sel4 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .A(A[1]),
        .B(A[0]),
        .C(_05_),
        .Y(SEL[4])
    );
    sky130_fd_sc_hd__nor2_1 sel5 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .A(_03_),
        .B(_05_),
        .Y(SEL[5])
    );
    sky130_fd_sc_hd__nor2_1 sel6 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .A(_04_),
        .B(_05_),
        .Y(SEL[6])
    );
    sky130_fd_sc_hd__nor3_1 sel7 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .A(A[1]),
        .B(A[0]),
        .C(_06_),
        .Y(SEL[7])
    );
    sky130_fd_sc_hd__nor2_1 sel8 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .A(_03_),
        .B(_06_),
        .Y(SEL[8])
    );
    sky130_fd_sc_hd__a21oi_1 sel9 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .A1(_00_),
        .A2(_01_),
        .B1(_02_),
        .Y(SEL[9])
    );
endmodule

module DEC7x80 (
`ifdef USE_POWER_PINS
    input VPWR,
    input VGND,
`endif
    input   [6:0]    A,
    output  [80-1:0] SEL
);
    wire [9:0] SEL0_w ;
    wire [2:0] A_buf;

    DEC4x10 DEC_L0 (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
    `endif
        .A(A[6:3]),
        .SEL(SEL0_w)
    );

    sky130_fd_sc_hd__clkbuf_16 ABUF[2:0] (
    `ifdef USE_POWER_PINS
        .VPWR(VPWR),
        .VGND(VGND),
        .VPB(VPWR),
        .VNB(VGND),
    `endif
        .X(A_buf),
        .A(A[2:0])
    );

    generate
        genvar i;
        for (i=0; i<10; i=i+1) begin : DEC_L1
            DEC3x8 U (
            `ifdef USE_POWER_PINS
                .VPWR(VPWR),
                .VGND(VGND),
            `endif
                .EN(SEL0_w[i]),
                .A(A_buf),
                .SEL(SEL[7+8*i: 8*i])
            );
        end
    endgenerate
endmodule
