`timescale 1ns / 1ps

module CPUSystemSimulation ();
  wire [11:0] T;
  integer test_no;
  integer clock_count;
  wire clock;
  wire reset;

  wire [5:0] OPC;
  wire [1:0] RSEL;
  wire [7:0] ADDR;
  wire [2:0] DSTREG;
  wire [2:0] SREG1;
  wire [2:0] SREG2;

  CrystalOscillator clk ();
  ResetGenerator rg ();

  CPUSystem CPUSys (
      .Clock(clk.clock),
      .Reset(rg.reset),
      .T(T)
  );
  FileOperation F ();

  assign clock = clk.clock;
  assign reset = rg.reset;

  task ClearRegisters;
    begin
      clock_count = 0;
      CPUSys.ALUSys.RF.R1.Q = 16'h0;
      CPUSys.ALUSys.RF.R2.Q = 16'h0;
      CPUSys.ALUSys.RF.R3.Q = 16'h0;
      CPUSys.ALUSys.RF.R4.Q = 16'h0;
      CPUSys.ALUSys.RF.S1.Q = 16'h0;
      CPUSys.ALUSys.RF.S2.Q = 16'h0;
      CPUSys.ALUSys.RF.S3.Q = 16'h0;
      CPUSys.ALUSys.RF.S4.Q = 16'h0;
      CPUSys.ALUSys.ARF.PC.Q = 16'h0;
      CPUSys.ALUSys.ARF.AR.Q = 16'h0;
      CPUSys.ALUSys.ARF.SP.Q = 16'h00FF;
      CPUSys.ALUSys.ALU.FlagsOut = 4'b0000;
      CPUSys.ALUSys.DMU.DR.DROut = 16'h0;
      CPUSys.ALUSys.IMU.IR.IROut = 16'h0;
    end
  endtask

  task SetRegisters;
    input [15:0] value;
    begin
      CPUSys.ALUSys.ARF.PC.Q = value;
      CPUSys.ALUSys.ARF.AR.Q = value;
      CPUSys.ALUSys.ARF.SP.Q = value;
      CPUSys.ALUSys.RF.R1.Q = value;
      CPUSys.ALUSys.RF.R2.Q = value;
      CPUSys.ALUSys.RF.R3.Q = value;
      CPUSys.ALUSys.RF.R4.Q = value;
      CPUSys.ALUSys.RF.S1.Q = value;
      CPUSys.ALUSys.RF.S2.Q = value;
      CPUSys.ALUSys.RF.S3.Q = value;
      CPUSys.ALUSys.RF.S4.Q = value;
      CPUSys.ALUSys.DMU.DR.DROut = 16'h0;
      CPUSys.ALUSys.IMU.IR.IROut = 16'h0;
    end
  endtask

  task SetALUFlags;
    input [3:0] value;
    begin
      CPUSys.ALUSys.ALU.FlagsOut = value;
    end
  endtask

  task SetRegistersRx;
    begin
      CPUSys.ALUSys.RF.R1.Q = 16'h2312;
      CPUSys.ALUSys.RF.R2.Q = 16'h6789;
      CPUSys.ALUSys.RF.R3.Q = 16'h8894;
      CPUSys.ALUSys.RF.R4.Q = 16'hF210;
    end
  endtask

  task DisableAll;
    begin
      CPUSys.RF_RegSel = 4'b1111;
      CPUSys.RF_ScrSel = 4'b1111;
      CPUSys.ARF_RegSel = 3'b111;
      CPUSys.ALU_WF = 0;
      CPUSys.IMU_CS = 0;
      CPUSys.DMU_CS = 0;
      CPUSys.T_Reset = 1;
    end
  endtask

  task ResetT;
    begin
      CPUSys.T_Reset = 1;
    end
  endtask

  assign OPC  = CPUSys.OPC;
  assign RSEL  = CPUSys.RSEL;
  assign ADDR = CPUSys.ADDR;
  assign DSTREG = CPUSys.DSTREG;
  assign SREG1 = CPUSys.SREG1;
  assign SREG2 = CPUSys.SREG2;

  initial begin
    F.SimulationName = "CPUSystem";
    F.InitializeSimulation(0);
    clk.clock = 0;

    //Test 1
    test_no = 1;
    clock_count = 0;
    DisableAll();
    ClearRegisters();

    SetRegisters(16'h7777);
    F.CheckValues(CPUSys.ALUSys.RF.R2.Q, 16'h7777, test_no, "R2");
    rg.ActivateReset();
    clk.Clock();
    rg.DeactivateReset();
    F.CheckValues(CPUSys.ALUSys.RF.R2.Q, 16'h0000, test_no, "R2");
    CPUSys.ALUSys.ARF.PC.Q = 16'h0056;

    //Test 2 BGT 0x11
    test_no = 2;
    ClearRegisters();
    CPUSys.ALUSys.IMU.IR.IROut = 16'h1011;
    SetALUFlags(4'b0000);
    CPUSys.T = 12'b0000_0000_0100;  // Set T to 4
    while (CPUSys.T != 12'b0000_0000_0001 && clock_count <= 15) begin
      clk.Clock();
      clock_count = clock_count + 1;
    end
    F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h0011, test_no, "PC");

    //Test 3 DEC R1, R2
    test_no = 3;
    ClearRegisters();
    CPUSys.ALUSys.RF.R2.Q = 16'h0001;
    CPUSys.ALUSys.IMU.IR.IROut = 16'h2250;
    CPUSys.T = 12'b0000_0000_0100;  // Set T to 4
    while (CPUSys.T != 12'b0000_0000_0001 && clock_count <= 15) begin
      clk.Clock();
      clock_count = clock_count + 1;
    end
    F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'h0000, test_no, "R1");
    F.CheckValues(CPUSys.ALUSys.RF.R2.Q, 16'h0001, test_no, "R2");
    F.CheckValues(CPUSys.ALUSys.ALU.FlagsOut[3], 1, test_no, "Z");

    //Test 4 LSL R2 R2
    test_no = 4;
    ClearRegisters();
    CPUSys.ALUSys.RF.R2.Q = 16'h0002;
    CPUSys.ALUSys.IMU.IR.IROut = 16'h26D0;
    CPUSys.T = 12'b0000_0000_0100;
    while (CPUSys.T != 12'b0000_0000_0001 && clock_count <= 15) begin
      clk.Clock();
      clock_count = clock_count + 1;
    end
    F.CheckValues(CPUSys.ALUSys.OutA, 16'h0004, test_no, "OutA");
    F.CheckValues(CPUSys.ALUSys.ALUOut, 16'h0008, test_no, "ALUOut");
    F.CheckValues(CPUSys.ALUSys.RF.R2.Q, 16'h0004, test_no, "R2");

    //Test 5 ADD PC AR SP
    test_no = 5;
    ClearRegisters();
    CPUSys.ALUSys.ARF.AR.Q = 16'h3550;
    CPUSys.ALUSys.IMU.IR.IROut = 16'h4CA6;
    CPUSys.T = 12'b0000_0000_0100;
    while (CPUSys.T != 12'b0000_0000_0001 && clock_count <= 15) begin
      clk.Clock();
      clock_count = clock_count + 1;
    end
    F.CheckValues(CPUSys.ALUSys.ARF.PC.Q, 16'h364F, test_no, "PC");

    //Test 6 MOV AR, R4
    test_no = 6;
    ClearRegisters();
    SetRegistersRx();
    CPUSys.ALUSys.IMU.IR.IROut = 16'h5970;
    CPUSys.T = 12'b0000_0000_0100;
    while (CPUSys.T != 12'b0000_0000_0001 && clock_count <= 15) begin
      clk.Clock();
      clock_count = clock_count + 1;
    end
    F.CheckValues(CPUSys.ALUSys.RF.R4.Q, 16'hF210, test_no, "R4");
    F.CheckValues(CPUSys.ALUSys.ARF.AR.Q, 16'hF210, test_no, "AR");

    //Test 7 IMM R1, 0x01
    test_no = 7;
    ClearRegisters();
    SetRegistersRx();
    SetALUFlags(4'b1111);
    CPUSys.ALUSys.IMU.IR.IROut = 16'h5C01;
    CPUSys.T = 12'b0000_0000_0100;
    while (CPUSys.T != 12'b0000_0000_0001 && clock_count <= 15) begin
      clk.Clock();
      clock_count = clock_count + 1;
    end
    F.CheckValues(CPUSys.ALUSys.RF.R1.Q, 16'h0001, test_no, "R1");

    F.FinishSimulation();
  end

endmodule
