`timescale 1ns / 1ps

module DataMemoryUnit (
    input wire Clock,
    input wire [15:0] Address,
    input wire [7:0] I,
    input wire WR,
    input wire CS,
    input wire FunSel,

    output wire [15:0] DMUOut
);

  wire [7:0] MemOut;

  DataMemory DM (
      .Address(Address),
      .Data(I),
      .WR(WR),
      .CS(~CS),
      .Clock(Clock),
      .MemOut(MemOut)
  );

  DataRegister DR (
      .Clock(Clock),
      .I(MemOut),
      .E(CS),
      .FunSel(FunSel),
      .DROut(DMUOut)
  );
endmodule
