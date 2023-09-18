module data_sampling #( parameter PRESCALE_WIDTH = 'd6 ) //To fit 32
(
  input                              RX_IN, dat_samp_en,
  input                              CLK, RST,
  input     [PRESCALE_WIDTH - 1:0]   Prescale,
  input     [PRESCALE_WIDTH - 1:0]   edge_cnt,
  output                             sampled_bit
  );
  
  wire      [PRESCALE_WIDTH - 2:0]   mid_point;
  reg                                S1, S2, S3;
  
  always @(posedge CLK or negedge RST)
    begin
      if (!RST)
        begin
          S1 <= 1'b0;
          S2 <= 1'b0;
          S3 <= 1'b0;
        end
      else if (dat_samp_en && edge_cnt == mid_point - 1'b1)
        begin
          S1 <= RX_IN;
        end
      else if (dat_samp_en && edge_cnt == mid_point)
        begin
          S2 <= RX_IN;
        end
      else if (dat_samp_en && edge_cnt == mid_point + 1'b1)
        begin
          S3 <= RX_IN;
        end
    end
  
  assign mid_point = {1'b0, Prescale[PRESCALE_WIDTH - 1:1]};
  assign sampled_bit = (S1 & S2) | (S2 & S3) | (S1 & S3); // Majority of the three samples
  
endmodule
