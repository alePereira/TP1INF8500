module rxControler(
   input  logic clk, 
                arst,
                brTick8x,
                rx,
   output logic shiftEn,
                moveDatEn);
                
   logic       chronoRst;
   logic [6:0] chronoVal;
   
                
   rxControlFSM fsm(.*);
   
   genericCounter #(
      .length(7), 
      .incNotDec(1'b1)) 
   chrono(.rst(chronoRst),
          .en(brTick8x),
          .dat_i(7'h00),
          .dat_o(chronoVal),
          .rc(),
          .*);
endmodule
