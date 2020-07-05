
module i2c_slave(
    input wire rst,
    inout wire sda,
    input wire scl,
    input wire clk,
    output wire [15:0] data_in,
    input wire  [15:0] data_out,
    output wire [6:0]  slave_addr,
    output wire [7:0]  pointer_in,
    output wire [7:0]  pointer_out
    );

    `include "constants.vh"

    reg [7:0] sm;
    reg [6:0] addr;
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


    assign sda = (sda_oe) ? sda_out : 1'bZ;
    assign data_in = (data_rdy) ? data_in_int : 16'bx;

    always @ (negedge sda) begin
        if(scl) begin
            start <= 1;
        end
    end

    always @ (posedge sda) begin
        if(scl)
            stop <= 1;
    end


    // always @ (posedge clk) begin
    //     if (rst) begin
    //         sda_oe <= 0;
    //     end
    //     else begin
    //         if(sm == DATA || sm == WAIT_SEC_ACK) begin
    //             if (rd_wr) begin
    //                 sda_oe <= 1; // If RD, SDA is input
    //             end
    //             else begin
    //                 sda_oe <= 0; // If WR, SDA is output
    //             end
    //         end
    //         else begin
    //             sda_oe <= 0;
    //         end
    //     end
    // end

    always @(posedge clk) begin
        if (rst) begin
            sm <= IDLE;
            //addr <= 'h55;
            //data_in_int <= 8'haa;
            count <= 8'd0;
            start <= 0;
            stop  <= 0;
            scl_enable <= 0;
            rw <= 0;
            sda_oe <= 0;
            data_rdy <= 0;
        end
        else begin
            case (sm)
                IDLE: begin
                    if(start) begin
                        count <= 6;
                        sm <= ADDR;
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
                        addr[count] <= sda;
                        count <= 2;
                        sm <= SLV_ADDR_ACK;
                    end
                    else begin
                        addr[count] <= sda;
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
                        count <= 1;
                        sm <= WAIT_STOP;
                    end
                    else begin
                        addr_pointer[count] <= sda;
                        count <= count - 1;
                    end
                end

                DATA: begin
                    if (count == 0) begin
                        sm <= (rw) ? WAIT_ACK : ACK;
                        data_rdy <= 1;
                        sda_oe <= 0;
//                        data_in_int[count] <= sda;
                    end
                    else begin
                        if (rw) begin
                            sda_out <= data_out[8+count-1];
                        end
                        else begin
                            data_in_int[8+count] <= sda;
                        end
                    end
                    count <= count -1;
                end

                WAIT_ACK: begin
                    count <= 8;
                    sda_oe <= (rw) ? 1 : 0;
                    sm <= SEC_DATA;
                end

                SEC_DATA: begin
                    if (count == 0) begin
                        sm <= (rw) ? SEC_DATA_ACK : ACK;
                        data_rdy <= 1;
                        sda_oe <= 0;
//                        data_in_int[count] <= sda;
                    end
                    else begin
                        if (rw) begin
                            sda_out <= data_out[count-1];
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
                    if (count == 0) begin
                        if (stop)
                            sm <= IDLE;
                    end
                    else begin
                        count <= count - 1;
                    end
                end
            endcase
        end
    end
    
endmodule