program test_uart #(time Tck = 20000ps) (if_to_Uart bfm, bfm2);
   	bit[7:0] ctrl_tx, ctrl_rx;
	int i = 0;
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
	mailbox status_m = new();
	
	covergroup Cg_config;
		Parity : coverpoint uart_cfg.parity;
		Baud_rate : coverpoint uart_cfg.baud_rate;
		cross Baud_rate, Parity;
		cross Baud_rate, Parity;
		option.per_instance=1;
	endgroup
	Cg_config cg;
	
	
	initial begin
		
		cg = new();
		uart_cfg= new();
		while(cg.get_inst_coverage()<100 && i < 100 ) begin
			i = i+1;
			uart_rxtx = new(bfm,bfm2,err_rxtx);
			uart_driver = new(bfm,bfm2,envoiT,envoiR,testT,testR,err_rxtx,err_check,status_m);
			uart_write = new(envoiT,envoiR);
			uart_check = new(receptT,testT,receptR,testR,err_check,status_m);
			uart_receiver = new(bfm,bfm2,receptT,receptR,status_m);
			//generation aleatoire des configurations de test
			uart_cfg.randomize();
			cg.sample();
			ctrl_tx = 3 + (uart_cfg.parity << 3);
			ctrl_rx = 3 + (uart_cfg.parity << 3);
			$display("baud_rate : %d, valeur de control tx : %d, control rx : %d",uart_cfg.baud_rate,ctrl_tx, ctrl_rx);
			
			uart_rxtx.init(uart_cfg);
			// 153600 bauds, Tx Rx int enable, error disable, sans parite
			uart_driver.init_uart(uart_cfg.baud_rate,Tck,ctrl_tx,ctrl_tx,uart_cfg);
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

		end
		$display("i =  ", i);
		uart_driver.stats;
		$finish();
	end //initial
   
   
   
   final begin
      uart_check.bilan();
   end //final

endprogram : test_uart

