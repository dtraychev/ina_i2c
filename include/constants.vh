// I2C Master state machine states
localparam IDLE          = 0;
localparam START         = 1;
localparam STOP          = 2;
localparam DATA          = 3;
localparam ADDR          = 4;
localparam RW            = 5;
localparam WAIT_ACK      = 6;
localparam WAIT_SEC_ACK  = 7;
localparam ACK           = 8;
localparam WAIT_STOP     = 9;
localparam ADDR_POINTER  = 10;
localparam NOP_INPUT     = 11;
localparam SLV_ADDR_ACK  = 12;
localparam SEC_DATA      = 13;
localparam SEC_DATA_ACK  = 14;
localparam DATA_ACK      = 15;
