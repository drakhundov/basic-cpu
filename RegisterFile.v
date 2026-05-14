`timescale 1ns / 1ps

module RegisterFile (
    input wire [15:0] I,
    input wire [3:0] RegSel,
    input wire [3:0] ScrSel,
    input wire [1:0] FunSel,
    input wire [2:0] OutASel,
    input wire [2:0] OutBSel,
    input wire Clock,

    output reg [15:0] OutA,
    output reg [15:0] OutB
);

  wire [15:0] R1_out, R2_out, R3_out, R4_out;
  wire [15:0] S1_out, S2_out, S3_out, S4_out;

  reg R1_en, R2_en, R3_en, R4_en;
  reg S1_en, S2_en, S3_en, S4_en;

  Register16bit R1 (
      .Clock(Clock),
      .I(I),
      .E(R1_en),
      .FunSel(FunSel),
      .Q(R1_out)
  );
  Register16bit R2 (
      .Clock(Clock),
      .I(I),
      .E(R2_en),
      .FunSel(FunSel),
      .Q(R2_out)
  );
  Register16bit R3 (
      .Clock(Clock),
      .I(I),
      .E(R3_en),
      .FunSel(FunSel),
      .Q(R3_out)
  );
  Register16bit R4 (
      .Clock(Clock),
      .I(I),
      .E(R4_en),
      .FunSel(FunSel),
      .Q(R4_out)
  );

  Register16bit S1 (
      .Clock(Clock),
      .I(I),
      .E(S1_en),
      .FunSel(FunSel),
      .Q(S1_out)
  );
  Register16bit S2 (
      .Clock(Clock),
      .I(I),
      .E(S2_en),
      .FunSel(FunSel),
      .Q(S2_out)
  );
  Register16bit S3 (
      .Clock(Clock),
      .I(I),
      .E(S3_en),
      .FunSel(FunSel),
      .Q(S3_out)
  );
  Register16bit S4 (
      .Clock(Clock),
      .I(I),
      .E(S4_en),
      .FunSel(FunSel),
      .Q(S4_out)
  );

  always @(*) begin
    // RegSel and ScrSel are active-low.
    // Need to convert to active-high.
    case (RegSel)
      4'b0000: {R1_en, R2_en, R3_en, R4_en} = 4'b1111;
      4'b0001: {R1_en, R2_en, R3_en, R4_en} = 4'b1110;
      4'b0010: {R1_en, R2_en, R3_en, R4_en} = 4'b1101;
      4'b0011: {R1_en, R2_en, R3_en, R4_en} = 4'b1100;
      4'b0100: {R1_en, R2_en, R3_en, R4_en} = 4'b1011;
      4'b0101: {R1_en, R2_en, R3_en, R4_en} = 4'b1010;
      4'b0110: {R1_en, R2_en, R3_en, R4_en} = 4'b1001;
      4'b0111: {R1_en, R2_en, R3_en, R4_en} = 4'b1000;
      4'b1000: {R1_en, R2_en, R3_en, R4_en} = 4'b0111;
      4'b1001: {R1_en, R2_en, R3_en, R4_en} = 4'b0110;
      4'b1010: {R1_en, R2_en, R3_en, R4_en} = 4'b0101;
      4'b1011: {R1_en, R2_en, R3_en, R4_en} = 4'b0100;
      4'b1100: {R1_en, R2_en, R3_en, R4_en} = 4'b0011;
      4'b1101: {R1_en, R2_en, R3_en, R4_en} = 4'b0010;
      4'b1110: {R1_en, R2_en, R3_en, R4_en} = 4'b0001;
      4'b1111: {R1_en, R2_en, R3_en, R4_en} = 4'b0000;
    endcase

    case (ScrSel)
      4'b0000: {S1_en, S2_en, S3_en, S4_en} = 4'b1111;
      4'b0001: {S1_en, S2_en, S3_en, S4_en} = 4'b1110;
      4'b0010: {S1_en, S2_en, S3_en, S4_en} = 4'b1101;
      4'b0011: {S1_en, S2_en, S3_en, S4_en} = 4'b1100;
      4'b0100: {S1_en, S2_en, S3_en, S4_en} = 4'b1011;
      4'b0101: {S1_en, S2_en, S3_en, S4_en} = 4'b1010;
      4'b0110: {S1_en, S2_en, S3_en, S4_en} = 4'b1001;
      4'b0111: {S1_en, S2_en, S3_en, S4_en} = 4'b1000;
      4'b1000: {S1_en, S2_en, S3_en, S4_en} = 4'b0111;
      4'b1001: {S1_en, S2_en, S3_en, S4_en} = 4'b0110;
      4'b1010: {S1_en, S2_en, S3_en, S4_en} = 4'b0101;
      4'b1011: {S1_en, S2_en, S3_en, S4_en} = 4'b0100;
      4'b1100: {S1_en, S2_en, S3_en, S4_en} = 4'b0011;
      4'b1101: {S1_en, S2_en, S3_en, S4_en} = 4'b0010;
      4'b1110: {S1_en, S2_en, S3_en, S4_en} = 4'b0001;
      4'b1111: {S1_en, S2_en, S3_en, S4_en} = 4'b0000;
    endcase

    case (OutASel)
      3'b000: OutA = R1_out;
      3'b001: OutA = R2_out;
      3'b010: OutA = R3_out;
      3'b011: OutA = R4_out;
      3'b100: OutA = S1_out;
      3'b101: OutA = S2_out;
      3'b110: OutA = S3_out;
      3'b111: OutA = S4_out;
    endcase
    case (OutBSel)
      3'b000: OutB = R1_out;
      3'b001: OutB = R2_out;
      3'b010: OutB = R3_out;
      3'b011: OutB = R4_out;
      3'b100: OutB = S1_out;
      3'b101: OutB = S2_out;
      3'b110: OutB = S3_out;
      3'b111: OutB = S4_out;
    endcase
  end
endmodule
