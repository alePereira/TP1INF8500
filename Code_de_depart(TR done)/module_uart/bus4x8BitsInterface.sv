module bus4x8BitsInterface(
   input  logic       we, 
                      ce,
   input  logic [1:0] adr,
   inout  wire  [7:0] dat,
//   inout  logic  [7:0] dat,
   input  logic [7:0] rBus0, 
                      rBus1, 
                      rBus2,
                      rBus3,
   output logic [7:0] wBus,
   output logic       re0,
                      re1,
                      re2,
                      re3,
                      we0,
                      we1,
                      we2,
                      we3);
   logic outEn;
   logic [7:0] _dat;
   biDirBuffer busBuffer(
      .dat_i(_dat),
      .dat_o(wBus),
      .dat_io(dat),
      .outEn(outEn));
      
   assign outEn = ce & ~we;
   
   mux8Bits41 datOutMux(
      .dat0(rBus0),
      .dat1(rBus1),
      .dat2(rBus2),
      .dat3(rBus3),
      .dat_o(_dat),
      .adr(adr));
      
   decoder4 wAdrDecoder(
      .en1(ce),
      .en2(we),
      .ce0(we0), 
      .ce1(we1), 
      .ce2(we2), 
      .ce3(we3),
      .adr(adr));
      
   decoder4 rAdrDecoder(
      .en1(ce),
      .en2(~we),
      .ce0(re0), 
      .ce1(re1), 
      .ce2(re2), 
      .ce3(re3),
      .adr(adr));
   
endmodule
