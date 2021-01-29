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

	// VP
	input  wire [12:0] vp_addr,
	output wire [7:0]  vp_data,
	input  wire        vp_en_n,

	output wire vp_rst_n,
   input wire  [31:0] host_bootdata,
   input wire  host_bootdata_req,
   input wire  host_bootdata_reset,
   output reg  host_bootdata_ack,
	input wire  [15:0] host_bootdata_size,
	output wire [15:0] currentROM,
	input wire  test_rom ,
	output wire test_led

	);


   //fifo signal
   //reg write_fifo;
   //reg read_fifo;
   wire full_fifo;
   reg skip_fifo = 1'b0;
   wire [7:0] dout_fifo;

   reg [12:0] counter_fifo;
   reg [31:0] host_bootdata_save;
   assign clk_fifo = counter_fifo[7]; 
   assign clk_gameloader = counter_fifo[6]; 

//   fifo_loader loaderbuffer (
//         .wr_clk(clk),
//         .rd_clk(clk_fifo), 
//         .din(host_bootdata), 
//         .wr_en(write_fifo), 
//         .rd_en(read_fifo), 
//         .dout(dout_fifo),
//         .full(full_fifo), 
//         .empty(empty_fifo)
//   );

   //loader signal
   reg [1:0] boot_state = 2'b0;
   reg [15:0] bytesloaded;
   wire cartgt2k, cartgt4k;

   assign cartgt2k = (host_bootdata_size >= 16'h1000) ? 1'b1: 0; //control cart 2k-4k
   assign cartgt4k = (host_bootdata_size >= 16'h2000) ? 1'b1: 0; //control cart 8k

   //FSM receive from ctrlmodule and sendto fifo
   always@( posedge clk)
   begin
      if (loader_reset == 1'b1) begin
         host_bootdata_ack <= 1'b0;
         boot_state <= 2'b00;
         //write_fifo <= 1'b0;
         loader_write <= 1'b0;
         //read_fifo <= 1'b0;
         //skip_fifo <= 1'b0;
         skip_fifo <= 1'b1;
         bytesloaded <= 16'h00000000;
         loader_addr <= 22'h000000;
         loader_done <= 1'b0;
      end else begin
         //if (dout_fifo == 8'h4E) skip_fifo <= 1'b1;

         case (boot_state)
            2'b00: begin
                  loader_addr <= loader_addr;
                  if (host_bootdata_req == 1'b1) begin
                     //if (full_fifo == 1'b0) begin
                        boot_state <= 2'b11;
                        host_bootdata_ack <= 1'b1;
                        //write_fifo <= (bytesloaded < host_bootdata_size) ? 1'b1 : 1'b0;
                        loader_write <= (loader_done) ? 1'b0 : 1'b1;
                        loader_write_data <= host_bootdata[31:24];
                        host_bootdata_save<= host_bootdata;
                     //end else read_fifo <= 1'b1;
                  end
                  else begin
                     host_bootdata_ack <= 1'b0;
                     if (bytesloaded[15:2] == host_bootdata_size[15:2]) 
                        loader_done <= 1;
                     boot_state <= 2'b00;
                     loader_write <= 1'b0;
                  end
               end
//            2'b01: 
//               begin
//                  host_bootdata_ack <= 2'b00;
//                  //write_fifo <= 1'b0;
//                  loader_write <= (bytesloaded < host_bootdata_size) ? 1'b1 : 1'b0;
//                  bytesloaded <= bytesloaded + 1;
//                  loader_addr <= loader_addr + 1;
//                  boot_state <= 2'b10;
//                  host_bootdata_ack <= 1'b0;
//               end
            2'b01: 
               begin
                  //host_bootdata_ack <= 1'b0;
                  //if (ram_busy == 1'b1) begin
                  //  boot_state <= 2'b01;
                    loader_write <= 1'b0;
                    loader_addr <= loader_addr;
                  //end
                  //else
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

   always@( posedge clk21m ) //¿clock de 21mhz?
   begin
      if (reset) begin
         counter_fifo <= 0;
         clk_loader <= 0;
      end 
      else begin
         counter_fifo <= counter_fifo + 1'b1;
         clk_loader <= !clk_fifo && skip_fifo;
      end
   end
   
   always@( posedge clk_loader)
   begin
      loader_input <= dout_fifo;
   end

   //signal for gameloader
   reg [21:0] loader_addr;
   reg [7:0] loader_write_data;
   reg  [7:0] loader_input;
   wire loader_reset = host_bootdata_reset; //host_reset_loader;
   reg loader_write;
   //wire [31:0] mapper_flags;
   reg loader_done, loader_fail;
   wire reset_done;
   reg  loader_done_r;
   wire empty_fifo;

   reg  clk_loader;
   wire clk_gameloader;
   wire clk_fifo;

//   GameLoader loader(
//       clk_gameloader, 
//       loader_reset, 
//       loader_input, 
//       clk_loader,
//       { 6'b0, host_bootdata_size },   //input [21:0] romsize,       
//       loader_addr, 
//       loader_write_data, 
//       loader_write,
//       //mapper_flags,
//       loader_done,
//       loader_fail
//   );
   reg [7:0] count_reset = 0;
   //reset Videopac
   assign vp_rst_n = (reset)? 1'b0 : loader_done;//!(count_reset[7] == 1'b0 && count_reset[0] == 1'b1);
   assign test_led = !loader_done;



	//assign sram_addr = ( loader_write || !loader_done) ? loader_addr : { 8'b0 , vp_addr};
   assign sram_addr = ( loader_write || !loader_done) ? loader_addr : 
                        { 6'b0, vp_addr[12] && cartgt4k, vp_addr[11] && cartgt2k , vp_addr[10:0]};
	assign sram_data = ( loader_write == 1'b1 ) ? loader_write_data : 8'hZ;
	assign sram_we_n = !loader_write;
   
   assign vp_data = (test_rom == 1'b0) ? vp_data_aux : data_testrom;
   //assign vp_data = vp_data_aux;
   assign vp_data_aux = (loader_write == 1'b0 && vp_en_n == 1'b0 ) ? sram_data :	8'hFF;
 
   always @(posedge clk21m) begin
      count_reset = {count_reset[6:0], loader_done};
   end
   
   
   //debug data
   wire   [13:0] debugaddr;
   wire   [15:0] debugdata;

   // This is the memory controller to access the board's SRAM
   wire ram_busy;
//   reg ramfail;
//   always @(posedge clk) begin
//    if (loader_reset)
//      ramfail <= 0;
//    else
//      ramfail <= ram_busy && loader_write || ramfail;
//   end

//	assign vp_data = (test_rom == 1'b0) ? vp_data_aux : data_testrom;
//	assign vp_data_aux = (dataToVP == 1'b1 && vp_en_n == 1'b0 ) ? sram_data :	8'hFF;

//   MemoryController memory(.clk(clk),
//                           .read_a( !loader_write && !vp_en_n ), 
//                           .read_b( 1'b0 ),
//                           .write( loader_write ), 
//                           .addr( loader_write ? loader_addr : { 9'b0 , vp_addr} ), 
//                           .din(  loader_write ? loader_write_data : 8'hFF ), 
//                           .dout_a( vp_data_aux ), 
//                           .dout_b(), 
//                           .busy(ram_busy), 
//                           .MemWRN(sram_we_n), 
//                           .MemAdr(sram_addr), 
//                           .MemDB(sram_data), 
//                           .debugaddr(debugaddr), 
//                           .debugdata(debugdata)
//                           );
   


////*****************************************************************//	
//	parameter
//		STATE_INITIAL = 4'd0,
//		STATE_SRAM_WAIT = 4'd1,
//		STATE_WRITE_B0 = 4'd2,
//		STATE_WRITE_B1 = 4'd3,
//		STATE_WRITE_B2 = 4'd4,
//		STATE_WRITE_B3 = 4'd5,
//		STATE_READNEXT = 4'd6,
//		STATE_SRAM_WAIT2 = 4'd7,
//		STATE_SRAM_WAIT3 = 4'd8
//		;
//
//	initial ram_wr_n = 1'b1;
//
//	reg dataToVP = 1'b0;
//	reg executingVP = 1'b1;
//	reg  [7:0] test_romq = 8'b0;
//	reg  [15:0] addr_wip;
	wire [7:0] vp_data_aux;
//
	wire [13:0] addr_testrom;
	wire [7:0]  data_testrom;
//
//	//assign vp_rst_n = executingVP;
//	assign vp_rst_n = (reset)? 1'b0 : (test_rom == 1'b0)? !executingVP : test_romq[7];
//   assign test_led = (state == STATE_INITIAL)? 1'b0 : 1'b1;
//	always @(posedge clk) begin
//	    test_romq <= {test_romq[6:0] , test_rom};
//	end
//
//	reg [3:0] state = STATE_INITIAL;
//	reg [3:0] nextstate = STATE_INITIAL;
//
//	reg [18:0] ram_addr;
//	reg [7:0]  ram_data;
//	reg        ram_wr_n;
//	reg [15:0] old_bootdata_size;
//
//	// SRAM logic
//	assign sram_addr = ( dataToVP == 1'b0 ) ? ram_addr : { 6'b0, vp_addr };
//	assign sram_data = ( dataToVP == 1'b0 && sram_we_n == 1'b0 ) ? ram_data : 8'hZ;
//	assign sram_we_n = ram_wr_n;
//	// VP Memory logic
//	//assign vp_data = ( dataToVP == 1'b1 && vp_en_n == 1'b0 ) ? sram_data : 8'hFF;
//	assign vp_data = (test_rom == 1'b0) ? vp_data_aux : data_testrom;
//	assign vp_data_aux = (dataToVP == 1'b1 && vp_en_n == 1'b0 ) ? sram_data :	8'hFF;
	assign addr_testrom = {1'b0, vp_addr};
//
//	assign currentROM = {12'b0, state};
//
//	//State machine to receive and stash boot data in BRAM
//	always @(posedge clk) begin
//		if (reset) begin
//			ram_addr <= 19'b0;
//			ram_wr_n <= 1'b1;
//			host_bootdata_ack <= 1'b0;
//			executingVP <= 1'b0;
//			dataToVP <= 1'b1;
//		   state <= STATE_INITIAL;		
//		end
//		else begin
//			host_bootdata_ack <= 1'b0;			
//			case (state)
//				STATE_INITIAL: begin
//						//ram_addr <= 19'b0;
//						//ram_data <= 9'b0;
//						ram_wr_n <= 1'b1;
//						if (host_bootdata_req == 1'b1) begin
//							host_bootdata_ack <= 1'b0;	
//							state <= STATE_WRITE_B0;
//					      dataToVP <= 1'b0;
//						   executingVP <= 1'b1;
//					   end
//						else begin
//					      dataToVP <= 1'b1;
//						   executingVP <= 1'b0;
//						end
//				end
//
//				STATE_SRAM_WAIT: begin
//						ram_addr <= ram_addr + 1'b1;
//						ram_wr_n <= 1'b1;
//						host_bootdata_ack <= 1'b1;	
//						state <= nextstate;	
//				end
//
//				STATE_WRITE_B0: begin
//						ram_data <= host_bootdata[7:0];
//						ram_wr_n <= 1'b0;
//						state <= STATE_SRAM_WAIT;
//						nextstate <= STATE_INITIAL;
//				end
//			endcase			
//		end
//	end
//
//	rom_test rom_test
//	(
//		 .addr(addr_testrom[10:0]),
//		 .data(data_testrom)
//	);

endmodule
