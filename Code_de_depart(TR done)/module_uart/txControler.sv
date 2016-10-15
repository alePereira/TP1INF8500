module txControler(
   input  logic clk, 
                arst,
                brTick,
                datStb,
   output logic moveDatEn,
                shiftEn);
   
   logic [3:0] symbolCtrVal;
   
   counter4Bits  symbolCounter(
      .rst(moveDatEn),
      .en(shiftEn),
      .dat(symbolCtrVal),
      .*);
   txControlFSM fsm(.*);             
endmodule

