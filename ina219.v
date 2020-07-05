module ina219(
    inout sda,
    input scl,
    input rst,
    input clk
);
    reg [15:0] data_out;

    initial begin
        data_out = 16'h91;
    end
    i2c_slave slv_interface (
        .sda (sda),
        .scl (scl),
        .clk (clk),
        .rst (rst),
        .data_in (data_in),
        .data_out (data_out),
        .slave_addr (), // input for ina
        .pointer_in (), // input for ina
        .pointer_out () // Output from ina
    );

endmodule
