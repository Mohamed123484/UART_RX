module RX_FSM #( parameter PRESCALE_WIDTH = 'd6 )
(
  input                         RX_IN, PAR_EN, 
  input [PRESCALE_WIDTH - 1:0]  edge_cnt,
  input [PRESCALE_WIDTH - 1:0]  Prescale,
  input [3:0]                   bit_cnt,
  input                         par_err, strt_glitch, stp_err,
  input                         CLK, RST,
  output  reg                   par_chk_en, strt_chk_en, stp_chk_en, 
                                enable, deser_en, dat_samp_en,
  output  reg                   data_valid                          
  );
  
  localparam  IDLE  = 3'b000,
              START = 3'b001,
              DATA  = 3'b011,
              PAR   = 3'b010,
              STOP  = 3'b110;
  
  reg [2:0]   current_state,
              next_state;
  
  wire    [PRESCALE_WIDTH - 2:0]   mid_point;
  assign mid_point = {1'b0, Prescale[PRESCALE_WIDTH - 1:1]};
  
  always @(posedge CLK or negedge RST)
    begin
      if (!RST)
        begin
          current_state <= IDLE ;
        end
      else
        begin
          current_state <= next_state ;
        end
    end
  
  always @(*)
    begin
      case(current_state)
        IDLE    : begin
                   strt_chk_en = 'b0;
                   par_chk_en = 'b0;
                   stp_chk_en = 'b0;
                   deser_en = 'b0;
                   data_valid = 'b0;
                   
                   if (!RX_IN)
                     begin
                       next_state = START;
                       enable = 'b1;
                       dat_samp_en = 'b1;
                     end
                   else
                     begin
                       next_state = IDLE;
                       enable = 'b0;
                       dat_samp_en = 'b0;
                     end
                  end
        
        START   : begin
                   par_chk_en = 'b0;
                   stp_chk_en = 'b0;
                   deser_en = 'b0;
                   data_valid = 'b0;
                   enable = 'b1;
                   dat_samp_en = 'b1;
                   if (edge_cnt == mid_point + 1'b1)
                     begin
                       strt_chk_en = 'b1;
                     end
                   else
                     begin
                       strt_chk_en = 'b0;
                     end
                   
                   if (strt_glitch && (edge_cnt == mid_point + 2'd2))
                     begin
                       next_state = IDLE;
                     end
                   else if (bit_cnt == 'd1)
                     begin
                       next_state = DATA;
                     end
                   else
                     begin
                       next_state = START;
                     end
                  end
        
        DATA    : begin
                   strt_chk_en = 'b0;
                   par_chk_en = 'b0;
                   stp_chk_en = 'b0;
                   data_valid = 'b0;
                   enable = 'b1;
                   dat_samp_en = 'b1;
                   
                   if (edge_cnt == mid_point + 1'b1)
                     begin
                       deser_en = 'b1;
                     end
                   else
                     begin
                       deser_en = 'b0;
                     end
                   
                   if (bit_cnt == 'd9)
                     begin
                       next_state = (PAR_EN) ? PAR : STOP;
                     end
                   else
                     begin
                       next_state = DATA;
                     end
                  end
        
        PAR     : begin
                   strt_chk_en = 'b0;
                   stp_chk_en = 'b0;
                   deser_en = 'b0;
                   data_valid = 'b0;
                   enable = 'b1;
                   dat_samp_en = 'b1;
                   
                   if (edge_cnt == mid_point + 1'b1)
                     begin
                       par_chk_en = 'b1;
                     end
                   else
                     begin
                       par_chk_en = 'b0;
                     end
                   
                   if (bit_cnt == 'd10)
                     begin
                       next_state = STOP;
                     end
                   else
                     begin
                       next_state = PAR;
                     end
                  end
        
        STOP    : begin
                   par_chk_en = 'b0;
                   deser_en = 'b0;
                   strt_chk_en = 'b0;
                   
                   if (edge_cnt == mid_point + 1'b1)
                     begin
                       stp_chk_en = 'b1;
                     end
                   else
                     begin
                       stp_chk_en = 'b0;
                     end
                   
                   if (edge_cnt == mid_point + 2'd2)
                     begin
                       data_valid = ~(par_err | stp_err);
                     end
                   else
                     begin
                       data_valid = 'b0;
                     end
                   
                   if (edge_cnt == Prescale - 1'b1)
                     begin
                       next_state = IDLE;
                       enable = 'b0;
                       dat_samp_en = 'b0;
                     end
                   else
                     begin
                       next_state = STOP;
                       enable = 'b1;
                       dat_samp_en = 'b1;
                    end
                  end
                
        default : begin
                   par_chk_en = 'b0;
                   strt_chk_en = 'b0;
                   stp_chk_en = 'b0;
                   enable = 'b0;
                   deser_en = 'b0;
                   dat_samp_en = 'b0;
                   data_valid = 'b0;
                   next_state = IDLE;
                  end
                
      endcase
    end
  
endmodule
