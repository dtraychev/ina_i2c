
module i2c_slave(
    input wire rst,
    inout wire sda,
    input wire scl,
    input wire clk,
    output wire [15:0] rx_data,
    input wire  [15:0] tx_data,
    output wire [6:0]  slave_addr,
    output wire [7:0]  pointer,
    output wire        write_en,
    output wire        addr_valid,
    output wire        pointer_valid,
    output wire        data_valid
    );

    `include "constants.vh"

    reg        clk_dev2 = 0;
    reg [7:0] sm;
    reg [6:0] slv_addr;
    reg [15:0] data_in_int;
    reg [7:0] count;
    reg start;
    reg stop;
    reg scl_enable;
    reg rw;
    reg sda_oe;
    reg sda_in;
    reg sda_out;
    reg data_rdy;
    reg [7:0] addr_pointer;
    reg addr_rdy;
    reg p_valid;

    // Signal that slave address read is ready
    assign addr_valid = addr_rdy;
    // Set slave address and wr outputs
    assign slave_addr = (addr_rdy) ? slv_addr : 8'h0;
    assign write_en = (addr_rdy) ? ~rw : 1'b0;

    // Signal that pointer address read is ready
    assign pointer_valid = p_valid;
    // Set address pointer output
    assign pointer = (p_valid) ? addr_pointer : 8'h0;

    // Signal that data read is ready
    assign data_valid = data_rdy;
    // Set read data otput
    assign rx_data = (data_rdy && ~rw) ? data_in_int : 16'bx;

    // Make sda output/input
    assign sda = (sda_oe) ? sda_out : 1'bZ;

    // Valid signals conditions
    always @ (posedge clk) begin
        if (rst) begin
            data_rdy <= 0;
            addr_rdy <= 0;
            p_valid  <= 0;
        end
        else begin
            if (sm == SLV_ADDR_ACK) begin
                addr_rdy <= 1;
            end else
                addr_rdy <= 0;

            if (sm == WAIT_SEC_ACK) begin
                p_valid <= 1;
            end
            else begin
                p_valid <= 0;
            end

            if (sm == SEC_DATA_ACK) begin
                data_rdy <= 1;
            end
            else 
                data_rdy <= 0;
        end
    end
    
    // Detect START condition
    always @ (negedge sda) begin
        if(scl) begin
            start = 1;
            stop  = 0;
        end
    end

    // Detect STOP condition
    always @ (posedge clk_dev2 && sda) begin
        if (scl == 1) begin
            stop  = 1;
            start = 0;
        end
    end

    // Generate clock for I2C Slave state maching. Main clock devided by 2.
    always @ (negedge clk) begin
        clk_dev2 = ~clk_dev2; // 400KHz
    end

    // I2C State machine
    always @(negedge clk_dev2) begin
        if (rst) begin
            sm <= IDLE;
            count <= 8'd0;
            scl_enable <= 0;
            rw <= 0;
            sda_oe <= 0;
        end
        else begin
            case (sm)
                IDLE: begin
                    if(start) begin
                        sm <= START;
                    end
                end

                START: begin
                    sm <= ADDR;
                    count <= 6;
                end

                ADDR: begin
                    sda_oe  = 0;
                    if(count == 0) begin
                        count <= 8; // for 8 bits of data
                        slv_addr[count] <= sda;
                        count <= 2;
                        sm <= SLV_ADDR_ACK;
                    end
                    else begin
                        slv_addr[count] <= sda;
                        count <= count - 1;
                    end
                end

                RW: begin
                    if(sda == 1) begin
                        rw <= 1; // Read
                    end
                    else begin
                        rw <= 0; // Write
                    end
                    sm <= ACK;
                end

                SLV_ADDR_ACK: begin
                    if (count == 0) begin
                        count <= 7;
                        sda_oe <= 0;
                        sm  <= ADDR_POINTER;
                    end
                    else if (count == 2) begin
                        if(sda == 1) begin
                            rw <= 1; // Read
                            count <= 8;
                            sda_oe <= 1;
                            sm <= DATA;
                        end
                        else begin
                            rw <= 0; // Write
                            sda_oe <= 1;
                            sda_out <= 0;
                            count <= count - 1;
                        end
                    end
                    else begin
                        count <= count - 1;
                    end
                end

                ADDR_POINTER: begin
                    if (count == 0) begin
                        addr_pointer[count] <= sda;
                        sda_oe <= 1;
                        sda_out <= 0; // Second ACK
                        sm <= WAIT_SEC_ACK;
                       // pointer_valid <= 1;
                    end
                    else begin
                        addr_pointer[count] <= sda;
                        count <= count - 1;
                    end
                end

                WAIT_SEC_ACK: begin
                    if (rw) begin
                        count <= 8;
                        sda_oe <= 1;
                    end
                    else begin
                        count <= 7;
                        sda_oe <= 0;
                    end
                    sm <= DATA;
                end

                DATA: begin
                    if (count == 0) begin
                        if (rw) begin
                            sda_oe <= 0;
                        end
                        else begin
                            data_in_int[count+8] <= sda;
                            sda_oe <= 1;
                        end
                        sm <= DATA_ACK;
                    end
                    else begin
                        if (rw) begin
                            sda_out <= tx_data[8+count-1];
                        end
                        else begin
                            if(stop)
                                sm <= WAIT_STOP;
                            data_in_int[8+count] <= sda;
                        end
                    end
                    count <= count -1;
                end

                DATA_ACK: begin
                    if (rw) begin
                        sda_oe <= 1;
                        sda_out <= tx_data[7];
                        count <= 7;
                    end
                    else begin
                        sda_oe <= 0;
                        count <= 7;
                    end
                    sm <= SEC_DATA;
                end

                SEC_DATA: begin
                    if (count == 0) begin
                        if (rw) begin
                            sda_oe <= 0;
                            sm <= SEC_DATA_ACK;
                        end
                        else begin
                            data_in_int[count] <= sda;
                            sda_oe <= 1;
                            sm <= SEC_DATA_ACK;
                        end
                    end
                    else begin
                        if (rw) begin
                            sda_out <= tx_data[count-1];
                        end
                        else begin
                            data_in_int[count] <= sda;
                        end
                    end
                    count <= count -1;
                end

                SEC_DATA_ACK: begin
                    sda_oe <= 0;
                    count <= 1;
                    sm <= WAIT_STOP;
                end

                WAIT_STOP: begin
                    sda_oe <= 0;
                    count <= 0;
                    if (stop)
                        sm <= IDLE;
                end
            endcase
        end
    end
    
endmodule