//--------------------------------------------------------------------------------
// File Name:     i2cSlave.sv
// Project:       i2cMaster
// Author:        Shustov Aleksey ( SemperAnte ), semte@semte.ru
// History:
//    23.07.2016 - created
//--------------------------------------------------------------------------------
// simple I2C slave for testbench
//--------------------------------------------------------------------------------
`timescale 1 ns / 100 ps

module i2cSlave
    ( input  logic           clk,
      input  logic           reset,       // async reset
      
      // i2c slave control
      input  logic           slvClear,    // clear slave state
      input  int             slvStretch,  // number of clocks for stretching
      input  logic [ 7 : 0 ] slvByteWr,   // byte to slave for writing ( answer to master )
      output logic [ 7 : 0 ] slvByteRd,   // reading byte from slave ( master wrote this byte )
      output logic           slvAck,      // reading ack from slave
      
      // i2c lines
      inout  wire            sdat,
      inout  wire            sclk );
      
   // sdat / sclk tri-state control
   logic  sdatIn, sdatOut;
   assign sdatIn = sdat;
   assign sdat = ( sdatOut ) ? 1'bz : 1'b0;
   logic  sclkIn, sclkOut;
   assign sclkIn = sclk;
   assign sclk = ( sclkOut ) ? 1'bz : 1'b0;
   
   // previous state
   logic sdatPrv, sclkPrv;
   always_ff @( posedge clk, posedge reset ) begin
      sdatPrv <= sdatIn;
      sclkPrv <= sclkIn;
   end
   
   // sdat / sclk rising, falling edge
   logic sdatFalling, sdatRising;
   logic sclkFalling, sclkRising;
   assign sdatFalling =  sdatPrv & ~sdatIn;
   assign sdatRising  = ~sdatPrv &  sdatIn;
   assign sclkFalling =  sclkPrv & ~sclkIn;
   assign sclkRising  = ~sclkPrv &  sclkIn;
   
   // delay for output on shift registers
   localparam int DELAY = 5;
   logic [ DELAY - 1 : 0 ] sdatShift;
   logic [ DELAY - 1 : 0 ] sclkShift;
   logic                   sdatDly;
   logic                   sclkDly;
   always_ff @( posedge clk, posedge reset )
      if ( reset ) begin
         sdatShift <= '1;
         sclkShift <= '1;
      end else
         if ( slvClear ) begin
            sdatShift <= '1;
            sclkShift <= '1;
         end else begin
            sdatShift <= { sdatDly, sdatShift[ DELAY - 2 : 1 ] };
            sclkShift <= { sclkDly, sclkShift[ DELAY - 2 : 1 ] };
         end
         
   assign sdatOut = sdatShift[ 0 ];
   assign sclkOut = sclkShift[ 0 ];
   
   // slave control
   int             cntBit, cntByte, cntStretch;
   logic [ 7 : 0 ] shiftRd, shiftWr;
   enum int unsigned { IDLE, SLAVE_READ, SLAVE_WRITE, SLAVE_ACK, MASTER_ACK } state; 
   
   always_ff @( posedge clk, posedge reset )
      if ( reset ) begin
         sdatDly <= 1'b1;
         sclkDly <= 1'b1;
         state   <= IDLE;
      end else
         if ( slvClear ) begin // clear state
            sdatDly <= 1'b1;
            sclkDly <= 1'b1;
            state   <= IDLE;
         end else begin
            // start bit
            if ( sclkPrv & sclkIn & sdatFalling ) begin
               cntBit     <= 0;
               cntByte    <= 0;
               cntStretch <= 0;
               state      <= SLAVE_READ;
               $display( "i2c slave : start bit detected at %0t ns", $time );
            end
            // stop bit
            if ( sclkPrv & sclkIn & sdatRising ) begin
               state <= IDLE;
               $display( "i2c slave : stop bit detected at %0t ns", $time );
            end
            // fsm
            case ( state )
               IDLE : begin
                  sdatDly <= 1'b1;
                  sclkDly <= 1'b1;
               end
               SLAVE_READ : begin  
                  // stretched state emulation
                  if ( sclkFalling && cntBit == 3 ) begin
                     cntStretch <= slvStretch;
                  end
                  if ( cntStretch > 0 ) begin
                     sclkDly    <= 1'b0;
                     cntStretch <= cntStretch - 1;
                  end else begin
                     sclkDly    <= 1'b1;
                  end  
                  // read bit on rising edge sclk
                  if ( sclkRising ) begin
                     cntBit  <= cntBit + 1;
                     shiftRd <= { shiftRd[ 6 : 0 ], sdatIn };
                     if ( cntBit == 7 ) begin
                        cntBit <= 0;
                        state  <= SLAVE_ACK;
                     end
                  end
               end
               SLAVE_WRITE : begin
                  // before first falling
                  if ( cntBit == 0 ) begin
                     sdatDly <= slvByteWr[ 7 ];;
                  end
                  // after first falling
                  if ( sclkFalling ) begin
                     cntBit <= cntBit + 1;
                     if ( cntBit == 0 ) begin // but second bit
                        shiftWr  = slvByteWr;
                        shiftWr  = { shiftWr[ 6 : 0 ], 1'b0 };
                        sdatDly <= shiftWr[ 7 ];
                     end else if ( cntBit == 7 ) begin // ack by Master
                        sdatDly <= 1'b1;
                        cntBit  <= 0;
                        state   <= MASTER_ACK;
                     end else begin
                        shiftWr  = { shiftWr[ 6 : 0 ], 1'b0 };
                        sdatDly <= shiftWr[ 7 ];                    
                     end
                  end
               end
               SLAVE_ACK : begin
                  if ( sclkFalling ) begin
                     if ( cntBit == 0 ) begin // first falling - ack by 0
                        sdatDly <= 1'b0;
                        cntBit  <= cntBit + 1;
                        state   <= SLAVE_ACK;
                     end else begin           // second falling - clear ack                                         
                        sdatDly   <= 1'b1;
                        cntBit    <= 0;
                        cntByte   <= cntByte + 1;
                        slvByteRd  = shiftRd;
                        $display( "i2c slave : read byte %b at %0t ns", shiftRd, $time );
                        if ( cntByte == 0 ) begin // for first byte after start - check write / read command
                           if ( ~shiftRd[ 0 ] ) begin
                              state <= SLAVE_READ;
                              $display( "i2c slave : read command from master detected at %0t ns", $time );
                           end else begin   
                              state <= SLAVE_WRITE;
                              $display( "i2c slave : write command from master detected at %0t ns", $time );
                           end
                        end else begin
                           state <= SLAVE_READ;
                        end                     
                     end
                  end
               end
               MASTER_ACK : begin               
                  if ( sclkRising ) begin    
                     slvAck <= sdatIn;
                     if ( ~sdatIn ) begin // continue - wait sclkFalling
                        $display( "i2c slave : ack by master detected at %0t ns", $time );                  
                     end else begin
                        state <= IDLE;
                        $display( "i2c slave : no ack by master detected at %0t ns", $time );
                     end
                  end
                  if ( sclkFalling ) begin
                     cntBit <= 0;
                     state  <= SLAVE_WRITE;
                  end 
               end
            endcase
         end // slvClear
      
endmodule