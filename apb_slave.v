module apb_slave #(
    parameter ADDR_WIDTH  = 32,
    parameter DATA_WIDTH  = 32,
    parameter NUM_REGS    = 16,
    parameter WAIT_STATES = 0
)(
    input                           PCLK, 
    input                           PRESETn,
    input                           PSEL, 
    input                           PENABLE,
    input                           PWRITE,
    input  [ADDR_WIDTH - 1 : 0]     PADDR,
    input  [DATA_WIDTH - 1 : 0]     PWDATA,
    input  [DATA_WIDTH/8-1:0]       PSTRB,   

    output reg [DATA_WIDTH - 1 : 0] PRDATA,
    output reg                      PREADY,
    output reg                      PSLVERR
);
    localparam IDLE   = 3'b001;
    localparam SETUP  = 3'b010;
    localparam ACCESS = 3'b100;

    reg [DATA_WIDTH - 1 : 0] REG_FILE [0 : NUM_REGS - 1];

    // in this case : 
    // the reg file consists of 16 regs 
    // each reg consists of 4 strobes
    // each strobe is 1 8'th the data width which is 1 byte
    // the PADDR bus is 32 bit but we only need the Least significant 6 bits to address a certain byte
    // PADDR[1:0] used to address which strobe 
    // PADDR[5:2] used to address which reg
    
    localparam STRB_WIDTH = DATA_WIDTH/8;
    localparam REGS_IDXs  = $clog2(NUM_REGS);   // Registers number of indices
    localparam STRB_IDXs  = $clog2(STRB_WIDTH); // Strobes number of indices

    wire [REGS_IDXs - 1 : 0] reg_idx = PADDR[REGS_IDXs + STRB_IDXs - 1 : STRB_IDXs];

    reg [2:0] STATE_REG, NEXT_STATE;

    // Error Signals 
    wire aligned       = PADDR[STRB_IDXs - 1 : 0] == 0;
    wire in_range      = reg_idx < NUM_REGS;
    wire address_valid = aligned && in_range;

    // Wait Counter Logic
    integer WAIT_COUNTER = 0;
    always@(posedge PCLK, negedge PRESETn) begin
        if (!PRESETn) begin
            WAIT_COUNTER <= 0;
        end
        else if (PSEL && PENABLE) begin
            if(WAIT_COUNTER < WAIT_STATES) begin
                WAIT_COUNTER <= WAIT_COUNTER + 1;
            end
            else begin
                WAIT_COUNTER <= 0;
            end
        end
        else 
            WAIT_COUNTER <= 0;
    end

    // Next State Transfer
    always@(posedge PCLK, negedge PRESETn) begin
        if(!PRESETn) begin
            STATE_REG    <= IDLE;
        end
        else 
            STATE_REG <= NEXT_STATE;    
    end

    // Next state Logic
    always@(*) begin        
        case(STATE_REG)
            IDLE:  
                if(PSEL && !PENABLE) 
                    NEXT_STATE = SETUP;
                else 
                    NEXT_STATE = IDLE;
            SETUP: 
                if(PSEL && PENABLE) 
                    NEXT_STATE = ACCESS;
                else 
                    NEXT_STATE = IDLE;

            ACCESS: begin
                if(PREADY)
                    if(PSEL && !PENABLE) 
                        NEXT_STATE = SETUP;
                    else 
                        NEXT_STATE = IDLE;
                else
                    NEXT_STATE = ACCESS;     
            end 

            default: NEXT_STATE = IDLE;          
        endcase 
    end

    // Write Logic
    always@(posedge PCLK) begin
        if (PSEL && PENABLE && PREADY && PWRITE && address_valid) begin
            if(PSTRB[0])
                REG_FILE[reg_idx][7:0] <= PWDATA[7:0];
            if(PSTRB[1])
                REG_FILE[reg_idx][15:8] <= PWDATA[15:8];
            if(PSTRB[2])
                REG_FILE[reg_idx][23:16] <= PWDATA[23:16];
            if(PSTRB[3])
                REG_FILE[reg_idx][31:24] <= PWDATA[31:24];
            end
    end

    // Read Logic
    always@(*) begin
        PREADY  = 0;
        PRDATA  = 0;
        PSLVERR = 0;
        
        // Setup is in the Condition to take care of the registered behaviour (1 Cycle delay) 
        // of the FSM
        if ((STATE_REG == SETUP || STATE_REG == ACCESS) && PSEL && PENABLE) 
            PREADY = (WAIT_COUNTER >= WAIT_STATES);
            
        if (PSEL && PENABLE) begin
            if (PWRITE) begin
                if (!address_valid && PREADY) begin
                    PSLVERR = 1;
                end
            end
            else begin
                if (address_valid) begin
                    PRDATA = REG_FILE[reg_idx];
                end
                else if (PREADY) begin
                    PSLVERR = 1;
                end
            end
        end
    end
endmodule