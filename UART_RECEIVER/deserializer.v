module deserializer (
  input            sampled_bit, deser_en,
  input            CLK, RST,
  output reg [7:0] P_DATA
  );
  
  always @(posedge CLK or negedge RST)
    begin
      if (!RST)
        begin
          P_DATA <= 8'b0;
        end
      else if (deser_en)
        begin
          P_DATA <= {sampled_bit, P_DATA[7:1]};
        end
    end
  
endmodule
