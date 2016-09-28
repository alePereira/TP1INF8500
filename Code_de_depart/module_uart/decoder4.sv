module decoder4(
   input  logic       en1,
                      en2,
   input  logic [1:0] adr,
   output logic       ce0, 
                      ce1, 
                      ce2, 
                      ce3);
   logic [3:0] _ce;
   
   always_comb begin
      _ce = 4'b0000;
      if (en1 && en2) begin
        _ce[adr] = 1'b1;
      end
   end
   always_comb begin
     ce0 = _ce[0];
     ce1 = _ce[1];
     ce2 = _ce[2];
     ce3 = _ce[3];
   end  
endmodule
