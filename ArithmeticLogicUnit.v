`timescale 1ns / 1ps

module ArithmeticLogicUnit (
    input wire [15:0] A,
    input wire [15:0] B,
    input wire [3:0] FunSel,
    input wire WF,
    input wire Clock,
    output wire [15:0] ALUOut,
    output reg [3:0] FlagsOut = 0
);
  reg [16:0] result17;
  reg [15:0] result16;

  reg C, O;
  wire Z, N;

  assign Z = result16 == 0;
  assign N = result16[15];
  assign ALUOut = result16;

  always @(*) begin
    case (FunSel)
      4'b0000: begin  // A
        result17 = A;
        result16 = A;
      end

      4'b0001: begin  // B
        result17 = B;
        result16 = B;
      end

      4'b0010: begin  // NOT A
        result17 = ~A;
        result16 = ~A;
      end

      4'b0011: begin  // NOT B
        result17 = ~B;
        result16 = ~B;
      end

      4'b0100: begin  // ADD A, B
        result17 = A + B;
        result16 = A + B;

        C = result17[16];
        O = (A[15] == B[15]) && (result16[15] != A[15]);
      end

      4'b0101: begin  // ADD A, B, Carry
        result17 = A + B + FlagsOut[2];
        result16 = A + B + FlagsOut[2];

        C = result17[16];
        O = (A[15] == B[15]) && (result16[15] != A[15]);
      end

      4'b0110: begin  // SUB A, B
        result17 = A - B;
        result16 = A - B;

        C = result17[16];
        O = (A[15] != B[15]) && (result16[15] != A[15]);
      end

      4'b0111: begin  // A AND B
        result17 = A & B;
        result16 = A & B;
      end

      4'b1000: begin  // A OR B
        result17 = A | B;
        result16 = A | B;
      end

      4'b1001: begin  // A XOR B
        result17 = A ^ B;
        result16 = A ^ B;
      end

      4'b1010: begin  // A NAND B
        result17 = ~(A & B);
        result16 = ~(A & B);
      end

      4'b1011: begin  // LSL A
        result17 = {A[14:0], 1'b0};
        result16 = {A[14:0], 1'b0};

        C = A[15];
      end

      4'b1100: begin  // LSR A
        result17 = {1'b0, A[15:1]};
        result16 = {1'b0, A[15:1]};

        C = A[0];
      end

      4'b1101: begin  // ASR A
        result17 = {A[15], A[15:1]};
        result16 = {A[15], A[15:1]};
      end

      4'b1110: begin  // CSL A
        result17 = {A[14:0], FlagsOut[2]};
        result16 = {A[14:0], FlagsOut[2]};

        C = A[15];
      end

      4'b1111: begin  // CSR A
        result17 = {FlagsOut[2], A[15:1]};
        result16 = {FlagsOut[2], A[15:1]};

        C = A[0];
      end
    endcase
  end

  always @(posedge Clock) begin
    if (WF == 1) begin
      FlagsOut[3] <= Z;

      if (FunSel != 4'b1101) FlagsOut[1] <= N;

      if (FunSel == 4'b1011 || FunSel == 4'b1100 || FunSel == 4'b1110 || FunSel == 4'b1111)
        FlagsOut[2] <= C;

      if (4'b0100 <= FunSel && FunSel <= 4'b0110) begin
        FlagsOut[2] <= C;
        FlagsOut[0] <= O;
      end
    end
  end
endmodule
