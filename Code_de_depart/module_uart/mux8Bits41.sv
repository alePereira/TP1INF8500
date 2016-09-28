module mux8Bits41(
   input  logic [1:0] adr,
   input  logic [7:0] dat0,
                      dat1,
                      dat2,
                      dat3,
   output logic [7:0] dat_o);
   
   always_comb begin
      case (adr)
      2'b00: dat_o = dat0;
      2'b01: dat_o = dat1;
      2'b10: dat_o = dat2;
      2'b11: dat_o = dat3;
      endcase
   end
endmodule
