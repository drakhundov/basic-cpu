`timescale 1ns / 1ps

module AddressRegisterFile (
    input wire [15:0] I,
    input wire [2:0] RegSel,
    input wire [1:0] FunSel,
    input wire [1:0] OutCSel,
    input wire OutDSel,
    input wire Clock,

    output reg  [15:0] OutC,
    output reg  [15:0] OutD,
    output wire [15:0] OutE
);

  wire [15:0] PC_out, AR_out, SP_out;
  reg PC_en, AR_en, SP_en;

  Register16bit PC (
      .Clock(Clock),
      .I(I),
      .E(PC_en),
      .FunSel(FunSel),
      .Q(PC_out)
  );
  Register16bit AR (
      .Clock(Clock),
      .I(I),
      .E(AR_en),
      .FunSel(FunSel),
      .Q(AR_out)
  );
  Register16bit SP (
      .Clock(Clock),
      .I(I),
      .E(SP_en),
      .FunSel(FunSel),
      .Q(SP_out)
  );

  assign OutE = PC_out;

  always @(*) begin
    case (RegSel)
      3'b000: {PC_en, SP_en, AR_en} = 3'b111;
      3'b001: {PC_en, SP_en, AR_en} = 3'b110;
      3'b010: {PC_en, SP_en, AR_en} = 3'b101;
      3'b011: {PC_en, SP_en, AR_en} = 3'b100;
      3'b100: {PC_en, SP_en, AR_en} = 3'b011;
      3'b101: {PC_en, SP_en, AR_en} = 3'b010;
      3'b110: {PC_en, SP_en, AR_en} = 3'b001;
      3'b111: {PC_en, SP_en, AR_en} = 3'b000;
    endcase

    case (OutCSel)
      2'b00: OutC = PC_out;
      2'b01: OutC = PC_out;
      2'b10: OutC = AR_out;
      2'b11: OutC = SP_out;
    endcase

    case (OutDSel)
      1'b0: OutD = AR_out;
      1'b1: OutD = SP_out;
    endcase
  end
endmodule
