

module gpio(input clk,
            input rst,
            inout [7:0] gpio_data, 
            input [7:0] gpio_en,
            input [7:0] gpio_dir,
            inout [7:0] gpio_reg);
    // gpio temporary input register
    reg [7:0] gpio_reg_i;
    // gpio temporary output register
    reg [7:0] gpio_reg_o;
    // set internal gpio register to the input from gpio_data
    assign gpio_reg = (gpio_reg_i | gpio_reg);
    // set the gpio data output to the output values from gpio_reg
    assign gpio_data = (gpio_reg_o | gpio_data);
    initial begin
        gpio_reg_i = {0};
        gpio_reg_o = {0};
    end

    always @(posedge clk) begin
        if (rst == 1) begin
            gpio_reg_i <= {0};
            gpio_reg_o <= {0};
        end
        else begin
            // set the gpio temp input register to the data corresponding
            // to the enabled pins and pin direction (1 is input)
            gpio_reg_i <= (gpio_dir & gpio_en & gpio_data);
            // set the gpio temp output register to the data corresponding
            // to the enable pins and pin direction (0 is output).
            // we not the direction register to have a 1 for the right output pins.
            gpio_reg_o <= (~gpio_dir & gpio_en & gpio_reg);
        end
    end

endmodule