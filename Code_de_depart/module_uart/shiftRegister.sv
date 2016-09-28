module shiftRegister(
   input  logic        clk, 
                       arst,
                       rst,
                       en,
                       ldDat,
                       serial_i,
   input  logic [10:0] dat_i,
   output logic [10:0] dat_o,
   output logic        serial_o);
   
   assign serial_o = dat_o[0];
   
   always_ff @(posedge clk, posedge arst) begin
      if (arst) begin
         dat_o <= 11'h7FF;
      end
      else if (rst) begin
         dat_o <= 11'h7FF;
      end
      else if (ldDat) begin
          dat_o <= dat_i;
      end
      else if (en) begin
         dat_o[9:0] <= dat_o[10:1];
         dat_o[10]  <= serial_i;
      end
   end  
endmodule
