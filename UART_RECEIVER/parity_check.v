module parity_check (
  input       PAR_TYP, par_chk_en, sampled_bit,
  input [7:0] P_DATA,
  input       CLK, RST,
  output reg  par_err
  );
  
  wire        expec_par;
  
  always @(posedge CLK or negedge RST)
    begin
      if (!RST)
        begin
          par_err <= 1'b0;
        end
      else if (par_chk_en)
        begin
          par_err <= expec_par ^ sampled_bit;
        end
    end
  
  assign expec_par = (PAR_TYP) ? ~^(P_DATA) : ^(P_DATA);
endmodule
