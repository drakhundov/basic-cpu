`timescale 1ns / 1ps

module Register16bitSimulation ();
  reg [15:0] I;
  reg E;
  reg [1:0] FunSel;
  wire [15:0] Q;
  integer test_no;

  CrystalOscillator clk ();
  Register16bit R (
      .I(I),
      .E(E),
      .FunSel(FunSel),
      .Clock(clk.clock),
      .Q(Q)
  );

  FileOperation F ();

  initial begin
    F.SimulationName = "Register16bit";
    F.InitializeSimulation(1);
    clk.clock = 0;

    //Test 1
    test_no = 1;
    R.Q = 16'h0025;
    FunSel = 2'b00;
    E = 0;
    #5;
    clk.Clock();
    F.CheckValues(R.Q, 16'h0025, test_no, "Q");

    //Test 2 
    test_no = 2;
    R.Q = 16'h0025;
    FunSel = 2'b00;
    E = 1;
    #5;
    clk.Clock();
    F.CheckValues(R.Q, 16'h000, test_no, "Q");

    //Test 3 
    test_no = 3;
    R.Q = 16'h0025;
    I = 16'h0012;
    FunSel = 2'b01;
    E = 0;
    #5;
    clk.Clock();
    F.CheckValues(R.Q, 16'h0025, test_no, "Q");

    //Test 4 
    test_no = 4;
    R.Q = 16'h0025;
    I = 16'h0012;
    FunSel = 2'b01;
    E = 1;
    #5;
    clk.Clock();
    F.CheckValues(R.Q, 16'h0012, test_no, "Q");

    F.FinishSimulation();
  end
endmodule
