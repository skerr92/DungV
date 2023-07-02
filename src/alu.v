`default_nettype none
module alu(input wire clk, 
           input alu_en,
           input [15:0] operandA, 
           input [15:0]operandB, 
           input [3:0] oper, 
           output [15:0] q);

    always @(posedge clk) begin
        if (alu_en) begin
            case(oper)
            1: q <= operandB + operandA; // add
            2: q <= operandB - operandA; // sub
            3: q <= operandB & operandA; // and
            4: q <= operandB | operandA; // or
            5: q <= operandB ^ operandA; // xor
            6: q <= operandA >> operandB; // shift right certain bits
            7: q <= operandA << operandB; // shift left certain bits
            8: begin // rotate by one bit to the right
                q[15] <= operandA[0];
                q[14:0] <= operandA[15:1];
            end
            9: begin // rotate by one bit to the left
                q[0] <= operandA[15];
                q[15:1] <= operandA[14:1];
            end
            10: q <= ~operandA; // not operand A
            11: q <= operandA * operandB;
            12: q <= operandA / operandB;
            default: q <= 0;//no op
            endcase
        end
    end
endmodule