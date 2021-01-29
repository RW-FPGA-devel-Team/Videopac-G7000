`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    08/05/2018
// Design Name: 
// Module Name:    rom_selector
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//    Author yomboprime
//
//
//////////////////////////////////////////////////////////////////////////////////

module rom_selector (

	input wire clk,
	input wire reset,

	// SD
	output wire sd_clk,
	output wire sd_mosi,
	input wire sd_miso,
	output wire sd_cs_n,

	// SRAM
	output wire [18:0] sram_addr,
	inout wire [7:0] sram_data,
	output reg sram_we_n,

	// VP
	input wire [12:0] vp_addr,
	output wire [7:0] vp_data,
	input wire vp_en_n,

	output wire vp_rst_n,
	output wire sd_initialized_o,
	input wire doLoadRom,
	input wire [15:0] selectedROM,
	output reg [15:0] currentROM,

	input wire test_rom //,

	//output reg [7:0] debugled
	);
	
	parameter
		STATE_INITIAL = 4'd0,
		STATE_WAIT_START = 4'd1,
		STATE_START_READING_ROM = 4'd2,
		STATE_START_READING_SECTOR = 4'd3,
		STATE_START_READING_BYTE = 4'd4,
		STATE_READ_BYTE = 4'd5,
		STATE_FINISH_READING_BYTE = 4'd6,
		STATE_START_WRITING_BYTE = 4'd7,
		STATE_FINISH_WRITING_BYTE = 4'd8,
		STATE_FINISH_READING_ROM = 4'd9,
		STATE_READ_TESTROM  = 4'd10,
		STATE_READ_BYTETESTROM  = 4'd11,
		STATE_FINISH_READ_BYTETESTROM  = 4'd12,
		STATE_START_WRITING_TESTBYTE = 4'd13,
		STATE_FINISH_WRITING_TESTBYTE = 4'd14
		;

	initial sram_we_n = 1'b1;
	initial currentROM = 16'b0;
	//initial debugled = 8'h80;

	reg dataToVP = 1'b0;
	reg executingVP = 1'b0;
	assign vp_rst_n = (reset)? 1'b0 : (test_rom == 1'b0)? !executingVP : test_romq[7];
	wire sd_initialized;
	wire [7:0]  vp_data_aux;
	reg [7:0] test_romq = 8'b0;

	wire clk_sd;
	reg [1:0] clk_sd_counter = 2'b0;
	reg sd_rst = 1'b0;
	wire [7:0] sd_data_in;
	wire sd_rd_n;
	wire sd_busy;
	reg doStartRead = 1'b0;
	reg [3:0] state = STATE_INITIAL;

	reg [9:0] byteInSector;
	reg [4:0] sectorInROM;

	wire [31:0] sector_addr;
	assign sector_addr = { 12'b0, currentROM, sectorInROM[3:0] };
	
	reg [7:0] data_to_sram;

	always @(posedge clk) begin
	    clk_sd_counter <= clk_sd_counter + 2'd1;
	end

	always @(posedge clk) begin
	    test_romq <= {test_romq[6:0] , test_rom};
	end

	
	assign clk_sd = clk_sd_counter[1];

	assign sram_addr = ( dataToVP == 1'b0 ) ? { 6'b0, sectorInROM[3:0], byteInSector[8:0] } : { 6'b0, vp_addr };
	
	assign sram_data = ( dataToVP == 1'b0 && sram_we_n == 1'b0 ) ? data_to_sram : 8'hZ;
	
	assign vp_data = (test_rom == 1'b0) ? vp_data_aux : data_testrom;
	assign vp_data_aux = (dataToVP == 1'b1 && vp_en_n == 1'b0 ) ? sram_data :	8'hFF;
							
	
	assign sd_initialized_o = (test_rom == 1'b0) ? sd_initialized : test_romq[7];
	
	//output always from test rom
	assign addr_testrom =  {1'b0, vp_addr};
	//assign vp_data = data_testrom;

	sd_access sd1 (
      .clk(clk_sd),
      .rst(sd_rst),
      .spi_clk(sd_clk),
      .spi_di(sd_mosi),
      .spi_do(sd_miso),
      .spi_cs(sd_cs_n),
      .busy(sd_busy),
      .sd_initialized(sd_initialized),
      .d_out(sd_data_in),
      .wr_out_n(sd_rd_n),
      .sector_addr(sector_addr),
      .doStartRead(doStartRead)
   );

	always @(posedge clk_sd) begin

		case (state)

			STATE_INITIAL: begin
				//debugled <= 8'h80;
				if ( doLoadRom ) begin
					dataToVP <= 1'b0;
					executingVP <= 1'b1;
					state <= STATE_WAIT_START;
				end
				else begin
					dataToVP <= 1'b1;
					executingVP <= 1'b0;
				end
			end
			
			STATE_WAIT_START: begin
				if ( ! doLoadRom ) begin
					state <= STATE_START_READING_ROM;
					//state <= STATE_READ_TESTROM;
					currentROM <= selectedROM;
				end
			end
			
//			//INI TEST ROM
//			STATE_READ_TESTROM: begin
//				addr_testrom <= 14'b0;
//				byteInSector <= 10'b0;
//				sectorInROM <= 5'b0;
//				state <= STATE_READ_BYTETESTROM;
//			end
//
//			STATE_READ_BYTETESTROM: begin
//					byteInSector[8:0] <= addr_testrom[8:0];
//					sectorInROM[3:0]	<= addr_testrom[12:9];				
//					data_to_sram <= data_testrom;
//					state <= STATE_FINISH_READ_BYTETESTROM;
//			end
//
//			STATE_FINISH_READ_BYTETESTROM: begin
//					state <= STATE_START_WRITING_TESTBYTE;
//			end
//			
//			STATE_START_WRITING_TESTBYTE: begin
//				sram_we_n <= 1'b0;
//				state <= STATE_FINISH_WRITING_TESTBYTE;
//			end
//			
//			STATE_FINISH_WRITING_TESTBYTE: begin
//				sram_we_n <= 1'b1;
//				addr_testrom <= addr_testrom + 10'd1;
//				if (addr_testrom == 14'h1FFF) begin
//					executingVP <= 1'b0;
//					state <= STATE_INITIAL;
//				end else
//					state <= STATE_READ_BYTETESTROM;
//			end
//			//FIN TEST ROM

			STATE_START_READING_ROM: begin
				//debugled <= 8'd1;
				if ( sd_initialized == 1'b1 ) begin
					if ( sd_busy == 1'b0 ) begin
						byteInSector <= 10'b0;
						sectorInROM <= 5'b0;
						state <= STATE_START_READING_SECTOR;
					end
				end
				else begin
					state <= STATE_INITIAL;
				end
			end


			STATE_START_READING_SECTOR: begin
				//debugled <= 8'd2;
				if ( sectorInROM >= 5'd16 ) begin
					state <= STATE_FINISH_READING_ROM;
				end
				else if ( sd_busy == 1'b0 ) begin
					state <= STATE_START_READING_BYTE;
					doStartRead <= 1'b1;
				end
			end

			STATE_START_READING_BYTE: begin
				//debugled <= 8'd3;
				doStartRead <= 1'b0;
				if ( byteInSector >= 10'd512 ) begin
					sectorInROM <= sectorInROM + 5'd1;
					byteInSector <= 10'b0;
					state <= STATE_START_READING_SECTOR;
				end
				else begin
					state <= STATE_READ_BYTE;
				end
			end
			
			STATE_READ_BYTE: begin
				if ( sd_rd_n == 1'b0 ) begin
					//debugled <= 8'd4;
					data_to_sram <= sd_data_in;
					state <= STATE_FINISH_READING_BYTE;
				end
				else begin
					if ( sd_initialized == 1'b0 ) begin
						state <= STATE_INITIAL;
					end
					//debugled <= { 3'b110, sectorInROM };
				end
			end
			
			STATE_FINISH_READING_BYTE: begin
				//debugled <= 8'd5;
				if ( sd_rd_n == 1'b1 ) begin
					state <= STATE_START_WRITING_BYTE;
				end
			end
			
			STATE_START_WRITING_BYTE: begin
				//debugled <= 8'd6;
				sram_we_n <= 1'b0;
				state <= STATE_FINISH_WRITING_BYTE;
			end
			
			STATE_FINISH_WRITING_BYTE: begin
				//debugled <= 8'd7;
				sram_we_n <= 1'b1;
				byteInSector <= byteInSector + 10'd1;
				state <= STATE_START_READING_BYTE;
			end
			
			STATE_FINISH_READING_ROM: begin
				//debugled <= 8'd8;
				executingVP <= 1'b0;
				state <= STATE_INITIAL;
			end
			
		endcase

	end
	
	wire [13:0] addr_testrom;
	wire [7:0]  data_testrom;

//	 dpram_testrom #(14, 8) dpram_testrom
//	 (
//		 .clk_a_i(clk),
//		 .we_i(1'b0),
//		 .addr_a_i(addr_testrom),
//		 .data_a_i(),
//		 .data_a_o(data_testrom),
//		 .clk_b_i(),
//		 .addr_b_i(),
//		 .data_b_o()
//	  );
	
//	 rom_test rom_test
//	 (
//		 .clk(clk),
//		 .a(addr_testrom),
//		 .dout(data_testrom)
//	  );

	 rom_test rom_test
	 (
		 .addr(addr_testrom[10:0]),
		 .data(data_testrom)
	  );


  
endmodule
