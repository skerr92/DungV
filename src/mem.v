`default_nettype none
//this should be transformed into a bram when doing a synthesis in yosys 0.8
//and it should be equivalent to the explicit_bram.v

module mem(input wire clk, input wire wr_en, input wire [10:0] wr_addr, input wire [15:0] data_in, output reg [15:0] data_out);

    reg [15:0] memory [0:2047];
    integer i;

    initial begin
        for(i = 0; i <= 2048; i=i+1) begin
            memory[i] = 16'b001;
        end
    end

    always @(posedge clk)
    begin
        // default
        if(wr_en) begin
            memory[wr_addr] <= data_in;
        end
        data_out <= memory[wr_addr];

    end
endmodule
