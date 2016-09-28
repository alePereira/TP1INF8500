module parity3(
   input  logic a,
                b,
                c,
   output logic r);
   
//   always_comb r = a ^ b ^ c;
   assign r = a ^ b ^ c;
endmodule
