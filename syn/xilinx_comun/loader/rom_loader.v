`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    04/12/2020
// Design Name: 
// Module Name:    rom_loader
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: rom loader based on nes core loader by DistWave
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//    Author AvlixA
//
//
//////////////////////////////////////////////////////////////////////////////////

module rom_loader (

	input wire clk,
   input wire clk21m,
	input wire reset,

	// SRAM
	output wire [18:0] sram_addr,
	inout wire  [7:0] sram_data,
	output wire sram_we_n,
   // ROM ADDR
   output wire [13:0] rom_addr,
   
   // CHAR RAM
   output wire [8:0] char_addr,
   output wire [7:0] char_data,
   output wire char_we,
   
	// VP
	//input  wire [12:0] vp_addr,
   input  wire [11:0] cart_addr,
   input  wire  cart_bs0,
   input  wire  cart_bs1,
	output wire [7:0]  vp_data,
	input  wire        vp_en_n,

	output wire vp_rst_n,
   input wire  [31:0] host_bootdata,
   input wire  host_bootdata_req,
   input wire  host_bootdata_reset,
   output reg  host_bootdata_ack,
	input wire  [15:0] host_bootdata_size,
	output wire [15:0] currentROM,
   input wire loadchr,
	input wire  test_rom,
	output wire test_led

	);

   //reg to temporary save input data from ctrlmodule
   reg [31:0] host_bootdata_save;
   reg [15:0] host_rom_size;

   //loader signal
   reg [1:0] boot_state = 2'b0;
   reg [15:0] bytesloaded;
   wire cartgt4k, cartgt8k, cartgt12k;
   wire [13:0] rom_addr_s;

   assign cartgt4k = (host_rom_size >= 16'h1000) ? 1'b1: 0; //control cart 2k-4k
   assign cartgt8k = (host_rom_size >= 16'h2000) ? 1'b1: 0; //control cart 8k
   assign cartgt12k = (host_rom_size >= 16'h4000) ? 1'b1: 0; //control cart 12K (16k banked)

   //FSM receive from ctrlmodule and sendto fifo
   always@( posedge clk)
   begin
      if (loader_reset == 1'b1) begin
         host_bootdata_ack <= 1'b0;
         boot_state <= 2'b00;
         loader_write <= 1'b0;
         bytesloaded <= 16'h00000000;
         loader_addr <= 22'h000000;
         loader_done <= 1'b0;
      end else begin

         case (boot_state)
            2'b00: begin
                  loader_addr <= loader_addr;
                  if (host_bootdata_req == 1'b1) begin
                        boot_state <= 2'b11;
                        host_bootdata_ack <= 1'b1;
                        loader_write <= (loader_done) ? 1'b0 : 1'b1;
                        loader_write_data <= host_bootdata[31:24];
                        host_bootdata_save<= host_bootdata;
                        if ( loadchr == 1'b0) begin
                           host_rom_size <= host_bootdata_size;
                        end
                  end
                  else begin
                     host_bootdata_ack <= 1'b0;
                     if (bytesloaded[15:2] == host_bootdata_size[15:2]) 
                        loader_done <= 1;
                     boot_state <= 2'b00;
                     loader_write <= 1'b0;
                  end
               end
            2'b01: 
               begin
                    loader_write <= 1'b0;
                    loader_addr <= loader_addr;
                    boot_state <= 2'b10;
               end
            2'b10:
               begin
                  bytesloaded <= bytesloaded + 1'b1;
                  loader_addr <= loader_addr + 1'b1;
                  host_bootdata_ack <= 1'b0;
                  if (loader_addr[1:0] == 2'b11) begin
                    boot_state <= 2'b00;
                  end
                  else begin
                     boot_state <= 2'b01;
                     loader_write <= (loader_done) ? 1'b0 : 1'b1;
                     if (loader_addr[1:0] == 2'b00) begin //siguiente bit = 2
                        loader_write_data <= host_bootdata_save[23:16];
                     end
                     else if (loader_addr[1:0] == 2'b01) begin //siguiente bit = 3
                        loader_write_data <= host_bootdata_save[15:8];
                     end
                     else if (loader_addr[1:0] == 2'b10) begin //siguiente bit = 4
                        loader_write_data <= host_bootdata_save[7:0];
                     end
                  end
               end
            2'b11:
               begin
                  if (host_bootdata_req == 1'b0) begin
                        boot_state <= 2'b01;
                        host_bootdata_ack <= 1'b0;
                  end
                  else begin
                        host_bootdata_ack <= 1'b1;
                        boot_state <= 2'b01;
                  end
               end
         endcase
      end
   end

   //signal for gameloader
   reg  [21:0] loader_addr;
   reg  [7:0]  loader_write_data;
   reg  [7:0]  loader_input;
   wire loader_reset = host_bootdata_reset; //host_reset_loader;
   reg  loader_write;
   reg  loader_done, loader_fail;
   wire reset_done;
   reg  loader_done_r;

   //reset Videopac
   assign vp_rst_n = (reset)? 1'b0 : loader_done;
   assign test_led = !loader_done;
   //ROM addr logic
   assign rom_addr_s  = (cartgt12k == 1'b1) ? {2'b0,cart_bs1,cart_bs0, cart_addr[11:0]} :
                   (cartgt8k == 1'b1) ? {2'b0,cart_bs1,cart_bs0, cart_addr[11], cart_addr[9:0]} :
                   (cartgt4k == 1'b1) ? {3'b0,cart_bs0, cart_addr[11], cart_addr[9:0]} :
                   {3'b0, cart_addr[11], cart_addr[9:0]};
   assign sram_addr = ( loader_write || !loader_done) ? loader_addr : { 5'b0,rom_addr_s};
   assign rom_addr  = rom_addr_s;
   
   //SRAM memory signals
	assign sram_data = ( loader_write == 1'b1 ) ? loader_write_data : 8'hZ;
	assign sram_we_n = !loader_write && !loadchr;
   
   //Output data to videopac core
   assign vp_data = (test_rom == 1'b0) ? vp_data_aux : data_testrom;
   assign vp_data_aux = (loader_write == 1'b0 && vp_en_n == 1'b0 ) ? sram_data :	8'hFF;
   
   //CHAR RAM memory signals
   assign char_addr = ( !loader_done && loadchr ) ? loader_addr[8:0] : 10'd0;
   assign char_data = ( !loader_done && loadchr ) ? loader_write_data : 8'hZ;
   assign char_we = loader_write && loadchr;
   
   //Internal Test rom 
	wire [7:0] vp_data_aux;
	wire [13:0] addr_testrom;
	wire [7:0]  data_testrom;
	assign addr_testrom = {2'b0, cart_addr};

	rom_test rom_test
	(
		 .addr(addr_testrom[10:0]),
		 .data(data_testrom)
	);

endmodule
