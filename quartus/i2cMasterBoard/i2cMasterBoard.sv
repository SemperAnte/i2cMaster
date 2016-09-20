module i2cMasterBoard (
		input  wire  OSC_50_B3B,
      inout  wire  AUD_I2C_SCLK,
      inout  wire  AUD_I2C_SDAT );

	i2cMasterQsys i2cMasterQsysInst
      ( .clk_clk       ( OSC_50_B3B   ),
        .reset_reset_n ( 1'b1         ),
        .conduit_sclk  ( AUD_I2C_SCLK ), 
        .conduit_sdat  ( AUD_I2C_SDAT ) );

endmodule
