`timescale 1ns / 1ps

module InstructionMemoryUnit (
    input wire Clock,
    input wire [15:0] Address,
    input wire CS,
    input wire LH,

    output wire [15:0] IROut,
    output wire [15:0] IMUOut  // LSB of IROut.
);
  wire [7:0] MemOut;

  ReadOnlyMemory IM (
      .Address(Address),
      .CS(CS),
      .MemOut(MemOut)
  );

  InstructionRegister IR (
      .I(MemOut),
      .Clock(Clock),
      .LH(LH),
      .Write(CS),
      .IROut(IROut)
  );

  // Represents address.
  assign IMUOut = {8'b0, IROut[7:0]};
endmodule
