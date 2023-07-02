module instr_mem(input wire clk, input fetch_en,input [5:0] pc,inout reg [29:0] instruction);
    reg [29:0] instruction_mem [0:63];

    integer i = 0;
    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            instruction_mem[i] = 30'h1;
        end
    end

    always @ (posedge clk) begin
        if (fetch_en)
            instruction <= instruction_mem[pc];
        else
            instruction_mem[pc] <= instruction;
    end
endmodule