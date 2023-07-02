`default_nettype none
`include "instr_mem.v"
`include "instr_decode.v"
`include "mem.v"
`include "alu.v"

module top(input P4, output LED_R, output LED_G, output LED_B,
           output P6,
           P9,
           P10,
           P11,
           P12,
           P13,
           P18,
           P19,
           P20,
           P21,
           P23,
           P25,
           P37,
           P38,
           P42,
           P43);

    reg [15:0] counter;
    reg [5:0] pc;
    wire clk;
    assign LED_R = counter[7];
    assign LED_G = counter[6];
    assign LED_B = counter[5];
    wire [5:0] regA;
    wire [5:0] regB;
    reg [15:0] operA;
    reg [15:0] operB;
    wire [15:0] intermed;
    wire [3:0] oper;
    wire [1:0] flag;
    wire [9:0] mem_addr;
    wire [1:0] mem_op;
    reg we;
    reg fetch_en;
    reg alu_en;
    wire [15:0] alu_out;
    reg [15:0] reg_file [0:63];
    wire [15:0] mem_in;
    wire [15:0] mem_out;
    reg [15:0] out;
    reg [29:0] instruction;
    assign {P6,P9,P10,P11,P12,P13,P18,P19,P20,P21,P23,P25,P37,P38,P42,P43} = out;
    integer i = 0;
    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            reg_file[i] = 16'b001;
        end

        fetch_en <= 1;
    end

    //10khz used for low power applications (or sleep mode)
    SB_LFOSC SB_LFOSC_inst(
        .CLKLFEN(1),
        .CLKLFPU(1),
        .CLKLF(clk)
    );
    
    mem mem(.clk(clk),
            .wr_en(we),
            .wr_addr(mem_addr),
            .data_in(mem_in),
            .data_out(mem_out));

    instr_mem instr_mem(.clk(clk), .pc(pc),
                        .fetch_en(fetch_en ),
                        .instruction(instruction));

    instr_decode instr_decode(.clk(clk),
                              .instruction(instruction),
                              .rega(regA),
                              .regb(regB),
                              .intermed(intermed),
                              .flag(flag),
                              .oper(oper),
                              .mem_op(mem_op),
                              .mem_addr(mem_addr));
    alu alu(.clk(clk),
            .alu_en(alu_en),
            .oper(oper),
            .operandA(operA),
            .operandB(operB),
            .q(alu_out));

    always @ (posedge clk) begin
        if (P4) begin
            counter <= 0;
            pc <= 0;
            fetch_en <= 0;
            alu_en <= 0;
            we <= 0;
        end
        
        counter <= counter + 1;
        pc = pc + 1;
        case (flag)
        
        'h1: begin
            we <= 0;
            fetch_en <= 1;
            case (oper)
            'h1: begin
                operA <= reg_file[regA];
                operB <= reg_file[regB];
                alu_en <= 1;
                out <= alu_out;
                reg_file[regA] <= alu_out;
            end
            'h2: begin
                operA <= reg_file[regA];
                operB <= reg_file[regB];
                alu_en <= 1;
                out <= alu_out;
                reg_file[regA] <= alu_out;
            end
            'h3: begin
                operA <= reg_file[regA];
                operB <= reg_file[regB];
                alu_en <= 1;
                reg_file[regA] <= alu_out;
                out <= alu_out;
                
            end
            'h4: begin
                operA <= reg_file[regA];
                operB <= reg_file[regB];
                alu_en <= 1;
                reg_file[regA] <= alu_out;
                out <= alu_out;
            end
            'h5: begin
                operA <= reg_file[regA];
                operB <= reg_file[regB];
                alu_en <= 1;
                reg_file[regA] <= alu_out;
                out <= alu_out;
            end
            'h6 : begin 
                operA <= reg_file[regA];
                operB <= regB;
                alu_en <= 1;
                reg_file[regA] <= alu_out;
                out <= alu_out;
            end
            'h7 : begin 
                operA <= reg_file[regA];
                operB <= regB;
                alu_en <= 1;
                reg_file[regA] <= alu_out;
                out <= alu_out;
            end
            'h8 : begin 
                operA <= reg_file[regA];
                operB <= regB;
                alu_en <= 1;
                reg_file[regA] <= alu_out;
                out <= alu_out;
            end
            'h9 : begin 
                operA <= reg_file[regA];
                operB <= regB;
                alu_en <= 1;
                reg_file[regA] <= alu_out;
                out <= alu_out;
            end
            'hA : begin 
                operA <= reg_file[regA];
                alu_en <= 1;
                reg_file[regB] <= alu_out;
                out <= alu_out;
            end
            'hB : begin 
                operA <= reg_file[regA];
                operB <= regB;
                alu_en <= 1;
                reg_file[regA] <= alu_out;
                out <= alu_out;
            end
            'hC : begin 
                operA <= reg_file[regA];
                operB <= regB;
                alu_en <= 1;
                reg_file[regA] <= alu_out;
                out <= alu_out;
            end
            default:
                out <= 16'h0;
            endcase
        end
        'h2 :begin
            fetch_en <= 1;
            alu_en <= 0;
            we <= 0;
            case (oper)
            'h2: begin
                reg_file[regA] <= reg_file[regB];
                out <= reg_file[regA];
            end
            'h3: begin 
                reg_file[regA] <= intermed;
                out <= reg_file[regA];
            end
            default:
                out <= 16'h0;
            endcase
        end
        'h3: begin
            fetch_en <= 1;
            alu_en <= 0;
            we <= 0;
            case (mem_op)
            'h1: begin
                reg_file[regA] <= mem_out;
                out <= reg_file[regA];
            end
            'h2: begin
                mem_in <= reg_file[regA];
                we <= 1;
                out <= mem_out;
            end
            'h3: begin 
                mem_in <= intermed;
                we <= 1;
                out <= mem_out;
            end
            default:
                out <= 16'h0;
            endcase
        end
        default:
                out <= 16'h0;
        endcase
    end

endmodule