module edge_bit_counter #( parameter PRESCALE_WIDTH = 'd6 ) //To fit 32
(
  input                              enable, 
  input      [PRESCALE_WIDTH - 1:0]  Prescale,
  input                              CLK, RST,
  output reg [PRESCALE_WIDTH - 1:0]  edge_cnt,
  output reg [3:0]                   bit_cnt
  );
  
  wire                               edge_done;
  always @(posedge CLK or negedge RST)
    begin
      if (!RST)
        begin
          edge_cnt <= 'b0;
          bit_cnt <= 'b0;
        end
      else if (enable && edge_done)
        begin
          edge_cnt <= 'b0;
          bit_cnt <= bit_cnt + 1'b1;
        end
      else if (enable)
        begin
          edge_cnt <= edge_cnt + 1'b1;
        end
      else
        begin
          edge_cnt <= 'b0;
          bit_cnt <= 'b0;
        end
    end
    
  assign edge_done = (edge_cnt == Prescale - 1'b1);
  
endmodule
