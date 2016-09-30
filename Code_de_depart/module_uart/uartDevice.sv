module uartDevice(
   input  logic       clk, 
                      arst, 
                      we, 
                      ce,
   input  logic [1:0] adr,
   inout  wire  [7:0] dat,
//   inout  logic  [7:0] dat,
   input  logic       rx,
   output logic       tx,
                      inter);
   
   logic [7:0]  _dat,
                rxBufferReg,
                txBufferReg,
                rxDatOut,
                statusReg,
                controlReg;
   logic [15:0] brDivReg;
   logic        txBRegCe,
                rxBRegCe,
                cRegCe,
                sRegCe,
                brLSRegCe,
                brMSRegCe,
                brTick8x,
                rxMvDatEn,
                setPErr,
                setFErr,
                txMvDatEn,
                txDatStb;
               
   assign txDatStb = ~statusReg[5];
                   
   bus4x8BitsInterface busInterface(
      .rBus0(rxBufferReg), 
      .rBus1(statusReg), 
      .rBus2(8'h00),
      .rBus3(8'h00),
      .wBus(_dat),
      .re0(rxBRegCe),
      .re1(sRegCe),
      .re2(),
      .re3(),
      .we0(txBRegCe),
      .we1(cRegCe),
      .we2(brLSRegCe),
      .we3(brMSRegCe),
      .*);
      
   reg8Bits txBufferReg_(
      .we(txBRegCe),
      .dat_i(_dat),
      .dat_o(txBufferReg),
      .*);
   
   reg8Bits rxBufferReg_(
      .we(rxMvDatEn),
      .dat_i(rxDatOut),
      .dat_o(rxBufferReg),
      .*);
   
   reg8Bits controlReg_(
      .we(cRegCe),
      .dat_i(_dat),
      .dat_o(controlReg),
      .*);
   
   
   statusRegModule statusReg_(
      .dat(statusReg),
      .*);
   
   reg8Bits brDivLSReg_(
      .we(brLSRegCe),
      .dat_i(_dat),
      .dat_o(brDivReg[7:0]),
      .*);
   
   reg8Bits brDivMSReg_(
      .we(brMSRegCe),
      .dat_i(_dat),
      .dat_o(brDivReg[15:8]),
      .*);
      
   intControler interrupt(
      .*);
   
   genericCounter #(
      .length(16),
      .incNotDec(0))
   baudRateGenerator(
      .rst(1'b0), 
      .en(1'b1),
      .dat_i(brDivReg),
      .rc(brTick8x),
      .dat_o(),
      .*);
      
   txCore txCore_(
      .parityEn(controlReg[3]),
      .parityEven(controlReg[4]),
      .datStb(txDatStb),
      .brTick8x(brTick8x),
      .dat(txBufferReg),
      .moveDatEn(txMvDatEn),
      .*);
      
   rxCore rxCore_ci(
      .parityEn(controlReg[3]), 
      .parityEven(controlReg[4]),
      .moveDatEn(rxMvDatEn),
      .dat(rxDatOut),
      .*);
endmodule

