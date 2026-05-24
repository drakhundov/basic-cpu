`timescale 1ns / 1ps

module ArithmeticLogicUnitSystemSimulation ();
  reg [2:0] RF_OutASel, RF_OutBSel;
  reg [1:0] RF_FunSel;
  reg [3:0] RF_RegSel, RF_ScrSel;
  reg [3:0] ALU_FunSel;
  reg ALU_WF;
  reg [1:0] ARF_OutCSel, ARF_FunSel;
  reg [2:0] ARF_RegSel;
  reg ARF_OutDSel;
  reg IMU_CS, IMU_LH, DMU_WR, DMU_CS, DMU_FunSel;
  reg [1:0] MuxASel, MuxBSel;
  reg MuxCSel;

  integer test_no;
  wire Z, C, N, O;



  CrystalOscillator clk ();
  ArithmeticLogicUnitSystem ALUSys (
      .RF_OutASel(RF_OutASel),
      .RF_OutBSel(RF_OutBSel),
      .RF_FunSel(RF_FunSel),
      .RF_RegSel(RF_RegSel),
      .RF_ScrSel(RF_ScrSel),
      .ALU_FunSel(ALU_FunSel),
      .ALU_WF(ALU_WF),
      .ARF_OutCSel(ARF_OutCSel),
      .ARF_OutDSel(ARF_OutDSel),
      .ARF_FunSel(ARF_FunSel),
      .ARF_RegSel(ARF_RegSel),
      .IMU_CS(IMU_CS),
      .IMU_LH(IMU_LH),
      .DMU_WR(DMU_WR),
      .DMU_CS(DMU_CS),
      .MuxASel(MuxASel),
      .MuxBSel(MuxBSel),
      .MuxCSel(MuxCSel),
      .Clock(clk.clock),
      .DMU_FunSel(DMU_FunSel)
  );
  FileOperation F ();

  assign {Z, C, N, O} = ALUSys.ALU.FlagsOut;

  task ClearRegisters;
    begin
      ALUSys.RF.R1.Q = 16'h0;
      ALUSys.RF.R2.Q = 16'h0;
      ALUSys.RF.R3.Q = 16'h0;
      ALUSys.RF.R4.Q = 16'h0;
      ALUSys.RF.S1.Q = 16'h0;
      ALUSys.RF.S2.Q = 16'h0;
      ALUSys.RF.S3.Q = 16'h0;
      ALUSys.RF.S4.Q = 16'h0;
      ALUSys.ARF.PC.Q = 16'h0;
      ALUSys.ARF.AR.Q = 16'h0;
      ALUSys.ARF.SP.Q = 16'h0;
      ALUSys.IMU.IR.IROut = 16'h0;
      ALUSys.DMU.DR.DROut = 16'h0;
    end
  endtask

  task SetRegisters;
    input [15:0] value;
    begin
      ALUSys.ARF.PC.Q = value;
      ALUSys.ARF.AR.Q = value;
      ALUSys.ARF.SP.Q = value;
      ALUSys.RF.R1.Q = value;
      ALUSys.RF.R2.Q = value;
      ALUSys.RF.R3.Q = value;
      ALUSys.RF.R4.Q = value;
      ALUSys.RF.S1.Q = value;
      ALUSys.RF.S2.Q = value;
      ALUSys.RF.S3.Q = value;
      ALUSys.RF.S4.Q = value;
      ALUSys.IMU.IR.IROut = value;
      ALUSys.DMU.DR.DROut = value;
    end
  endtask

  task DisableAll;
    begin
      RF_RegSel = 4'b1111;
      RF_ScrSel = 4'b1111;
      ARF_RegSel = 3'b111;
      DMU_CS = 0;
      IMU_CS = 0;
      ALU_WF = 0;
    end
  endtask

  initial begin
    F.SimulationName = "ArithmeticLogicUnitSystem";
    F.InitializeSimulation(0);
    clk.clock = 0;

    //Test 1
    test_no   = 1;
    DisableAll();
    ClearRegisters();
    ALUSys.RF.R1.Q = 16'h7777;
    ALUSys.RF.S2.Q = 16'h8887;
    RF_OutASel = 3'b000;
    RF_OutBSel = 3'b101;
    ALUSys.ALU.FlagsOut = 4'b0000;
    ALU_FunSel = 4'b0101;
    ALU_WF = 1;
    MuxASel = 2'b00;
    MuxBSel = 2'b00;
    MuxCSel = 1'b0;
    RF_RegSel = 4'b1011;
    RF_ScrSel = 4'b1101;
    RF_FunSel = 2'b01;

    ARF_RegSel = 3'b011;
    ARF_FunSel = 2'b01;
    #5;
    F.CheckValues(ALUSys.OutA, 16'h7777, test_no, "OutA");
    F.CheckValues(ALUSys.OutB, 16'h8887, test_no, "OutB");
    F.CheckValues(ALUSys.ALUOut, 16'hFFFE, test_no, "ALUOut");
    F.CheckValues(Z, 0, test_no, "Z");
    F.CheckValues(C, 0, test_no, "C");
    F.CheckValues(N, 0, test_no, "N");
    F.CheckValues(O, 0, test_no, "O");
    F.CheckValues(ALUSys.MuxAOut, 16'hFFFE, test_no, "MuxAOut");
    F.CheckValues(ALUSys.MuxBOut, 16'hFFFE, test_no, "MuxBOut");
    F.CheckValues(ALUSys.MuxCOut, 8'hFE, test_no, "MuxCOut");
    F.CheckValues(ALUSys.RF.R2.Q, 16'h0000, test_no, "R2");
    F.CheckValues(ALUSys.RF.S3.Q, 16'h0000, test_no, "S3");

    clk.Clock();

    //Test 2
    test_no = 2;
    F.CheckValues(ALUSys.OutA, 16'h7777, test_no, "OutA");
    F.CheckValues(ALUSys.OutB, 16'h8887, test_no, "OutB");
    F.CheckValues(ALUSys.ALUOut, 16'hFFFE, test_no, "ALUOut");
    F.CheckValues(Z, 0, test_no, "Z");
    F.CheckValues(C, 0, test_no, "C");
    F.CheckValues(N, 1, test_no, "N");
    F.CheckValues(O, 0, test_no, "O");
    F.CheckValues(ALUSys.MuxAOut, 16'hFFFE, test_no, "MuxAOut");
    F.CheckValues(ALUSys.MuxBOut, 16'hFFFE, test_no, "MuxBOut");
    F.CheckValues(ALUSys.MuxCOut, 8'hFE, test_no, "MuxCOut");
    F.CheckValues(ALUSys.RF.R2.Q, 16'hFFFE, test_no, "R2");
    F.CheckValues(ALUSys.RF.S3.Q, 16'hFFFE, test_no, "S3");
    F.CheckValues(ALUSys.ARF.PC.Q, 16'hFFFE, test_no, "PC");

    //Test 3
    test_no = 3;
    DisableAll();
    ClearRegisters();
    ALUSys.IMU.IM.ROM_DATA[16'h23] = 8'h15;
    ALUSys.ARF.AR.Q = 16'h1254;
    ALUSys.ARF.PC.Q = 16'h0023;
    ARF_OutCSel = 2'b10;
    ARF_OutDSel = 0;
    IMU_CS = 1;
    IMU_LH = 0;
    #5;
    F.CheckValues(ALUSys.OutC, 16'h1254, test_no, "OutC");
    F.CheckValues(ALUSys.OutD, 16'h1254, test_no, "OutD");
    F.CheckValues(ALUSys.OutE, 16'h23, test_no, "OutE");
    F.CheckValues(ALUSys.IMU.IM.MemOut, 8'h15, test_no, "Memout");
    F.CheckValues(ALUSys.IROut, 16'h0000, test_no, "IROut");

    //Test 4
    test_no = 4;
    clk.Clock();
    F.CheckValues(ALUSys.OutC, 16'h1254, test_no, "OutC");
    F.CheckValues(ALUSys.OutD, 16'h1254, test_no, "OutD");
    F.CheckValues(ALUSys.OutE, 16'h23, test_no, "OutE");
    F.CheckValues(ALUSys.IMU.IM.MemOut, 8'h15, test_no, "Memout");
    F.CheckValues(ALUSys.IROut, 16'h0015, test_no, "IROut");

    F.FinishSimulation();
  end
endmodule
