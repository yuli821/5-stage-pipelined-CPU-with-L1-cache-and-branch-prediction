module cmp 
import rv32i_types::*;
(
    input cmp_ops cmpop,
    input [31:0] a, b,
    output logic f
);

always_comb
begin
    unique case (cmpop)
        eq: f = (a == b);
        ne: f = (a != b); 
        lt: f = ($signed(a) < $signed(b)); 
        ge: f = ($signed(a) >= $signed(b)); 
        ltu: f = (a < b); 
        geu: f = (a >= b); 
        default: f = 1'b0; 
    endcase
end

endmodule