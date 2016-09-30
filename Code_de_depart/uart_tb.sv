module uart_tb;
   parameter time Tck = 20000ps;
   bit clk; // le type bit evite de creer un evenement a t=0
   if_to_Uart bfm(clk);     // interface  
   if_to_Uart bfm2(clk);
    
   top_Uart mut(bfm); // module testé 
   top_Uart mut2(bfm2); //golden model 
   test_uart #(Tck) stimuli(bfm,bfm2); // programme de test   
   initial forever #(Tck/2) clk = ~clk;
endmodule : uart_tb
