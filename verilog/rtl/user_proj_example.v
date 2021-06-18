// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output reg wbs_ack_o,
    output reg [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    wire clk;
    wire rst;
    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;
    wire [31:0] rdata; 
    wire [31:0] wdata;
    wire [BITS-1:0] count;

    wire valid;
    wire [3:0] wstrb;
    wire [31:0] la_write;

    wire pwm1_select , pwm2_select , i2c_select , rtc_select , pid_select ;
    wire pwm1_wbs_stb_i , pwm2_wbs_stb_i , i2c_wbs_stb_i , rtc_wbs_stb_i , pid_wbs_stb_i ;
    wire pwm1_wbs_ack_o , pwm2_wbs_ack_o , i2c_wbs_ack_o , rtc_wbs_ack_o , pid_wbs_ack_o ; 

    wire [31:0] pwm1_wbs_dat_o ;
    wire [31:0] pwm2_wbs_dat_o ;
    wire [7:0] i2c_wbs_dat_o ;
    wire [31:0] rtc_wbs_dat_o ;
    wire [31:0] pid_wbs_dat_o  ;

    wire pwm_out1 , pwm_out2 ;
    wire pwm_out1_oen , pwm_out2_oen ;
    wire ptc1_intr , ptc2_intr , i2c_intr , rtc_intr ;
    reg led1, led2, led3 ; 
    wire ptc_clk1,ptc_clk2;
    wire capt_in1,capt_in2;
    wire i2c_scl_in, i2c_sda_in, scl_pad_o, scl_padoen_o, sda_pad_o, sda_padoen_o ; 

    assign ptc_clk1 = io_in[0] ;                           // IO[0]
    assign io_oeb[0]= 1'b1;

    assign ptc_clk2 = io_in[1] ;                           // IO[1]
    assign io_oeb[1]= 1'b1;

    assign capt_in1 = io_in[2] ;                           // IO[2]
    assign io_oeb[1]= 1'b1;

    assign capt_in2 = io_in[3] ;                           // IO[3]
    assign io_oeb[1]= 1'b1;

    
    assign io_out[5:4] = la_data_in[110:109] ;             // IO[5:4]
    assign io_oeb[5:4] = la_oenb[110:109]    ;

    assign io_out[7:6] = {pwm_out2,pwm_out1} ;             // IO[7:6]
    assign io_oeb[7:6] = {pwm_out2_oen,pwm_out1_oen} ;

    assign io_out[8] = scl_pad_o ;                         // IO[8]
    assign io_oeb[8] = scl_padoen_o ;

    assign i2c_scl_in = io_in[9] ;                         // IO[9]
    assign io_oeb[9]= 1'b1;

    assign io_out[10] = sda_pad_o ;                        // IO[10]
    assign io_oeb[10] = sda_padoen_o;

    assign i2c_sda_in = io_in[11] ;                        // IO[11]
    assign io_oeb[11]= 1'b1;

    // Inputs

    // IRQ
    assign irq = {rtc_intr , i2c_intr , {ptc2_intr || ptc1_intr} };	

    // LA
   assign clk = wb_clk_i ;
   assign rst = wb_rst_i ;

   // Module Address Select Logic
   assign pwm1_select = (wbs_adr_i[31:12] == 20'h30001) ;
   assign pwm2_select = (wbs_adr_i[31:12] == 20'h30002) ;
   assign i2c_select  = (wbs_adr_i[31:12] == 20'h30003) ;
   assign rtc_select  = (wbs_adr_i[31:12] == 20'h30004) ;
   assign pid_select  = (wbs_adr_i[31:12] == 20'h30005) ;
  
   // Module STROBE Select based on Address Range
   assign pwm1_wbs_stb_i = (wbs_stb_i && pwm1_select) ;
   assign pwm2_wbs_stb_i = (wbs_stb_i && pwm2_select) ;
   assign i2c_wbs_stb_i  = (wbs_stb_i && i2c_select)  ;
   assign rtc_wbs_stb_i  = (wbs_stb_i && rtc_select)  ;
   assign pid_wbs_stb_i  = (wbs_stb_i && pid_select)  ;


   // Slave Acknowledge Response 
   always @(posedge clk)
	   wbs_ack_o <= (pwm1_wbs_ack_o || pwm2_wbs_ack_o || i2c_wbs_ack_o || rtc_wbs_ack_o || pid_wbs_ack_o) ;

   // Slave Return Data
   always @(posedge clk)
	   if (pwm1_wbs_ack_o)
		   wbs_dat_o <= pwm1_wbs_dat_o ;
	   else if (pwm2_wbs_ack_o)
		   wbs_dat_o <= pwm2_wbs_dat_o ;
	   else if (i2c_wbs_ack_o)
		   wbs_dat_o <= {24'b0,i2c_wbs_dat_o} ;
	   else if (rtc_wbs_ack_o)
		   wbs_dat_o <= rtc_wbs_dat_o ;
	   else if (pid_wbs_ack_o)
		   wbs_dat_o <= pid_wbs_dat_o ;
	   else
		   wbs_dat_o <= 32'h0 ;


	   
   // PTC1 Module instantiations 
   ptc_top ptc1_i (
	   .wb_clk_i (clk),
	   .wb_rst_i (rst),
	   .wb_cyc_i (wbs_cyc_i),
	   .wb_adr_i ({8'h0,wbs_adr_i[7:0]}), // 16-bit address
	   .wb_dat_i (wbs_dat_i),    
	   .wb_sel_i (wbs_sel_i),
	   .wb_we_i  (wbs_we_i),
	   .wb_stb_i (pwm1_wbs_stb_i),
	   .wb_dat_o (pwm1_wbs_dat_o),
	   .wb_ack_o (pwm1_wbs_ack_o),
	   .wb_err_o ( ),
	   .wb_inta_o (ptc1_intr),
	   .gate_clk_pad_i (ptc_clk1),
	   .capt_pad_i (capt_in1),
	   .pwm_pad_o (pwm_out1), 
	   .oen_padoen_o (pwm_out1_oen)
   ); 

   // PTC2 Module instantiations 

 ptc_top ptc2_i (
	   .wb_clk_i (clk),
	   .wb_rst_i (rst),
	   .wb_cyc_i (wbs_cyc_i),
	   .wb_adr_i ({8'h0,wbs_adr_i[7:0]}), // 16-bit address
	   .wb_dat_i (wbs_dat_i),    
	   .wb_sel_i (wbs_sel_i),
	   .wb_we_i  (wbs_we_i),
	   .wb_stb_i (pwm2_wbs_stb_i),
	   .wb_dat_o (pwm2_wbs_dat_o),
	   .wb_ack_o (pwm2_wbs_ack_o),
	   .wb_err_o ( ),
	   .wb_inta_o (ptc2_intr),
	   .gate_clk_pad_i (ptc_clk2),
	   .capt_pad_i (capt_in2),
	   .pwm_pad_o (pwm_out2), 
	   .oen_padoen_o (pwm_out2_oen)
   );

   // I2C Module Instanciation 
 i2c_master_top i2c_i (
	   .wb_clk_i (clk),
	   .wb_rst_i (rst),
	   .arst_i   (1'b1),
	   .wb_adr_i (wbs_adr_i[4:2]), // 3-bit address
	   .wb_dat_i (wbs_dat_i[7:0]), // 8-bit data    
	   .wb_dat_o (i2c_wbs_dat_o),  // 8-bit data
	   .wb_we_i  (wbs_we_i),
	   .wb_stb_i (i2c_wbs_stb_i ),
	   .wb_cyc_i (wbs_cyc_i),
	   .wb_ack_o (i2c_wbs_ack_o),
	   .wb_inta_o (i2c_intr),
	   .scl_pad_i (i2c_scl_in),
	   .scl_pad_o (scl_pad_o),
	   .scl_padoen_o (scl_padoen_o),
	   .sda_pad_i (i2c_sda_in),
	   .sda_pad_o (sda_pad_o),
	   .sda_padoen_o (sda_padoen_o)
   );

   // RTC Module Instanciation

  rtcdate rtc_date_i (
	  .i_clk (clk),
	  .i_ppd (la_data_in[111]),
	  .i_wb_cyc (wbs_cyc_i),
	  .i_wb_stb (rtc_wbs_stb_i),
	  .i_wb_we (wbs_we_i),
	  .i_wb_data (wbs_dat_i),
	  .o_wb_ack (rtc_wbs_ack_o),
	  .o_wb_data (rtc_wbs_dat_o)
  );

/*
   // PID Module Instantiation 
  PID pid (
	  .i_clk (clk),
	  .i_rst (rst),
	  .i_wb_cyc (wbs_cyc_i),
	  .i_wb_stb (pid_wbs_stb_i),
	  .i_wb_we (wbs_we_i),
	  .i_wb_adr ({8'h0,wbs_adr_i[7:0]}), // 16-bit address
	  .i_wb_data (wbs_dat_i),
	  .o_wb_ack (pid_wbs_ack_o),
	  .o_wb_data (pid_wbs_dat_o),
	  .o_un (),
	  .o_valid ()
  ); 


   // FPU Instanciation
   fpu fpu_i (

	   .clk 	(clk),
	   .rmode 	(la_data_in[105:104]), 	// 2-bit
	   .fpu_op 	(la_data_in[108:106]), 	// 3-bit
	   .opa 	(la_data_in[31:0]),	// 32-bit
	   .opb		(la_data_in[63:32]),	// 32-bit
	   .out		(la_data_in[95:64]), 	// 32-bit
	   .inf		(la_data_out[96]),
	   .snan	(la_data_out[97]),
	   .qnan	(la_data_out[98]),
	   .ine		(la_data_out[99]),
	   .overflow	(la_data_out[100]),
	   .underflow	(la_data_out[101]),
	   .zero	(la_data_out[102]),
	   .div_by_zero	(la_data_out[103]),

   );
*/

endmodule
`default_nettype wire
