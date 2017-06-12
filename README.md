This is based on the xillybus demo code for the Kintex-7 board.  It follows the recommendations for capturing data from the documentation [1], and uses an asynchronous FIFO.

Currently, the FPGA generates simple events of the following structure:

    Offset(h) 00 01 02 03 04 05 06 07

    00000000  AA AA AA AA 02 00 00 00  ªªªª....
    00000008  04 00 00 00 06 00 00 00  ........
    00000010  08 00 00 00 0A 00 00 00  ........
    00000018  0C 00 00 00 0E 00 00 00  ........
    00000020  10 00 00 00 12 00 00 00  ........
    00000028  14 00 00 00 16 00 00 00  ........
    00000030  18 00 00 00 1A 00 00 00  ........
    00000038  1C 00 00 00 1E 00 00 00  ........
    00000040  20 00 00 00 22 00 00 00   ..."...
    00000048  24 00 00 00 26 00 00 00  $...&...
    00000050  28 00 00 00 2A 00 00 00  (...*...
    00000058  2C 00 00 00 2E 00 00 00  ,.......
    00000060  30 00 00 00 F0 F0 F0 F0  0...ðððð

That is, `0xAAAAAAAA` as a header and `0xF0F0F0F0` as a tail, and inbetween 96 bytes of dummy data.  (The reason for using a 4-byte header is only that it was much easier to implement, as the FIFO is 4 bytes wide.  Every cycle, we transmit either header, tail, or one word (4 bytes) of data (here a counter).  If the header was shorter, we would have to transmit e.g. the header and three bytes of the counter, then the remaining byte and three bytes of the next counter, and so on.)

Previously, I tried a non-async version, as in the demo bundle, however it often lost data (skipped part of events), so I think the async FIFO is the way to go.

## Usage

Open Vivado, select "Tools/Run TCL Script", and open `verilog/xillydemo-vivado.tcl`.  Now this should generate a Vivado project for you.  Then you should be able to just generate a bitstream.

[1]: http://xillybus.com/downloads/doc/xillybus_fpga_api.pdf