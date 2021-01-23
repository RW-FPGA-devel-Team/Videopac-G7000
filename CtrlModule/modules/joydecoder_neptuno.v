//Control module for DB9 Splitter of Antonio Villena by Aitor Pelaez (NeuroRulez)
//Based on the ZXDOS module written by me too.
//
module joydecoder 
(
 input  clk,      //Reloj de Entrada sobre 48-50Mhz
 output JOY_CLK,
 output JOY_LOAD,  
 input  JOY_DATA, 
 output JOY_SELECT,
 output [7:0] joystick1,
 output [7:0] joystick2
);
//Gestion de Joystick
assign JOY_SELECT = 1'b1; //(Para usar MD como normal)

reg [15:0] JCLOCKS;
always @(posedge clk) begin 
   JCLOCKS <= JCLOCKS +8'd1;
end

reg [7:0] joy1  = 8'hFF, joy2  = 8'hFF;
reg joy_renew = 1'b1;
reg [4:0]joy_count = 5'd0;
   
assign JOY_CLK = JCLOCKS[3]; //con 3 Funciona = 3Mhz
assign JOY_LOAD = joy_renew;
always @(posedge JOY_CLK) begin 
    if (joy_count == 5'd0) begin
       joy_renew = 1'b0;
    end else begin
       joy_renew = 1'b1;
    end
    if (joy_count == 5'd18) begin
      joy_count = 5'd0;
    end else begin
      joy_count = joy_count + 1'd1;
    end      
end
always @(posedge JOY_CLK) begin
    case (joy_count)
				5'd2  : joy1[7]  <= JOY_DATA; //1p Start  
				5'd3  : joy1[6]  <= JOY_DATA; //1p Fire 3 
				5'd4  : joy1[5]  <= JOY_DATA; //1p Fuego 2 
				5'd5  : joy1[4]  <= JOY_DATA; //1p Fuego 1 
				5'd6  : joy1[0]  <= JOY_DATA; //1p Derecha 
				5'd7  : joy1[1]  <= JOY_DATA; //1p Izquierda 
				5'd8  : joy1[2]  <= JOY_DATA; //1p Abajo 
				5'd9  : joy1[3]  <= JOY_DATA; //1p Ariba 
				5'd10 : joy2[7]  <= JOY_DATA; //2p Start 
				5'd11 : joy2[6]  <= JOY_DATA; //2p Fire 3 
				5'd12 : joy2[5]  <= JOY_DATA; //2p Fuego 2 
				5'd13 : joy2[4]  <= JOY_DATA; //2p Fuego 1 
				5'd14 : joy2[0]  <= JOY_DATA; //2p Derecha
				5'd15 : joy2[1]  <= JOY_DATA; //2p Izquierda
				5'd16 : joy2[2]  <= JOY_DATA; //2p Abajo
				5'd17 : joy2[3]  <= JOY_DATA; //2p Arriba
    endcase              
end
//----DCBAUDLR
assign joystick1 = joy1; //~joy1;  //Cambio para que 0 sea activo.
assign joystick2 = joy2; //~joy2;

endmodule