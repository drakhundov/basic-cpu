`timescale 1ns / 1ps

module CrystalOscillator;
  reg clock = 0;

  initial begin
    forever begin
      #10 clock = ~clock;
    end
  end

endmodule

module ResetGenerator;
  reg reset = 1;  // Start with reset INACTIVE (high)

  initial begin
    reset = 1;              // Start inactive
    #5;                     // Wait for clock to stabilize
    reset = 0;              // Assert reset (low)
    #20;                    // Hold for 2 clock cycles
    reset = 1;              // Release reset (high)
    #10000;                 // Timeout 10us
    reset = 0;              // Reset again
  end

endmodule

module Main ();
  wire clock, reset;
  wire [11:0] T;

  CrystalOscillator clk ();
  ResetGenerator rg ();

  CPUSystem CPUSys (
      .Clock(clk.clock),
      .Reset(rg.reset),
      .T(T)
  );

  assign clock = clk.clock;
  assign reset = rg.reset;

  // Display header
  initial begin
    $display("");
    $display(
        "╔════════════════════════════════════════════════════════════════════════════════════════╗");
    $display(
        "║                         CPU REGISTER STATE MONITOR                                    ║");
    $display(
        "╚════════════════════════════════════════════════════════════════════════════════════════╝");
    $display("");
  end

  // Continuous monitoring with formatted table
  initial begin
    #10
    forever begin
      @(posedge clock);
      #1;  // Wait a bit for all signals to settle

      $display(
          "┌─────────────────────────────────────────────────────────────────────────────────────┐");
      $display("│ T[%0d] | T_Reset=%b | Opcode=0x%02X | Clock Cycle=%0d", $clog2(T),
               CPUSys.T_Reset, CPUSys.Opcode, ($stime / 20) - 1);
      $display(
          "├─────────────────────────────────────────────────────────────────────────────────────┤");

      // Register File
      $display(
          "│ REGISTER FILE (General Purpose):                                                  │");
      $display("│   R1: 0x%04X  │  R2: 0x%04X  │  R3: 0x%04X  │  R4: 0x%04X",
               CPUSys.ALUSys.RF.R1.Q, CPUSys.ALUSys.RF.R2.Q, CPUSys.ALUSys.RF.R3.Q,
               CPUSys.ALUSys.RF.R4.Q);

      // Scratch Registers
      $display(
          "│ REGISTER FILE (Scratch):                                                          │");
      $display("│   S1: 0x%04X  │  S2: 0x%04X  │  S3: 0x%04X  │  S4: 0x%04X",
               CPUSys.ALUSys.RF.S1.Q, CPUSys.ALUSys.RF.S2.Q, CPUSys.ALUSys.RF.S3.Q,
               CPUSys.ALUSys.RF.S4.Q);

      // Address Register File
      $display(
          "│ ADDRESS REGISTER FILE:                                                            │");
      $display("│   PC: 0x%04X  │  AR: 0x%04X  │  SP: 0x%04X", CPUSys.ALUSys.ARF.PC.Q,
               CPUSys.ALUSys.ARF.AR.Q, CPUSys.ALUSys.ARF.SP.Q);

      // ALU Flags
      $display(
          "│ ALU FLAGS:                                                                        │");
      $display("│   Z: %b  │  N: %b  │  C: %b  │  O: %b", CPUSys.ALUSys.ALU.FlagsOut[3],
               CPUSys.ALUSys.ALU.FlagsOut[1], CPUSys.ALUSys.ALU.FlagsOut[2],
               CPUSys.ALUSys.ALU.FlagsOut[0]);

      // Instruction Fetch Debug
      $display(
          "│ INSTRUCTION FETCH:                                                          │");
      $display("│   IMU_CS=%b | IMU_LH=%b | IMUOut=0x%04X | IR=0x%04X", CPUSys.IMU_CS,
               CPUSys.IMU_LH, CPUSys.ALUSys.IMUOut, CPUSys.IR_Out);

      // Decoded Register Fields
      $display(
          "│ DECODED REGISTERS:                                                                │");
      $display("│   DestReg=0x%0X | SrcReg1=0x%0X | SrcReg2=0x%0X", CPUSys.DestReg,
               CPUSys.SrcReg1, CPUSys.SrcReg2);

      $display(
          "└─────────────────────────────────────────────────────────────────────────────────────┘");
      $display("");
    end
  end

  // Stop simulation after timeout
  initial begin
    #10010;  // Timeout
    $display("");
    $display(
        "═══════════════════════════════════════════════════════════════════════════════════════");
    $display("   SIMULATION COMPLETE");
    $display(
        "═══════════════════════════════════════════════════════════════════════════════════════");
    $finish;
  end

endmodule
