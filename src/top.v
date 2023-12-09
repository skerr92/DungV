`default_nettype none
`include "instr_mem.v"
`include "instr_decode.v"
`include "mem.v"
`include "alu.v"
// Designed to run on the IcyBlue FPGA. please update the parameters
// to match your targe FPGA.
module top(input P4, output LED_R, output LED_G, output LED_B,
           inout P6,
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

    reg [31:0] counter;
    reg [7:0] pc;
    wire clk, sclk;
    assign LED_R = ~counter[25];
    assign LED_G = ~counter[24];
    assign LED_B = ~counter[23];
    wire [5:0] regA;
    wire [5:0] regB;
    wire [15:0] operA;
    wire [15:0] operB;
    wire [15:0] intermed;
    wire [3:0] oper;
    wire [1:0] flag;
    wire [9:0] mem_addr;
    wire [1:0] mem_op;
    wire we;
    wire fetch_en;
    wire alu_en;
    wire [15:0] alu_out;
    reg [15:0] reg_file [0:63];
    wire [7:0] gpio_bank_0;
    wire [7:0] gpio_bank_1;
    reg [7:0] gpio_bank_0_regs [1:0];
    reg [7:0] gpio_bank_1_regs [1:0];
    wire [15:0] mem_in;
    wire [15:0] mem_out;
    wire [31:0] instruction;
    assign {P6,P9,P10,P11,P12,P13,P18,P19} = gpio_bank_0;
    assign {P20,P21,P23,P25,P37,P38,P42,P43} = gpio_bank_1;

    integer i = 0;
    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            reg_file[i] = 16'hFFFF;
        end
        counter = 0;
        // gpio bank 0 enable
        gpio_bank_0_regs[0] = 0;
        // gpio bank 0 direction 0 out 1 in
        gpio_bank_0_regs[1] = 0;
        // gpio bank 0 data
        gpio_bank_0_regs[2] = 0;
        gpio_bank_0_regs[3] = 8'hX;
        // gpio bank 1 enable
        gpio_bank_1_regs[0] = 0;
        // gpio bank 1 direction 0 out 1 in
        gpio_bank_1_regs[1] = 0;
        // gpio bank 1 data
        gpio_bank_1_regs[2] = 0;
        gpio_bank_1_regs[3] = 8'hX;
        gpio_bank_0 <= 8'hZ;
        gpio_bank_1 <= 8'hZ;
        fetch_en <= 1;
    end

    //10khz used for low power applications (or sleep mode)
    SB_HFOSC SB_HFOSC_inst(
        .CLKHFEN(1),
        .CLKHFPU(1),
        .CLKHF(clk),
    );
    defparam SB_HFOSC_inst.CLKHF_DIV = "0b01";
    
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

    always @(*) begin
        gpio_bank_0 = (gpio_bank_0_regs[0] == 1) ? (gpio_bank_0_regs[2] & gpio_bank_0_regs[1]) : 8'hZ;
        gpio_bank_1 = (gpio_bank_1_regs[0] == 1) ? (gpio_bank_1_regs[2] & gpio_bank_1_regs[1]) : 8'hZ;
        gpio_bank_0_regs[2] = (gpio_bank_0_regs[0] == 1) ? (gpio_bank_0 ^ ~gpio_bank_0_regs[1]) : gpio_bank_0_regs[2];
        gpio_bank_1_regs[2] = (gpio_bank_1_regs[0] == 1) ? (gpio_bank_1 ^ ~gpio_bank_1_regs[1]) : gpio_bank_1_regs[2];
    end

    always @ (posedge clk) begin
        if (P4) begin // reset
            counter <= 0;
            pc <= 0;
            fetch_en <= 0;
            alu_en <= 0;
            we <= 0;
        end
        
        counter <= counter + 1;
        pc = pc + 1;
        case (flag)
        'h0: begin 
            we <= 0;
            fetch_en <= 1;
            case (oper[0])
            0: begin 
                case (oper[1:2])
                3: begin
                    gpio_bank_0_regs[2] <= (reg_file[intermed[0:5]][0:7] & intermed[8:15]);
                end
                default:
                    gpio_bank_0_regs[oper[1:2]] <= (intermed[0:7] & intermed[8:15]);
                endcase
            end
            1: begin 
                case (oper[1:2])
                3: begin
                    gpio_bank_1_regs[2] <= (reg_file[intermed[0:5]][8:15] & intermed[8:15]);
                end
                default:
                    gpio_bank_1_regs[oper[1:2]] <= (intermed[0:7] & intermed[8:15]);
                endcase
            end
            endcase
        end
        'h1: begin
            we <= 0;
            fetch_en <= 1;
            case (oper)
            'h1: begin // ADD operB to operA
                operA <= reg_file[regA];
                operB <= reg_file[regB];
                alu_en <= 1;
                reg_file[regA] <= alu_out;
            end
            'h2: begin // SUB operB from operA
                operA <= reg_file[regA];
                operB <= reg_file[regB];
                alu_en <= 1;
                reg_file[regA] <= alu_out;
            end
            'h3: begin // AND operA with operB
                operA <= reg_file[regA];
                operB <= reg_file[regB];
                alu_en <= 1;
                reg_file[regA] <= alu_out;                
            end
            'h4: begin // OR operA with operB
                operA <= reg_file[regA];
                operB <= reg_file[regB];
                alu_en <= 1;
                reg_file[regA] <= alu_out;
            end
            'h5: begin // XOR operA with operB
                operA <= reg_file[regA];
                operB <= reg_file[regB];
                alu_en <= 1;
                reg_file[regA] <= alu_out;
            end
            'h6 : begin // shift right operA by 0-31
                operA <= reg_file[regA];
                operB <= regB;
                alu_en <= 1;
                reg_file[regA] <= alu_out;
            end
            'h7 : begin // shift left operA by 0-31
                operA <= reg_file[regA];
                operB <= regB;
                alu_en <= 1;
                reg_file[regA] <= alu_out;
            end
            'h8 : begin // rotate operA right
                operA <= reg_file[regA];
                operB <= regB;
                alu_en <= 1;
                reg_file[regA] <= alu_out;
            end
            'h9 : begin // rotate operA left
                operA <= reg_file[regA];
                operB <= regB;
                alu_en <= 1;
                reg_file[regA] <= alu_out;
            end
            'hA : begin // not operA
                operA <= reg_file[regA];
                alu_en <= 1;
                reg_file[regB] <= alu_out;
            end
            'hB : begin // multiply operA and operB
                operA <= reg_file[regA];
                operB <= regB;
                alu_en <= 1;
                reg_file[regA] <= alu_out;
            end
            'hC : begin // JEQ jump equal
                if (reg_file[regA] == reg_file[regB]) begin
                    pc <= intermed[7:0];
                end
            end
            'hD : begin // JNE jump not equal
                if (reg_file[regA] != reg_file[regB]) begin
                    pc <= intermed[7:0];
                end
            end
            'hE : begin // JMP jump
                pc <= intermed[7:0];
            end
            endcase
        end
        'h2 :begin
            fetch_en <= 1;
            alu_en <= 0;
            we <= 0;
            case (oper)
            'h2: begin
                reg_file[regA] <= reg_file[regB];
            end
            'h3: begin 
                reg_file[regA] <= intermed;
            end
            endcase
        end
        'h3: begin
            fetch_en <= 1;
            alu_en <= 0;
            we <= 0;
            case (mem_op)
            'h1: begin
                reg_file[regA] <= mem_out;
            end
            'h2: begin
                mem_in <= reg_file[regA];
                we <= 1;
            end
            'h3: begin 
                mem_in <= intermed;
                we <= 1;
            end
            endcase
        end
        endcase

    end

endmodule