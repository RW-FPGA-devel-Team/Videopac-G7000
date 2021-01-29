//-------------------------------------------------------------------------------------------------
module clock
//-------------------------------------------------------------------------------------------------
(
	input  wire i50,   // 50.000 MHz
	output wire o50,   // 50.000 MHz
	output wire o70,   // 70.833 MHz     50x17/12
	output wire o42,   // 42.857 MHz     50x12/14
	output wire locked
);
//-------------------------------------------------------------------------------------------------
 wire ci,c50,c50b,c70,c42;

IBUFG IBufg(.I(i50), .O(ci));

DCM_SP #
(
	.CLKIN_PERIOD          (20.000),
	.CLKFX_MULTIPLY        (17    ),
	.CLKFX_DIVIDE          (12    ),
	.CLKDV_DIVIDE          ( 2.000),
   .CLK_FEEDBACK          ("1X")
)
Dcm
(
	.RST                   (1'b0),
	.DSSEN                 (1'b0),
	.PSCLK                 (1'b0),
	.PSEN                  (1'b0),
	.PSINCDEC              (1'b0),
	.CLKIN                 (ci),
	.CLKFB                 (c50),
	.CLK0                  (c50),
	.CLK90                 (),
	.CLK180                (),
	.CLK270                (),
	.CLK2X                 (),
	.CLK2X180              (),
	.CLKFX                 (c70),
	.CLKFX180              (),
	.CLKDV                 (),
	.PSDONE                (),
	.STATUS                (),
	.LOCKED                (locked)
);

BUFGCE_1 Bufgce(.I(c70), .O(o70), .CE(locked));

BUFG BUFG_inst1 (
.O(o50), // 1-bit output: Clock buffer output
.I(c50)  // 1-bit input: Clock buffer input
);


DCM_SP #
(
	.CLKIN_PERIOD          (20.000),
	.CLKFX_MULTIPLY        (12    ),
	.CLKFX_DIVIDE          (14    ),
	.CLKDV_DIVIDE          ( 2.000),
   .CLK_FEEDBACK          ("1X")
)
Dcm2
(
	.RST                   (1'b0),
	.DSSEN                 (1'b0),
	.PSCLK                 (1'b0),
	.PSEN                  (1'b0),
	.PSINCDEC              (1'b0),
	.CLKIN                 (ci),
	.CLKFB                 (c50b),
	.CLK0                  (c50b),
	.CLK90                 (),
	.CLK180                (),
	.CLK270                (),
	.CLK2X                 (),
	.CLK2X180              (),
	.CLKFX                 (c42),
	.CLKFX180              (),
	.CLKDV                 (),
	.PSDONE                (),
	.STATUS                (),
	.LOCKED                ()
);

BUFG BUFG_inst2 (
.O(o42), // 1-bit output: Clock buffer output
.I(c42)  // 1-bit input: Clock buffer input
);


//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
