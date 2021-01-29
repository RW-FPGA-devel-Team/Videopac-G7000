`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:26:48 02/11/2016 
// Design Name: 
// Module Name:    GameLoader 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//    Based on GameLoader in NES core by DistWave
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
// Module reads bytes and writes to proper address in ram.
// Done is asserted when the whole game is loaded.
module GameLoader(input        clk, 
                  input        reset,
                  input [7:0]  indata, 
                  input        indata_clk,
                  input [21:0] romsize,
                  output reg [21:0] mem_addr, 
                  output [7:0] mem_data, 
                  output       mem_write,
                  output       done,
                  output       error);
  reg [1:0] state = 0;
  reg [21:0] bytes_left;
  reg done_r = 1;
  
  assign done = done_r;
  assign error = (state == 3);
  assign mem_data  = indata;
  assign mem_write = (bytes_left != 0) && (state == 1) && indata_clk;
  
  always @(posedge clk) begin
    if (reset) begin
      state <= 0;
      //done_r <= 0;
      mem_addr <= 0;  // Address for PRG
    end else begin
      case(state)
         0: begin // Initialize
            mem_addr <= 0;  // Address for PRG
            bytes_left <= romsize;
            done_r <= 0;
            state <= 1;
         end
         1, 2: begin // Read the next |bytes_left| bytes into |mem_addr|
            if (bytes_left != 0) begin
               if (indata_clk) begin
                 bytes_left <= bytes_left - 1;
                 mem_addr <= mem_addr + 1;
               end
            end else if (state == 1) begin
               state <= 2;
            end else if (state == 2) begin
               done_r <= 1;
            end
         end
      endcase
    end
  end
endmodule
