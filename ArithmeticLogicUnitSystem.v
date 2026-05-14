`timescale 1ns / 1ps

module ArithmeticLogicUnitSystem (
    input wire Clock,

    input wire [1:0] MuxASel,
    input wire [1:0] MuxBSel,
    input wire MuxCSel,

    input wire [3:0] RF_RegSel,
    input wire [3:0] RF_ScrSel,
    input wire [1:0] RF_FunSel,
    input wire [2:0] RF_OutASel,
    input wire [2:0] RF_OutBSel,

    input wire [2:0] ARF_RegSel,
    input wire [1:0] ARF_FunSel,
    input wire [1:0] ARF_OutCSel,
    input wire ARF_OutDSel,

    input wire ALU_WF,
    input wire [3:0] ALU_FunSel,

    input wire DMU_WR,
    input wire DMU_FunSel,
    input wire DMU_CS,

    input wire IMU_LH,
    input wire IMU_CS,

    output wire [15:0] ALUOut,
    output wire [ 3:0] FlagsOut,
    output wire [15:0] IROut,
    output wire [15:0] IMUOut
);

  wire [15:0] OutA, OutB;
  wire [15:0] OutC, OutD, OutE;
  wire [15:0] DMUOut;
  wire [15:0] MuxAOut;
  wire [15:0] MuxBOut;
  wire [ 7:0] MuxCOut;

  RegisterFile RF (
      .Clock(Clock),
      .I(MuxAOut),
      .RegSel(RF_RegSel),
      .ScrSel(RF_ScrSel),
      .FunSel(RF_FunSel),
      .OutASel(RF_OutASel),
      .OutBSel(RF_OutBSel),
      .OutA(OutA),
      .OutB(OutB)
  );

  AddressRegisterFile ARF (
      .Clock(Clock),
      .I(MuxBOut),
      .RegSel(ARF_RegSel),
      .FunSel(ARF_FunSel),
      .OutCSel(ARF_OutCSel),
      .OutDSel(ARF_OutDSel),
      .OutC(OutC),
      .OutD(OutD),
      .OutE(OutE)
  );

  ArithmeticLogicUnit ALU (
      .A(OutA),
      .B(OutB),
      .FunSel(ALU_FunSel),
      .ALUOut(ALUOut),
      .FlagsOut(FlagsOut),
      .WF(ALU_WF),
      .Clock(Clock)
  );

  DataMemoryUnit DMU (
      .Clock(Clock),
      .FunSel(DMU_FunSel),
      .WR(DMU_WR),
      .CS(DMU_CS),
      .Address(OutD),
      .I(MuxCOut),
      .DMUOut(DMUOut)
  );

  InstructionMemoryUnit IMU (
      .Clock(Clock),
      .CS(IMU_CS),
      .LH(IMU_LH),
      .Address(OutE),
      .IMUOut(IMUOut),
      .IROut(IROut)
  );

  assign MuxAOut = (MuxASel==2'b00) ? ALUOut :
                     (MuxASel==2'b01) ? OutC :
                     (MuxASel==2'b10) ? DMUOut : IMUOut;

  assign MuxBOut = (MuxBSel==2'b00) ? ALUOut :
                     (MuxBSel==2'b01) ? OutC :
                     (MuxBSel==2'b10) ? DMUOut : IMUOut;

  assign MuxCOut = MuxCSel ? ALUOut[15:8] : ALUOut[7:0];

endmodule
