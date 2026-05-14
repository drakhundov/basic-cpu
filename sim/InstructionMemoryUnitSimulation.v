`timescale 1ns / 1ps

module InstructionMemoryUnitSimulation ();
  reg [15:0] Address;
  reg CS;
  reg LH;
  reg Clock;
  wire [15:0] IMUOut;
  wire [15:0] IROut;
  integer test_no;

  CrystalOscillator clk ();
  InstructionMemoryUnit IMU (
      .Address(Address),
      .CS(CS),
      .LH(LH),
      .Clock(clk.clock),
      .IMUOut(IMUOut),
      .IROut(IROut)
  );

  FileOperation F ();

  initial begin
    F.SimulationName = "InstructionMemoryUnit";
    F.InitializeSimulation(0);
    clk.clock = 0;

    //Test 1
    test_no = 1;
    IMU.IR.IROut = 16'h2367;
    LH = 0;
    CS = 1;
    Address = 16'h15;
    #5;
    clk.Clock();
    F.CheckValues(IMU.IM.ROM_DATA[16'h0015], 8'h05, test_no, "MEM[h15]");
    F.CheckValues(IMUOut, 16'h0005, test_no, "IMUOut");
    F.CheckValues(IROut, 16'h2305, test_no, "IROut");

    //Test 2
    test_no = 2;
    IMU.IR.IROut = 16'h2367;
    LH = 1;
    CS = 1;
    Address = 16'h15;
    #5;
    clk.Clock();
    F.CheckValues(IMUOut, 16'h0067, test_no, "IMUOut");
    F.CheckValues(IROut, 16'h0567, test_no, "IROut");

    F.FinishSimulation();
  end
endmodule
