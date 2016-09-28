package statusBitFunc;
   function logic newSBit(input logic sBit, set, clr);
      if (set) begin
         newSBit = 1'b1;
      end
      else if (clr) begin
         newSBit = 1'b0;
      end
      else begin
         newSBit = sBit;
      end
   endfunction
endpackage

module statusBit(
   input  logic clk,
                arst,
                set,
                clr,
   output logic sBit);
   
   import statusBitFunc::*;
   
   always_ff @(posedge clk, posedge arst) begin
      if (arst) begin
         sBit <= 1'b0;
      end
      else begin
         sBit <= newSBit(sBit, set, clr);
      end
   end
endmodule


module statusRegModule(
   input  logic       clk,
                      arst,
                      rxBRegCe,
                      txBRegCe,
                      sRegCe,
                      txMvDatEn,
                      rxMvDatEn,
                      setPErr,
                      setFErr,
   output logic [7:0] dat);
   
   logic [5:0] _clrVec, 
               _setVec;
   logic       rxBRFull;
   
   logic [5:0] _dat;
   
   assign rxBRFull = _dat[0];
   
   
   assign _clrVec = {txMvDatEn,              //NOT txBREmpty
                     1'b0,
                     sRegCe,                  //fErr
                     sRegCe,                  //pErr
                     sRegCe,                  //oErr
                     rxBRegCe};               //rxBRFull
   
   assign _setVec = {txBRegCe,               //NOT txBREmpty
                     1'b0, 
                     setFErr & rxMvDatEn,     //fErr
                     setPErr & rxMvDatEn,     //pErr
                     rxMvDatEn & rxBRFull 
                        & ~ rxBRegCe,         //oErr
                     rxMvDatEn};              //rxBRFull
   genvar i;
   generate for(i = 0; i < 6; i++) begin : sb_gen
         statusBit sb(.set(_setVec[i]),
                      .clr(_clrVec[i]),
                      .sBit(_dat[i]),
                      .*);
      end
   endgenerate 
   
   assign dat = {2'b00, ~_dat[5], 1'b0, _dat[3:0]};
endmodule
