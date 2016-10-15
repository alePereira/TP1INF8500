module mux41(
   input  logic [1:0] sel,
   input  logic       dat0,
                      dat1,
                      dat2,
                      dat3,
   output logic       dat_o);
   
   logic [3:0] _dat;
   
   assign _dat = {dat3, dat2, dat1, dat0};
   
//   always_comb dat_o = _dat[sel];
   assign dat_o = _dat[sel];
endmodule
