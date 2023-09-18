module UART_RX #( parameter PRESCALE_WIDTH = 'd6 )
(
  input    [PRESCALE_WIDTH - 1:0] Prescale,
  input                           RX_IN, PAR_EN, PAR_TYP,
  input                           CLK, RST,
  output   [7:0]                  P_DATA,
  output                          data_valid
  );
  
  wire [PRESCALE_WIDTH - 1:0] edge_cnt;
  wire [3:0]                  bit_cnt;
  wire                        par_err, strt_glitch, stp_err,
                              par_chk_en, strt_chk_en, stp_chk_en, 
                              enable, deser_en, dat_samp_en;
  wire                        sampled_bit;
  
  RX_FSM #(.PRESCALE_WIDTH(PRESCALE_WIDTH)) U0
  (
    .RX_IN(RX_IN), 
    .PAR_EN(PAR_EN), 
    .edge_cnt(edge_cnt),
    .Prescale(Prescale),
    .bit_cnt(bit_cnt),
    .par_err(par_err), 
    .strt_glitch(strt_glitch), 
    .stp_err(stp_err),
    .CLK(CLK), 
    .RST(RST),
    .par_chk_en(par_chk_en), 
    .strt_chk_en(strt_chk_en), 
    .stp_chk_en(stp_chk_en), 
    .enable(enable), 
    .deser_en(deser_en), 
    .dat_samp_en(dat_samp_en),
    .data_valid(data_valid)                          
    );
  
  edge_bit_counter #(.PRESCALE_WIDTH(PRESCALE_WIDTH)) U1
  (
    .enable(enable),
    .Prescale(Prescale),
    .CLK(CLK), 
    .RST(RST),
    .edge_cnt(edge_cnt),
    .bit_cnt(bit_cnt)
    );
  
  strt_check U2
  (
    .strt_chk_en(strt_chk_en), 
    .sampled_bit(sampled_bit),
    .CLK(CLK), 
    .RST(RST),
    .strt_glitch(strt_glitch)
    );
  
  parity_check U3 
  (
    .PAR_TYP(PAR_TYP), 
    .par_chk_en(par_chk_en), 
    .sampled_bit(sampled_bit),
    .P_DATA(P_DATA),
    .CLK(CLK), 
    .RST(RST),
    .par_err(par_err)
    );
  
  stop_check U4
  (
    .stp_chk_en(stp_chk_en), 
    .sampled_bit(sampled_bit),
    .CLK(CLK), 
    .RST(RST),
    .stp_err(stp_err)
    );
  
  deserializer U5 
  (
    .sampled_bit(sampled_bit), 
    .deser_en(deser_en),
    .CLK(CLK), 
    .RST(RST),
    .P_DATA(P_DATA)
    );
  
  data_sampling #(.PRESCALE_WIDTH(PRESCALE_WIDTH)) U6
  (
    .RX_IN(RX_IN), 
    .dat_samp_en(dat_samp_en),
    .CLK(CLK), 
    .RST(RST),
    .Prescale(Prescale),
    .edge_cnt(edge_cnt),
    .sampled_bit(sampled_bit)
    );
  
endmodule
