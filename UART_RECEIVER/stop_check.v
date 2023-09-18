module stop_check (
  input       stp_chk_en, sampled_bit,
  input       CLK, RST,
  output reg  stp_err
  );
  
  
  always @(posedge CLK or negedge RST)
    begin
      if (!RST)
        begin
          stp_err <= 1'b0;
        end
      else if (stp_chk_en)
        begin
          stp_err <= ~sampled_bit;
        end
    end
endmodule
