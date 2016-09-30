module test_uart #(time Tck = 20000ps) (if_to_Uart bfm,bfm2);
   import uart_test_classes::*;
   Uart_driver uart_driver ;
   Uart_write uart_write ;
   //Uart_check uart_check ;
   Uart_rxtx uart_rxtx;
   Uart_Receiver uart_receiver;
   
   mailbox envoiT = new();
   mailbox envoiR = new();
   mailbox receptT = new();
   mailbox testT = new();
   mailbox receptR = new();
   mailbox testR = new();
   
   initial begin
      uart_rxtx = new(bfm,bfm2);
      uart_rxtx.run();
   end
  
   initial begin
      uart_driver = new(bfm,bfm2,envoiT,envoiR,testT,testR);
		uart_write = new(envoiT,envoiR);
		//uart_check = new(receptT,testT,receptR,testR);
		uart_receiver = new(bfm,bfm2,receptT,receptR);
		uart_driver.init_uart(153600,Tck,3,3);
      // 153600 bauds, Tx Rx int enable, error disable, sans parite
      fork : test_simple
         uart_driver.run();
         uart_receiver.run();
         uart_write.run();
         //uart_check.run();
      join_any
      disable test_simple;
      $display("simulation terminée à %t",$time);
      //uart_check.bilan();
      uart_driver.stats;
      $finish();
   end //initial

   final begin
      //uart_check.bilan();
   end //final      
   
endmodule : test_uart
