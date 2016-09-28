module counter4Bits(
   input  logic       clk,
                      arst,
                      rst,
                      en,
   output logic [3:0] dat);
   
   always_ff @(posedge clk, posedge arst) begin
      if (arst) begin
         dat <= 0;
      end 
      else if (rst) begin
         dat <= 0;
      end 
      else if (en) begin
         dat <= dat + 1;
      end
   end
endmodule
   