module test_uart #(time Tck = 20000ps) (if_to_Uart bfm,bfm2);
   bit[7:0] ctrl;
   import uart_test_classes::*;
   Uart_driver uart_driver ;
   Uart_write uart_write ;
   Uart_check uart_check ;
   Uart_rxtx uart_rxtx;
   Uart_Receiver uart_receiver;
   Uart_config uart_cfg;

	//TODO : mise a jour des fonctions new pour permettre l'injection d'erreur
	mailbox envoiT = new();
	mailbox envoiR = new();
	mailbox receptT = new();
	mailbox testT = new();
	mailbox receptR = new();
	mailbox testR = new();
	mailbox err_rxtx = new();
	mailbox err_check = new();
	
	initial begin
		uart_rxtx = new(bfm,bfm2,err_rxtx);
		uart_driver = new(bfm,bfm2,envoiT,envoiR,testT,testR,err_rxtx,err_check);
		uart_write = new(envoiT,envoiR);
		uart_check = new(receptT,testT,receptR,testR,err_check);
		uart_receiver = new(bfm,bfm2,receptT,receptR);
		uart_cfg= new();
		//TODO : replace with randomize and covergroup
		uart_cfg.baud_rate = uart_test_classes::br_153600;
		uart_cfg.parity = uart_test_classes::NONE;
		//endTODO
		
		uart_rxtx.init(uart_cfg);
		// 153600 bauds, Tx Rx int enable, error disable, sans parite
		uart_driver.init_uart(uart_cfg.baud_rate,Tck,11,11);
		fork : test_simple
			uart_rxtx.run();
			uart_driver.run();
			uart_receiver.run();
			uart_write.run();
			uart_check.run();
		join_any
		disable test_simple;
		//reinitialisation des semaphores
		uart_test_classes::semT = new(1);
		uart_test_classes::semR = new(1);
		$display("simulation terminée à %t",$time);
		uart_check.bilan();
		uart_driver.stats;
		$finish();
   end //initial

   final begin
      uart_check.bilan();
   end //final      
   
endmodule : test_uart
