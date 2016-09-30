package uart_test_classes;
int errT_num = 0; // comptage des erreurs de transmission
int errR_num = 0; //comptage des erreurs de reception
semaphore  semT = new(1);
semaphore  semR = new(1);
        // Pilote du p�riph�rique c�t� bus

// config
typedef enum {br_9600=9600, br_19200=19200, br_115200=115200, br_153600=153600, br_921600=921600} Valid_baudrate;
typedef enum {NONE=0, EVEN=1, ODD=3} Parity;

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
   mailbox write_mT,write_mR, test_mT, test_mR;
   semaphore  sem = new(1);
   
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
  
   function new(virtual if_to_Uart bfm,bfm2,
                mailbox write_mT,write_mR,test_mT,test_mR);
      this.bfm = bfm;
      this.bfm2 = bfm2;
      this.write_mT = write_mT;
	  this.write_mR = write_mR;
      this.test_mT = test_mT;
      this.test_mR = test_mR;
   endfunction : new
   
// calcule le pr�diviseur (en fonction de la vitesse choisie 
// et de la fr�quence d'horloge), r�initialise le
// p�riph�rique et fixe le protocole choisi (control)
// ici : sans traitement d'erreurs
   task init_uart(bit[31:0] baud_rate, time Tck,
                  bit[7:0] control,bit[7:0] control2);
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
			//cg.sample();
			semT.get(1);
			bfm.wait_it();
			bfm.read_if(1,status);
			//si il est pret a envoyer une nouvelle donn�e on l'envoi
			if(status[5] == 1 && write_mT.try_get(write_datT)>0)begin
				if (write_mT.num()==1)begin
					control[1]=0;
					$display("end ...");
					// inhibe les interruptions en transmission
					bfm.write_if(1, control); 
				end 
				$display("1e UART transmet %d",write_datT);
				test_mT.put(write_datT);            
				bfm.write_if(0,write_datT);
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
				if (write_mR.num()==1)begin
				$display("end ...");
					control2[1]=0;
					// inhibe les interruptions en transmission
					bfm2.write_if(1, control2); 
				end 
				$display("2e UART transmet %d",write_datR);
				test_mR.put(write_datR);            
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
        // Source des donn�es
class Uart_write;
   mailbox envoiT,envoiR;

   function new(mailbox envoiT,envoiR);
      this.envoiR = envoiR;
	  this.envoiT = envoiT;
   endfunction : new
   
   task run();
      logic [7:0] dat = $random();
      repeat(10) begin
		 #5ms;
         envoiR.put(dat);
		 envoiT.put(dat);
         $display("gene : %d envoy�e",dat);
         dat = $random();
         #($urandom_range(40e6)); 
        // retard al�atoire en picosecondes
      end //repeat
      #200ms; // Mise en someil du g�n�rateur
   endtask : run
endclass : Uart_write

        // Contr�le de la r�ception
		
class Uart_check;
// Les donn�es sont re�ues par deux voies : 
// directement du g�n�rateur dans la boite test
// � travers le p�riph�rique dans la boite recu
   mailbox recuT, testT, recuR, testR;

   function new(mailbox recuT, testT,recuR,testR);
      this.recuT = recuT;
      this.testT = testT;
      this.recuR = recuR;
      this.testR = testR;
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
   
   task checkR();
	logic [7:0] rec_dat, test_dat;
		recuR.get(rec_dat);
		testR.get(test_dat);
		assert(rec_dat==test_dat)
            $display("check : %d recu",test_dat);
            else begin
               $display("erreur : %d recu, %d attendu",rec_dat, test_dat);
               errR_num +=1;
            end
   endtask : checkR
   
   function void bilan();
      $display("nombre d'erreurs de transmission : %d",errT_num);
      $display("nombre d'erreurs de reception : %d",errR_num); 
   endfunction : bilan

endclass : Uart_check

        // connexion des ports serie des 2 modules UART.
class Uart_rxtx;
   local virtual if_to_Uart bfm,bfm2;

   function new(virtual if_to_Uart bfm,bfm2);
   	this.bfm = bfm;
   	this.bfm2 = bfm2;
   endfunction : new
   
   task run();
      forever @(bfm.cb) begin 
	bfm2.cb.rx  <= bfm.cb.tx;
	bfm.cb.rx <= bfm2.cb.tx;
      end
     // test loop back 
   endtask : run
   
endclass : Uart_rxtx

	//Module de reception des resultats de l'execution du DUT
class Uart_Receiver;
   local virtual if_to_Uart bfm,bfm2;
   static logic  [7:0] status,status2;
   logic [7:0] read_datT, read_datR;
   mailbox read_mT, read_mR;
function new(virtual if_to_Uart bfm,bfm2,
                mailbox read_mT,read_mR);
      this.bfm = bfm;
      this.bfm2 = bfm2;
      this.read_mT = read_mT;
      this.read_mR = read_mR;
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
		semR.get(1);
		bfm.wait_it();
		
		bfm.read_if(1,status);
	   	if(status[0] == 1) begin
			bfm.read_if(0,read_datR);
			$display("1e UART recoit %d",read_datR);
			read_mR.put(read_datR);
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
		semR.put(1);
	end //forever
endtask : receptDUT

task receptReference();
	forever begin
		semT.get(1);
		bfm2.wait_it();
		
		bfm2.read_if(1,status2);
	   	if(status2[0] == 1) begin
			bfm2.read_if(0,read_datT);
			$display("2e UART recoit %d",read_datT);
			read_mT.put(read_datT);
		end
		if(status2[1] == 1) begin
           $display("� %t, Overrun error on emission",$time);
           end
        if(status2[2] == 1) begin
           $display("� %t, Parity error on emission",$time);
           end
        if(status2[3] == 1) begin
           $display("� %t, Framing error on emission",$time);
       	end
		semT.put(1);
	end //forever
endtask : receptReference


endclass : Uart_Receiver


endpackage : uart_test_classes
