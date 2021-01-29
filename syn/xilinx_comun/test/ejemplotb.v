module ps2_ascii_input(clock_27mhz, reset, clock, data, notes_ready,
notes);
input clock_27mhz;
input reset; // Active high asynchronous reset
input clock; // PS/2 clock
input data; // PS/2 data
output notes_ready; // notes ready (one clock_27mhz cycle active high)
output [1:0] notes; // notes of the musical scales
reg [7:0] lastkey; // last keycode
reg [7:0] curkey; // current keycode
reg notes_ready; // synchronous one-cycle ready flag
reg [1:0] notes; // the 2 notes of the keyboard
reg brk = 0; // logic for whether or not a key is being released
// get keycodes
wire fifo_rd; // keyboard read request
wire [7:0] fifo_data; // keyboard data
wire fifo_empty; // flag: no keyboard data
wire fifo_overflow; // keyboard data overflow

ps2 myps2(reset, clock_27mhz, clock, data, fifo_rd, fifo_data,
fifo_empty,fifo_overflow);

assign fifo_rd = ~fifo_empty; // continous read
reg key_ready;
always @(posedge clock_27mhz) begin
// get key if ready
curkey <= ~fifo_empty ? fifo_data : curkey;
lastkey <= ~fifo_empty ? curkey : lastkey;
key_ready <= ~fifo_empty;
// raise notes_ready for last key which was read
notes_ready <= key_ready & ~(curkey[7]|lastkey[7]);
case (curkey)
8'h1c: begin notes[0] <= brk ? 0 :1; brk <= (lastkey == 8'hf0) ? brk : 0; end
8'h1a: begin notes[1] <= brk ? 0 : 1; brk <= (lastkey == 8'hf0) ? brk : 0; end
8'hf0: brk <= 1;
default: begin notes <= notes; brk <= 0; end
endcase // case(curkey)
end // always @ (posedge clock_27mhz)
endmodule // ps2toascii


module ps2(reset, clock_27mhz, clock, data, fifo_rd, fifo_data,
fifo_empty,fifo_overflow);
input clock_27mhz,reset;
input data,clock; // ps2 data
input fifo_rd; // fifo read request (active high)
output [7:0] fifo_data; // fifo data output
output fifo_empty; // fifo empty (active high)
output fifo_overflow; // fifo overflow - too much kbd input
reg [3:0] count; // count incoming data bits
reg [9:0] shift; // accumulate incoming data bits
reg [7:0] fifo[7:0]; // 8 element data fifo
reg fifo_overflow;
reg [2:0] wptr,rptr; // fifo write and read pointers
wire [2:0] wptr_inc = wptr + 1;
assign fifo_empty = (wptr == rptr);
assign fifo_data = fifo[rptr];
// synchronize PS2 clock to local clock and look for falling edge
reg [2:0] ps2c_sync;
always @ (posedge clock_27mhz) ps2c_sync <= {ps2c_sync[1:0],clock};
wire sample = ps2c_sync[2] & ~ps2c_sync[1];
always @ (posedge clock_27mhz) begin
if (reset) begin
count <= 0;
wptr <= 0;
rptr <= 0;
fifo_overflow <= 0;
end
else if (sample) begin
// order of arrival: 0,8 bits of data (LSB first),odd parity,1
if (count==10) begin
// just received what should be the stop bit
if (shift[0]==0 && data==1 && (^shift[9:1])==1) begin
fifo[wptr] <= shift[8:1];
wptr <= wptr_inc;
fifo_overflow <= fifo_overflow | (wptr_inc == rptr);
end
count <= 0;
end else begin
shift <= {data,shift[9:1]};
count <= count + 1;
end
end
// bump read pointer if we’re done with current value.
// Read also resets the overflow indicator
if (fifo_rd && !fifo_empty) begin
rptr <= rptr + 1;
fifo_overflow <= 0;
end
end
endmodule

module tb(clock_27mhz, reset, clock, data, notes_ready,
notes);
output reg clock_27mhz;
output reg reset; // Active high asynchronous reset
output reg clock; // PS/2 clock
output reg data; // PS/2 data
input wire notes_ready; // notes ready (one clock_27mhz cycle active high)
input wire [1:0] notes; // notes of the musical scales

ps2_ascii_input s1(clock_27mhz, reset, clock, data, notes_ready,
notes);
assign fifo_rd = 0;
always
#20 clock=~clock;
always
#3 clock_27mhz=~clock_27mhz;
initial begin
$monitor($time,,,"clock_27mhz=%b, reset=%b, clock=%b, data=%b, notes_ready=%b,notes=%b",clock_27mhz, reset, clock, data, notes_ready,notes);
reset=1; clock=0; clock_27mhz=0; data=1;
#6 data=0;#6 data=0;#6 data=0;#6 data=1;#6 data=1;#6 data=1;#6 data=0;#6 data=0;//mc
#6 data=1;#6 data=1;#6 data=0;
#6 data=1;#6 data=1;#6 data=1;#6 data=1;#6 data=0;#6 data=0;#6 data=0;#6 data=0;//mc
#6 data=1;#6 data=1;#6 data=0;
#6 data=0;#6 data=0;#6 data=0;#6 data=1;#6 data=1;#6 data=1;#6 data=0;#6 data=0;//mc

#0 $finish;
end
endmodule
