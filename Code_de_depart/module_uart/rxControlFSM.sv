module rxControlFSM(
   input  logic       clk,
                      arst,
                      brTick8x,
                      rx,
   input  logic [6:0] chronoVal,
   output logic       shiftEn,
                      moveDatEn,
                      chronoRst);

   typedef enum logic [3:0] {
      waitForStartBit = 4'b0001,
      waitForSynchro  = 4'b0000,
      sampleRx        = 4'b0010,
      dataReady       = 4'b0101,
      waitForStopBit  = 4'b1001} state_t;
      
   state_t state;
   
   logic [2:0] _chronoSymbolVal;
   logic [3:0] _symbolCtrVal;
   assign _chronoSymbolVal = chronoVal[2:0];
   assign _symbolCtrVal    = chronoVal[6:3];
   
   assign chronoRst = state[0];
   assign shiftEn   = state[1];
   assign moveDatEn = state[2];
   
   always_ff @(posedge clk, posedge arst) begin
      if (arst)
         state <= waitForStartBit;
      else begin
         case (state)
         waitForStartBit: begin
            if (!rx)
               state <= waitForSynchro;
         end
         waitForSynchro: begin
            if (_chronoSymbolVal == 3 && brTick8x) 
               state <= sampleRx;
         end
         sampleRx: begin
            if (_symbolCtrVal == 10)
               state <= dataReady;
            else
               state <= waitForSynchro; 
         end
         dataReady: begin
            state <= waitForStopBit;
         end
         waitForStopBit: begin
            if (rx)
               state <= waitForStartBit;          
         end
         endcase
      end
   end
endmodule
