`timescale 1ns / 1ps

module DataMemoryUnitSimulation ();
  reg [7:0] I;
  reg [15:0] Address;
  reg WR;
  reg CS;
  reg FunSel;
  reg Clock;
  wire [15:0] DMUOut;
  integer test_no;

  CrystalOscillator clk ();
  DataMemoryUnit DMU (
      .I(I),
      .Address(Address),
      .WR(WR),
      .CS(CS),
      .FunSel(FunSel),
      .Clock(clk.clock),
      .DMUOut(DMUOut)
  );

  FileOperation F ();

  initial begin
    F.SimulationName = "DataMemoryUnit";
    F.InitializeSimulation(0);
    clk.clock = 0;

    //Test 1
    test_no = 1;
    DMU.DR.DROut = 16'h2367;
    FunSel = 0;
    CS = 1;
    WR = 0;
    Address = 16'h0015;
    #5;
    clk.Clock();
    F.CheckValues(DMU.DM.RAM_DATA[16'h0015], 8'h07, test_no, "MEM[h15]");
    F.CheckValues(DMUOut, 16'h2307, test_no, "DMUOut");

    //Test 2
    test_no = 2;
    DMU.DR.DROut = 16'h2367;
    FunSel = 1;
    CS = 1;
    WR = 0;
    Address = 16'h0015;
    #5;
    clk.Clock();
    F.CheckValues(DMUOut, 16'h0767, test_no, "DMUOut");

    F.FinishSimulation();
  end
endmodule
