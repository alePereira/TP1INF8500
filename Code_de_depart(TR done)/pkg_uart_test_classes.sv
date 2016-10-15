package uart_test_classes;
int errT_num = 0; // compteur des erreurs de transmission
int errR_num = 0; //compteur des erreurs de reception
int errP_num = 0;
int errF_num = 0;
int errD_num = 0;  
semaphore  semT = new(1);
semaphore  semR = new(1);
        // Pilote du péripherique coté bus

// config
typedef enum {br_9600=9600, br_19200=19200, br_115200=115200, br_153600=153600, br_921600=921600} Valid_baudrate;
typedef enum {NONE=0, EVEN=1, ODD=3} Parity;
typedef enum {noError=0,pError=1,fError=2,dError=3} Error_type;

class Uart_config;
  rand Valid_baudrate baud_rate;
  rand Parity parity;
  


  function report();
    $display(" baudrate : %d", this.baud_rate);
    $display(" parity : %d", this.parity);
  endfunction : report

endclass : Uart_config

class Uart_driver;
	time Tck = 20000ps;
	local virtual if_to_Uart bfm,bfm2;
	static logic  [7:0] status,status2, control,control2;
	logic [7:0] write_datT, write_datR;
	rand int bit_to_change;
	constraint bitChange {
		bit_to_change inside{[1:7]};
	}
   rand Error_type err_type;
   mailbox write_mT,write_mR, test_mT, test_mR,err_rxtx,err_check,status_m;
   bit test = 0;
   Parity parite;
   
   /*covergroup cg;
      status : coverpoint status {
         wildcard bins Rx    = {8'b???????1};
         wildcard bins Tx    = {8'b??1?????};
         wildcard bins O_err = {8'b??????1?};
         wildcard bins P_err = {8'b?????1??};
         wildcard bins F_err = {8'b????1???};
         bins vide =   default ;
    }
   endgroup*/
