
module i2c_master(
    input wire clk,
    input wire rst,
    input wire rd_wr,
    input wire [15:0] data_in,
    input wire [6:0] slv_addr_in,
    input wire [7:0] pointer_addr,
    output reg [15:0] data_out,
    input wire start,
    output reg eot, // End Of Transfer
    input reg data_valid,
    inout wire sda,
    output wire scl
);

    `include "constants.vh"
    reg        clk_dev2 = 0;
    reg [ 7:0] sm      ; // State Machine
    reg [ 7:0] sm_r    ; // State Machine
    reg [ 7:0] count   ;
    reg        sda_out ; 
    reg [15:0] rd_data ;

    reg scl_enable = 0; // SCL enable
    reg scl_enable_r = 0; // SCL enable
    reg sda_oe     = 0; // SDA Output enable

    assign scl = (scl_enable == 0) ? 1 : ~clk_dev2;
    assign sda = (sda_oe) ? sda_out : 1'bZ;
    assign data_out = (eot) ? rd_data : 16'h0;

    always @ (negedge clk) begin
        clk_dev2 = ~clk_dev2;
    end

    always @ (posedge clk) begin
        if(rst) begin
            scl_enable <= 0;
            scl_enable_r <= 0;
            clk_dev2 <= 0;
        end
        else begin
            if (sm == IDLE || sm == STOP) begin
                scl_enable <= 0;
            end
            else begin
                scl_enable <= 1;
            end
            //sm_r <= sm;
         end
    end

    // always @ (negedge clk_dev2) begin
    //     if(sm==STOP)
    //         scl_enable_r <= 0;
    //     scl_enable <= scl_enable_r;
    // end

    always @ (negedge clk) begin
        if (sm == STOP) begin
            sda_out <= 1;
        end
    end

    always @ (posedge clk_dev2) begin
        if (rst) begin
            sda_oe <= 1;
        end
//        sm_r <= sm;
        // else begin
        //     if(sm == DATA) begin
        //         if (rd_wr) begin
        //             sda_oe <= 0; // If RD, SDA is input
        //         end
        //         else begin
        //             sda_oe <= 1; // If WR, SDA is output
        //         end
        //     end
        //     else begin
        //         sda_oe <= 1;
        //     end
        // end
    end

    always @(negedge clk_dev2) begin
        if (rst) begin
            sm      <= IDLE;
            sda_out <= 1;
            count   <= 8'd0;
            eot     <= 1'b0;
        end
        else begin
            case (sm)
                IDLE: begin
                    sda_out <= 1;
                    eot <= 0;
                    if(start == 1) begin
                        count <= 1;
                        sda_out <= 0;
                        sm <= START;
                    end
                    //eot <= 0;
                end // IDLE

                START: begin
                    //if (count == 0) begin
                       // scl_enable <= 1;
                        sm <= ADDR;
                        count <= 6;
                    //end
                    //else begin
                     //   scl_enable <= 0;
                        sda_out <= 0;
                      //  count <= count - 1;
                    //end
                end // START

                ADDR: begin
                    if(count == 0)  begin
                        count <= 1;
                        sm <= RW;
                        sda_out <= slv_addr_in[count];
                    end
                    else begin
                        sda_out <= slv_addr_in[count];
                        count <= count -1;
                    end
                end // ADDR

                WAIT_ACK: begin
                    if (sda == 0) begin
                        count <= 7;
                        if (rd_wr) begin
                            sm <= DATA;
                            sda_oe <= 0;
                        end
                        else begin
                            sm <= ADDR_POINTER;
                            sda_oe <= 1;
                        end
                    end
                end // WAIT_ACK

                NOP_INPUT: begin
                    sda_oe <= 0;
                    sm <= sm_r;
                end

                ADDR_POINTER: begin
                    if (count == 0) begin
                        sda_out <= pointer_addr[count];
                        sm <= NOP_INPUT;
                        sm_r <= WAIT_SEC_ACK;
                    end
                    else begin
                        sda_out <= pointer_addr[count];
                        count <= count - 1;
                    end
                end

                WAIT_SEC_ACK: begin
                    if (data_valid) begin
                        sda_out <= data_in[7+8];
                        count <= 7;
                        sda_out <= 0;
                        sda_oe <= 1;
                        sm <= DATA;
                    end
                    else begin
                        sda_out <= 0;
                        sda_oe <= 1;
                        sm <= STOP;
                    end
                end // WAIT_SEC_ACK

                RW: begin
                    if(count == 0)  begin
                        sm <= WAIT_ACK;
                        sda_oe <= 0;
                    end
                    else begin
                        if(rd_wr) begin
                            sda_out <= 1;  // RD High
                        end
                        else begin
                            sda_out <= 0; // WR Low
                        end
                        count <= count -1;
                    end
                end // RW

                DATA: begin
                    if (count == 0) begin
                        sm <= DATA_ACK;
                        if (rd_wr) begin
                            sda_oe <= 1;
                            sda_out <= 0; // ACK
                            rd_data[count+8] <= sda;
                        end
                        else begin
                            sda_oe <= 0;
                            sda_out <= data_in[count+8];
                        end
                    end
                    else if (rd_wr) begin
                        rd_data[count+8] <= sda;
                    end
                    else begin
                        sda_out <= data_in[count-1+8];
                    end
                    count <= count -1;
                end // DATA

                DATA_ACK: begin
                    count <= 7;
                    sda_oe <= (rd_wr) ? 0 : 1;
                    if (!rd_wr) begin
                        sda_out <= data_in[7];
                    end
                    sm <= SEC_DATA;
                end

                SEC_DATA: begin
                    if (count == 0) begin
                        sm <= SEC_DATA_ACK;
                        sda_oe <= (rd_wr) ? 1 : 0;
                        sda_out <= 0; // ACK
                        if (rd_wr) begin
                            rd_data[count] <= sda;
                        end
                    end
                    else if (rd_wr) begin
                        rd_data[count] <= sda;
                    end
                    else begin
                        sda_out <= data_in[count-1];
                    end
                    count <= count -1;
                end

                SEC_DATA_ACK: begin
                    sda_out <= 0;
                    sda_oe <= 1;
                    sm <= STOP;
                end

                STOP: begin
                        eot <= 1;
                        sm <= IDLE;
                end // STOP
            endcase
        end
    end
    
endmodule