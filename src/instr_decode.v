// Module for the instruction decoder
`default_nettype none
module instr_decode(input wire clk,
                    input [29:0] instruction,
                    output [5:0] rega, 
                    output [5:0] regb, 
                    output [15:0]intermed,
                    output [1:0] flag,
                    output [3:0] oper,
                    output [1:0] mem_op,
                    output [9:0] mem_addr);

    always @(posedge clk) begin
        flag <= instruction[0:1];
        case (flag) 
            1: begin
                oper <= instruction[2:5];
                rega <= instruction[6:11];
                regb <= instruction[12:17];
                intermed = 16'h0; // usually zero
                mem_op <= 0;
                mem_addr <= 0;
            end
            2: begin
                oper <= instruction[2:5];
                case (oper)
                    2: begin
                        rega <= instruction[6:11];
                        regb <= instruction[12:17];
                        intermed <= 16'h0;
                        mem_op <= 0;
                        mem_addr <= 0;
                    end
                    3: begin
                        rega <= instruction[6:11];
                        regb <= 0;
                        intermed <= instruction[12:29];
                        mem_op <= 0;
                        mem_addr <= 0;
                    end
                    default: rega <= 0; // no op
                endcase
                
            end
            3: begin
                mem_op <= instruction[2:3];
                if (mem_op == 1 || mem_op == 2) begin
                    rega <= instruction[4:9];
                    mem_addr <= instruction[10:19];
                    intermed <= 0;
                end
                else begin
                    mem_addr <= instruction[4:13];
                    intermed <= instruction[14:29];
                end
            end
            default: rega <= 0;//no op
        endcase
    end

endmodule