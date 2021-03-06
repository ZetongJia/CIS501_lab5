/* TODO: name and PennKeys of all group members here
 *
 * lc4_single.v
 * Implements a single-cycle data path
 *
 */

`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module lc4_processor
   (input  wire        clk,                // Main clock
    input  wire        rst,                // Global reset
    input  wire        gwe,                // Global we for single-step clock
   
    output wire [15:0] o_cur_pc,           // Address to read from instruction memory
    input  wire [15:0] i_cur_insn_A,         // Output of instruction memory
    input  wire [15:0] i_cur_insn_B,         // Output of instruction memory

    output wire [15:0] o_dmem_addr,        // Address to read/write from/to data memory; SET TO 0x0000 FOR NON LOAD/STORE INSNS
    input  wire [15:0] i_cur_dmem_data,    // Output of data memory
    output wire        o_dmem_we,          // Data memory write enable
    output wire [15:0] o_dmem_towrite,     // Value to write to data memory

    // testbench signals (always emitted from the WB stage)
    output wire [ 1:0] test_stall_A,        // is this a stall cycle?  (0: no stall,
    output wire [ 1:0] test_stall_B,        // 1: pipeline stall, 2: branch stall, 3: load stall)

    output wire [15:0] test_cur_pc_A,       // program counter
    output wire [15:0] test_cur_pc_B,
    output wire [15:0] test_cur_insn_A,     // instruction bits
    output wire [15:0] test_cur_insn_B,
    output wire        test_regfile_we_A,   // register file write-enable
    output wire        test_regfile_we_B,
    output wire [ 2:0] test_regfile_wsel_A, // which register to write
    output wire [ 2:0] test_regfile_wsel_B,
    output wire [15:0] test_regfile_data_A, // data to write to register file
    output wire [15:0] test_regfile_data_B,
    output wire        test_nzp_we_A,       // nzp register write enable
    output wire        test_nzp_we_B,
    output wire [ 2:0] test_nzp_new_bits_A, // new nzp bits
    output wire [ 2:0] test_nzp_new_bits_B,
    output wire        test_dmem_we_A,      // data memory write enable
    output wire        test_dmem_we_B,
    output wire [15:0] test_dmem_addr_A,    // address to read/write from/to memory
    output wire [15:0] test_dmem_addr_B,
    output wire [15:0] test_dmem_data_A,    // data to read/write from/to memory
    output wire [15:0] test_dmem_data_B,   
    input  wire [7:0]  switch_data,        // Current settings of the Zedboard switches
    output wire [7:0]  led_data            // Which Zedboard LEDs should be turned on?
    );

   // By default, assign LEDs to display switch inputs to avoid warnings about
   // disconnected ports. Feel free to use this for debugging input/output if
   // you desire.
   assign led_data = switch_data;

   
   /* DO NOT MODIFY THIS CODE */

   // pc wires attached to the PC register's ports
   
   wire [15:0]   next_pc_A; // Next program counter (you compute this and feed it into next_pc)


   /* END DO NOT MODIFY THIS CODE */
   

   /*******************************
    * TODO: INSERT YOUR CODE HERE *
    *******************************/
    
    wire inc;

    wire [2:0] i_rs_A, i_rt_A, i_rd_A;
    wire i_rd_we_A, nzp_we_A, select_pc_plus_one_A, is_load_A, is_store_A, is_branch_A, is_control_insn_A;
    wire [15:0] o_result_A, i_wdata_A, o_rt_data_A, o_rs_data_A, pc_plus1_A, fetch_pcplus1_A, fetch_iwdata_A;  
    wire [15:0]   fetch_pc_A;      // fetch_pc_output

    wire [2:0] i_rs_B, i_rt_B, i_rd_B;
    wire i_rd_we_B, nzp_we_B, select_pc_plus_one_B, is_load_B, is_store_B, is_branch_B, is_control_insn_B;
    wire [15:0] o_result_B, i_wdata_B, o_rt_data_B, o_rs_data_B, pc_plus1_B, fetch_pcplus1_B, fetch_iwdata_B;  
    wire [15:0] fetch_pc_B;      // fetch_pc_output


   /*******************************
    *            Fetch            *
    *******************************/

    // branch_OP branch(.clk(clk), .gwe(gwe), .rst(rst), .i_pc(fetch_pc), .i_rs_data(wri_rs_data_A), 
    // .program_op(wri_iwdata), .o_pc(next_pc), .pc_inc(pc_plus1), .i_insn(wri_insn_A), 
    // .test_nzp_new_bits(test_nzp_new_bits), .nzp_we(test_nzp_we), .nzp_we_input(wri_nzpwe), .is_branch(wri_isbranch), .is_control_insn(wri_iscontroinsn), .i_result(wri_oresult_insn));

    // Fetch Program counter register
    Nbit_reg #(16, 16'h8200) fetch_pc_reg_A (.in(next_pc_A), .out(fetch_pc_A), .clk(clk), .we(decode_we), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h8200) fetch_pcplus1_reg_A (.in(pc_plus1_A), .out(fetch_pcplus1_A), .clk(clk), .we(decode_we), .gwe(gwe), .rst(rst));

    assign inc = !(is_AB_dependent || decode_stall_ltu_sel_B); //inc 1 if no stall and don't inc if has stall(so then only inc a total of 2)
    cla16 cla1_A(.a(fetch_pc_A), .b(16'b1), .cin(inc), .sum(pc_plus1_A));
    cla16 cla1_B(.a(fetch_pc_A), .b(16'b10), .cin(inc), .sum(pc_plus1_B)); //B INC BASED ON A

    Nbit_reg #(16, 16'h8201) fetch_pc_reg_B (.in(next_pc_A+'b1), .out(fetch_pc_B), .clk(clk), .we(decode_we), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h8201) fetch_pcplus1_reg_B (.in(pc_plus1_B), .out(fetch_pcplus1_B), .clk(clk), .we(decode_we), .gwe(gwe), .rst(rst));

    //The current PC to fetch!
    assign o_cur_pc= fetch_pc_A;

    /*******************************
    *            Decode          *
    *******************************/

    wire [15:0]   decode_pc_A, decode_insn_A, decode_pcplus1_A, decode_iwdata_A, decode_insn_input_A;
    wire decode_isload_insn_A, decode_issotre_insn_A, decode_selpcplusone_insn_A, decode_irdwe_A, decode_isstore_insn_A, decode_nzpwe_A, decode_isbranch_A, decode_iscontroinsn_A, decode_check_rt_A, decode_check_rs_A, decode_check_rd_A;
    wire [2:0]  decode_ird_A, decode_irs_A, decode_irt_A;   

    wire [15:0]   decode_pc_B, decode_insn_B, decode_pcplus1_B, decode_iwdata_B, decode_insn_input_B;
    wire decode_isload_insn_B, decode_issotre_insn_B, decode_selpcplusone_insn_B, decode_irdwe_B, decode_isstore_insn_B, decode_nzpwe_B, decode_isbranch_B, decode_iscontroinsn_B, decode_check_rs_B, decode_check_rt_B;
    wire [2:0]  decode_ird_B, decode_irs_B, decode_irt_B;

    lc4_decoder dec_A(.insn(decode_insn_input_A), .r1sel(i_rs_A), .r1re(), .r2sel(i_rt_A), .r2re(), .wsel(i_rd_A), .regfile_we(i_rd_we_A), .nzp_we(nzp_we_A), 
    .select_pc_plus_one(select_pc_plus_one_A), // output ---- write PC+1 to the regfile?
    .is_load(is_load_A),            // is this a load instruction?
    .is_store(is_store_A),           // is this a store instruction?
    .is_branch(is_branch_A),          // is this a branch instruction?
    .is_control_insn(is_control_insn_A)     // is this a control instruction (JSR, JSRR, RTI, JMPR, JMP, TRAP)?
    );

    lc4_decoder dec_B(.insn(decode_insn_input_B), .r1sel(i_rs_B), .r1re(), .r2sel(i_rt_B), .r2re(), .wsel(i_rd_B), .regfile_we(i_rd_we_B), .nzp_we(nzp_we_B), 
    .select_pc_plus_one(select_pc_plus_one_B), // output ---- write PC+1 to the regfile?
    .is_load(is_load_B),            // is this a load instruction?
    .is_store(is_store_B),           // is this a store instruction?
    .is_branch(is_branch_B),          // is this a branch instruction?
    .is_control_insn(is_control_insn_B)     // is this a control instruction (JSR, JSRR, RTI, JMPR, JMP, TRAP)?
    );

    //**** this is if we DONT want to check rs/rt/rd
    assign decode_check_rd_A = decode_insn_A[15:12]=='b0000 || decode_isstore_insn_A
                                          || decode_insn_A[15:12]=='b0010
                                          || decode_insn_A[15:12]=='b0100
                                          || decode_insn_A[15:12]=='b1100
                                          || decode_insn_A[15:12]=='b1111
                                          || decode_insn_A[15:12]=='b1000;
    assign decode_check_rt_A = decode_isstore_insn_A || decode_isload_insn_A
                                          || (decode_insn_A[15:12]=='b0001 && decode_insn_A[5]=='b1)
                                          || (decode_insn_A[15:12]=='b0010 && (decode_insn_A[8:7] == 'b10 ||decode_insn_A[8:7] == 'b11))
                                          || (decode_insn_A[15:12]=='b0101 && (decode_insn_A[5:3] == 'b001 || decode_insn_A[5] == 'b1))
                                          || (decode_insn_A[15:12]=='b1001)
                                          || (decode_insn_A[15:12]=='b1010 && (decode_insn_A[5:4] != 'b11))
                                          || decode_insn_A[15:12] == 'b1101
                                          || decode_insn_A[15:12] == 'b1001
                                          || decode_insn_A[15:12] == 'b0100
                                          || decode_insn_A[15:12] == 'b1100
                                          || decode_insn_A == 16'h8200;
    assign decode_check_rt_B = decode_isstore_insn_B || decode_isload_insn_B
                                          || (decode_insn_B[15:12]=='b0001 && decode_insn_B[5]=='b1)
                                          || (decode_insn_B[15:12]=='b0010 && (decode_insn_B[8:7] == 'b10 ||decode_insn_B[8:7] == 'b11))
                                          || (decode_insn_B[15:12]=='b0101 && (decode_insn_B[5:3] == 'b001 || decode_insn_B[5] == 'b1))
                                          || (decode_insn_B[15:12]=='b1001)
                                          || (decode_insn_B[15:12]=='b1010 && (decode_insn_B[5:4] != 'b11))
                                          || decode_insn_B[15:12] == 'b1101
                                          || decode_insn_B[15:12] == 'b1001
                                          || decode_insn_B[15:12] == 'b0100
                                          || decode_insn_B[15:12] == 'b1100
                                          || decode_insn_B == 16'h8200;
    assign decode_check_rs_B = decode_insn_B[15:12] == 'b1001 || decode_insn_B[15:12] == 'b1111 || (decode_insn_B[15:12]=='b0100 && (decode_insn_B[11] == 'b1))
                                                   || (decode_insn_B[15:12]=='b1100 && (decode_insn_B[11] == 'b1)) || decode_insn_B == 16'h8200;
    assign decode_check_rs_A = decode_insn_A[15:12] == 'b1001 || decode_insn_A[15:12] == 'b1111 || (decode_insn_A[15:12]=='b0100 && (decode_insn_A[11] == 'b1))
                                                   || (decode_insn_A[15:12]=='b1100 && (decode_insn_A[11] == 'b1)) || decode_insn_A == 16'h8200;


    /*******************************
    *          Decode stall        *
    *******************************/
    // b's source = A's destination
    // 2 memories

    wire is_AB_dependent, i_br_stall_A, i_br_stall_B, decode_br_stall_A, decode_br_stall_B, decode_rst;
    wire [1:0] decode_SSstall_input_B, decode_SSstall_input_A, decode_stall_B, decode_stall_A; 
    wire [15:0] decode_pc_input_A, decode_pc_input_B;

    //super scalar stall
    assign is_AB_dependent = (!decode_check_rd_A && ((decode_ird_A == decode_irt_B && !decode_check_rt_B) 
                                                    || (decode_ird_A == decode_irs_B && !decode_check_rs_B)))
                              || ((decode_isload_insn_A || decode_isstore_insn_A) && (decode_isstore_insn_B || decode_isload_insn_B))
                              || (decode_nzpwe_A && decode_isbranch_B);

    assign decode_insn_input_A = (is_AB_dependent || decode_stall_ltu_sel_B) ? decode_insn_B : i_cur_insn_A; 
    assign decode_insn_input_B = (is_AB_dependent || decode_stall_ltu_sel_B) ? i_cur_insn_A : i_cur_insn_B; 

    assign decode_pc_input_A = (is_AB_dependent || decode_stall_ltu_sel_B) ? decode_pc_B : fetch_pc_A; 
    assign decode_pc_input_B = (is_AB_dependent || decode_stall_ltu_sel_B) ? fetch_pc_A : fetch_pc_B; 

    /*******************************
    *            LTU stall         *
    *******************************/
    wire decode_we, decode_stall_ltu_sel_A, decode_stall_ltu_sel_B;
    assign decode_we = !decode_stall_ltu_sel_A;
    //decode A has a stall so both decode stays
    assign decode_stall_ltu_sel_A = (exe_isload_insn_A && exe_irdwe_A && ((decode_irs_A == exe_ird_A && !decode_check_rs_A) || (decode_irt_A==exe_ird_A && !decode_check_rt_A))) 
                                    || (exe_isload_insn_A && decode_isbranch_A)
                                    || (exe_isload_insn_B && exe_irdwe_B && ((decode_irs_A == exe_ird_B && !decode_check_rs_A) || (decode_irt_A==exe_ird_B && !decode_check_rt_A))) 
                                    || (exe_isload_insn_B && decode_isbranch_A);
    //Decode B has a stall so A stays and B scoud over; treat as A and B dependent but need to give B's as LTU
    assign decode_stall_ltu_sel_B = (exe_isload_insn_A && exe_irdwe_A && ((decode_irs_B == exe_ird_A && !decode_check_rs_B) || (decode_irt_B==exe_ird_A && !decode_check_rt_B))) 
                                    || (exe_isload_insn_A && decode_isbranch_B)
                                    || (exe_isload_insn_B && exe_irdwe_B && ((decode_irs_B == exe_ird_B && !decode_check_rs_B) || (decode_irt_B==exe_ird_B && !decode_check_rt_B))) 
                                    || (exe_isload_insn_B && decode_isbranch_B);

    /*******************************
    *            BRANCH STALL      *
    *******************************/
    assign i_br_stall_A = ((exe_iscontroinsn_A) || (exe_isbranch_A && nzp_sel_A));
    assign i_br_stall_B = ((exe_iscontroinsn_B) || (exe_isbranch_B && nzp_sel_B));
    assign decode_rst = rst || i_br_stall_A || i_br_stall_B;

   /*******************************
    *            Decode A         *
    *******************************/

    //decode stall reg
    assign decode_SSstall_input_A = (decode_stall_ltu_sel_A) ? 'b11 : 'b00;
    Nbit_reg #(2, 2'b10) decode_stall_reg_A (.in(decode_SSstall_input_A), .out(decode_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst|| i_br_stall_A || i_br_stall_B));
    Nbit_reg #(1, 0) decode_br_stall_reg_A (.in(i_br_stall_A), .out(decode_br_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst|| i_br_stall_A || i_br_stall_B));
    
    // Decode Program counter register
    Nbit_reg #(16, 16'h8200) decode_pc_reg_A (.in(decode_pc_input_A), .out(decode_pc_A), .clk(clk), .we(decode_we), .gwe(gwe), .rst(decode_rst));
    Nbit_reg #(16, 16'h8200) decode_insn_reg_A (.in(decode_insn_input_A), .out(decode_insn_A), .clk(clk), .we(decode_we), .gwe(gwe), .rst(decode_rst));
    Nbit_reg #(16, 16'h8200) decode_pcplus1_reg_A (.in(fetch_pcplus1_A), .out(decode_pcplus1_A), .clk(clk), .we(decode_we), .gwe(gwe), .rst(decode_rst));

    Nbit_reg #(3, 16'h8200) decode_irs_reg_A (.in(i_rs_A), .out(decode_irs_A), .clk(clk), .we(decode_we), .gwe(gwe), .rst(decode_rst));
    Nbit_reg #(3, 16'h8200) decode_irt_reg_A (.in(i_rt_A), .out(decode_irt_A), .clk(clk), .we(decode_we), .gwe(gwe), .rst(decode_rst));

    Nbit_reg #(1, 16'h8200) decode_irdwe_reg_A (.in(i_rd_we_A), .out(decode_irdwe_A), .clk(clk), .we(decode_we), .gwe(gwe), .rst(decode_rst));
    Nbit_reg #(3, 16'h8200) decode_ird_reg_A (.in(i_rd_A), .out(decode_ird_A), .clk(clk), .we(decode_we), .gwe(gwe), .rst(decode_rst));
    Nbit_reg #(1, 16'h8200) decode_nzpwe_reg_A (.in(nzp_we_A), .out(decode_nzpwe_A), .clk(clk), .we(decode_we), .gwe(gwe), .rst(decode_rst));
    Nbit_reg #(1, 16'h8200) decode_selpcplusone_reg_A (.in(select_pc_plus_one_A), .out(decode_selpcplusone_insn_A), .clk(clk), .we(decode_we), .gwe(gwe), .rst(decode_rst));

    Nbit_reg #(1, 16'h8200) decode_isload_reg_A (.in(is_load_A), .out(decode_isload_insn_A), .clk(clk), .we(decode_we), .gwe(gwe), .rst(decode_rst));
    Nbit_reg #(1, 16'h8200) decode_isstore_reg_A (.in(is_store_A), .out(decode_isstore_insn_A), .clk(clk), .we(decode_we), .gwe(gwe), .rst(decode_rst));
    Nbit_reg #(1, 16'h8200) decode_isbranch_reg_A (.in(is_branch_A), .out(decode_isbranch_A), .clk(clk), .we(decode_we), .gwe(gwe), .rst(decode_rst));
    Nbit_reg #(1, 16'h8200) decode_iscontroinsn_reg_A (.in(is_control_insn_A), .out(decode_iscontroinsn_A), .clk(clk), .we(decode_we), .gwe(gwe), .rst(decode_rst));

    /*******************************
    *            Decode B         *
    *******************************/

    //if decodeA LTU or super scalar stall --> 1; if decode B LTU --> 2!
    assign decode_SSstall_input_B = (is_AB_dependent || decode_stall_ltu_sel_A) ? 'b1 : (decode_stall_ltu_sel_B? 'b11 : 'b0);
    //decode stall reg
    Nbit_reg #(2, 2'b10) decode_stall_reg_B (.in(decode_SSstall_input_B), .out(decode_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst|| i_br_stall_A || i_br_stall_B));
    Nbit_reg #(1, 0) decode_br_stall_reg_B (.in(i_br_stall_B), .out(decode_br_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst|| i_br_stall_A || i_br_stall_B));

    // Decode Program counter register
    Nbit_reg #(16, 16'h8200) decode_pc_reg_B (.in(decode_pc_input_B), .out(decode_pc_B), .clk(clk), .we(decode_we), .gwe(gwe), .rst(decode_rst));
    Nbit_reg #(16, 16'h8200) decode_insn_reg_B (.in(decode_insn_input_B), .out(decode_insn_B), .clk(clk), .we(decode_we), .gwe(gwe), .rst(decode_rst));
    Nbit_reg #(16, 16'h8200) decode_pcplus1_reg_B (.in(fetch_pcplus1_B), .out(decode_pcplus1_B), .clk(clk), .we(decode_we), .gwe(gwe), .rst(decode_rst));

    Nbit_reg #(3, 16'h8200) decode_irs_reg_B (.in(i_rs_B), .out(decode_irs_B), .clk(clk), .we(decode_we), .gwe(gwe), .rst(decode_rst));
    Nbit_reg #(3, 16'h8200) decode_irt_reg_B (.in(i_rt_B), .out(decode_irt_B), .clk(clk), .we(decode_we), .gwe(gwe), .rst(decode_rst));

    Nbit_reg #(1, 16'h8200) decode_irdwe_reg_B (.in(i_rd_we_B), .out(decode_irdwe_B), .clk(clk), .we(decode_we), .gwe(gwe), .rst(decode_rst));
    Nbit_reg #(3, 16'h8200) decode_ird_reg_B (.in(i_rd_B), .out(decode_ird_B), .clk(clk), .we(decode_we), .gwe(gwe), .rst(decode_rst));
    Nbit_reg #(1, 16'h8200) decode_nzpwe_reg_B (.in(nzp_we_B), .out(decode_nzpwe_B), .clk(clk), .we(decode_we), .gwe(gwe), .rst(decode_rst));
    Nbit_reg #(1, 16'h8200) decode_selpcplusone_reg_B (.in(select_pc_plus_one_B), .out(decode_selpcplusone_insn_B), .clk(clk), .we(decode_we), .gwe(gwe), .rst(decode_rst));

    Nbit_reg #(1, 16'h8200) decode_isload_reg_B (.in(is_load_B), .out(decode_isload_insn_B), .clk(clk), .we(decode_we), .gwe(gwe), .rst(decode_rst));
    Nbit_reg #(1, 16'h8200) decode_isstore_reg_B (.in(is_store_B), .out(decode_isstore_insn_B), .clk(clk), .we(decode_we), .gwe(gwe), .rst(decode_rst));
    Nbit_reg #(1, 16'h8200) decode_isbranch_reg_B (.in(is_branch_B), .out(decode_isbranch_B), .clk(clk), .we(decode_we), .gwe(gwe), .rst(decode_rst));
    Nbit_reg #(1, 16'h8200) decode_iscontroinsn_reg_B (.in(is_control_insn_B), .out(decode_iscontroinsn_B), .clk(clk), .we(decode_we), .gwe(gwe), .rst(decode_rst));

    /*******************************
    *            Execute A          *
    *******************************/

    wire [15:0]   exe_insn_A, exe_pc_A, exe_alu_rs_input_A, exe_alu_rt_input_A;
    wire [15:0]   exe_rt_data_A, exe_rs_data_A;
    wire exe_isload_insn_A, exe_isstore_insn_A, exe_selpcplusone_insn_A, exe_irdwe_A, exe_nzpwe_A, exe_isbranch_A, exe_iscontroinsn_A, exe_br_stall_A;
    wire [15:0] exe_pcplus1_A;
    wire [2:0] exe_ird_A, exe_irs_A, exe_irt_A;
    wire [1:0] exe_stall_A, exe_stall_A_input;
    
    wire exe_rst_A;

    assign exe_rst_A = rst || decode_SSstall_input_A || i_br_stall_A || i_br_stall_B;
    //1st condition to preserve the initial 0
    assign exe_stall_A_input = (decode_stall_A == 'b10)? decode_stall_A : decode_SSstall_input_A;

    //decode stall reg
    Nbit_reg #(2, 2'b10) exe_stall_reg_A (.in(exe_stall_A_input), .out(exe_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst|| i_br_stall_A || i_br_stall_B));
    
    Nbit_reg #(1, 0) exe_br_stall_reg_A (.in(decode_br_stall_A), .out(exe_br_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst|| i_br_stall_A || i_br_stall_B));

    Nbit_reg #(16, 16'h8200) exe_pc_reg_A (.in(decode_pc_A), .out(exe_pc_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_A));
    Nbit_reg #(16, 16'h8200) exe_insn_reg_A (.in(decode_insn_A), .out(exe_insn_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_A));
    Nbit_reg #(16, 16'h8200) exe_rs_reg_A (.in(o_rs_data_A), .out(exe_rs_data_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_A));
    Nbit_reg #(16, 16'h8200) exe_rt_reg_A (.in(o_rt_data_A), .out(exe_rt_data_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_A));

    Nbit_reg #(1, 16'h8200) exe_isload_reg_A (.in(decode_isload_insn_A), .out(exe_isload_insn_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_A));
    Nbit_reg #(1, 16'h8200) exe_isstore_reg_A (.in(decode_isstore_insn_A), .out(exe_isstore_insn_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_A));
    Nbit_reg #(1, 16'h8200) exe_selpcplusone_reg_A (.in(decode_selpcplusone_insn_A), .out(exe_selpcplusone_insn_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_A));
    Nbit_reg #(16, 16'h8200) exe_pcplus1_reg_A (.in(decode_pcplus1_A), .out(exe_pcplus1_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_A));
    Nbit_reg #(1, 16'h8200) exe_irdwe_reg_A (.in(decode_irdwe_A), .out(exe_irdwe_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_A));
    Nbit_reg #(3, 16'h8200) exe_ird_reg_A (.in(decode_ird_A), .out(exe_ird_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_A));
    Nbit_reg #(3, 16'h8200) exe_irs_reg_A (.in(decode_irs_A), .out(exe_irs_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_A));
    Nbit_reg #(3, 16'h8200) exe_irt_reg_A (.in(decode_irt_A), .out(exe_irt_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_A));
    

    Nbit_reg #(1, 16'h8200) exe_nzpwe_reg_A (.in(decode_nzpwe_A), .out(exe_nzpwe_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_A));
    Nbit_reg #(1, 16'h8200) exe_isbranch_reg_A (.in(decode_isbranch_A), .out(exe_isbranch_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_A));
    Nbit_reg #(1, 16'h8200) exe_iscontroinsn_reg_A (.in(decode_iscontroinsn_A), .out(exe_iscontroinsn_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_A));
   
   /*******************************
    *            Execute B          *
    *******************************/

    wire [15:0]   exe_insn_B, exe_pc_B, exe_alu_rs_input_B, exe_alu_rt_input_B, exe_rt_data_B, exe_rs_data_B, exe_pcplus1_B;
    wire exe_isload_insn_B, exe_isstore_insn_B, exe_selpcplusone_insn_B, exe_irdwe_B, exe_nzpwe_B, exe_isbranch_B, exe_iscontroinsn_B, exe_rst_B, exe_br_stall_B;
    wire [2:0] exe_ird_B, exe_irs_B, exe_irt_B;
    wire [1:0] exe_stall_B, exe_stall_B_input;

    // first step preserve the initial stall else just based on decode_SSstall_input_B
    assign exe_stall_B_input = (decode_stall_B == 'b10)? decode_stall_B : decode_SSstall_input_B;
    assign exe_rst_B = rst || (exe_stall_B_input != 0) || decode_SSstall_input_B || i_br_stall_A || i_br_stall_B;

    Nbit_reg #(2, 2'b10) exe_stall_reg_B (.in(exe_stall_B_input), .out(exe_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst|| i_br_stall_A || i_br_stall_B));
    Nbit_reg #(1, 0) exe_br_stall_reg_B (.in(decode_br_stall_B), .out(exe_br_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst|| i_br_stall_A || i_br_stall_B));

    Nbit_reg #(16, 16'h8200) exe_pc_reg_B (.in(decode_pc_B), .out(exe_pc_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_B ));
    Nbit_reg #(16, 16'h8200) exe_insn_reg_B (.in(decode_insn_B), .out(exe_insn_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_B ));
    Nbit_reg #(16, 16'h8200) exe_rs_reg_B (.in(o_rs_data_B), .out(exe_rs_data_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_B ));
    Nbit_reg #(16, 16'h8200) exe_rt_reg_B (.in(o_rt_data_B), .out(exe_rt_data_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_B ));

    Nbit_reg #(1, 16'h8200) exe_isload_reg_B (.in(decode_isload_insn_B), .out(exe_isload_insn_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_B ));
    Nbit_reg #(1, 16'h8200) exe_isstore_reg_B (.in(decode_isstore_insn_B), .out(exe_isstore_insn_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_B ));
    Nbit_reg #(1, 16'h8200) exe_selpcplusone_reg_B (.in(decode_selpcplusone_insn_B), .out(exe_selpcplusone_insn_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_B ));
    Nbit_reg #(16, 16'h8200) exe_pcplus1_reg_B (.in(decode_pcplus1_B), .out(exe_pcplus1_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_B ));
    Nbit_reg #(1, 16'h8200) exe_irdwe_reg_B (.in(decode_irdwe_B), .out(exe_irdwe_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_B ));
    Nbit_reg #(3, 16'h8200) exe_ird_reg_B (.in(decode_ird_B), .out(exe_ird_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_B ));
    Nbit_reg #(3, 16'h8200) exe_irs_reg_B (.in(decode_irs_B), .out(exe_irs_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_B ));
    Nbit_reg #(3, 16'h8200) exe_irt_reg_B (.in(decode_irt_B), .out(exe_irt_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_B ));
    

    Nbit_reg #(1, 16'h8200) exe_nzpwe_reg_B (.in(decode_nzpwe_B), .out(exe_nzpwe_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_B ));
    Nbit_reg #(1, 16'h8200) exe_isbranch_reg_B (.in(decode_isbranch_B), .out(exe_isbranch_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_B ));
    Nbit_reg #(1, 16'h8200) exe_iscontroinsn_reg_B (.in(decode_iscontroinsn_B), .out(exe_iscontroinsn_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(exe_rst_B ));


        /*********************
        *     WX/MX BYPASS   *
        **********************/
        //WX & MX bypass : MX then use mem_oresult_insn, if w then use wri_iwdata, else use exe_rs/rt
    
        assign exe_alu_rs_input_A = ((exe_irs_A == mem_ird_B) && mem_irdwe_B) ? mem_oresult_insn_B:
                                    (((exe_irs_A == mem_ird_A) && mem_irdwe_A) ? mem_oresult_insn_A: 
                                    (((exe_irs_A == wri_ird_B) && wri_irdwe_B)? wri_iwdata_B: 
                                    (((exe_irs_A == wri_ird_A) && wri_irdwe_A)? wri_iwdata_A: exe_rs_data_A)));

        assign exe_alu_rt_input_A = ((exe_irt_A == mem_ird_B) && mem_irdwe_B) ? mem_oresult_insn_B:
                                    (((exe_irt_A == mem_ird_A) && mem_irdwe_A) ? mem_oresult_insn_A: 
                                    (((exe_irt_A == wri_ird_B) && wri_irdwe_B)? wri_iwdata_B: 
                                    (((exe_irt_A == wri_ird_A) && wri_irdwe_A)? wri_iwdata_A: exe_rt_data_A)));

        lc4_alu alu_A(.i_insn(exe_insn_A), .i_pc(exe_pc_A), .i_r1data(exe_alu_rs_input_A), 
                        .i_r2data(exe_alu_rt_input_A), .o_result(o_result_A));

        assign exe_alu_rs_input_B = ((exe_irs_B == mem_ird_B) && mem_irdwe_B) ? mem_oresult_insn_B:
                                    (((exe_irs_B == mem_ird_A) && mem_irdwe_A) ? mem_oresult_insn_A: 
                                    (((exe_irs_B == wri_ird_B) && wri_irdwe_B)? wri_iwdata_B: 
                                    (((exe_irs_B == wri_ird_A) && wri_irdwe_A)? wri_iwdata_A: exe_rs_data_B)));
        assign exe_alu_rt_input_B = ((exe_irt_B == mem_ird_B) && mem_irdwe_B) ? mem_oresult_insn_B:
                                    (((exe_irt_B == mem_ird_A) && mem_irdwe_A) ? mem_oresult_insn_A: 
                                    (((exe_irt_B == wri_ird_B) && wri_irdwe_B)? wri_iwdata_B: 
                                    (((exe_irt_B == wri_ird_A) && wri_irdwe_A)? wri_iwdata_A: exe_rt_data_B)));

        lc4_alu alu_B(.i_insn(exe_insn_B), .i_pc(exe_pc_B), .i_r1data(exe_alu_rs_input_B), 
                        .i_r2data(exe_alu_rt_input_B), .o_result(o_result_B));

    //PRE-BRANCH
    wire[2:0] nzp_serial_input, nzp_serial_last; //nzp_serial_last is the nzp of the last element right before A
    assign nzp_serial_input = exe_nzpwe_B? i_nzp_new_bits_B : i_nzp_new_bits_A;
    Nbit_reg #(.n(3), .r(3'b000)) nzp_serial(.in(nzp_serial_input), .out(nzp_serial_last), .clk(clk), .we(exe_nzpwe_A || (!i_br_stall_A && exe_nzpwe_B)), .gwe(gwe), .rst(rst));

    /*****************
    *    BRANCH A.    *
    ******************/

    wire[2:0] nzp_3bit_A, i_nzp_new_bits_A;
    wire nzp_sel_A; //0 or 1
    wire[15:0] JSR_op_A; //just for JSR
    wire[15:0] branch_result_afterMux_A, data_to_test_A; 
    //which data to test? if a pc+1 data then just exe_pc+1, if nzpwe then oresult
    assign data_to_test_A = exe_selpcplusone_insn_A? (exe_pc_A + 1): (exe_nzpwe_A? o_result_A: i_cur_dmem_data);
    //testing wire!
    wire[1:0] data_to_test_sel_A;
    assign data_to_test_sel_A = exe_selpcplusone_insn_A? 'b0: (exe_nzpwe_A? 'b01: 'b10);

    NZP_testor nzp_t_A(.result(data_to_test_A), .nzp(i_nzp_new_bits_A));
    assign nzp_3bit_A = exe_nzpwe_A ? i_nzp_new_bits_A : nzp_serial_last;
    // Nbit_reg #(.n(3), .r(3'b000)) nzp_reg_A(.in(i_nzp_new_bits_A), .out(nzp_3bit_A), .clk(clk), .we(exe_nzpwe_A), .gwe(gwe), .rst(rst));
     NZP_check nzp_c_A(.i_insn(exe_insn_A[11:9]), .nzp(nzp_3bit_A), .NZP_op(nzp_sel_A)); //nzp_sel correspond to current nzp

     //***if JSR/JSRR then -1
     //***check if branch/NOP/JMP/JMPR/TRAP
     assign branch_result_afterMux_A = (nzp_sel_A == 1) ? o_result_A : (exe_pc_A + 1);
     //if current instruction is controinsn then def take in; if a taken branch, use branch result. else, don't do anything
     assign next_pc_A = exe_iscontroinsn_A ? o_result_A : 
                        ((exe_isbranch_A & nzp_sel_A) ? branch_result_afterMux_A : 
                          (exe_iscontroinsn_B ? o_result_B:
                            ((exe_isbranch_B & nzp_sel_B) ? branch_result_afterMux_B : pc_plus1_A)));

      //testing wire!
      wire[2:0] test_next_pc_A;
      assign test_next_pc_A = exe_iscontroinsn_A ? 'b0 : 
                        ((exe_isbranch_A & nzp_sel_A) ? 'b1 : 
                          (exe_iscontroinsn_B ? 'b10:
                            ((exe_isbranch_B & nzp_sel_B) ? 'b11 : 'b100)));

    /*****************
    *    BRANCH B.    *
    ******************/
    wire[2:0] nzp_3bit_B, i_nzp_new_bits_B;
    wire nzp_sel_B; //0 or 1
    wire[15:0] JSR_op_B; //just for JSR
    wire[15:0] branch_result_afterMux_B, data_to_test_B; 
    assign data_to_test_B = exe_selpcplusone_insn_B? (exe_pc_B + 1): (exe_nzpwe_B? o_result_B: i_cur_dmem_data);

    //testing wire!
    wire[1:0] data_to_test_sel_B;
    assign data_to_test_sel_B = exe_selpcplusone_insn_B? 'b0: (exe_nzpwe_B? 'b01: 'b10);

     NZP_testor nzp_t_B(.result(data_to_test_B), .nzp(i_nzp_new_bits_B));
     assign nzp_3bit_B = exe_nzpwe_B ? i_nzp_new_bits_B : (exe_nzpwe_A? i_nzp_new_bits_A : nzp_serial_last);
     // Nbit_reg #(.n(3), .r(3'b000)) nzp_reg_B(.in(i_nzp_new_bits_B), .out(nzp_3bit_B), .clk(clk), .we('b10), .gwe(gwe), .rst(rst));
     NZP_check nzp_c_B(.i_insn(exe_insn_B[11:9]), .nzp(nzp_3bit_B), .NZP_op(nzp_sel_B)); //nzp_sel correspond to current nzp

     //***if JSR/JSRR then -1
     //***check if branch/NOP/JMP/JMPR/TRAP
     assign branch_result_afterMux_B = (nzp_sel_B == 1) ? o_result_B : (exe_pc_B+1);
     
    /*******************************
    *            Memory  A         *
    *******************************/   
    wire mem_isload_insn_A, mem_selpcplusone_insn_A, mem_irdwe_A, mem_odmemwe_A, mem_isbranch_A, mem_iscontroinsn_A, mem_nzpwe_A, mem_isstore_insn_A, o_dmem_we_A, mem_br_stall_A;          
    wire [15:0] mem_oresult_insn_A, mem_pcplus1_A, mem_pc_A, mem_insn_A, mem_odmemaddr_A, mem_odmemtowrite_A, mem_rs_data_A, mem_rt_data_A, o_dmem_addr_A, o_dmem_towrite_A;
    wire [2:0] mem_ird_A, mem_irs_A, mem_irt_A, mem_nzp_new_bits_A;

    wire [1:0] mem_stall_A;

    //decode stall reg
    Nbit_reg #(2, 2'b10) mem_stall_reg_A (.in(exe_stall_A), .out(mem_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 0) mem_br_stall_reg_A (.in(exe_br_stall_A), .out(mem_br_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

    Nbit_reg #(16, 16'h8200) mem_pc_reg_A (.in(exe_pc_A), .out(mem_pc_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h8200) mem_insn_reg_A (.in(exe_insn_A), .out(mem_insn_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 16'h8200) mem_isload_reg_A (.in(exe_isload_insn_A), .out(mem_isload_insn_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 16'h8200) mem_isstore_reg_A (.in(exe_isstore_insn_A), .out(mem_isstore_insn_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h8200) mem_oresult_reg_A (.in(o_result_A), .out(mem_oresult_insn_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 16'h8200) mem_selpcplusone_reg_A (.in(exe_selpcplusone_insn_A), .out(mem_selpcplusone_insn_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h8200) mem_pcplus1_reg_A (.in(exe_pcplus1_A), .out(mem_pcplus1_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 16'h8200) mem_irdwe_reg_A (.in(exe_irdwe_A), .out(mem_irdwe_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 16'h8200) mem_ird_reg_A (.in(exe_ird_A), .out(mem_ird_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

    Nbit_reg #(16, 16'h8200) mem_rs_reg_A (.in(exe_alu_rs_input_A), .out(mem_rs_data_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h8200) mem_rt_reg_A (.in(exe_alu_rt_input_A), .out(mem_rt_data_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 16'h8200) mem_nzpwe_reg_A (.in(exe_nzpwe_A), .out(mem_nzpwe_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 16'h8200) mem_isbranch_reg_A (.in(exe_isbranch_A), .out(mem_isbranch_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 16'h8200) mem_iscontroinsn_reg_A (.in(exe_iscontroinsn_A), .out(mem_iscontroinsn_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 16'h8200) mem_irs_reg_A (.in(exe_irs_A), .out(mem_irs_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 16'h8200) mem_irt_reg_A (.in(exe_irt_A), .out(mem_irt_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    
    wire[2:0] nzp_new_bits_A_input; //fun observation: all branch has nzp_new_bits=4 :)
    assign nzp_new_bits_A_input = (exe_isbranch_A || exe_iscontroinsn_A || exe_isstore_insn_A) ? 'b100 : i_nzp_new_bits_A;
    Nbit_reg #(3, 3'h8200) mem_nzp_new_reg_A (.in(nzp_new_bits_A_input), .out(mem_nzp_new_bits_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

    // Nbit_reg #(3, 3'h8200) mem_nzp_new_reg_A (.in(i_nzp_new_bits_A), .out(mem_nzp_new_bits_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(mem_rst_B));


    /*******************************
    *            Memory  B         *
    *******************************/   
    wire mem_isload_insn_B, mem_selpcplusone_insn_B, mem_irdwe_B, mem_odmemwe_B, mem_isbranch_B, mem_iscontroinsn_B, mem_nzpwe_B, mem_isstore_insn_B, o_dmem_we_B, mem_br_stall_B;          
    wire [15:0] mem_oresult_insn_B, mem_pcplus1_B, mem_pc_B, mem_insn_B, mem_odmemaddr_B, mem_odmemtowrite_B, mem_rs_data_B, mem_rt_data_B, o_dmem_addr_B, o_dmem_towrite_B;
    wire [2:0] mem_ird_B, mem_irs_B, mem_irt_B, mem_nzp_new_bits_B;
    wire [1:0] mem_stall_B;

    wire mem_rst_B;

    assign mem_rst_B = rst || i_br_stall_A;

    Nbit_reg #(2, 2'b10) mem_stall_reg_B (.in(exe_stall_B), .out(mem_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(mem_rst_B));
    Nbit_reg #(1, 0) mem_br_stall_reg_B (.in(exe_br_stall_B), .out(mem_br_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(mem_rst_B));

    Nbit_reg #(16, 16'h8200) mem_pc_reg_B (.in(exe_pc_B), .out(mem_pc_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(mem_rst_B));
    Nbit_reg #(16, 16'h8200) mem_insn_reg_B (.in(exe_insn_B), .out(mem_insn_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(mem_rst_B));
    Nbit_reg #(1, 16'h8200) mem_isload_reg_B (.in(exe_isload_insn_B), .out(mem_isload_insn_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(mem_rst_B));
    Nbit_reg #(1, 16'h8200) mem_isstore_reg_B (.in(exe_isstore_insn_B), .out(mem_isstore_insn_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(mem_rst_B));
    Nbit_reg #(16, 16'h8200) mem_oresult_reg_B (.in(o_result_B), .out(mem_oresult_insn_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(mem_rst_B));
    Nbit_reg #(1, 16'h8200) mem_selpcplusone_reg_B (.in(exe_selpcplusone_insn_B), .out(mem_selpcplusone_insn_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(mem_rst_B));
    Nbit_reg #(16, 16'h8200) mem_pcplus1_reg_B (.in(exe_pcplus1_B), .out(mem_pcplus1_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(mem_rst_B));
    Nbit_reg #(1, 16'h8200) mem_irdwe_reg_B (.in(exe_irdwe_B), .out(mem_irdwe_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(mem_rst_B));
    Nbit_reg #(3, 16'h8200) mem_ird_reg_B (.in(exe_ird_B), .out(mem_ird_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(mem_rst_B));

    Nbit_reg #(16, 16'h8200) mem_rs_reg_B (.in(exe_alu_rs_input_B), .out(mem_rs_data_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(mem_rst_B));
    Nbit_reg #(16, 16'h8200) mem_rt_reg_B (.in(exe_alu_rt_input_B), .out(mem_rt_data_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(mem_rst_B));
    Nbit_reg #(1, 16'h8200) mem_nzpwe_reg_B (.in(exe_nzpwe_B), .out(mem_nzpwe_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(mem_rst_B));
    Nbit_reg #(1, 16'h8200) mem_isbranch_reg_B (.in(exe_isbranch_B), .out(mem_isbranch_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(mem_rst_B));
    Nbit_reg #(1, 16'h8200) mem_iscontroinsn_reg_B (.in(exe_iscontroinsn_B), .out(mem_iscontroinsn_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(mem_rst_B));
    Nbit_reg #(3, 16'h8200) mem_irs_reg_B (.in(exe_irs_B), .out(mem_irs_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(mem_rst_B));
    Nbit_reg #(3, 16'h8200) mem_irt_reg_B (.in(exe_irt_B), .out(mem_irt_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(mem_rst_B));

    wire[2:0] nzp_new_bits_B_input;
    assign nzp_new_bits_B_input = (exe_isbranch_B || exe_iscontroinsn_B || exe_isstore_insn_B) ? 'b100 : i_nzp_new_bits_B;
    Nbit_reg #(3, 3'h8200) mem_nzp_new_reg_B (.in(nzp_new_bits_B_input), .out(mem_nzp_new_bits_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(mem_rst_B));
    // Nbit_reg #(3, 3'h8200) mem_nzp_new_reg_B (.in(i_nzp_new_bits_B), .out(mem_nzp_new_bits_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(mem_rst_B));

        /*********************
        *     WM BYPASS   *
        **********************/

        //**** this is if we DONT want to check rs/rt/rd
        wire mem_check_rt_A, mem_check_rt_B, wri_check_rd_B, wri_check_rd_A, mem_check_rd_A;
        assign wri_check_rd_A = wri_insn_A[15:12]=='b0000 || wri_insn_A[15:12]=='b0111
                                              || wri_insn_A[15:12]=='b0010
                                              || wri_insn_A[15:12]=='b0100
                                              || wri_insn_A[15:12]=='b1100
                                              || wri_insn_A[15:12]=='b1111
                                              || wri_insn_A[15:12]=='b1000;
        assign mem_check_rt_A = mem_isstore_insn_A || mem_isload_insn_A
                                              || (mem_insn_A[15:12]=='b0001 && mem_insn_A[5]=='b1)
                                              || (mem_insn_A[15:12]=='b0010 && (mem_insn_A[8:7] == 'b10 || mem_insn_A[8:7] == 'b11))
                                              || (mem_insn_A[15:12]=='b0101 && (mem_insn_A[5:3] == 'b001 || mem_insn_A[5] == 'b1))
                                              || (mem_insn_A[15:12]=='b1001)
                                              || (mem_insn_A[15:12]=='b1010 && (mem_insn_A[5:4] != 'b11))
                                              || mem_insn_A[15:12] == 'b1101
                                              || mem_insn_A[15:12] == 'b1001
                                              || mem_insn_A[15:12] == 'b0100
                                              || mem_insn_A[15:12] == 'b1100
                                              || mem_insn_A == 16'h8200;
        assign wri_check_rd_B = wri_insn_B[15:12]=='b0000 || wri_isstore_insn_B
                                              || wri_insn_B[15:12]=='b0010
                                              || wri_insn_B[15:12]=='b0100
                                              || wri_insn_B[15:12]=='b1100
                                              || wri_insn_B[15:12]=='b1111
                                              || wri_insn_B[15:12]=='b1000;
        assign mem_check_rt_B = mem_isstore_insn_B || mem_isload_insn_B
                                              || (mem_insn_B[15:12]=='b0001 && mem_insn_B[5]=='b1)
                                              || (mem_insn_B[15:12]=='b0010 && (mem_insn_B[8:7] == 'b10 || mem_insn_B[8:7] == 'b11))
                                              || (mem_insn_B[15:12]=='b0101 && (mem_insn_B[5:3] == 'b001 || mem_insn_B[5] == 'b1))
                                              || (mem_insn_B[15:12]=='b1001)
                                              || (mem_insn_B[15:12]=='b1010 && (mem_insn_B[5:4] != 'b11))
                                              || mem_insn_B[15:12] == 'b1101
                                              || mem_insn_B[15:12] == 'b1001
                                              || mem_insn_B[15:12] == 'b0100
                                              || mem_insn_B[15:12] == 'b1100
                                              || mem_insn_B == 16'h8200;
        assign mem_check_rd_A = mem_insn_A[15:12]=='b0000 || mem_isstore_insn_A
                                              || mem_insn_A[15:12]=='b0010
                                              || mem_insn_A[15:12]=='b0100
                                              || mem_insn_A[15:12]=='b1100
                                              || mem_insn_A[15:12]=='b1111
                                              || mem_insn_A[15:12]=='b1000;

        assign o_dmem_towrite_A = ((mem_isstore_insn_A) && (wri_ird_B == mem_irt_A)  && !wri_check_rd_B) ? wri_iwdata_B :
                                   (((mem_isstore_insn_A) && (wri_ird_A == mem_irt_A) && !wri_check_rd_A) ? wri_iwdata_A : 
                                   (mem_isstore_insn_A ? mem_rt_data_A : 'b0000));
        assign o_dmem_addr_A = ((mem_isload_insn_A || mem_isstore_insn_A) ? mem_oresult_insn_A : 'b0000);
        assign o_dmem_we_A = mem_isstore_insn_A;


        //NOTE NO BYPASS FOR B!
        assign o_dmem_towrite_B = (mem_isstore_insn_B && (mem_ird_A == mem_irt_B)  && !mem_check_rd_A) ? mem_oresult_insn_A :
                                    ((mem_isstore_insn_B && (wri_ird_B == mem_irt_B) && !wri_check_rd_B) ? wri_iwdata_B :
                                    ((mem_isstore_insn_B && (wri_ird_A == mem_irt_B) && !wri_check_rd_A) ? wri_iwdata_A:
                                     (mem_isstore_insn_B ? mem_rt_data_B : 'b0000)));
        assign o_dmem_addr_B = ((mem_isload_insn_B || mem_isstore_insn_B) ? mem_oresult_insn_B : 'b0000);
        assign o_dmem_we_B = mem_isstore_insn_B;

        assign o_dmem_we = (o_dmem_we_A || o_dmem_we_B)? 1 : 0;
        assign o_dmem_addr = (o_dmem_addr_A != 'b0000) ? o_dmem_addr_A : ((o_dmem_addr_B != 'b0000) ? o_dmem_addr_B: 0);
        assign o_dmem_towrite = (o_dmem_we_A) ? o_dmem_towrite_A : ((o_dmem_we_B) ? o_dmem_towrite_B: 'b0000);

    /*******************************
    *            Writeback         *
    *******************************/     

    wire [15:0] wri_iwdata_A, wri_pc_A, wri_insn_A, wri_odmemaddr_A, wri_odmemtowrite_A, wri_icurdmemdata_A, wri_rs_data_A, wri_rt_data_A, wri_pcplus1_A, wri_oresult_insn_A;
    wire wri_irdwe_A, wri_odmemwe_A, wri_nzpwe_A, wri_isbranch_A, wri_iscontroinsn_A, wri_isload_insn_A, wri_isstore_insn_A, wri_selpcplusone_insn_A, wri_br_stall_A;
    wire [2:0] wri_ird_A, wri_irs_A, wri_irt_A, wri_nzp_new_bits_A;
    wire [1:0] wri_stall_A;
    


    //decode stall reg
    Nbit_reg #(2, 2'b10) wri_stall_reg_A (.in(mem_stall_A), .out(wri_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 0) wri_br_stall_reg_A (.in(mem_br_stall_A), .out(wri_br_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

    Nbit_reg #(16, 16'h8200) wri_pc_reg_A (.in(mem_pc_A), .out(wri_pc_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h8200) wri_insn_reg_A (.in(mem_insn_A), .out(wri_insn_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 16'h8200) wri_irdwe_reg_A (.in(mem_irdwe_A), .out(wri_irdwe_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 16'h8200) wri_ird_reg_A (.in(mem_ird_A), .out(wri_ird_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 16'h8200) wri_irs_reg_A (.in(mem_irs_A), .out(wri_irs_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 16'h8200) wri_irt_reg_A (.in(mem_irt_A), .out(wri_irt_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    
    Nbit_reg #(1, 16'h8200) wri_odmemwe_reg_A (.in(o_dmem_we_A), .out(wri_odmemwe_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h8200) wri_odmemaddr_reg_A (.in(o_dmem_addr_A), .out(wri_odmemaddr_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h8200) wri_odmemtowrite_reg_A (.in(o_dmem_towrite_A), .out(wri_odmemtowrite_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h8200) wri_icurdmemdata_reg_A (.in(i_cur_dmem_data), .out(wri_icurdmemdata_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h8200) wri_rs_reg_A (.in(mem_rs_data_A), .out(wri_rs_data_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h8200) wri_rt_reg_A (.in(mem_rt_data_A), .out(wri_rt_data_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h8200) wri_pcplus1_reg_A (.in(mem_pcplus1_A), .out(wri_pcplus1_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 16'h8200) wri_nzpwe_reg_A (.in(mem_nzpwe_A), .out(wri_nzpwe_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 16'h8200) wri_isbranch_reg_A (.in(mem_isbranch_A), .out(wri_isbranch_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 16'h8200) wri_iscontroinsn_reg_A (.in(mem_iscontroinsn_A), .out(wri_iscontroinsn_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 16'h8200) wri_isload_reg_A (.in(mem_isload_insn_A), .out(wri_isload_insn_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 16'h8200) wri_isstore_reg_A (.in(mem_isstore_insn_A), .out(wri_isstore_insn_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h8200) wri_oresult_reg_A (.in(mem_oresult_insn_A), .out(wri_oresult_insn_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 16'h8200) wri_selpcplusone_reg_A (.in(mem_selpcplusone_insn_A), .out(wri_selpcplusone_insn_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 3'h0000) test_nzp_new_reg_A (.in(mem_nzp_new_bits_A), .out(wri_nzp_new_bits_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


   assign wri_iwdata_A =  wri_selpcplusone_insn_A ? (wri_pc_A + 1'b1) :  
               (wri_isload_insn_A ? wri_icurdmemdata_A : wri_oresult_insn_A);

    /*******************************
    *            Writeback         *
    *******************************/     

    wire [15:0] wri_iwdata_B, wri_pc_B, wri_insn_B, wri_odmemaddr_B, wri_odmemtowrite_B, wri_icurdmemdata_B, wri_rs_data_B, wri_rt_data_B, wri_pcplus1_B, wri_oresult_insn_B;
    wire wri_irdwe_B, wri_odmemwe_B, wri_nzpwe_B, wri_isbranch_B, wri_iscontroinsn_B, wri_isload_insn_B, wri_isstore_insn_B, wri_selpcplusone_insn_B, wri_br_stall_B;
    wire [2:0] wri_ird_B, wri_irs_B, wri_irt_B, wri_nzp_new_bits_B;
    wire [1:0] wri_stall_B;

    Nbit_reg #(2, 2'h10) wri_stall_reg_B (.in(mem_stall_B), .out(wri_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 0) wri_br_stall_reg_B (.in(mem_br_stall_B), .out(wri_br_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

    Nbit_reg #(16, 16'h8200) wri_pc_reg_B (.in(mem_pc_B), .out(wri_pc_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h8200) wri_insn_reg_B (.in(mem_insn_B), .out(wri_insn_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 16'h8200) wri_irdwe_reg_B (.in(mem_irdwe_B), .out(wri_irdwe_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 16'h8200) wri_ird_reg_B (.in(mem_ird_B), .out(wri_ird_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 16'h8200) wri_irs_reg_B (.in(mem_irs_B), .out(wri_irs_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 16'h8200) wri_irt_reg_B (.in(mem_irt_B), .out(wri_irt_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    
    Nbit_reg #(1, 16'h8200) wri_odmemwe_reg_B (.in(o_dmem_we_B), .out(wri_odmemwe_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h8200) wri_odmemaddr_reg_B (.in(o_dmem_addr_B), .out(wri_odmemaddr_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h8200) wri_odmemtowrite_reg_B (.in(o_dmem_towrite_B), .out(wri_odmemtowrite_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h8200) wri_icurdmemdata_reg_B (.in(i_cur_dmem_data), .out(wri_icurdmemdata_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h8200) wri_rs_reg_B (.in(mem_rs_data_B), .out(wri_rs_data_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h8200) wri_rt_reg_B (.in(mem_rt_data_B), .out(wri_rt_data_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h8200) wri_pcplus1_reg_B (.in(mem_pcplus1_B), .out(wri_pcplus1_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 16'h8200) wri_nzpwe_reg_B (.in(mem_nzpwe_B), .out(wri_nzpwe_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 16'h8200) wri_isbranch_reg_B (.in(mem_isbranch_B), .out(wri_isbranch_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 16'h8200) wri_iscontroinsn_reg_B (.in(mem_iscontroinsn_B), .out(wri_iscontroinsn_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 16'h8200) wri_isload_reg_B (.in(mem_isload_insn_B), .out(wri_isload_insn_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 16'h8200) wri_isstore_reg_B (.in(mem_isstore_insn_B), .out(wri_isstore_insn_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(16, 16'h8200) wri_oresult_reg_B (.in(mem_oresult_insn_B), .out(wri_oresult_insn_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(1, 16'h8200) wri_selpcplusone_reg_B (.in(mem_selpcplusone_insn_B), .out(wri_selpcplusone_insn_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
    Nbit_reg #(3, 3'h0000) test_nzp_new_reg_B (.in(mem_nzp_new_bits_B), .out(wri_nzp_new_bits_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));


   assign wri_iwdata_B =  wri_selpcplusone_insn_B ? (wri_pc_B + 1'b1) :  
               (wri_isload_insn_B ? wri_icurdmemdata_B : wri_oresult_insn_B);

    /********************************************************************************************************************************************/

    lc4_regfile_ss #(.n(16)) regfile1(.clk(clk), .gwe(gwe), .rst(rst), .i_rs_A(decode_irs_A),
                    .o_rs_data_A(o_rs_data_A), .i_rt_A(decode_irt_A), .o_rt_data_A(o_rt_data_A), 
                    .i_rd_A(wri_ird_A), .i_wdata_A(wri_iwdata_A), .i_rd_we_A(wri_irdwe_A), .i_rs_B(decode_irs_B),
                    .o_rs_data_B(o_rs_data_B), .i_rt_B(decode_irt_B), .o_rt_data_B(o_rt_data_B), 
                    .i_rd_B(wri_ird_B), .i_wdata_B(wri_iwdata_B), .i_rd_we_B(wri_irdwe_B));


   assign test_cur_pc_A = wri_pc_A;
   assign test_cur_insn_A = wri_insn_A;
   assign test_regfile_we_A = wri_irdwe_A;
   assign test_regfile_wsel_A = wri_ird_A;
   assign test_regfile_data_A = wri_iwdata_A;
   assign test_dmem_we_A = wri_odmemwe_A;
   assign test_dmem_addr_A = wri_odmemaddr_A;
   assign test_dmem_data_A = (wri_isload_insn_A) ? wri_icurdmemdata_A : wri_odmemtowrite_A;
   assign test_stall_A = (wri_stall_A != 0) ? wri_stall_A: (wri_br_stall_A ? 'b10 : 0);

   assign test_cur_pc_B = wri_pc_B;
   assign test_cur_insn_B = wri_insn_B;
   assign test_regfile_we_B = wri_irdwe_B;
   assign test_regfile_wsel_B = wri_ird_B;
   assign test_regfile_data_B = wri_iwdata_B;
   assign test_dmem_we_B = wri_odmemwe_B;
   assign test_dmem_addr_B = wri_odmemaddr_B;
   // if load insn then use icurdmemdata
   assign test_dmem_data_B = (wri_isload_insn_B) ? wri_icurdmemdata_B : wri_odmemtowrite_B;
   assign test_stall_B = (wri_stall_B != 0) ? wri_stall_B: ((wri_br_stall_B || wri_br_stall_A) ? 'b10 : 0);

   wire [2:0] load_nzp_A, load_nzp_B;
   assign test_nzp_we_A = wri_nzpwe_A;
   NZP_testor nzp_load_testor_A(.result(test_dmem_data_A), .nzp(load_nzp_A));
   assign test_nzp_new_bits_A = wri_isload_insn_A? load_nzp_A:wri_nzp_new_bits_A;

   assign test_nzp_we_B = wri_nzpwe_B;
   NZP_testor nzp_load_testor_B(.result(test_dmem_data_B), .nzp(load_nzp_B));
   assign test_nzp_new_bits_B = wri_isload_insn_B? load_nzp_B:wri_nzp_new_bits_B;



   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    *
    * You may also use if statements inside the always block
    * to conditionally print out information.
    *
    * You do not need to resynthesize and re-implement if this is all you change;
    * just restart the simulation.
    * 
    * To disable the entire block add the statement
    * `define NDEBUG
    * to the top of your file.  We also define this symbol
    * when we run the grading scripts.
    */
