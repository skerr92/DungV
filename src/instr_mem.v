module instr_mem(input wire clk, input fetch_en,input [7:0] pc,inout reg [31:0] instruction);
    reg [31:0] instruction_mem [0:255];

    integer i = 0;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            instruction_mem[i] = 32'hF;
        end
    end

    always @ (posedge clk) begin
        if (fetch_en)
            instruction <= instruction_mem[pc];
        else
            instruction_mem[pc] <= instruction;
    end
endmodule