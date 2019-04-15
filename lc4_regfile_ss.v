/* Zetong Jia (zetongj), Ye Dong(yedong)
 *
 * lc4_regfile.v
 * Implements an 8-register register file parameterized on word size.
 *
 */

`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

module lc4_regfile_ss #(parameter n = 16)
   (input  wire         clk,        //main clock
    input  wire         gwe,       //global write enable that controls every register
    input  wire         rst,        //global rest
    
    input  wire [  2:0] i_rs_A,      // pipe A: rs selector
    output wire [n-1:0] o_rs_data_A, // pipe A: rs contents
    input  wire [  2:0] i_rt_A,      // pipe A: rt selector
    output wire [n-1:0] o_rt_data_A, // pipe A: rt contents

    input  wire [  2:0] i_rs_B,      // pipe B: rs selector
    output wire [n-1:0] o_rs_data_B, // pipe B: rs contents
    input  wire [  2:0] i_rt_B,      // pipe B: rt selector
    output wire [n-1:0] o_rt_data_B, // pipe B: rt contents

    input  wire [  2:0]  i_rd_A,     // pipe A: rd selector
    input  wire [n-1:0]  i_wdata_A,  // pipe A: data to write
    input  wire          i_rd_we_A,  // pipe A: write enable

    input  wire [  2:0]  i_rd_B,     // pipe B: rd selector
    input  wire [n-1:0]  i_wdata_B,  // pipe B: data to write
    input  wire          i_rd_we_B   // pipe B: write enable
    );


    wire reg1_we, reg2_we, reg3_we, reg4_we, reg5_we, reg6_we, reg7_we, reg8_we;
    wire[15:0] reg1_in, reg2_in, reg3_in, reg4_in, reg5_in, reg6_in, reg7_in, reg8_in;
    wire[n-1:0] reg1_out, reg2_out, reg3_out, reg4_out, reg5_out, reg6_out, reg7_out, reg8_out;

    assign reg1_we = (((i_rd_B == 'b000) && (i_rd_we_B == 1)) || ((i_rd_A == 'b000) && (i_rd_we_A == 1))) ? 1 : 0;
    assign reg2_we = (((i_rd_B == 'b001) && (i_rd_we_B == 1)) || ((i_rd_A == 'b001) && (i_rd_we_A == 1))) ? 1 : 0;
    assign reg3_we = (((i_rd_B == 'b010) && (i_rd_we_B == 1)) || ((i_rd_A == 'b010) && (i_rd_we_A == 1))) ? 1 : 0;
    assign reg4_we = (((i_rd_B == 'b011) && (i_rd_we_B == 1)) || ((i_rd_A == 'b011) && (i_rd_we_A == 1))) ? 1 : 0;
    assign reg5_we = (((i_rd_B == 'b100) && (i_rd_we_B == 1)) || ((i_rd_A == 'b100) && (i_rd_we_A == 1))) ? 1 : 0;
    assign reg6_we = (((i_rd_B == 'b101) && (i_rd_we_B == 1)) || ((i_rd_A == 'b101) && (i_rd_we_A == 1))) ? 1 : 0;
    assign reg7_we = (((i_rd_B == 'b110) && (i_rd_we_B == 1)) || ((i_rd_A == 'b110) && (i_rd_we_A == 1))) ? 1 : 0;
    assign reg8_we = (((i_rd_B == 'b111) && (i_rd_we_B == 1)) || ((i_rd_A == 'b111) && (i_rd_we_A == 1))) ? 1 : 0;


    // assign reg1_we = (i_rd_B == 'b000) ? (i_rd_we_B == 1) :
    //                   ((i_rd_A == 'b000 && i_rd_A != i_rd_B) ? (i_rd_we_A == 1): 0);
    // assign reg2_we = (i_rd_B == 'b001) ? (i_rd_we_B == 1) :
    //                   ((i_rd_A == 'b001 && i_rd_A != i_rd_B) ? (i_rd_we_A == 1): 0);
    // assign reg3_we = (i_rd_B == 'b010) ? (i_rd_we_B == 1) :
    //                   ((i_rd_A == 'b010 && i_rd_A != i_rd_B) ? (i_rd_we_A == 1): 0);
    // assign reg4_we = (i_rd_B == 'b011) ? (i_rd_we_B == 1) :
    //                   ((i_rd_A == 'b011 && i_rd_A != i_rd_B) ? (i_rd_we_A == 1): 0);
    // assign reg5_we = (i_rd_B == 'b100) ? (i_rd_we_B == 1) :
    //                   ((i_rd_A == 'b100 && i_rd_A != i_rd_B) ? (i_rd_we_A == 1): 0);
    // assign reg6_we = (i_rd_B == 'b101) ? (i_rd_we_B == 1) :
    //                   ((i_rd_A == 'b101 && i_rd_A != i_rd_B) ? (i_rd_we_A == 1): 0);
    // assign reg7_we = (i_rd_B == 'b110) ? (i_rd_we_B == 1) :
    //                   ((i_rd_A == 'b110 && i_rd_A != i_rd_B) ? (i_rd_we_A == 1): 0);
    // assign reg8_we = (i_rd_B == 'b111) ? (i_rd_we_B == 1) :
    //                   ((i_rd_A == 'b111 && i_rd_A != i_rd_B) ? (i_rd_we_A == 1): 0);

    //data to put into each register
    assign reg1_in = ((i_rd_B == 'b000) && (i_rd_we_B == 1)) ? i_wdata_B : i_wdata_A;
    assign reg2_in = ((i_rd_B == 'b001) && (i_rd_we_B == 1)) ? i_wdata_B : i_wdata_A;
    assign reg3_in = ((i_rd_B == 'b010) && (i_rd_we_B == 1)) ? i_wdata_B : i_wdata_A;
    assign reg4_in = ((i_rd_B == 'b011) && (i_rd_we_B == 1)) ? i_wdata_B : i_wdata_A;
    assign reg5_in = ((i_rd_B == 'b100) && (i_rd_we_B == 1)) ? i_wdata_B : i_wdata_A;
    assign reg6_in = ((i_rd_B == 'b101) && (i_rd_we_B == 1)) ? i_wdata_B : i_wdata_A;
    assign reg7_in = ((i_rd_B == 'b110) && (i_rd_we_B == 1)) ? i_wdata_B : i_wdata_A;
    assign reg8_in = ((i_rd_B == 'b111) && (i_rd_we_B == 1)) ? i_wdata_B : i_wdata_A;


    Nbit_reg #(.n(16), .r(0)) reg1(.in(reg1_in), .out(reg1_out), .clk(clk), .we(reg1_we), .gwe(gwe), .rst(rst));
    Nbit_reg #(.n(16), .r(0)) reg2(.in(reg2_in), .out(reg2_out), .clk(clk), .we(reg2_we), .gwe(gwe), .rst(rst));
    Nbit_reg #(.n(16), .r(0)) reg3(.in(reg3_in), .out(reg3_out), .clk(clk), .we(reg3_we), .gwe(gwe), .rst(rst));
    Nbit_reg #(.n(16), .r(0)) reg4(.in(reg4_in), .out(reg4_out), .clk(clk), .we(reg4_we), .gwe(gwe), .rst(rst));
    Nbit_reg #(.n(16), .r(0)) reg5(.in(reg5_in), .out(reg5_out), .clk(clk), .we(reg5_we), .gwe(gwe), .rst(rst));
    Nbit_reg #(.n(16), .r(0)) reg6(.in(reg6_in), .out(reg6_out), .clk(clk), .we(reg6_we), .gwe(gwe), .rst(rst));
    Nbit_reg #(.n(16), .r(0)) reg7(.in(reg7_in), .out(reg7_out), .clk(clk), .we(reg7_we), .gwe(gwe), .rst(rst));
    Nbit_reg #(.n(16), .r(0)) reg8(.in(reg8_in), .out(reg8_out), .clk(clk), .we(reg8_we), .gwe(gwe), .rst(rst));

    //A is normal
    assign o_rs_data_A = (i_rs_A == i_rd_B && i_rd_we_B) ? i_wdata_B : 
                        ((i_rs_A == i_rd_A && i_rd_we_A) ? i_wdata_A :
                        ((i_rs_A == 'b000) ? reg1_out : 
                        ((i_rs_A == 'b001) ? reg2_out : 
                        ((i_rs_A == 'b010) ? reg3_out : 
                        ((i_rs_A == 'b011) ? reg4_out : 
                        ((i_rs_A == 'b100) ? reg5_out : 
                        ((i_rs_A == 'b101) ? reg6_out : 
                        ((i_rs_A == 'b110) ? reg7_out : reg8_out))))))));

    assign o_rt_data_A = (i_rt_A == i_rd_B && i_rd_we_B) ? i_wdata_B :  
                        ((i_rt_A == i_rd_A && i_rd_we_A) ? i_wdata_A :
                        ((i_rt_A == 'b000) ? reg1_out : 
                        ((i_rt_A == 'b001) ? reg2_out : 
                        ((i_rt_A == 'b010) ? reg3_out : 
                        ((i_rt_A == 'b011) ? reg4_out : 
                        ((i_rt_A == 'b100) ? reg5_out : 
                        ((i_rt_A == 'b101) ? reg6_out : 
                        ((i_rt_A == 'b110) ? reg7_out : reg8_out))))))));

    // If B get data from places where A wrote on first but then B wrote on, we'd want the data A wrote
    assign o_rs_data_B = (i_rs_B == i_rd_B && i_rd_we_B) ? i_wdata_B :
                            ((i_rs_B == i_rd_A && i_rd_we_A) ? i_wdata_A :
                            ((i_rs_B == 'b000) ? reg1_out : 
                            ((i_rs_B == 'b001) ? reg2_out : 
                            ((i_rs_B == 'b010) ? reg3_out : 
                            ((i_rs_B == 'b011) ? reg4_out : 
                            ((i_rs_B == 'b100) ? reg5_out : 
                            ((i_rs_B == 'b101) ? reg6_out : 
                            ((i_rs_B == 'b110) ? reg7_out : reg8_out))))))));

    assign o_rt_data_B = (i_rt_B == i_rd_B && i_rd_we_B) ? i_wdata_B :
                            ((i_rt_B == i_rd_A && i_rd_we_A) ? i_wdata_A :
                            ((i_rt_B == 'b000) ? reg1_out : 
                            ((i_rt_B == 'b001) ? reg2_out : 
                            ((i_rt_B == 'b010) ? reg3_out : 
                            ((i_rt_B == 'b011) ? reg4_out : 
                            ((i_rt_B == 'b100) ? reg5_out : 
                            ((i_rt_B == 'b101) ? reg6_out : 
                            ((i_rt_B == 'b110) ? reg7_out : reg8_out))))))));

endmodule

