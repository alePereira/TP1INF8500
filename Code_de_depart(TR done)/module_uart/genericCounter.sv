module genericCounter #(
   parameter int                length = 8,
   parameter bit                incNotDec = 1)
   (
   input     logic              clk, 
                                arst,
                                rst, 
                                en,
   input     logic [length-1:0] dat_i,
   output    logic              rc,
   output    logic [length-1:0] dat_o);
   
   always_ff @(posedge clk, posedge arst) begin
      if (arst) begin     // asynchrone reset
         dat_o <= 0;
      end 
      else if (rst) begin // synchrone reset
         dat_o <= 0;
      end 
      else if (en) begin
         if (incNotDec) begin
           if (dat_o == 2**length - 1) begin
             dat_o <= dat_i;
           end 
           else begin
             dat_o <= dat_o + 1;
           end
         end 
         else begin
           if (dat_o == 0) begin
             dat_o <= dat_i;
           end 
           else begin
             dat_o <= dat_o - 1;
           end
         end  
      end
   end
   
   always_comb begin
     if (incNotDec) begin
        if (dat_o == 2**length - 1 && en) begin
           rc = 1'b1;
        end
        else begin
           rc = 1'b0;
        end
     end
     else begin
        if (dat_o == 0 && en) begin
           rc = 1'b1;
        end
        else begin
           rc = 1'b0;
        end
     end
   end
endmodule
