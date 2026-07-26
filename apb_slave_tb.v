module apb_slave_tb;
    reg         PCLK;
    reg         PRESETn;
    reg         PSEL;
    reg         PENABLE;
    reg         PWRITE;
    reg  [31:0] PADDR;
    reg  [31:0] PWDATA;
    reg  [3:0]  PSTRB;

    wire [31:0] PRDATA;
    wire        PREADY;
    wire        PSLVERR;

    apb_slave #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .NUM_REGS(16),
        .WAIT_STATES(0) 
    ) dut (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PSTRB(PSTRB),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR)
    );

    initial begin
        PCLK = 0;
        forever #5 PCLK = ~PCLK;
    end

    initial begin
        PSEL    = 0;
        PENABLE = 0;
        PWRITE  = 0;
        PADDR   = 32'h0;
        PWDATA  = 32'h0;
        PSTRB   = 4'b0000;
        PRESETn = 0;
        
        #15;
        PRESETn = 1;
        $readmemh("regfile_init.dat", dut.REG_FILE);

        @(posedge PCLK);

        // =====================================================================
        // Transaction 0: Read from 0x0
        // =====================================================================
        
        // SETUP Phase
        PSEL    = 1;
        PWRITE  = 0;
        PENABLE = 0;
        PADDR   = 32'h0;
        PSTRB   = 4'b0000;
        @(posedge PCLK);

        // ACCESS Phase
        PENABLE = 1;
        wait(PREADY);
        @(posedge PCLK);


        // =====================================================================
        // Transaction 1: Write 0x000000EF to 0x0 (Strobe: 4'b0001)
        // =====================================================================
        
        // SETUP Phase
        PSEL    = 1;
        PWRITE  = 1;
        PENABLE = 0;
        PADDR   = 32'h0;
        PSTRB   = 4'b0001;
        PWDATA  = 32'h000000EF;
        @(posedge PCLK);

        // ACCESS Phase
        PENABLE = 1;
        wait(PREADY); 
        @(posedge PCLK);

        // =====================================================================
        // Transaction 2: Write 0x0000BE00 to 0x0 (Strobe: 4'b0010)
        // =====================================================================
        
        // SETUP Phase
        PSEL    = 1;
        PWRITE  = 1;
        PENABLE = 0;
        PADDR   = 32'h0;
        PSTRB   = 4'b0010;
        PWDATA  = 32'h0000BE00;
        @(posedge PCLK);

        // ACCESS Phase
        PENABLE = 1;
        wait(PREADY);
        @(posedge PCLK);

        // =====================================================================
        // Transaction 3: Write 0xDEAD0000 to 0x0 (Strobe: 4'b1100)
        // =====================================================================
        
        // SETUP Phase
        PSEL    = 1;
        PWRITE  = 1;
        PENABLE = 0;
        PADDR   = 32'h0;
        PSTRB   = 4'b1100;
        PWDATA  = 32'hDEAD0000;
        @(posedge PCLK);

        // ACCESS Phase
        
        PENABLE = 1;
        wait(PREADY);
        @(posedge PCLK);

        // =====================================================================
        // Transaction 4: Read from 0x0
        // =====================================================================
        
        // SETUP Phase
        PSEL    = 1;
        PWRITE  = 0;
        PENABLE = 0;
        PADDR   = 32'h0;
        PSTRB   = 4'b0000;
        @(posedge PCLK);

        // ACCESS Phase
        PENABLE = 1;
        wait(PREADY);
        @(posedge PCLK);

        // =====================================================================
        // Transaction 5: Read from 0x8
        // =====================================================================
        
        // SETUP Phase
        PSEL    = 1;
        PWRITE  = 0;
        PENABLE = 0;
        PADDR   = 32'h8;
        PSTRB   = 4'b0000;
        @(posedge PCLK);

        // ACCESS Phase
        PENABLE = 1;
        wait(PREADY);
        @(posedge PCLK);

        // =====================================================================
        // Return to IDLE
        // =====================================================================
        
        PSEL    = 0;
        PENABLE = 0;
        PWRITE  = 0;

        #30;
        $stop;
    end

endmodule