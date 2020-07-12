module ina219(
    inout sda,
    input scl,
    input rst,
    input clock,
    input [15:0] test_in_shunt,
    input [15:0] test_in_voltage
    );
    
    reg [ 15:0] voltage_reg ;
    reg [ 15:0] config_reg ;
    reg [ 15:0] power_reg ;
    reg [ 15:0] current_reg;
    reg [ 15:0] shunt_reg;
    reg [ 15:0] v_shunt;
    reg [ 15:0] calibration_reg;
    reg [  6:0] slave_addr;
    reg         wr_en;
    reg [  6:0] slv_addr;
    reg [  7:0] address;
    wire        addr_valid;
    wire        p_valid;
    wire        data_valid;
    wire [15:0] rx_data;
    reg  [15:0] tx_data;
    wire [ 7:0] pointer;
    wire        write_en;

    i2c_slave slv_interface (
        .sda           (sda),
        .scl           (scl),
        .rst           (rst),
        .clk           (clock),
        .rx_data       (rx_data),
        .tx_data       (tx_data),
        .write_en      (write_en),
        .slave_addr    (slave_addr),
        .pointer       (pointer),
        .addr_valid    (addr_valid),
        .pointer_valid (p_valid),
        .data_valid    (data_valid)
    );

    // Test inputs from testbench (represent ADC values)
    assign v_shunt      = test_in_shunt;
    assign voltage_reg  = test_in_voltage;


    // Read and write from register file
    always @(posedge clock) begin
        if (rst == 1'b1) begin
            config_reg      <= 16'h399F;
            current_reg     <= 16'b0;
            calibration_reg <= 16'b0;
            power_reg       <= 16'b0;
        end
        else begin
            // Set read or write and slave address
            if (addr_valid) begin
                wr_en <= write_en;
                slv_addr <= slave_addr; // TODO Check if slv_addr match device
            end

            // Set the address pointer
            if (p_valid) begin
                address <= pointer;
            end

            // Write to registers
            if (data_valid) begin
                if (wr_en) begin
                    if (address == 'h00) 
                        config_reg <= rx_data;
                    else if (address == 'h05) 
                        calibration_reg  <= rx_data;
                end
            end
            
            // Read from registers
            if (~wr_en) begin 
                if (address == 'h00)
                    tx_data <= config_reg;
                else if (address == 'h01)
                    tx_data <= shunt_reg;
                else if (address == 'h02)
                    tx_data <= voltage_reg;
                else if (address == 'h03) begin
                    current_reg  <= (shunt_reg*calibration_reg)/4096;
                    tx_data <=  current_reg ;
                end
                else if (address == 'h04) begin
                    power_reg  <= (current_reg*voltage_reg )/5000;
                    tx_data <=  power_reg ;
                    end
                else if (address == 'h05)
                    tx_data <= calibration_reg ;
            end

            // Limit Shunt register value corresponging to the PGA value
            // PGA /8 - MSB is sign
            // PGA /4 - 2 MSB are sign
            // PGA /2 - 3 MSB are sgin
            // PGA /1 - 4 MSB are sign
            case(config_reg[12:11])
                2'h0  : shunt_reg <= {{4{v_shunt[15]}},v_shunt[11:0]};           
                2'h1  : shunt_reg <= {{3{v_shunt[15]}},v_shunt[12:0]};
                2'h2  : shunt_reg <= {{2{v_shunt[15]}},v_shunt[13:0]};
                2'h3  : shunt_reg <= {v_shunt[15],v_shunt[14:0]};
            endcase 
        end
    end
endmodule
