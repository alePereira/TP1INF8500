module intControler(
   input  logic [7:0] controlReg,
                      statusReg,
   output logic       inter);
   
   logic       rxIntEn, txIntEn, errIntEn;
   assign {errIntEn, txIntEn, rxIntEn}  = controlReg[2:0];
   
   logic       rxBRFull, oErr, pErr, fErr, txBREmpty;
   assign txBREmpty = statusReg[5];
   assign {fErr, pErr, oErr, rxBRFull}  = statusReg[3:0];
   
//   always_comb begin
//      if ((rxIntEn  && rxBRFull)  ||
//          (txIntEn  && txBREmpty) ||
//          (errIntEn && (oErr || pErr || fErr))) begin
//         inter = 1;
//      end
//      else begin
//         inter = 0;
//      end
//   end
   always_comb begin
      if ((rxIntEn  & rxBRFull)  |
          (txIntEn  & txBREmpty) |
          (errIntEn & (oErr | pErr | fErr))) begin
         inter = 1;
      end
      else begin
         inter = 0;
      end
   end
endmodule
 

