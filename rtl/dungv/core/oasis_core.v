`default_nettype none
`include "oasis_defs.vh"

module oasis_core(
    input wire clk,
    input wire reset,
    output wire [`OASIS_PC_WIDTH-1:0] pc_value,
    output wire [`OASIS_XLEN-1:0] debug_out
);

    parameter PROGRAM_FILE = "";

    reg [`OASIS_PC_WIDTH-1:0] pc;
    reg [`OASIS_XLEN-1:0] out;

    wire [`OASIS_INSTR_WIDTH-1:0] instruction;
    wire [`OASIS_REG_ADDR_WIDTH-1:0] rega;
    wire [`OASIS_REG_ADDR_WIDTH-1:0] regb;
    wire [`OASIS_IMM_WIDTH-1:0] intermed;
    wire [1:0] instr_class;
    wire [3:0] oper;
    wire [1:0] mem_op;
    wire [`OASIS_DATA_ADDR_WIDTH-1:0] mem_addr;
    wire [`OASIS_XLEN-1:0] alu_out;
    wire [`OASIS_XLEN-1:0] mem_in;
    wire [`OASIS_XLEN-1:0] mem_out;
    wire [`OASIS_XLEN-1:0] reg_data_a;
    wire [`OASIS_XLEN-1:0] reg_data_b;
    wire [`OASIS_XLEN-1:0] operand_b;
    reg [`OASIS_XLEN-1:0] reg_wr_data;
    reg [`OASIS_REG_ADDR_WIDTH-1:0] reg_wr_addr;
    reg reg_wr_en;

    assign pc_value = pc;
    assign debug_out = out;
    assign mem_in = mem_op == `OASIS_MEM_MSI ? intermed : reg_data_a;
    assign operand_b = (oper >= `OASIS_ALU_SHR && oper <= `OASIS_ALU_RTL) ?
                       {{(`OASIS_XLEN-`OASIS_REG_ADDR_WIDTH){1'b0}}, regb} :
                       reg_data_b;

    instr_mem #(.INIT_FILE(PROGRAM_FILE)) instr_mem_inst(
        .pc(pc),
        .instruction(instruction)
    );

    instr_decode instr_decode_inst(
        .instruction(instruction),
        .rega(rega),
        .regb(regb),
        .intermed(intermed),
        .instr_class(instr_class),
        .oper(oper),
        .mem_op(mem_op),
        .mem_addr(mem_addr)
    );

    register_file register_file_inst(
        .clk(clk),
        .reset(reset),
        .wr_en(reg_wr_en),
        .wr_addr(reg_wr_addr),
        .wr_data(reg_wr_data),
        .rd_addr_a(rega),
        .rd_addr_b(regb),
        .rd_data_a(reg_data_a),
        .rd_data_b(reg_data_b)
    );

    data_mem data_mem_inst(
        .clk(clk),
        .wr_en(!reset && instr_class == `OASIS_CLASS_MEM &&
               (mem_op == `OASIS_MEM_MVT || mem_op == `OASIS_MEM_MSI)),
        .addr(mem_addr),
        .data_in(mem_in),
        .data_out(mem_out)
    );

    alu alu_inst(
        .operand_a(reg_data_a),
        .operand_b(operand_b),
        .oper(oper),
        .result(alu_out)
    );

    always @(*) begin
        reg_wr_en = 1'b0;
        reg_wr_addr = rega;
        reg_wr_data = {`OASIS_XLEN{1'b0}};

        case (instr_class)
            `OASIS_CLASS_ALU: begin
                case (oper)
                    `OASIS_ALU_ADD, `OASIS_ALU_SUB, `OASIS_ALU_AND,
                    `OASIS_ALU_OOR, `OASIS_ALU_XOR, `OASIS_ALU_SHR,
                    `OASIS_ALU_SHL, `OASIS_ALU_RTR, `OASIS_ALU_RTL,
                    `OASIS_ALU_NOT, `OASIS_ALU_MLT: begin
                        reg_wr_en = 1'b1;
                        reg_wr_data = alu_out;
                    end
                endcase
            end

            `OASIS_CLASS_REG: begin
                case (oper[1:0])
                    `OASIS_REG_MVV: begin
                        reg_wr_en = 1'b1;
                        reg_wr_data = reg_data_b;
                    end

                    `OASIS_REG_MVI: begin
                        reg_wr_en = 1'b1;
                        reg_wr_data = intermed;
                    end
                endcase
            end

            `OASIS_CLASS_MEM: begin
                if (mem_op == `OASIS_MEM_MVF) begin
                    reg_wr_en = 1'b1;
                    reg_wr_data = mem_out;
                end
            end
        endcase
    end

    always @(posedge clk) begin
        if (reset) begin
            pc <= {`OASIS_PC_WIDTH{1'b0}};
            out <= {`OASIS_XLEN{1'b0}};
        end else begin
            pc <= pc + 1'b1;

            case (instr_class)
                `OASIS_CLASS_ALU: begin
                    case (oper)
                        `OASIS_ALU_ADD, `OASIS_ALU_SUB, `OASIS_ALU_AND,
                        `OASIS_ALU_OOR, `OASIS_ALU_XOR, `OASIS_ALU_SHR,
                        `OASIS_ALU_SHL, `OASIS_ALU_RTR, `OASIS_ALU_RTL,
                        `OASIS_ALU_NOT, `OASIS_ALU_MLT: begin
                            out <= alu_out;
                        end

                        `OASIS_ALU_JEQ: begin
                            if (reg_data_a == reg_data_b) begin
                                pc <= intermed[`OASIS_PC_WIDTH-1:0];
                            end
                        end

                        `OASIS_ALU_JNE: begin
                            if (reg_data_a != reg_data_b) begin
                                pc <= intermed[`OASIS_PC_WIDTH-1:0];
                            end
                        end

                        `OASIS_ALU_JMP: begin
                            pc <= intermed[`OASIS_PC_WIDTH-1:0];
                        end

                        default: begin
                            out <= {`OASIS_XLEN{1'b0}};
                        end
                    endcase
                end

                `OASIS_CLASS_REG: begin
                    case (oper[1:0])
                        `OASIS_REG_MVV: out <= reg_data_b;
                        `OASIS_REG_MVI: out <= intermed;
                        default: out <= {`OASIS_XLEN{1'b0}};
                    endcase
                end

                `OASIS_CLASS_MEM: begin
                    case (mem_op)
                        `OASIS_MEM_MVF: out <= mem_out;
                        `OASIS_MEM_MVT: out <= reg_data_a;
                        `OASIS_MEM_MSI: out <= intermed;
                        default: out <= {`OASIS_XLEN{1'b0}};
                    endcase
                end

                default: begin
                    out <= {`OASIS_XLEN{1'b0}};
                end
            endcase
        end
    end

endmodule