`ifndef NDEBUG
   always @(posedge gwe) begin
      // $display("%b", i_cur_insn);
      // $display("%d %h %h %h %h %h", $time, f_pc, d_pc, e_pc, m_pc, test_cur_pc);
    //   if (next_pc == 16'h820e)
    //      $display("PC: %h, INSN: %h", fetch_pc, i_cur_insn);

    $display("\n \n");
    
    pinstr(i_cur_insn_A);
      $display("\n fetch_A PC: %h, i_cur insn: %h, o_rs_data: %h, o_rt_data: %h, i_rd: %h, i_rt: %h, i_rs: %h, cur_select_pc_plus_one: %h, pc_plus1: %h", fetch_pc_A, i_cur_insn_A, o_rs_data_A, o_rt_data_A, i_rd_A, i_rt_A, i_rs_A, select_pc_plus_one_A, pc_plus1_A);  
    pinstr(i_cur_insn_B);
      $display("\n fetch_B PC: %h, i_cur insn: %h, o_rs_data: %h, o_rt_data: %h, i_rd: %h, i_rt: %h, i_rs: %h, cur_select_pc_plus_one: %h, pc_plus1: %h", fetch_pc_B, i_cur_insn_B, o_rs_data_B, o_rt_data_B, i_rd_B, i_rt_B, i_rs_B, select_pc_plus_one_B, pc_plus1_B);  

    pinstr(decode_insn_A);
      $display("\n decode_A PC: %h, decode insn: %h, exe o_result: %h, exe_alu_rs_input: %h, exe_alu_rt_input: %h,  decode_ird: %h, decode_irs: %h, decode_irt: %h, decode_selpcplusone_insn: %h， decode_pcplus1: %h, nzp_we: %h", decode_pc_A, decode_insn_A, o_result_A, exe_alu_rs_input_A, exe_alu_rt_input_A, decode_ird_A, decode_irs_A, decode_irt_A, decode_selpcplusone_insn_A, decode_pcplus1_A, decode_nzpwe_A);  
      $display("decode_stall_A: %h, decode_br_stall_A: %h, o_result_A: %h ", decode_stall_A, decode_br_stall_A, o_result_A);
    pinstr(decode_insn_B);
      $display("\n decode_B PC: %h, decode insn: %h, exe o_result: %h, exe_alu_rs_input: %h, exe_alu_rt_input: %h,  decode_ird: %h, decode_irs: %h, decode_irt: %h, decode_selpcplusone_insn: %h， decode_pcplus1: %h, nzp_we: %h", decode_pc_B, decode_insn_B, o_result_B, exe_alu_rs_input_B, exe_alu_rt_input_B, decode_ird_B, decode_irs_B, decode_irt_B, decode_selpcplusone_insn_B, decode_pcplus1_B, decode_nzpwe_B);  
      $display("decode_stall_B: %h, decode_br_stall_B: %h, o_result_B: %h ", decode_stall_B, decode_br_stall_B, o_result_B);


      // (!decode_check_rd_A && ((decode_ird_A == decode_irt_B && !decode_check_rt_B) 
      //                                    || (decode_ird_A == decode_irs_B && !decode_check_rs_B)))
      //                         || ((decode_isload_insn_A || decode_isstore_insn_A) && (decode_isstore_insn_B || decode_isload_insn_B))
      //                         || (decode_nzpwe_A && decode_isbranch_B)

      $display("is_AB_dependent: %h， emmm ： %h", is_AB_dependent, (decode_ird_A == decode_irs_B && !decode_check_rs_B));


    $display("\n decode_stall_ltu_sel_A: %h, decode_stall_ltu_sel_B: %h, i_br_stall_A: %h, i_br_stall_B: %h", decode_stall_ltu_sel_A, decode_stall_ltu_sel_B, i_br_stall_A, i_br_stall_B);
    $display("\n exe_insn_A[11:9]: %h, nzp_3bit_A: %h, nzp_sel_A: %h ", exe_insn_A[11:9], nzp_3bit_A, nzp_sel_A);
    // assign next_pc_A = exe_iscontroinsn_A ? o_result_A : 
    //                     ((exe_isbranch_A & nzp_sel_A) ? branch_result_afterMux_A : 
    //                       (exe_iscontroinsn_B ? o_result_B:
    //                         ((exe_isbranch_B & nzp_sel_B) ? branch_result_afterMux_B : pc_plus1_A)));

    $display("\n next_pc_A: %h, o_result_A: %h, test_next_pc_A: %h ", next_pc_A, branch_result_afterMux_A, test_next_pc_A);

    pinstr(exe_insn_A);
      $display("\n exe_A PC: %h, exe insn: %h, mem_oresult_insn: %h,  exe_rs_data: %h, exe_rt_data: %h, exe_ird: %h, exe_irs: %h, exe_irt: %h, o_result： %h, exe_selpcplusone_insn: %h， exe_pcplus1： %h, exe_alu_rs_input_A: %h,  exe_alu_rt_input_A: %h, mem_B_BP: %h,  mem_A_BP: %h, wri_B_BP: %h, wri_A_BP: %h, mem_oresult_insn_B: %h, mem_oresult_insn_A: %h, nzp_we: %h ", exe_pc_A, exe_insn_A, o_result_A, exe_rs_data_A, exe_rt_data_A, exe_ird_A, exe_irs_A, exe_irt_A, o_result_A, exe_selpcplusone_insn_A, exe_pcplus1_A, exe_alu_rs_input_A, exe_alu_rt_input_A, 
                                                                                                                                                                                    ((exe_irs_A == mem_ird_B) && mem_irdwe_B), ((exe_irs_A == mem_ird_A) && mem_irdwe_A), ((exe_irs_A == wri_ird_B) && wri_irdwe_B), ((exe_irs_A == wri_ird_A) && wri_irdwe_A), mem_oresult_insn_B, mem_oresult_insn_A, exe_nzpwe_A);  
      $display("exe_stall_A: %h, exe_br_stall_A: %h, data_to_test_sel_A: %h , 0: %h, 1: %h, 2: %h， nzp_3bit_A： %h ", exe_stall_A, exe_br_stall_A, data_to_test_sel_A, exe_pcplus1_A, o_result_A, i_cur_dmem_data, nzp_3bit_A); 
    pinstr(exe_insn_B);
      $display("\n exe_B PC: %h, exe insn: %h, mem_oresult_insn: %h,  exe_rs_data: %h, exe_rt_data: %h, exe_ird: %h, exe_irs: %h, exe_irt: %h, o_result： %h, exe_selpcplusone_insn: %h， exe_pcplus1： %h, exe_alu_rt_input_B:%h, exe_alu_rt_input_B:%h , nzp_we: %h", exe_pc_B, exe_insn_B, o_result_B, exe_rs_data_B, exe_rt_data_B, exe_ird_B, exe_irs_B, exe_irt_B, o_result_B, exe_selpcplusone_insn_B, exe_pcplus1_B, exe_alu_rs_input_B, exe_alu_rt_input_B, exe_nzpwe_B);  
      $display("exe_stall_B: %h, exe_br_stall_B: %h, data_to_test_sel_B: %h ", exe_stall_B, exe_br_stall_B, data_to_test_sel_B);
    
    $display("\n nzp_serial_input: %h, nzp_serial_last: %h, nzp_3bit_A: %h, nzp_3bit_B: %h, nzp_sel_A: %h, nzp_sel_B: %h",nzp_serial_input, nzp_serial_last, nzp_3bit_A, nzp_3bit_B, nzp_sel_A, nzp_sel_B);

    pinstr(mem_insn_A);
      $display("\n mem_A PC: %h, mem insn: %h, mem_selpcplusone_insn: %h, mem_pcplus1: %h, mem_isload_insn: %h, mem_isstore_insn: %h, mem_oresult_insn: %h,  mem_rs_data: %h, mem_rt_data: %h, mem_ird: %h, mem_irs: %h, mem_irt: %h, o_dmem_addr_A : %h, mem_oresult_insn_A : %h , nzp_we: %h", mem_pc_A, mem_insn_A, mem_selpcplusone_insn_A, mem_pcplus1_A, mem_isload_insn_A, mem_isstore_insn_A, mem_oresult_insn_A, mem_rs_data_A, mem_rt_data_A, mem_ird_A, mem_irs_A, mem_irt_A, o_dmem_addr_A, mem_oresult_insn_A, mem_nzpwe_A);  
      $display("mem_stall_A: %h, mem_br_stall_A: %h, mem_nzp_new_bits_A: %h ", mem_stall_A, mem_br_stall_A, mem_nzp_new_bits_A);
    pinstr(mem_insn_B);
      $display("\n mem_B PC: %h, mem insn: %h, mem_selpcplusone_insn: %h, mem_pcplus1: %h, mem_isload_insn: %h, mem_isstore_insn: %h,  mem_oresult_insn: %h,  mem_rs_data: %h, mem_rt_data: %h, mem_ird: %h, mem_irs: %h, mem_irt: %h, o_dmem_addr_B: %h, mem_oresult_insn_B : %h , nzp_we: %h", mem_pc_B, mem_insn_B, mem_selpcplusone_insn_B, mem_pcplus1_B, mem_isload_insn_B, mem_isstore_insn_B, mem_oresult_insn_B, mem_rs_data_B, mem_rt_data_B, mem_ird_B, mem_irs_B, mem_irt_B, o_dmem_addr_B, mem_oresult_insn_B, mem_nzpwe_B);  
      $display("mem_stall_B: %h, mem_br_stall_B: %h, mem_nzp_new_bits_B: %h ", mem_stall_B, mem_br_stall_B, mem_nzp_new_bits_B);

    pinstr(wri_insn_A);
      $display("\n (current round A)wri PC: %h, wri insn: %h, wri_wdata: %h, wri_selpcplusone_insn: %h, wri_pcplus1: %h, wri_isload_insn: %h, wri_icurdmemdata: %h, wri_oresult_insn: %h,  wri_rs_data: %h, wri_rt_data: %h, wri_ird: %h, wri_irs: %h, wri_irt: %h, wri_odmemaddr_A: %h, nzp_we: %h", wri_pc_A, wri_insn_A, wri_iwdata_A, wri_selpcplusone_insn_A, wri_pcplus1_A, wri_isload_insn_A, wri_icurdmemdata_A, wri_oresult_insn_A, wri_rs_data_A, wri_rt_data_A, wri_ird_A, wri_irs_A, wri_irt_A, wri_odmemaddr_A, wri_nzpwe_A);  
      $display("wri_stall_A: %h, wri_br_stall_A: %h, wri_nzp_new_bits_A: %h ", wri_stall_A, wri_br_stall_A, wri_nzp_new_bits_A);
    pinstr(wri_insn_B);
      $display("\n (current round B)wri PC: %h, wri insn: %h, wri_wdata: %h, wri_selpcplusone_insn: %h, wri_pcplus1: %h, wri_isload_insn: %h, wri_icurdmemdata: %h, wri_oresult_insn: %h,  wri_rs_data: %h, wri_rt_data: %h, wri_ird: %h, wri_irs: %h, wri_irt: %h, wri_odmemaddr_A: %h, nzp_we: %h", wri_pc_B, wri_insn_B, wri_iwdata_B, wri_selpcplusone_insn_B, wri_pcplus1_B, wri_isload_insn_B, wri_icurdmemdata_B, wri_oresult_insn_B, wri_rs_data_B, wri_rt_data_B, wri_ird_B, wri_irs_B, wri_irt_B, wri_odmemaddr_B, wri_nzpwe_B);  
      $display("wri_stall_B: %h, wri_br_stall_B: %h, wri_nzp_new_bits_B: %h ", wri_stall_B, wri_br_stall_B, wri_nzp_new_bits_B);

      $display("\n \n");

// , wri_selpcplusone_insn: %h, wri_pcplus1: %h,  
//                wri_isload_insn: %h, wri_icurdmemdata: %h, wri_oresult_insn: %h

//                , wri_selpcplusone_insn, wri_pcplus1,  
//                wri_isload_insn, wri_icurdmemdata, wri_oresult_insn

      // Start each $display() format string with a %d argument for time
      // it will make the output easier to read.  Use %b, %h, and %d
      // for binary, hex, and decimal output of additional variables.
      // You do not need to add a \n at the end of your format string.
      // $display("%d ...", $time);s

      // Try adding a $display() call that prints out the PCs of
      // each pipeline stage in hex.  Then you can easily look up the
      // instructions in the .asm files in test_data.

      // basic if syntax:
      // if (cond) begin
      //    ...;
      //    ...;
      // end

      // Set a breakpoint on the empty $display() below
      // to step through your pipeline cycle-by-cycle.
      // You'll need to rewind the simulation to start
      // stepping from the beginning.

      // You can also simulate for XXX ns, then set the
      // breakpoint to start stepping midway through the
      // testbench.  Use the $time printouts you added above (!)
      // to figure out when your problem instruction first
      // enters the fetch stage.  Rewind your simulation,
      // run it for that many nano-seconds, then set
      // the breakpoint.

      // In the objects view, you can change the values to
      // hexadecimal by selecting all signals (Ctrl-A),
      // then right-click, and select Radix->Hexadecial.

      // To see the values of wires within a module, select
      // the module in the hierarchy in the "Scopes" pane.
      // The Objects pane will update to display the wires
      // in that module.

      $display();
   end
`endif
endmodule

module NZP_check 
  (input wire[2:0] i_insn, 
   input wire[2:0] nzp, 
   output wire NZP_op);
  
  wire op1, op2, op3, op12;
  assign op1 = i_insn[2] & nzp[2];
  assign op2 = i_insn[1] & nzp[1];
  assign op3 = i_insn[0] & nzp[0];
  assign op12 = op1 | op2;
  assign NZP_op = op12 | op3;

endmodule

module NZP_testor 
  (input wire[15:0] result, 
   output wire[2:0] nzp); //n(2)z(1)p(0)

  assign nzp[2] = ($signed(result) < 0)? 1:0;
  assign nzp[1] = ($signed(result) == 0)? 1:0;
  assign nzp[0] = ($signed(result) > 0)? 1:0;

endmodule