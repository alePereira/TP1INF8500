module rxCore(
   input  logic       clk, 
                      arst,
                      parityEn, 
                      parityEven,
                      rx,
                      brTick8x,
   output logic       moveDatEn,
                      setPErr,
                      setFErr,
   output logic [7:0] dat);
   logic        shiftEn,
                sy_rx,
                parity;
   logic [10:0] _dat;
   
   assign dat = _dat[8:1];
   
   always_ff @(posedge clk) sy_rx <= rx;
   
   rxControler controler(.*);
   
   shiftRegister rxShiftReg(
                       .rst(1'b0),
                       .en(shiftEn),
                       .ldDat(1'b0),
                       .serial_i(sy_rx),
                       .dat_i(11'h000),
                       .dat_o(_dat),
                       .serial_o(),
                       .*);
   parityGenerator parityGen(
                       .dat(_dat[8:1]),
                       .en(parityEn), 
                       .even(parityEven),
                       .parity(parity));
   assign setPErr = (_dat[9] ^ parity) & parityEn;  
   assign setFErr = (~_dat[9] & ~parityEn) |(~_dat[10] & parityEn);  
endmodule

 