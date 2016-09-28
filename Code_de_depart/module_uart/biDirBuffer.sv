module biDirBuffer(
   input  logic       outEn,
   input  logic [7:0] dat_i,
   output logic [7:0] dat_o,
   inout  logic  [7:0] dat_io);
   
   assign dat_o = dat_io; 
   assign dat_io = outEn ? dat_i : 'Z;
endmodule
