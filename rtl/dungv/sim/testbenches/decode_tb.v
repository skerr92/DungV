`default_nettype none
`include "oasis_defs.vh"

module decode_tb;
    reg [`OASIS_INSTR_WIDTH-1:0] instruction;
    wire [`OASIS_REG_ADDR_WIDTH-1:0] rega;
    wire [`OASIS_REG_ADDR_WIDTH-1:0] regb;
    wire [`OASIS_IMM_WIDTH-1:0] intermed;
    wire [1:0] instr_class;
    wire [3:0] oper;
    wire [1:0] mem_op;
    wire [`OASIS_DATA_ADDR_WIDTH-1:0] mem_addr;

    instr_decode dut(
        .instruction(instruction),
        .rega(rega),
        .regb(regb),
        .intermed(intermed),
        .instr_class(instr_class),
        .oper(oper),
        .mem_op(mem_op),
        .mem_addr(mem_addr)
    );

    task expect_reg;
        input [1:0] expected_class;
        input [3:0] expected_oper;
        input [`OASIS_REG_ADDR_WIDTH-1:0] expected_rega;
        input [`OASIS_REG_ADDR_WIDTH-1:0] expected_regb;
        input [`OASIS_IMM_WIDTH-1:0] expected_intermed;
        input [127:0] name;
        begin
            #1;
            if (instr_class !== expected_class || oper !== expected_oper ||
                rega !== expected_rega || regb !== expected_regb ||
                intermed !== expected_intermed) begin
                $display("FAIL %0s", name);
                $finish;
            end
        end
    endtask

    task expect_mem;
        input [1:0] expected_mem_op;
        input [`OASIS_REG_ADDR_WIDTH-1:0] expected_rega;
        input [`OASIS_DATA_ADDR_WIDTH-1:0] expected_mem_addr;
        input [`OASIS_IMM_WIDTH-1:0] expected_intermed;
        input [127:0] name;
        begin
            #1;
            if (mem_op !== expected_mem_op || rega !== expected_rega ||
                mem_addr !== expected_mem_addr || intermed !== expected_intermed) begin
                $display("FAIL %0s", name);
                $finish;
            end
        end
    endtask

    initial begin
        instruction = {`OASIS_CLASS_ALU, `OASIS_ALU_ADD, 6'd3, 6'd4, 14'd0};
        expect_reg(`OASIS_CLASS_ALU, `OASIS_ALU_ADD, 6'd3, 6'd4, 16'h0000, "add_decode");

        instruction = {`OASIS_CLASS_ALU, `OASIS_ALU_JEQ, 6'd1, 6'd2, 8'h2a, 6'd0};
        expect_reg(`OASIS_CLASS_ALU, `OASIS_ALU_JEQ, 6'd1, 6'd2, 16'h002a, "jeq_decode");

        instruction = {`OASIS_CLASS_REG, `OASIS_REG_MVI, 6'd7, 6'd0, 16'h1234};
        expect_reg(`OASIS_CLASS_REG, {2'b00, `OASIS_REG_MVI}, 6'd7, 6'd0, 16'h1234, "mvi_decode");

        instruction = {`OASIS_CLASS_MEM, `OASIS_MEM_MVT, 6'd8, 9'h055, 13'd0};
        expect_mem(`OASIS_MEM_MVT, 6'd8, 9'h055, 16'h0000, "mvt_decode");

        instruction = {`OASIS_CLASS_MEM, `OASIS_MEM_MSI, 9'h066, 3'd0, 16'hbeef};
        expect_mem(`OASIS_MEM_MSI, 6'd0, 9'h066, 16'hbeef, "msi_decode");

        $display("PASS decode_tb");
    end
endmodule
