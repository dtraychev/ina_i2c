`timescale 1 ns / 1 ns
module tb;

    reg clk_2;
    reg reset;
    reg [15:0] rx_data;
    reg [15:0] tx_data;
    reg [ 6:0] slv_addr;
    reg [ 7:0] pointer_addr;
    bit data_valid;
    bit rd_wr;
    bit start;
    bit eot;
    bit [15:0] test_in_voltage;
    bit [15:0] test_in_shunt;
    
    wire sda;
    wire scl;

    initial begin

        clk_2 = 0;
        reset = 1;
        #40
        reset = 0;
    end
    
    always clk_2 = #5 ~clk_2; // 200MHz

    initial begin
        if (reset) begin
            tx_data  = 16'b0;
            slv_addr =  7'b0;
            start    =  1'b0;
        end
    end

    i2c_master tb_master(
        .clk      (clk_2),
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
        .rst             (reset),
        .sda             (  sda),
        .scl             (  scl),
        .clock           (clk_2),
        .test_in_voltage (test_in_voltage),
        .test_in_shunt   (test_in_shunt)
    );
    
    /* Test sequence */
    task write_data(input [15:0] write_data, input [6:0] slv_addr_in, input [7:0] pointer_addr_in);
        $display("%t Send data %h on address %h",$time, write_data, pointer_addr_in);
        data_valid = 1;
        rd_wr = 0;
        start = 1'b1;
        tx_data = write_data;
        pointer_addr = pointer_addr_in;
        slv_addr = slv_addr_in;
        #20
        start = 1'b0;
        wait(eot);
    endtask

    task read_data(input [6:0] slv_addr_in, input [7:0] pointer_addr_in, output [15:0] read_data);
        data_valid = 0;
        rd_wr = 1'b0;
        start = 1'b1;
        pointer_addr = pointer_addr_in;
        slv_addr = slv_addr_in;
        #20
        start = 1'b0;
        wait(eot);
        #100
        start = 1'b1;
        slv_addr = slv_addr_in;
        rd_wr = 1;
        #20
        start = 1'b0;
        wait(eot);
        $display("%t ns Slave addr: %0h, Read data: %0h", $time, slv_addr_in ,rx_data);
        read_data = rx_data;
    endtask


    initial begin
        reg [15:0] data;
        reg [15:0] r_data;
        #100
        $display("%t ns Read configuration register after power-on", $time);
        read_data(7'h01, 8'h00, r_data);
        if(r_data == 16'h3955) begin
            $display("Configuration register value must be 16'h3955 after poweron");
            $finish;
        end

        #100
        $display("%t ns Setting 32V on Voltage register", $time);
        test_in_voltage = 32/4*1000;
        $display("%t ns Read Voltage register", $time);
        read_data(7'h01, 8'h02, r_data);
        #100;
        $display("%t ns Setting 240mV to shunt vontage with PGA /8", $time);
        test_in_shunt = 'd24000;
        $display("%t ns Read Shunt register", $time);
        read_data(7'h01, 8'h01, r_data);
        #100;

        $display("%t ns Check if Shunt reg value is limited by PGA", $time);
        $display("%t ns Change PGA to /4", $time);
        data = 16'h3955;
        data[12:11] = 2'b10;
        write_data(data, 8'h01, 7'h00);
        #100;
        $display("%t ns Again set 240mV to shunt vontage with PGA /4", $time);
        test_in_shunt = 'd24000;
        $display("%t ns Read Shunt register", $time);
        read_data(7'h01, 8'h01, r_data);
        if(r_data == test_in_shunt) begin
            $display("Read data equal to shunt voltage which is out of randge > 160mV");
            $finish;
        end

        #100;
        #200;
        $finish;
    end

    
endmodule