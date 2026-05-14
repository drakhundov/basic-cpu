`timescale 1ns / 1ps

module Register16bit (
    input [15:0] I,
    input E,
    input Clock,
    input [1:0] FunSel,
    output reg [15:0] Q
);

  always @(posedge Clock) begin
    if (E == 1'b0) begin
    end else begin
      case (FunSel)
        2'b00:   Q <= 16'b0;  // Clear
        2'b01:   Q <= I;  // Load
        2'b10:   Q <= Q + 1'b1;  // Incr.
        2'b11:   Q <= Q - 1'b1;  // Decr.
        default: Q <= Q;
      endcase
    end
  end
endmodule
