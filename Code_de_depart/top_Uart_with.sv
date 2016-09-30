// module top recepteur uart 
// sert d'interface avec le testbench via interface

module top_Uart(if_to_Uart bfm) ;
   uartDevice dut_phys ( 
               .clk(bfm.clk), 
               .arst(bfm.arst), 
               .we(bfm.we), 
               .ce(bfm.ce),
               .adr(bfm.adr),
               .dat(bfm.dat),
               .rx(bfm.rx),
               .tx(bfm.tx),
               .inter(bfm.inter) ) ;
endmodule : top_Uart