`default_nettype none
`include "instr_mem.v"
`include "instr_decode.v"
`include "mem.v"
`include "alu.v"

module top(input wire reset,
  input wire clk,

  // Logic anaylzer
  input wire i_la_write,
  input wire [6:0] i_la_addr,
  input wire [7:0] i_la_data,
  input wire i_la_wb_disable,
  output wire [31:0] la_data_out,

  // wishbone interface
  input  wire        i_wb_cyc,   // wishbone transaction
  input  wire        i_wb_stb,   // strobe
  input  wire        i_wb_we,    // write enable
  input  wire [31:0] i_wb_addr,  // address
  input  wire [31:0] i_wb_data,  // incoming data
  output wire        o_wb_ack,   // request is completed 
  output reg  [31:0] o_wb_data,  // output data

  // GPIO
 input  wire [7:0] io_in,
  output wire [7:0] io_out,
  output wire [7:0] io_oeb,  // out enable bar (low active)

  // SRAM wishbone controller
  output wire        rambus_wb_clk_o,   // clock, must run at system clock
  output wire        rambus_wb_rst_o,   // reset
  output wire        rambus_wb_stb_o,   // write strobe
  output wire        rambus_wb_cyc_o,   // cycle
  output wire        rambus_wb_we_o,    // write enable
  output wire [ 3:0] rambus_wb_sel_o,   // write word select
  output wire [31:0] rambus_wb_dat_o,   // ram data out
  output wire [ 9:0] rambus_wb_addr_o,  // 8 bit address
  input  wire        rambus_wb_ack_i,   // ack
  input  wire [31:0] rambus_wb_dat_i,   // ram data in

  // interrupt
  output wire interrupt);

    reg [31:0] counter;
    reg [7:0] pc;
    wire clk, sclk;
    assign LED_R = ~counter[25];
    assign LED_G = ~counter[24];
    assign LED_B = ~counter[23];
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
            reg_file[i] = 16'hFFFF;
        end

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
        
        'h1: begin
            we <= 0;
            fetch_en <= 1;
            case (oper)
            'h1: begin // ADD operB to operA
                operA <= reg_file[regA];
                operB <= reg_file[regB];
                alu_en <= 1;
                out <= alu_out;
                reg_file[regA] <= alu_out;
            end
            'h2: begin // SUB operB from operA
                operA <= reg_file[regA];
                operB <= reg_file[regB];
                alu_en <= 1;
                out <= alu_out;
                reg_file[regA] <= alu_out;
            end
            'h3: begin // AND operA with operB
                operA <= reg_file[regA];
                operB <= reg_file[regB];
                alu_en <= 1;
                reg_file[regA] <= alu_out;
                out <= alu_out;
                
            end
            'h4: begin // OR operA with operB
                operA <= reg_file[regA];
                operB <= reg_file[regB];
                alu_en <= 1;
                reg_file[regA] <= alu_out;
                out <= alu_out;
            end
            'h5: begin // XOR operA with operB
                operA <= reg_file[regA];
                operB <= reg_file[regB];
                alu_en <= 1;
                reg_file[regA] <= alu_out;
                out <= alu_out;
            end
            'h6 : begin // shift right operA by 0-31
                operA <= reg_file[regA];
                operB <= regB;
                alu_en <= 1;
                reg_file[regA] <= alu_out;
                out <= alu_out;
            end
            'h7 : begin // shift left operA by 0-31
                operA <= reg_file[regA];
                operB <= regB;
                alu_en <= 1;
                reg_file[regA] <= alu_out;
                out <= alu_out;
            end
            'h8 : begin // rotate operA right
                operA <= reg_file[regA];
                operB <= regB;
                alu_en <= 1;
                reg_file[regA] <= alu_out;
                out <= alu_out;
            end
            'h9 : begin // rotate operA left
                operA <= reg_file[regA];
                operB <= regB;
                alu_en <= 1;
                reg_file[regA] <= alu_out;
                out <= alu_out;
            end
            'hA : begin // not operA
                operA <= reg_file[regA];
                alu_en <= 1;
                reg_file[regB] <= alu_out;
                out <= alu_out;
            end
            'hB : begin // multiply operA and operB
                operA <= reg_file[regA];
                operB <= regB;
                alu_en <= 1;
                reg_file[regA] <= alu_out;
                out <= alu_out;
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
            'hF : begin // JMP jump
                pc <= intermed[7:0];
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