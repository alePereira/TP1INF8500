module parityGenerator(
   input  logic [7:0] dat,
   input  logic       en, 
                      even,
   output logic       parity);
   
   always_comb begin
      if (en) begin : boucle
         int i;
         parity = ~even;
         for (i = 0; i < 8; i++) begin
            parity ^= dat[i];
         end
      end 
      else begin
         parity = 1; // stopBit
      end
   end
endmodule
