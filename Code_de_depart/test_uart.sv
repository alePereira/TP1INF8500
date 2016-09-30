program test_uart #(time Tck = 20000ps) (if_to_Uart bfm, bfm2);
   bit[7:0] ctrl;
   import uart_test_classes::*;
   Uart_driver uart_driver ;
   Uart_write uart_write ;
   Uart_check uart_check ;
   Uart_rxtx uart_rxtx;
   Uart_Receiver uart_receiver;
   Uart_config uart_cfg;

   
   mailbox envoiT = new();
   mailbox envoiR = new();
   mailbox receptT = new();
   mailbox testT = new();
   mailbox receptR = new();
   mailbox testR = new();

	covergroup Cg_parity;
		coverpoint uart_cfg.parity;
	endgroup
	Cg_parity cg;
   initial begin
      uart_rxtx = new(bfm,bfm2);
      uart_rxtx.run();
   end

   initial begin
		uart_driver = new(bfm,bfm2,envoiT,envoiR,testT,testR);
		uart_write = new(envoiT,envoiR);
		uart_check = new(receptT,testT,receptR,testR);
		uart_receiver = new(bfm,bfm2,receptT,receptR);
		cg = new();
		uart_cfg= new();
		while(cg.get_inst_coverage()<100)
		begin
			//generation aleatoire des configurations de test
			uart_cfg.randomize();
			cg.sample();
			ctrl = 3 + (uart_cfg.parity << 3);
			$display("valeur de control : %d",ctrl);
			uart_driver.init_uart(uart_cfg.baud_rate, Tck, ctrl, ctrl);
			// uart_driver.init_uart(153600,Tck,3,3);
			// 153600 bauds, Tx Rx int enable, error disable, sans parite
			fork : test_simple
			   uart_driver.run();
			   uart_receiver.run();
			   uart_write.run();
			   uart_check.run();
			join_any
			disable test_simple;
			//reinitialisation des semaphores
			uart_test_classes::semT = new(1);
			uart_test_classes::semR = new(1);
		end
        $display("simulation termin�e � %t",$time);
        uart_check.bilan();
        uart_driver.stats;
		$display("Parity = %g", cg.get_inst_coverage());
      $finish();
	  $display("Cest fini");
   end //initial

   final begin
      uart_check.bilan();
   end //final

endprogram : test_uart

