`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// PWM DAC for VideoPac testing
// Antonio Sánchez (@TheSonders)
// Based on the Original Source from Xera4 project
// Left aligned PWM modulator
// Uses a 4 bits output resolution
// Derivated from a 50MHz prescaled clock obtains ~97.6KHz of modulated output
//////////////////////////////////////////////////////////////////////////////////
module dac (
	output reg DACout,
	input wire [3:0] DACin,
	input wire Clk,
	input wire Reset);

reg [8:0] PWM_prescaler=9'h000;
reg [3:0] PWM_Duty=4'h0;
reg [3:0] Channel_Duty=4'h0;

always @(posedge Clk) begin	
	if (Reset) begin
		DACout<=1'b0;
		PWM_prescaler<=9'h000;
		PWM_Duty<=4'h0;
		Channel_Duty<=4'h0;
	end
	else begin
		PWM_prescaler<=PWM_prescaler-9'h1;
		if (!PWM_prescaler) begin
			PWM_Duty<=PWM_Duty+4'h1;
			if (PWM_Duty==Channel_Duty)DACout<=1'h0;
			if (PWM_Duty==4'hF) begin
				Channel_Duty<=DACin;
				DACout<=(DACin)?1'b1:1'b0;
			end
		end
	end
end

endmodule
