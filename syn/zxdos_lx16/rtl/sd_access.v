`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    04:05:57 08/18/2016 
// Design Name: 
// Module Name:    ramtest 
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
//  Based on original sd test by mcleod_Ideafix http://zxuno.speccy.org
//
//
//////////////////////////////////////////////////////////////////////////////////

module sd_access (
   input wire clk,
   input wire rst,
   output wire spi_clk,    //
   output wire spi_di,     // Interface SPI
   input wire spi_do,      //
   output reg spi_cs,     //
   output reg busy,
   output reg sd_initialized,
   output reg[7:0] d_out,
   output reg wr_out_n,
   input wire [31:0] sector_addr,
   input wire doStartRead
   );
   
   initial busy = 1'b1;
   initial sd_initialized = 1'b0;
   initial wr_out_n = 1'b1;
   
   reg send_data = 1'b0;
   reg receive_data = 1'b0;
   reg [7:0] data_to_sd = 8'hFF;
   wire [7:0] data_from_sd;
   wire ready;
   initial spi_cs = 1'b1;
   
   spi slotsd (
      .clk(clk),         // 10.75 MHz
      .enviar_dato(send_data), // a 1 para indicar que queremos enviar un dato por SPI
      .recibir_dato(receive_data), // a 1 para indicar que queremos recibir un dato
      .din(data_to_sd),   // dato de entrada al modulo
      .dout(data_from_sd),  // dato de salida del modulo
      .wait_n(ready),
      .spi_clk(spi_clk),   // Interface SPI
      .spi_di(spi_di),     //
      .spi_do(spi_do)      //
   );
   
   reg [3:0] cnt = 4'd0;
   reg [7:0] tout = 8'd0;
   reg [2:0] currentCommand = 3'd0;
   reg [7:0] commandsBytes[0:4][0:5];
   reg [31:0] current_sector = 0;
   reg [9:0] byteInSector = 10'd0;
   initial begin
      commandsBytes[CMD_0][0] = 8'd0 | 8'h40;
      commandsBytes[CMD_0][1] = 8'h00;
      commandsBytes[CMD_0][2] = 8'h00;
      commandsBytes[CMD_0][3] = 8'h00;
      commandsBytes[CMD_0][4] = 8'h00;
      commandsBytes[CMD_0][5] = 8'h95;
      
      commandsBytes[CMD_8][0] = 8'd8 | 8'h40;
      commandsBytes[CMD_8][1] = 8'h00;
      commandsBytes[CMD_8][2] = 8'h00;
      commandsBytes[CMD_8][3] = 8'h01;
      commandsBytes[CMD_8][4] = 8'hAA;
      commandsBytes[CMD_8][5] = 8'h87;
      
      commandsBytes[CMD_41][0] = 8'd41 | 8'h40;
      commandsBytes[CMD_41][1] = 8'h40;
      commandsBytes[CMD_41][2] = 8'h00;
      commandsBytes[CMD_41][3] = 8'h00;
      commandsBytes[CMD_41][4] = 8'h00;
      commandsBytes[CMD_41][5] = 8'h77;
      
      /*
      // No sdhc
      commandsBytes[CMD_41][0] = 8'd41 | 8'h40;
      commandsBytes[CMD_41][1] = 8'h00;
      commandsBytes[CMD_41][2] = 8'h00;
      commandsBytes[CMD_41][3] = 8'h00;
      commandsBytes[CMD_41][4] = 8'h00;
      commandsBytes[CMD_41][5] = 8'he5;
      */
      
      commandsBytes[CMD_55][0] = 8'd55 | 8'h40;
      commandsBytes[CMD_55][1] = 8'h00;
      commandsBytes[CMD_55][2] = 8'h00;
      commandsBytes[CMD_55][3] = 8'h00;
      commandsBytes[CMD_55][4] = 8'h00;
      commandsBytes[CMD_55][5] = 8'h65;
      
      commandsBytes[CMD_58][0] = 8'd58 | 8'h40;
      commandsBytes[CMD_58][1] = 8'h00;
      commandsBytes[CMD_58][2] = 8'h00;
      commandsBytes[CMD_58][3] = 8'h00;
      commandsBytes[CMD_58][4] = 8'h00;
      commandsBytes[CMD_58][5] = 8'hFD;

   end
      
   reg [4:0] estado = SENDCLOCKS,
		retorno_de_sendspi = SENDCLOCKS,
		retorno_de_recvspi = SENDCLOCKS,
		retorno_de_respuesta = SENDCLOCKS;
   parameter
      SENDCLOCKS = 5'd0,
      SEND8CLOCKS = 5'd1,
      SENDCMD = 5'd2,
      RESPUESTA = 5'd3,
      CHECK = 5'd4,
      
      SENDCMD_8 = 5'd5,
      CHECK_RESP_8 = 5'd6,
      SENDCMD_55 = 5'd7,
      SENDCMD_41 = 5'd8,
      CHECK_RESP_41 = 5'd9,
      CHECK_RESP_58 = 5'd10,

      SPARECLOCKS = 5'd11,
      HALT = 5'd12,
      SENDSPI = 5'd13,
      OKTOSEND = 5'd14,
      WAIT1CLKSEND = 5'd15,
      WAITSEND = 5'd16,
      RECVSPI = 5'd17,
      OKTORECV = 5'd18,
      WAIT1CLKRECV = 5'd19,
      WAITRECV = 5'd20,
      
      START_READ = 5'd21,
      SEND_READ_COMMAND= 5'd22,
      RESPUESTA_READ= 5'd23,
      CHECK_READ= 5'd24,
      DO_READ= 5'd25,
      READ_CRC0= 5'd26,
      READ_CRC1= 5'd27,
      
      WAIT_COMMAND= 5'd28,
      
      CMD_0 = 3'd0,
      CMD_8 = 3'd1,
      CMD_41 = 3'd2,
      CMD_55 = 3'd3,
      CMD_58 = 3'd4
      ;
   always @(posedge clk) begin
      case (estado)
         SENDCLOCKS:
            begin
               busy <= 1'b1;
               sd_initialized <= 1'b0;
               //ledDebug <= 8'hFF;
               cnt <= 4'd0;
               spi_cs <= 1'b1;
               data_to_sd <= 8'hFF;
               estado <= SEND8CLOCKS;
            end
         SEND8CLOCKS:
            begin
               if (cnt == 4'd10) begin
                  spi_cs <= 1'b0;
                  cnt <= 4'd0; 
                  currentCommand <= CMD_0;
                  retorno_de_respuesta <= SENDCMD_8;
                  estado <= SENDCMD;
               end
               else begin
                  cnt <= cnt + 4'd1;
                  estado <= SENDSPI;
                  retorno_de_sendspi <= SEND8CLOCKS;
               end
            end
         SENDCMD:
            begin
               if (cnt == 4'd6) begin
                  tout <= 8'd0;
                  estado <= RESPUESTA;
               end
               else begin
                  data_to_sd <= commandsBytes[ currentCommand ][ cnt ];
                  cnt <= cnt + 4'd1; 
                  estado <= SENDSPI;
                  retorno_de_sendspi <= SENDCMD;
               end
            end
         RESPUESTA:
            begin
               if (tout == 8'hFF) begin
                  busy <= 1'b0;
                  sd_initialized <= 1'b0;
                  //ledDebug <= { 3'b0, estado };
                  estado <= SPARECLOCKS;
               end
               else begin
                  estado <= RECVSPI;
                  retorno_de_recvspi <= CHECK;
                  tout <= tout + 8'd1;
               end
            end
         CHECK:
            begin
               if (data_from_sd[7] == 1'b1) begin
                  estado <= RESPUESTA;
               end
               else begin
                  cnt <= 4'd0;
                  estado <= retorno_de_respuesta;
               end
            end
		 SENDCMD_8:
		    begin
			   if (data_from_sd != 8'h01) begin
                  busy <= 1'b0;
                  sd_initialized <= 1'b0;
                  //ledDebug <= { 3'b0, estado };
                  estado <= SPARECLOCKS;
               end
               else begin
			      cnt <= 4'd0;
                  currentCommand <= CMD_8;
                  retorno_de_respuesta <= CHECK_RESP_8;
                  estado <= SENDCMD;
			   end
		    end
		 CHECK_RESP_8:
		    begin
		      case (cnt)
		        4'd0: begin
					if (data_from_sd != 8'h01) begin
						busy <= 1'b0;
						sd_initialized <= 1'b0;
						//ledDebug <= { 3'b100, estado };
						estado <= SPARECLOCKS;
					end
					else begin
						estado <= RECVSPI;
						retorno_de_recvspi <= CHECK_RESP_8;
					end
		        end
		        4'd1: begin
					estado <= RECVSPI;
					retorno_de_recvspi <= CHECK_RESP_8;
		        end
		        4'd2: begin
					estado <= RECVSPI;
					retorno_de_recvspi <= CHECK_RESP_8;
		        end
		        4'd3: begin
					if ( data_from_sd == commandsBytes[ CMD_8 ][ 3 ] ) begin
						estado <= RECVSPI;
						retorno_de_recvspi <= CHECK_RESP_8;
					end
					else begin
						busy <= 1'b0;
						sd_initialized <= 1'b0;
						//ledDebug <= { 3'b010, estado };
						estado <= SPARECLOCKS;
					end
		        end
		        4'd4: begin
					if ( data_from_sd == commandsBytes[ CMD_8 ][ 4 ] ) begin
						estado <= SENDCMD_55;
					end
					else begin
						busy <= 1'b0;
						sd_initialized <= 1'b0;
						//ledDebug <= { 3'b001, estado };
						estado <= SPARECLOCKS;
					end
		        end
		      endcase
		      cnt <= cnt + 4'd1;
		    end
		 SENDCMD_55:
		    begin
		       cnt <= 4'd0; 
               currentCommand <= CMD_55;
               retorno_de_respuesta <= SENDCMD_41;
               estado <= SENDCMD;
		    end
		 SENDCMD_41:
		    begin
		       cnt <= 4'd0; 
               currentCommand <= CMD_41;
               retorno_de_respuesta <= CHECK_RESP_41;
               estado <= SENDCMD;
		    end
		 CHECK_RESP_41:
		    begin
		       if (data_from_sd == 8'h00) begin
                  cnt <= 4'd0; 
                  currentCommand <= CMD_58;
                  retorno_de_respuesta <= CHECK_RESP_58;
                  estado <= SENDCMD;
               end
               else begin
                  estado <= SENDCMD_55;
               end
		    end
		 CHECK_RESP_58:
		    begin
		      case (cnt)
		        4'd0: begin
					if (data_from_sd != 8'h00) begin
						busy <= 1'b0;
						sd_initialized <= 1'b0;
						//ledDebug <= { 3'b001, estado };
						estado <= SPARECLOCKS;
					end
					else begin
						estado <= RECVSPI;
						retorno_de_recvspi <= CHECK_RESP_58;
					end
		        end
		        4'd1: begin
					if ( ( data_from_sd & 8'hC0 ) == 8'hC0) begin
						estado <= RECVSPI;
						retorno_de_recvspi <= CHECK_RESP_58;
					end
					else begin
						busy <= 1'b0;
						sd_initialized <= 1'b0;
						//ledDebug <= { 3'b010, estado };
						estado <= SPARECLOCKS;
					end
		        end
		        4'd2: begin
					estado <= RECVSPI;
					retorno_de_recvspi <= CHECK_RESP_58;
		        end
		        4'd3: begin
					estado <= RECVSPI;
					retorno_de_recvspi <= CHECK_RESP_58;
		        end
		        4'd4: begin
					busy <= 1'b0;
					sd_initialized <= 1'b1;
					//ledDebug <= { 3'b101, estado };
					estado <= WAIT_COMMAND;
		        end
		      endcase
		      cnt <= cnt + 4'd1;
		    end
		 WAIT_COMMAND:
		    begin
		       //ledDebug <= { 3'b000, estado };
		       if ( doStartRead == 1'b1 ) begin
		          busy <= 1'b1;
		          estado <= START_READ;
		          current_sector <= sector_addr;
			   end
		    end
		 START_READ:
		    begin
               spi_cs <= 1'b0;
               cnt <= 4'd0; 
               estado <= SEND_READ_COMMAND;
               //ledDebug <= { 3'b000, estado };
		    end
		 SEND_READ_COMMAND:
		    begin
               if (cnt == 4'd0) begin
                  data_to_sd <= 8'd17 | 8'h40;
                  cnt <= cnt + 4'd1;
                  estado <= SENDSPI;
                  retorno_de_sendspi <= SEND_READ_COMMAND;
                  //ledDebug <= { 3'b000, estado };
               end
               else if (cnt == 4'd5) begin
                  data_to_sd <= 8'd1;
                  cnt <= cnt + 4'd1;
                  estado <= SENDSPI;
                  retorno_de_sendspi <= SEND_READ_COMMAND;
               end
               else if (cnt == 4'd6) begin
                  tout <= 8'd0;
                  estado <= RESPUESTA_READ;
               end
               else begin
                  data_to_sd <= current_sector[31:24];
                  current_sector <= { current_sector[23:0], 8'b0 };
                  cnt <= cnt + 4'd1;
                  estado <= SENDSPI;
                  retorno_de_sendspi <= SEND_READ_COMMAND;
               end
            end
         RESPUESTA_READ:
            begin
               if (tout == 8'hFF) begin
                  busy <= 1'b0;
                  sd_initialized <= 1'b0;
                  //ledDebug <= { 3'b0, estado };
                  estado <= SPARECLOCKS;
               end
               else begin
                  estado <= RECVSPI;
                  retorno_de_recvspi <= CHECK_READ;
                  tout <= tout + 8'd1;
               end
            end
         CHECK_READ:
            begin
               if (data_from_sd == 8'hFE) begin
                  // Valid data token
                  byteInSector <= 10'd0;
                  estado <= RECVSPI;
                  retorno_de_recvspi <= DO_READ;
               end
               else if ((data_from_sd[7:5] == 3'b000) && (data_from_sd[4:0] != 5'b0)) begin
                  // Error
                  busy <= 1'b0;
                  sd_initialized <= 1'b0;
                  //ledDebug <= { 3'b001, estado };
                  //ledDebug <= data_from_sd;
                  //ledDebug <= { 3'b111, data_from_sd[4:0] };
                  estado <= SPARECLOCKS;
               end
               else begin
                  estado <= RESPUESTA_READ;
               end
            end
         DO_READ:
            begin
               if (byteInSector >= 10'b1000000000) begin
                  estado <= RECVSPI;
                  retorno_de_recvspi <= READ_CRC0;
                  wr_out_n <= 1'b1;
               end
               else begin
               
                  if ( wr_out_n == 1'b0 ) begin
                     wr_out_n <= 1'b1;
                  end
                  else begin
                     d_out <= data_from_sd;
                     wr_out_n <= 1'b0;
                     
                     //if (byteInSector < 9'd32)
                     //   ledDebug <= data_from_sd;

                     //ledDebug <= { 3'b101, estado };

                     byteInSector <= byteInSector + 9'd1;
                     estado <= RECVSPI;
                     retorno_de_recvspi <= DO_READ;
                  end

               end
            end
         READ_CRC0:
            begin
               estado <= RECVSPI;
               retorno_de_recvspi <= READ_CRC1;
            end
         READ_CRC1:
            begin
               busy <= 1'b0;
               estado <= WAIT_COMMAND;
            end
         SPARECLOCKS:
            begin
               spi_cs <= 1'b1;
               data_to_sd <= 8'hFF;
               estado <= SENDSPI;
               retorno_de_sendspi <= HALT;
            end
         HALT:
            if (rst == 1'b1)
               estado <= SENDCLOCKS;
            
         SENDSPI:
            begin
               if (ready == 1'b1)
                  estado <= OKTOSEND;
            end
         OKTOSEND:
            begin
               send_data <= 1'b1;
               estado <= WAIT1CLKSEND;
            end
         WAIT1CLKSEND:
            begin
               send_data <= 1'b0;
               estado <= WAITSEND;
            end
         WAITSEND:
            begin
               if (ready == 1'b1)
                  estado <= retorno_de_sendspi;
            end
            
         RECVSPI:
            begin
               if (ready == 1'b1)
                  estado <= OKTORECV;
            end
         OKTORECV:
            begin
               receive_data <= 1'b1;
               estado <= WAIT1CLKRECV;
            end
         WAIT1CLKRECV:
            begin
               receive_data <= 1'b0;
               estado <= WAITRECV;
            end
         WAITRECV:
            begin
               if (ready == 1'b1)
                  estado <= retorno_de_recvspi;
            end
      endcase
   end      
endmodule
