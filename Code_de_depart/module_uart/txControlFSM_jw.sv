module txControlFSM(
   input  logic       clk, 
                      arst,
                      brTick,
                      datStb,
   input  logic [3:0] symbolCtrVal,
   output logic       shiftEn, 
                      moveDatEn);
   typedef enum bit [1:0] {waitForData, writing,
                 sendFrame} state_t;
   state_t state;
   
   always_ff @(posedge clk, posedge arst) begin
      if (arst)
         state <= waitForData;
      else begin
         case (state)
         waitForData: begin
            if (datStb) 
               state <= writing;
         end
         writing: begin
            if (~datStb) 
               state <= sendFrame;
         end
         sendFrame: begin
            if (brTick && symbolCtrVal == 4'd10)
               state <= waitForData;
         end
         default: begin
            state <= waitForData;
         end
         endcase
      end
   end
   
   always_comb begin
      case (state)
      waitForData: begin
         shiftEn   = 1'b0;
         moveDatEn = 0; 
      end 
      writing: begin
         shiftEn   = 0;
         moveDatEn = 1;
      end 
      sendFrame: begin
         moveDatEn = 1'b0;
         if (brTick)
            shiftEn = 1'b1;
         else
            shiftEn = 1'b0;
      end
      default: begin
         moveDatEn = 1'b0;
         shiftEn = 1'b0;
      end
      endcase
   end
endmodule
