`timescale 1 ns / 1 ns
module tb;
    
    reg clk;
    reg reset;
    reg [15:0] rx_data;
    reg [15:0] tx_data;
    reg [ 6:0] slv_addr;
    reg [ 7:0] pointer_addr;
    bit data_valid;
    bit rd_wr;
    bit start;
    bit eot;
    
    wire sda;
    wire scl;

    initial begin
        clk = 0;
        reset = 1;
        #40
        reset = 0;
    end
    
    always clk = #10 ~clk;

    initial begin
        if (reset) begin
            tx_data = 16'b0;
            slv_addr    =  7'b0;
            start   =  1'b0;
        end
    end

    i2c_master tb_master(
        .clk      (clk),
        .rst      (reset),
        .rd_wr    (rd_wr),
        .data_in  (tx_data),
        .slv_addr_in  (slv_addr),
        .pointer_addr (pointer_addr),
        .data_out (rx_data),
        .start    (start),
        .eot      (eot),
        .data_valid (data_valid),
        .sda      (sda),
        .scl      (scl)
    );

    ina219 dut(
        .rst (reset),
        .sda (sda),
        .scl (scl),
        .clk (clk)
    );

    /* Test sequence */
    // task write_data(input [15:0] data_in, input [6:0] addr_in);
    //     $display("%t Send data %h on address %h",$time, data_in, addr_in);
    //     rd_wr = 0;
    //     start = 1'b1;
    //     #20
    //     start = 1'b0;
    //     tx_data = data_in;
    //     addr = addr_in;
    //     wait(eot);
    //     $display("%t End of send task", $time);
    // endtask

    task read_data(input [6:0] slv_addr_in, input [7:0] pointer_addr_in);
        //$display("%t Send data %h on address %h",$time, data_in, slv_addr);
        data_valid = 0;
        start = 1'b1;
        pointer_addr = pointer_addr_in;
        slv_addr = slv_addr_in;
        #20
        start = 1'b0;
        //tx_data = data_in;
        wait(eot);
        #100
        start = 1'b1;
        slv_addr = slv_addr_in;
        rd_wr = 1;
        #20
        start = 1'b0;
        wait(eot);
        $display("%t Slave addr: %0h, Read data: %0h", $time, slv_addr_in ,rx_data);
        $display("%t End of send task", $time);
    endtask


    initial begin
        #100
        //send_data(8'h55, 7'hAA);
        read_data(7'h01, 8'h81);
    end

    
endmodule