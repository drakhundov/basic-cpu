`timescale 1ns / 1ps

module ArithmeticLogicUnitSimulation ();
  reg [15:0] A, B;
  reg [3:0] FunSel;
  reg WF;
  wire [15:0] ALUOut;
  wire [3:0] FlagsOut;
  integer test_no;
  wire Z, C, N, O;
  CrystalOscillator clk ();
  ArithmeticLogicUnit ALU (
      .A(A),
      .B(B),
      .FunSel(FunSel),
      .WF(WF),
      .Clock(clk.clock),
      .ALUOut(ALUOut),
      .FlagsOut(FlagsOut)
  );

  FileOperation F ();

  assign {Z, C, N, O} = FlagsOut;

  initial begin
    F.SimulationName = "ArithmeticLogicUnit";
    F.InitializeSimulation(0);
    clk.clock = 0;

    //Test 1
    test_no = 1;
    A = 16'h1234;
    B = 16'h4321;
    ALU.FlagsOut = 4'b1111;
    FunSel = 4'b0100;
    WF = 1;
    #5 F.CheckValues(ALUOut, 16'h5555, test_no, "ALUOut");
    F.CheckValues(Z, 1, test_no, "Z");
    F.CheckValues(C, 1, test_no, "C");
    F.CheckValues(N, 1, test_no, "N");
    F.CheckValues(O, 1, test_no, "O");

    //Test 2
    test_no = 2;
    clk.Clock();
    F.CheckValues(ALUOut, 16'h5555, test_no, "ALUOut");
    F.CheckValues(Z, 0, test_no, "Z");
    F.CheckValues(C, 0, test_no, "C");
    F.CheckValues(N, 0, test_no, "N");
    F.CheckValues(O, 0, test_no, "O");

    //Test 3 
    test_no = 3;
    A = 16'h7777;
    B = 16'h8888;  //16'b8889;
    ALU.FlagsOut = 4'b0100;  //4'b0100;
    FunSel = 4'b0101;
    WF = 1;
    #5 clk.Clock();
    F.CheckValues(ALUOut, 16'h0000, test_no, "ALUOut");
    F.CheckValues(Z, 1, test_no, "Z");
    F.CheckValues(C, 1, test_no, "C");
    F.CheckValues(N, 0, test_no, "N");
    F.CheckValues(O, 0, test_no, "O");


    /**********************************************************/
    //ALUOut =  A (16 Bit)
    /**********************************************************/
    //Test 4
    test_no = 4;
    A = 16'h2233;
    B = 16'h6677;
    ALU.FlagsOut = 4'b1111;
    FunSel = 4'b0000;
    WF = 1;
    #5;
    clk.Clock();
    F.CheckValues(ALUOut, 16'h2233, test_no, "ALUOut");
    F.CheckValues(Z, 0, test_no, "Z");
    F.CheckValues(C, 1, test_no, "C");
    F.CheckValues(N, 0, test_no, "N");
    F.CheckValues(O, 1, test_no, "O");

    F.FinishSimulation();
  end
endmodule
