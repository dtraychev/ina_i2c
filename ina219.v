module ina219(
    inout sda,
    input scl,
    input rst,
    input clk
);
    reg [15:0] data_out;
    reg [ 6:0] slave_addr;
    reg [ 7:0] pointer_addr;
    reg [15:0] data_in;

    initial begin
        data_out = 16'h8191;
    end
    i2c_slave slv_interface (
        .sda (sda),
        .scl (scl),
        .clk (clk),
        .rst (rst),
        .data_in (data_in),
        .data_out (data_out),
        .slave_addr (slave_addr), // input for ina
        .pointer_in (pointer_addr), // input for ina
        .pointer_out () // Output from ina
    );

endmodule
