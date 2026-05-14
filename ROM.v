module ReadOnlyMemory (
    input wire [15:0] Address,
    input wire CS,
    output reg [7:0] MemOut
);

  reg [7:0] ROM_DATA[0:65535];
  initial $readmemh("ROM.mem", ROM_DATA);

  always @(*) begin
    MemOut = CS ? ROM_DATA[Address] : 8'hz;
  end
endmodule
