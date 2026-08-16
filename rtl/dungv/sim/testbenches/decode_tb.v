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
    wire mem_mmio;
    wire [`OASIS_DATA_ADDR_WIDTH-1:0] mem_addr;

    instr_decode dut(
        .instruction(instruction),
        .rega(rega),
        .regb(regb),
        .intermed(intermed),
        .instr_class(instr_class),
        .oper(oper),
        .mem_op(mem_op),
        .mem_mmio(mem_mmio),
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
        input expected_mem_mmio;
        input [`OASIS_DATA_ADDR_WIDTH-1:0] expected_mem_addr;
        input [`OASIS_IMM_WIDTH-1:0] expected_intermed;
        input [127:0] name;
        begin
            #1;
            if (mem_op !== expected_mem_op || rega !== expected_rega ||
                mem_mmio !== expected_mem_mmio ||
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

        // Exact v1.0 encodings emitted by the OASIS assembler. These straddle
        // the v0.x/v1.0 compatibility boundary for direct memory operands.
        instruction = 32'hd2015400; // MVF r8, mem:[0x055]
        expect_mem(`OASIS_MEM_MVF, 6'd8, 1'b0, 11'h055, 16'h0000, "mvf_mem_v1_decode");

        instruction = 32'he23ffc00; // MVT r8, io:[0x7ff]
        expect_mem(`OASIS_MEM_MVT, 6'd8, 1'b1, 11'h7ff, 16'h0000, "mvt_io_v1_decode");

        instruction = 32'hf066beef; // MSI mem:[0x066], 0xbeef
        expect_mem(`OASIS_MEM_MSI, 6'd0, 1'b0, 11'h066, 16'hbeef, "msi_mem_v1_decode");

        instruction = 32'hfffe1234; // MSI io:[0x7fe], 0x1234
        expect_mem(`OASIS_MEM_MSI, 6'd0, 1'b1, 11'h7fe, 16'h1234, "msi_io_v1_decode");

        $display("PASS decode_tb");
    end
endmodule
