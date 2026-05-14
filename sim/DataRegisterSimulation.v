`timescale 1ns / 1ps

module DataRegisterSimulation ();
  reg [7:0] I;
  reg E;
  reg FunSel;
  wire [15:0] DROut;
  integer test_no;

  CrystalOscillator clk ();
  DataRegister DR (
      .I(I),
      .E(E),
      .FunSel(FunSel),
      .Clock(clk.clock),
      .DROut(DROut)
  );

  FileOperation F ();

  initial begin

    F.SimulationName = "DataRegister";
    F.InitializeSimulation(0);
    clk.clock = 0;

    //Test 1
    test_no = 1;
    DR.DROut = 16'h2367;
    FunSel = 0;
    E = 1;
    I = 8'h15;
    #5;
    clk.Clock();
    F.CheckValues(DROut, 16'h2315, test_no, "DROut");

    //Test 2
    test_no = 2;
    DR.DROut = 16'h2367;
    FunSel = 1;
    E = 1;
    I = 8'h15;
    #5;
    clk.Clock();
    F.CheckValues(DROut, 16'h1567, test_no, "DROut");

    F.FinishSimulation();
  end

endmodule
