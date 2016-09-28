module txCore(
   input  logic       clk, 
                      arst,
                      parityEn,
                      parityEven,
                      datStb,
                      brTick8x,
   input  logic [7:0] dat,
   output logic       moveDatEn,
                      tx);
   logic brTick,
         shiftEn,
         parity;
         
   txControler controler(.*);   
      
   genericCounter #(
      .length(3),
      .incNotDec(1'b1))
   brTickGen(
      .rst(1'b0), 
      .en(brTick8x),
      .dat_i(3'b000),
      .rc(brTick),
      .dat_o(),
      .*);
      
   parityGenerator parityGen(
      .en(parityEn), 
      .even(parityEven),
      .*);
  
   shiftRegister txShiftReg(
      .rst(1'b0),
      .en(shiftEn),
      .ldDat(moveDatEn),
      .serial_i(1'b1),
      .dat_i({parity, dat, 2'b01}),
      .dat_o(),
      .serial_o(tx),
      .*);  
endmodule