/*   covergroup cg;
      status : coverpoint status {
         wildcard bins Rx    = {8'b???????1};
         wildcard bins Tx    = {8'b??1?????};
         wildcard bins O_err = {8'b??????1?};
         wildcard bins P_err = {8'b?????1??};
         wildcard bins F_err = {8'b????1???};
         bins vide =   default ;}
      Rx    : coverpoint status[0] == 1;
      Tx    : coverpoint status[5] == 1;
      O_err : coverpoint status[1] == 1;
      P_err : coverpoint status[2] == 1;
      F_err : coverpoint status[3] == 1;
   endgroup*/
   //cg = new;
  
	covergroup cg_driver;
		status : coverpoint status {
			wildcard bins Rx    = {8'b???????1};
			wildcard bins Tx    = {8'b??1?????};
			wildcard bins O_err = {8'b??????1?};
			wildcard bins P_err = {8'b?????1??};
			wildcard bins F_err = {8'b????1???};
			bins vide =   default ;
		}
		input_values : coverpoint write_datT {
			bins low = {[0:55]};
			bins med_low = {[56:124]};
			bins med_high = {[125:200]};
			bins high = {[201:255]};
		}
		cross_status : cross status, input_values;
		option.per_instance=1;
		endgroup
	cg_driver = new;
  
  
  
  
   function new(virtual if_to_Uart bfm,bfm2,
                mailbox write_mT, write_mR, test_mT, test_mR, err_rxtx, err_check,status_m);
      this.bfm = bfm;
      this.bfm2 = bfm2;
      this.write_mT = write_mT;
	  this.write_mR = write_mR;
      this.test_mT = test_mT;
      this.test_mR = test_mR;
	  this.err_rxtx = err_rxtx;
	  this.err_check = err_check;
	  this.status_m = status_m;
   endfunction : new
   
// calcule le prédiviseur (en fonction de la vitesse choisie 
// et de la fréquence d'horloge), réinitialise le
// périphérique et fixe le protocole choisi (control)
// ici : sans traitement d'erreurs
   task init_uart(bit[31:0] baud_rate, time Tck,
                  bit[7:0] control,bit[7:0] control2,
				  Uart_config conf);
      automatic bit[15:0] diviseur;
      diviseur = 1e12/(8*baud_rate*Tck) - 1;
      // unite de temps ps => 1e12
      $display("diviseur = %d\n",diviseur);
      this.Tck = Tck;
      this.control = control;
      this.control2 = control2;
      bfm.reset_if();
      bfm2.reset_if();
      bfm.write_if(2,diviseur & 8'hff); // baud rate LS
      bfm2.write_if(2,diviseur & 8'hff); 
      bfm.write_if(3,diviseur >> 8); // baud rate MS
      bfm2.write_if(3,diviseur >> 8); 
      bfm.write_if(1, control); 
      bfm2.write_if(1, control2); 
	  parite = conf.parity;
   endtask : init_uart   
 
	task run();
		fork : parallelSection
			runDUT();
			runReference();
		join
		disable parallelSection;
    endtask : run 

	task runDUT();
		forever begin
			
			semT.get(1);
			bfm.wait_it();
			bfm.read_if(1,status);
			//si il est pret a envoyer une nouvelle donn�e on l'envoi
			if(status[5] == 1 &&  write_mT.try_get(write_datT)>0)begin
				$display("1e UART transmet %d",write_datT);
				test_mT.put(write_datT);            
				bfm.write_if(0,write_datT);
			end
			cg_driver.sample();
			
		if(status[3] == 1 ||status[2] == 1) begin
			status_m.put(status);
		end
		
		if(status[1] == 1) begin
           $display("� %t, Overrun error on reception",$time);
           end
        if(status[2] == 1) begin
			$display("� %t, Parity error on reception",$time);
			end
        if(status[3] == 1) begin
			$display("� %t, Framing error on reception",$time);
       	end
			semT.put(1);
		end //forever
	endtask : runDUT
   
    task runReference();
		forever begin
			//cg.sample();
			semR.get(1);
			bfm2.wait_it();
			bfm2.read_if(1,status2);
			//si il est pret a envoyer une nouvelle donn�e on l'envoi
			if(status2[5] == 1 && write_mR.try_get(write_datR)>0)begin

				//if(test == 0) begin
				if(parite != NONE ) begin
					this.randomize();
				end
				else begin
					err_type = noError;
				end
				//	test = 1;
				//end
				//else begin
				//	err_type = noError;
				//end
				//bit_to_change = 5;
				$display("2e UART transmet %d avec l'erreur de type %d, sur le bit numero %d ",write_datR,err_type,bit_to_change);
				err_check.put(err_type);
				test_mR.put(write_datR);
				err_rxtx.put(err_type);
				err_rxtx.put(bit_to_change);
				bfm2.write_if(0,write_datR);
			end	
			
			semR.put(1);
		end //forever
    endtask : runReference
   task stats;
         $display(" couverture :");
   /*      $display("Tx = %g  Rx = %g  O_err = %g  P_err = %g  F_err = %g ",
                  cg.Rx.get_inst_coverage(),cg.Tx.get_inst_coverage(),
                  cg.O_err.get_inst_coverage(),cg.P_err.get_inst_coverage(),
                  cg.F_err.get_inst_coverage()); 
           $display("status = %p ", cg.status);*/ 
         //$display("status = %g ", cg.status.get_inst_coverage()); 
   endtask : stats

endclass : Uart_driver
// Source des données
class Uart_write;
   mailbox envoiT,envoiR;

   function new(mailbox envoiT,envoiR);
      this.envoiR = envoiR;
	  this.envoiT = envoiT;
   endfunction : new
   
   task run();
      logic [7:0] dat = $random();
	
      repeat(10) begin
         envoiR.put(dat);
		 envoiT.put(dat);
         $display("gene : %d envoyée",dat);
         dat = $random();
         #($urandom_range(40e6)); 
        // retard al�atoire en picosecondes
      end //repeat
      #200ms; // Mise en someil du g�n�rateur
   endtask : run
endclass : Uart_write

// Controle de la réception
class Uart_check;
// Les données sont reçues par deux voies : 
// directement du générateur dans la boite test
// à travers le périphérique dans la boite recu
	mailbox recuT, testT, recuR, testR, err_check, status_m;
	function new(mailbox recuT, testT, recuR, testR, err_check,status_m);
      this.recuT = recuT;
      this.testT = testT;
      this.recuR = recuR;
      this.testR = testR;
	  this.err_check = err_check;
	  this.status_m = status_m;
	endfunction : new
   
   
   
   task run();
      //logic [7:0] rec_dat, test_dat;
		repeat(10) begin
			fork : parallelCheck
			checkT();
			checkR();
			join
			disable parallelCheck;
		end //repeat
   endtask : run
   
   task checkT();
	 logic [7:0] rec_dat, test_dat;
		recuT.get(rec_dat);
        testT.get(test_dat);
         assert(rec_dat==test_dat)
            $display("check : %d transmis",test_dat);
            else begin
               $display("erreur : %d transmis, %d attendu",rec_dat, test_dat);
               errT_num +=1;
            end
   endtask : checkT
   //TODO : case pour la detection d'erreur
   task checkR();
	logic [7:0] rec_dat, test_dat,err_dat,status,status2;
		err_check.get(err_dat);
		
		recuR.get(rec_dat);
		testR.get(test_dat);
		case (err_dat)
			noError : begin
				assert(rec_dat==test_dat)
				$display("check : %d recu",test_dat);
				else begin
				   $display("erreur : %d recu, %d attendu",rec_dat, test_dat);
				   errR_num +=1;
				end
			end
            pError : begin
                // Parity error
				//on laisse le temps que soit receiver soit driver detecte l'erreur si ce n'est pas le cas l'erreur n'est pas detecte
				//#1ms;
				if(status_m.num() > 0 ) begin
					status_m.get(status);
					assert(status[2])
						$display("erreur de parite detectee");
						else begin
							$display("non detection de l'erreur de parite");
							errP_num +=1;
						end
				end
				else begin
					$display("non detection de l'erreur de parite");
					errP_num +=1;
				end
				
				
            end
			fError : begin
                if(status_m.num() > 0 ) begin
					status_m.get(status);
					assert(status[3])
						$display("erreur de framing detectee");
						else begin
							$display("non detection de l'erreur de framing");
							errF_num +=1;
						end
				end
				else begin
					$display("non detection de l'erreur de framing");
					errF_num +=1;
				end
            end          
            dError : begin
                if(status_m.num() == 0 ) begin
					assert(rec_dat != test_dat)
						$display("erreur de data detectee");
						else begin
							$display("non detection de l'erreur de data");
							errD_num +=1;
						end
				end
				else begin
					$display("non detection de l'erreur de data");
					errD_num +=1;
				end
            end
			
        endcase
   endtask : checkR
   
   function void bilan();
		$display("nombre d'erreurs de transmission : %d",errT_num);
		$display("nombre d'erreurs de reception : %d",errR_num); 
		$display("nombre d'erreurs de parite non detecte : %d",errP_num);
		$display("nombre d'erreurs de framing non detecte : %d",errF_num);
		$display("nombre d'erreurs de data non detecte : %d",errD_num); 
   endfunction : bilan

endclass : Uart_check

// connexion des ports serie des 2 modules UART.
class Uart_rxtx;
	local virtual if_to_Uart bfm,bfm2;
	time divisor = 20000ps;
	bit ErrInjection = 0;
	Error_type err;
	int data_bit_to_change = 0; //bit sur lequel on doit injecter une erreur(doit etre choisi aléatoirement)
	mailbox err_rxtx;
	
	function new(virtual if_to_Uart bfm,bfm2,mailbox err_rxtx);
		this.bfm = bfm;
		this.bfm2 = bfm2;
		this.err_rxtx = err_rxtx;
	endfunction : new
   
	task init(Uart_config uart_config);
		this.divisor  = 1e12/(8*uart_config.baud_rate*this.divisor);
		this.divisor = this.divisor*8*20000;
		//on considere que l'injection d'erreur n'a de sens que lorsque l'on est en mesure de les detecter
		if(uart_config.parity != noError) begin
			ErrInjection = 1;
		end
	endtask : init
   
   
	task run();
		fork : parralelSection
			dut_tx_to_uart_rx();
			uart_tx_to_dut_rx();
		join_any
		disable parralelSection;
   endtask : run
   
	task uart_tx_to_dut_rx();
		bit output_tx_bit = 1;
		bfm.cb.rx <= output_tx_bit;
		forever begin
			//get ErrInjection
			err_rxtx.get(err);
			err_rxtx.get(data_bit_to_change);
			@(negedge bfm2.cb.tx);
			//#(this.divisor-1);
			bfm.cb.rx <= 0;
			for(int count = 1;count <= 10;count++) begin
				#(this.divisor);
				output_tx_bit = bfm2.tx;
				case (this.err)
            
					pError : begin
						// Parity error
						if(count == data_bit_to_change) begin
							output_tx_bit = !output_tx_bit;
						end
					end    
					fError : begin
                        // Frame error
						if(count == 10) begin
							//on decale d'une demi periode le signal de stop : permet de generer une frame error 
							//tout en ne perturbant pas les prochaines transmission car on detectera quand meme un negedge au tick suivant
							bfm.rx <= 0;
							#(this.divisor/2);
							output_tx_bit = 1;
						end
					end                     
					dError : begin
						if(count == data_bit_to_change) begin
							output_tx_bit = !output_tx_bit;
						end
						//on change le bit de parité afin de respecter la parité. On pourra ainsi verifier qu'une erreur de donnée ne provoque pas d'erreur de parité
						if(count == 8) begin
							output_tx_bit = !output_tx_bit;
						end
					end
				endcase
				
				
				
				bfm.rx <= output_tx_bit;
				output_tx_bit = 1;
			end //for
		end //forever
	endtask : uart_tx_to_dut_rx
   
	task dut_tx_to_uart_rx();
		forever @(bfm.cb) begin
			bfm2.cb.rx <= bfm.cb.tx;
		end //forever
	endtask : dut_tx_to_uart_rx
   
endclass : Uart_rxtx

//Module de reception des resultats de l'execution du DUT
class Uart_Receiver;
   local virtual if_to_Uart bfm,bfm2;
   static logic  [7:0] status,status2;
   logic [7:0] read_datT, read_datR;
   mailbox read_mT, read_mR,status_m;
function new(virtual if_to_Uart bfm,bfm2,
                mailbox read_mT,read_mR,status_m);
      this.bfm = bfm;
      this.bfm2 = bfm2;
      this.read_mT = read_mT;
      this.read_mR = read_mR;
	  this.status_m = status_m;
   endfunction : new

task run();
	fork : parallelSection
		receptDUT();
		receptReference();
	join
	disable parallelSection;
endtask : run

task receptDUT();
	forever begin
		semT.get(1);
		bfm.wait_it();
		bfm.read_if(1,status);
	   	if(status[0] == 1) begin
			bfm.read_if(0,read_datR);
			$display("1e UART recoit %d",read_datR);
			$display("valeur de parite : %d",status[2]);
			//TODO : ici dans le cas une erreur est detecté, on envoie le code d'erreur. On pourra ainsi verifier que l'uart detecte une erreur et qu'il s'agit de la bonne erreur
			read_mR.put(read_datR);
		end
		
		
		if(status[3] == 1 ||status[2] == 1) begin
			status_m.put(status);
		end
		
		if(status[1] == 1) begin
           $display("� %t, Overrun error on reception",$time);
           end
        if(status[2] == 1) begin
           $display("� %t, Parity error on reception",$time);
           end
        if(status[3] == 1) begin
           $display("� %t, Framing error on reception",$time);
       	end
		semT.put(1);
	end //forever
endtask : receptDUT

task receptReference();
	forever begin
		semR.get(1);
		bfm2.wait_it();
		bfm2.read_if(1,status2);
	   	if(status2[0] == 1) begin
			bfm2.read_if(0,read_datT);
			$display("2e UART recoit %d",read_datT);
			read_mT.put(read_datT);
		end
		if(status2[1] == 1) begin
           $display("at %t, Overrun error on emission",$time);
           end
        if(status2[2] == 1) begin
           $display("at %t, Parity error on emission",$time);
           end
        if(status2[3] == 1) begin
           $display("at %t, Framing error on emission",$time);
       	end
		semR.put(1);
	end //forever
endtask : receptReference


endclass : Uart_Receiver




endpackage : uart_test_classes
