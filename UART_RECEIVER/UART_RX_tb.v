`timescale 1 ns / 1 ps

module UART_RX_tb;
  
  //________________________________PARAMETERS________________________________ //
  
  parameter     CLK_PER = 5;
  parameter     EVEN = 0, ODD = 1;
  parameter     PRESCALE_WIDTH = 'd6;
  
  //========================================================================== //
  //________________________________VARIABLES_________________________________ //
  
  integer       i;
  reg    [7:0]  CURRENT_DATA;
  
  //========================================================================== //
  //_______________________________DUT SIGNALS________________________________ //
    
  reg    [PRESCALE_WIDTH - 1:0] Prescale_tb;
  reg                           RX_IN_tb, PAR_EN_tb, PAR_TYP_tb;
  reg                           CLK_tb, RST_tb;
  wire   [7:0]                  P_DATA_tb;
  wire                          data_valid_tb;
  
  //========================================================================== //
  //__________________________________CLOCK___________________________________ //
  
  always #(CLK_PER/2.0) CLK_tb = ~CLK_tb;
  
  //========================================================================== //
  //____________________________DUT INSTANTIATION_____________________________ //
  
  UART_RX #(.PRESCALE_WIDTH(PRESCALE_WIDTH)) DUT
  (
    .Prescale(Prescale_tb),
    .RX_IN(RX_IN_tb), 
    .PAR_EN(PAR_EN_tb), 
    .PAR_TYP(PAR_TYP_tb),
    .CLK(CLK_tb), 
    .RST(RST_tb),
    .P_DATA(P_DATA_tb),
    .data_valid(data_valid_tb)
    );
  
  //========================================================================== //
  //______________________________INITIAL BLOCK_______________________________ //
  
  initial
    begin
      $dumpfile ("RX_DUMP.vcd");
      $dumpvars;
      initialize();
      reset();
      //====================================== //
      //configure task:
      // configure(prescale, parity enable, parity type, delay representing clocks not in sync);
      //send_data task:
      // send_data(8-bit data, one to test with wrong parity, one to test with wrong stop);
      //====================================== //
      
      // Testing Consequent Frames, Even Parity, Prescale = 8
      configure('d8, 1'b1, EVEN, 2'd2);
      send_data(8'b11000001, 'b0, 'b0);
      send_data(8'b11111100, 'b0, 'b0);
      send_data(8'b10101010, 'b0, 'b0);
      
      // Testing Consequent Frames, Odd Parity, Prescale = 16
      configure('d16, 1'b1, ODD, 2'd0);
      send_data(8'b00101101, 'b0, 'b0);
      send_data(8'b10110111, 'b0, 'b0);
      send_data(8'b11000001, 'b0, 'b0);
      
      // Testing Consequent Frames, Parity Bit Is Disabled, Prescale = 32
      configure('d32, 1'b0, ODD, 2'd0);
      send_data(8'b10110111, 'b0, 'b0);
      send_data(8'b10101010, 'b0, 'b0);
      send_data(8'b00101101, 'b0, 'b0);
      
      // Testing Start Glitch Functionality and IDLE State Restoration After A Glitch
      glitch();
      
      configure('d8, 1'b0, ODD, 2'd0);
      #((Prescale_tb - 'b1) * CLK_PER);
      send_data(8'b01010001, 'b0, 'b0);
      
      // Testing Wrong Parity and Wrong Error Bits
      // data_valid signal is expected to stay low
      configure('d8, 1'b1, ODD, 2'd0);    //Odd Parity, Prescale = 8
      send_data(8'b10110111, 'b1, 'b0);
      configure('d8, 1'b0, ODD, 2'd0);    //Parity Bit Is Disabled, Prescale = 8
      send_data(8'b10101010, 'b0, 'b1);
      
      #100 $stop;
    end
  
  //========================================================================== //
  //_____________________________TESTING OUTPUT_______________________________ //
  
  always @(posedge data_valid_tb)
    begin
      if (P_DATA_tb == CURRENT_DATA)
        $display("Test Case is succeeded");
      else
        $display("Test Case is Failed");
    end
  
  //========================================================================== //
  //_____________________________INITIALIZATION_______________________________ //
  
  task initialize;
    begin
      CLK_tb = 1'b0;
      RST_tb = 1'b1;
      Prescale_tb = 4'd8; 
      PAR_EN_tb = 1'b0; 
      PAR_TYP_tb = 1'b0;
      RX_IN_tb = 1'b1;
    end
  endtask
  
  //========================================================================== //
  //__________________________________RESET___________________________________ //
  
  task reset;
    begin
      #1
      RST_tb  = 'b0;
      #(CLK_PER - 1)
      RST_tb  = 'b1;
    end
  endtask
  
  //========================================================================== //
  //________________________SETTING UART CONFIGURATION________________________ //
  
  task configure;
    input [PRESCALE_WIDTH - 1:0] pre_set;
    input                        Par_en, Par_type;
    input [1:0]                  DELAY;
    
    begin
      Prescale_tb = pre_set; 
      PAR_EN_tb = Par_en; 
      PAR_TYP_tb = Par_type;
      
      $display("=====================================");
      $display("CONFIGURATION:");
      $display("==============");
      if (Par_en && Par_type == EVEN)
        $display("-> Parity type is even");
      else if (Par_en && Par_type == ODD)
        $display("-> Parity type is odd");
      else
        $display("-> Parity is disabled");
      
      $display("-> Prescale Value is %d", Prescale_tb);
      
      if (DELAY != 'b0)
        begin
          @(posedge CLK_tb);
          #(DELAY);
        end
      
    end
  endtask
  
  //========================================================================== //
  //__________________________SENDING DATA ON RX_IN___________________________ //
  
  task send_data;
    input [7:0]                  TEST_DATA;
    input                        WRONG_PAR, WRONG_STP;
    
    reg                          parity;
    reg   [10:0]                 Frame;
    
    begin
      CURRENT_DATA = TEST_DATA;
      
      if(PAR_TYP_tb == EVEN)
        parity = ^(CURRENT_DATA);
      else
        parity = ~^(CURRENT_DATA);
      
      if(WRONG_PAR)
        parity = ~parity;
      
      if(PAR_EN_tb)
        Frame = {1'b1, parity, CURRENT_DATA, 1'b0};
      else
        Frame = {1'b1, 1'b1, CURRENT_DATA, 1'b0};
      
      if(WRONG_STP)
        Frame[9 + PAR_EN_tb] = 'b0;
        
      
      $display("---------------------------");  
      $display("Test Case with Data value %b", CURRENT_DATA);
      
      if(WRONG_PAR)
        begin
          $display("Sending wrong Parity bit");
          $display("-> data_valid signal is expected to stay low");
        end
      else if(WRONG_STP)
        begin
          $display("Sending wrong Stop bit");
          $display("-> data_valid signal is expected to stay low");
        end
      
      for (i = 0; i <= 9 + PAR_EN_tb; i = i + 1)
        begin
          RX_IN_tb = Frame[i];
          #(CLK_PER * Prescale_tb);
        end
      
      RX_IN_tb = 'b1;
    end
    
  endtask
  
  //========================================================================== //
  //_________________SENDING A SMALL PULSE (GLITCH) ON RX_IN_________________ //
  
  task glitch;
    begin
      RX_IN_tb = 'b0;
      #(CLK_PER);
      RX_IN_tb = 'b1;
    end
  endtask

endmodule