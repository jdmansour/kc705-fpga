`include "juxd/ClockDividerInteger.v"
module xillydemo
(
  input        PCIE_PERST_B_LS,
  input        PCIE_REFCLK_N,
  input        PCIE_REFCLK_P,
  input  [7:0] PCIE_RX_N,
  input  [7:0] PCIE_RX_P,
  output [3:0] GPIO_LED,
  output [7:0] PCIE_TX_N,
  output [7:0] PCIE_TX_P,
  output wire GPIO_LED_6 /* Signal light for reading data */
);

  // Clock and quiesce
  wire bus_clk;
  wire quiesce;
  
  // Memory array
  reg [7:0] demoarray[0:31];
  
  // Wires related to /dev/xillybus_mem_8
  wire       user_r_mem_8_rden;
  wire       user_r_mem_8_empty;
  reg  [7:0] user_r_mem_8_data;
  wire       user_r_mem_8_eof;
  wire       user_r_mem_8_open;
  wire       user_w_mem_8_wren;
  wire       user_w_mem_8_full;
  wire [7:0] user_w_mem_8_data;
  wire       user_w_mem_8_open;
  wire [4:0] user_mem_8_addr;
  wire       user_mem_8_addr_update;

  // Wires related to /dev/xillybus_read_32
  wire        user_r_read_32_rden;
  wire        user_r_read_32_empty;
  wire [31:0] user_r_read_32_data;
  wire        user_r_read_32_eof;
  wire        user_r_read_32_open;

  // Wires related to /dev/xillybus_read_8
  wire       user_r_read_8_rden;
  wire       user_r_read_8_empty;
  wire [7:0] user_r_read_8_data;
  wire       user_r_read_8_eof;
  wire       user_r_read_8_open;

  // Wires related to /dev/xillybus_write_32
  wire        user_w_write_32_wren;
  wire        user_w_write_32_full;
  wire [31:0] user_w_write_32_data;
  wire        user_w_write_32_open;

  // Wires related to /dev/xillybus_write_8
  wire       user_w_write_8_wren;
  wire       user_w_write_8_full;
  wire [7:0] user_w_write_8_data;
  wire       user_w_write_8_open;

  // Wires and registers related to data capturing
  wire        capture_clk;
  // reg [31:0]  capture_data;
  wire        capture_en;
  // reg [4:0]   slowdown;
  reg [1:0]   slowdown;
  wire        capture_full;

  reg 	       capture_open;
  reg 	       capture_open_cross;
  reg 	       capture_has_been_full;
  reg 	       capture_has_been_nonfull;
  reg 	       has_been_full_cross;
  reg 	       has_been_full;

  // =====================================
  // juxd
  // -------------------------------------
  // Parameter assert
  // -------------------------------------
  // Parameter : Signal light for reading data
//  wire GPIO_LED_6;
  reg  DAQ_LED_data_read = 1'b0; // Signal light : read data from FPGA
  reg  DAQ_LED_cfg_write = 1'b0; // Signal light : configure FPGA

  // -------------------------------------
  // Parameter : DAQ configure
  wire [7:0] DAQ_cfg_write_0; // Configure value write to mem : 8'b
  reg  [7:0] DAQ_flag_cfg_start  = 8'b11111111; // Configure flag : start 255
  reg  [7:0] DAQ_flag_cfg_reset  = 8'b11000000; // Configure flag : reset 192
  reg  [7:0] DAQ_flag_cfg_close  = 8'b11000111; // Configure flag : close 199
  reg        DAQ_flag_data_start = 1'b0;
  reg        DAQ_flag_data_reset = 1'b0;
  reg        DAQ_flag_data_close = 1'b0;

  // -------------------------------------
  // Parameter : test data
  // Test data
  // wire
  wire [31:0] tst_data_in;
  wire        tst_data_wren;
  wire        tst_flag_data_wren;
  wire        tst_data_reset;
  wire        tst_data_rden;
  // register
  // reg  [ 1:0] tst_clock_slow;
  reg  [ 7:0] tst_data_counter  = 8'b0;
  reg  [16:0] tst_data_row      = 16'b0;
  reg  [31:0] tst_data_out      = 32'b0;
  // reg         tst_flag_data_raw = 1'b0;

  // -------------------------------------
  //// Clock divider
  //wire DAQ_clock;
  //wire DAQ_reset;
  //wire DAQ_clock_divide;
  //assign DAQ_clock_divide = 3;
  //ClockDividerInteger clock_divide_3(.clock_o(DAQ_clock),
  //                                   .clock_i(bus_clk),
  //                                   .reset(DAQ_reset),
  //                                   .F_DIV(DAQ_clock_divide));

  // juxd
  // =====================================

  // Xillybus IP instantiate
  xillybus xillybus_ins 
  (
    // Ports related to /dev/xillybus_mem_8
    // FPGA to CPU signals:
    .user_r_mem_8_rden  ( user_r_mem_8_rden  ),
    .user_r_mem_8_empty ( user_r_mem_8_empty ),
    .user_r_mem_8_data  ( user_r_mem_8_data  ),
    .user_r_mem_8_eof   ( user_r_mem_8_eof   ),
    .user_r_mem_8_open  ( user_r_mem_8_open  ),
    
    // CPU to FPGA signals:
    .user_w_mem_8_wren ( user_w_mem_8_wren ),
    .user_w_mem_8_full ( user_w_mem_8_full ),
    .user_w_mem_8_data ( user_w_mem_8_data ),
    .user_w_mem_8_open ( user_w_mem_8_open ),
    
    // Address signals:
    .user_mem_8_addr        ( user_mem_8_addr        ),
    .user_mem_8_addr_update ( user_mem_8_addr_update ),
    
    // Ports related to /dev/xillybus_read_32
    // FPGA to CPU signals:
    .user_r_read_32_rden  ( user_r_read_32_rden  ),
    .user_r_read_32_empty ( user_r_read_32_empty ),
    .user_r_read_32_data  ( user_r_read_32_data  ),
    .user_r_read_32_eof   ( user_r_read_32_eof   ),
    .user_r_read_32_open  ( user_r_read_32_open  ),
    
    // Ports related to /dev/xillybus_write_32
    // CPU to FPGA signals:
    .user_w_write_32_wren ( user_w_write_32_wren ),
    .user_w_write_32_full ( user_w_write_32_full ),
    .user_w_write_32_data ( user_w_write_32_data ),
    .user_w_write_32_open ( user_w_write_32_open ),
    
    // Ports related to /dev/xillybus_read_8
    // FPGA to CPU signals:
    .user_r_read_8_rden  ( user_r_read_8_rden  ),
    .user_r_read_8_empty ( user_r_read_8_empty ),
    .user_r_read_8_data  ( user_r_read_8_data  ),
    .user_r_read_8_eof   ( user_r_read_8_eof   ),
    .user_r_read_8_open  ( user_r_read_8_open  ),
    
    // Ports related to /dev/xillybus_write_8
    // CPU to FPGA signals:
    .user_w_write_8_wren ( user_w_write_8_wren ),
    .user_w_write_8_full ( user_w_write_8_full ),
    .user_w_write_8_data ( user_w_write_8_data ),
    .user_w_write_8_open ( user_w_write_8_open ),
    
    // Signals to top level
    .PCIE_PERST_B_LS ( PCIE_PERST_B_LS ),
    .PCIE_REFCLK_N   ( PCIE_REFCLK_N   ),
    .PCIE_REFCLK_P   ( PCIE_REFCLK_P   ),
    .PCIE_RX_N       ( PCIE_RX_N       ),
    .PCIE_RX_P       ( PCIE_RX_P       ),
    .GPIO_LED        ( GPIO_LED        ),
    .PCIE_TX_N       ( PCIE_TX_N       ),
    .PCIE_TX_P       ( PCIE_TX_P       ),
    .bus_clk         ( bus_clk         ),
    .quiesce         ( quiesce         )
  );


  // Data capture section
  // ====================

  always @(posedge capture_clk)
    begin
      if (capture_en)
        begin
          // capture_data <= capture_data + 1; // Bogus data source

          // counts the 4-byte word we are in
          // tst_data_counter  = (tst_data_counter == 25) ? 0 : (tst_data_counter + 1);
          
          case (tst_data_counter) 
            0 :
              begin
                // head
                tst_data_out <= 32'hAAAAAAAA;
                // reset row counter
                tst_data_row <= 0;
                tst_data_counter <= tst_data_counter + 1;
              end

            25 :
              begin
                // tail
                tst_data_out <= 32'hF0F0F0F0;
                tst_data_row <= 0;
                tst_data_counter <= 0;
              end

            default :
              begin
                
                // tst_data_out  <= (tst_data_row-1) << 8 + tst_data_row;
                tst_data_out  <= {tst_data_row+1, tst_data_row+2};
                tst_data_row  <= tst_data_row + 2;
                tst_data_counter <= tst_data_counter + 1;
              end
          endcase

          // tst_flag_data_raw <= 1;
          DAQ_LED_data_read <= 1;

        end
      else
        begin
          // tst_flag_data_raw <= 0;
          DAQ_LED_data_read <= 0;
        end
      
      // The slowdown register limits the data pace to 1/32 the bus_clk
      // when capture_clk = bus_clk. This is necessary, because the
      // core in the evaluation kit is configured for simplicity, and
      // not for performance. Sustained data rates of 200 MB/sec are
      // easily reached with performance-oriented setting.
      // The slowdown register has no function in a real-life application.
      // slowdown <= slowdown + 1;
      slowdown <= 0;

      // capture_has_been_full remembers that the FIFO has been full
      // until the file is closed. capture_has_been_nonfull prevents
      // capture_has_been_full to respond to the initial full condition
      // every FIFO displays on reset.

      if (!capture_full)
        capture_has_been_nonfull <= 1;
      else if (!capture_open)
        capture_has_been_nonfull <= 0;
      
      if (capture_full && capture_has_been_nonfull)
        capture_has_been_full <= 1;
      else if (!capture_open)
        capture_has_been_full <= 0;
        
    end

  // The dependency on slowdown is only for bogus data
  assign capture_en = capture_open && !capture_full && 
          !capture_has_been_full &&
          (slowdown == 0);
  // assign capture_en = capture_open && !capture_full && 
  //         !capture_has_been_full;      

   // Clock crossing logic: bus_clk -> capture_clk
  always @(posedge capture_clk)
    begin
      capture_open_cross <= user_r_read_32_open;
      capture_open <= capture_open_cross;
    end

   // Clock crossing logic: capture_clk -> bus_clk
  always @(posedge bus_clk)
    begin
      has_been_full_cross <= capture_has_been_full;
      has_been_full <= has_been_full_cross;
    end

 
   // The user_r_read_32_eof signal is required to go from '0' to '1' only on
   // a clock cycle following an asserted read enable, according to Xillybus'
   // core API. This is assured, since it's a logical AND between
   // user_r_read_32_empty and has_been_full. has_been_full goes high when the
   // FIFO is full, so it's guaranteed that user_r_read_32_empty is low when
   // that happens. On the other hand, user_r_read_32_empty is a FIFO's empty
   // signal, which naturally meets the requirement.
   
   assign user_r_read_32_eof = user_r_read_32_empty && has_been_full;
   assign user_w_write_32_full = 0;
   
   // The data capture clock here is bus_clk for simplicity, but clock domain
   // crossing is done properly, so capture_clk can be an independent clock
   // without any other changes.
   
   assign capture_clk = bus_clk;
   
   async_fifo_32 fifo_32 
   //fifo_32x512  fifo_32
     (
      .rst(!user_r_read_32_open),
      .wr_clk(capture_clk),
      .rd_clk(bus_clk),
      .din(tst_data_out),
      .wr_en(capture_en),
      .rd_en(user_r_read_32_rden),
      .dout(user_r_read_32_data),
      .full(capture_full),
      .empty(user_r_read_32_empty)
      );


  // A simple inferred RAM
  always @(posedge bus_clk)
    begin
	    if (user_w_mem_8_wren)
	      demoarray[user_mem_8_addr] <= user_w_mem_8_data;
	    
	    if (user_r_mem_8_rden)
	      user_r_mem_8_data <= demoarray[user_mem_8_addr];	  
    end

  assign user_r_mem_8_empty = 0;
  assign user_r_mem_8_eof   = 0;
  assign user_w_mem_8_full  = 0;

  // // =====================================
  // // juxd
  // // -------------------------------------
  // // DAQ configure
  // // -------------------------------------
  // // Configure information write to mem8X32
  // assign DAQ_cfg_write_0 = demoarray[0][7:0];

  // // Compare FPGA configure with set DAQ register
  // always @(posedge bus_clk)
  //   begin
  //     case (DAQ_cfg_write_0)
  //       DAQ_flag_cfg_start : 
  //         begin
  //           DAQ_flag_data_start <= 1'b1;
  //           DAQ_flag_data_reset <= 1'b0;
  //           DAQ_flag_data_close <= 1'b0;
  //         end
  //       DAQ_flag_cfg_reset : 
  //         begin
  //           DAQ_flag_data_start <= 1'b0;
  //           DAQ_flag_data_reset <= 1'b1;
  //           DAQ_flag_data_close <= 1'b0;
  //         end
  //       DAQ_flag_cfg_close : 
  //         begin
  //           DAQ_flag_data_start <= 1'b0;
  //           DAQ_flag_data_reset <= 1'b0;
  //           DAQ_flag_data_close <= 1'b1;
  //         end
  //       default :  
  //         begin
  //           DAQ_flag_data_start <= 1'b0;
  //           DAQ_flag_data_reset <= 1'b0;
  //           DAQ_flag_data_close <= 1'b0;
  //         end
  //     endcase
  //   end

  // // DAQ start
  // // assign tst_flag_data_wren = DAQ_flag_data_start && (tst_clock_slow==0);
  // assign tst_flag_data_wren = DAQ_flag_data_start;

  // // DAQ reset

  // // -------------------------------------

  // // -------------------------------------
  // // Generate test data 
  // // -------------------------------------
  // always @(posedge bus_clk)
  // //always @(posedge DAQ_clock)
  //   begin
      
  //     if (tst_flag_data_wren)
  //       begin 

  //         // counts the 4-byte word we are in
  //         // tst_data_counter  = (tst_data_counter == 25) ? 0 : (tst_data_counter + 1);
          

  //         case (tst_data_counter) 
  //           0 :
  //             begin
  //               // head
  //               tst_data_out <= 32'hAAAAAAAA;
  //               // reset row counter
  //               tst_data_raw <= 0;
  //               tst_data_counter <= tst_data_counter + 1;
  //             end

  //           25 :
  //             begin
  //               // tail
  //               tst_data_out <= 32'hF0F0F0F0;
  //               tst_data_raw <= 0;
  //               tst_data_counter <= 0;
  //             end

  //           default :
  //             begin
                
  //               // tst_data_out  <= (tst_data_raw-1) << 8 + tst_data_raw;
  //               tst_data_out  <= {tst_data_raw+1, tst_data_raw+2};
  //               tst_data_raw  <= tst_data_raw + 2;
  //               tst_data_counter <= tst_data_counter + 1;
  //             end
  //         endcase

          
  //         // tst_data_out      <= (tst_data_counter == 0) ? 32'hAAAAAAAA :
  //         //                      ((tst_data_counter == 25) ? 32'hF0F0F0F0 :
  //         //                      tst_data_raw);
  //         tst_flag_data_raw <= 1;
  //         DAQ_LED_data_read <= 1;
  //       end
  //     else // (!tst_flag_data_wren)
  //       begin
  //         tst_data_raw      <= 32'hDEADBEEF;
  //         tst_data_out      <= tst_data_raw;
  //         tst_flag_data_raw <= 0;
  //         DAQ_LED_data_read <= 0;
  //       end // (!tst_flag_data_wren)

  //     tst_clock_slow <= tst_clock_slow + 1;
  //   end // always

  // assign GPIO_LED_6     = DAQ_LED_data_read;
  // assign tst_data_reset = DAQ_flag_data_reset;
  // assign tst_data_wren  = tst_flag_data_wren;
  // assign tst_data_rden  = tst_flag_data_raw;
  // assign tst_data_in    = tst_data_out;
  
  // 8-bit loopback
  fifo_8x2048 fifo_8
  (
    .clk   ( bus_clk                                     ),
    .srst  ( !user_w_write_8_open && !user_r_read_8_open ),
    .din   ( user_w_write_8_data                         ),
    .wr_en ( user_w_write_8_wren                         ),
    .rd_en ( user_r_read_8_rden                          ),
    .dout  ( user_r_read_8_data                          ),
    .full  ( user_w_write_8_full                         ),
    .empty ( user_r_read_8_empty                         )
  );

  assign user_r_read_8_eof = 0;
  
endmodule
