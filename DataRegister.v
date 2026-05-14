`timescale 1ns / 1ps

module DataRegister (
    input [7:0] I,
    input Clock,
    input E,
    input FunSel,

    output reg [15:0] DROut
);

  always @(posedge Clock) begin
    if (E) begin
      if (FunSel == 0) begin
        DROut[7:0] <= I;
      end else begin
        DROut[15:8] <= I;
      end
    end
  end
endmodule
