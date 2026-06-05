`default_nettype none
`include "oasis_defs.vh"

module alu_tb;
    reg [`OASIS_XLEN-1:0] operand_a;
    reg [`OASIS_XLEN-1:0] operand_b;
    reg [3:0] oper;
    wire [`OASIS_XLEN-1:0] result;

    alu dut(
        .operand_a(operand_a),
        .operand_b(operand_b),
        .oper(oper),
        .result(result)
    );

    task check_result;
        input [`OASIS_XLEN-1:0] expected;
        input [127:0] name;
        begin
            #1;
            if (result !== expected) begin
                $display("FAIL %0s: expected %h got %h", name, expected, result);
                $finish;
            end
        end
    endtask

    initial begin
        operand_a = 16'h000a;
        operand_b = 16'h0014;
        oper = `OASIS_ALU_ADD;
        check_result(16'h001e, "add");

        operand_a = 16'h000a;
        operand_b = 16'h0014;
        oper = `OASIS_ALU_SUB;
        check_result(16'hfff6, "sub_wrap");

        operand_a = 16'h8001;
        operand_b = 16'h0000;
        oper = `OASIS_ALU_RTR;
        check_result(16'h8001, "rtr_zero");

        operand_a = 16'h0001;
        operand_b = 16'h0001;
        oper = `OASIS_ALU_RTR;
        check_result(16'h8000, "rtr_one");

        operand_a = 16'h8000;
        operand_b = 16'h0001;
        oper = `OASIS_ALU_RTL;
        check_result(16'h0001, "rtl_one");

        operand_a = 16'h00ff;
        operand_b = 16'h0000;
        oper = `OASIS_ALU_NOT;
        check_result(16'hff00, "not");

        $display("PASS alu_tb");
    end
endmodule
