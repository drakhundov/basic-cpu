`timescale 1ns / 1ps

module DataMemory (
    input wire [15:0] Address,
    input wire [7:0] Data,
    input wire WR,  // Read = 0, Write = 1
    input wire CS,  // Chip is enabled when cs = 0
    input wire Clock,
    output reg [7:0] MemOut  // Output
);
  // Declaration of the RAM Area
  reg [7:0] RAM_DATA[0:65535];
  // Read Ram data from the file
  initial $readmemh("RAM.mem", RAM_DATA);
  // Read the selected data from RAM
  always @(*) begin
    MemOut = ~WR && ~CS ? RAM_DATA[Address] : 8'hZ;
  end

  // Write the data to RAM
  always @(posedge Clock) begin
    if (WR && ~CS) begin
      RAM_DATA[Address] = Data;
    end
  end
endmodule
