module latchReg8Bits(
   input  logic       arst,
                      we,
   input  logic [7:0] dat_i,
   output logic [7:0] dat_o);
   
   always_latch begin
      if (arst) begin
         dat_o <= 8'h00;
      end
      else if (we) begin
         dat_o <= dat_i;
      end
   end
endmodule
