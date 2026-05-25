`timescale 1ns / 1ps

module CPUSystem (
    input wire Clock,
    input wire Reset,
    output reg [11:0] T
);

  reg [3:0] RF_RegSel, RF_ScrSel;
  reg [2:0] ARF_RegSel;
  reg [1:0] RF_FunSel, ARF_FunSel;
  reg [3:0] ALU_FunSel;
  reg ALU_WF, MuxCSel, DMU_CS, DMU_WR, DMU_FunSel, IMU_CS, IMU_LH, T_Reset;
  reg [1:0] MuxASel, MuxBSel;
  reg [2:0] RF_OutASel, RF_OutBSel;
  reg [1:0] ARF_OutCSel;
  reg ARF_OutDSel;

  wire [15:0] IR_Out;
  wire [3:0] Flags;

  wire [5:0] OPC;
  wire [1:0] RSEL;
  wire [2:0] DSTREG;
  wire [2:0] SREG1;
  wire [2:0] SREG2;
  wire [7:0] ADDR;

  assign IR_Out = ALUSys.IROut;
  assign Flags = ALUSys.FlagsOut;

  assign OPC = IR_Out[15:10];
  assign RSEL = IR_Out[9:8];
  assign DSTREG = IR_Out[9:7];
  assign SREG1 = IR_Out[6:4];
  assign SREG2 = IR_Out[3:1];
  assign ADDR = IR_Out[7:0];

  // Conditions.
  wire DestSrc1SameCond;
  assign DestSrc1SameCond = DSTREG == SREG1;

  function arf_is_selected;
    input [2:0] op_reg_sel;
    arf_is_selected = ~op_reg_sel[2];
  endfunction

  function [2:0] arf_en_from_opcode;
    input [2:0] op_reg_sel;
    case (op_reg_sel)
      3'b000, 3'b001: arf_en_from_opcode = 3'b011;
      3'b010: arf_en_from_opcode = 3'b110;
      3'b011: arf_en_from_opcode = 3'b101;
      default: arf_en_from_opcode = 3'b111;  // Disable all.
    endcase
  endfunction

  function [3:0] rf_en_from_opcode;
    input [2:0] op_reg_sel;
    case (op_reg_sel)
      3'b100:  rf_en_from_opcode = 4'b0111;
      3'b101:  rf_en_from_opcode = 4'b1011;
      3'b110:  rf_en_from_opcode = 4'b1101;
      3'b111:  rf_en_from_opcode = 4'b1110;
      default: rf_en_from_opcode = 4'b1111;  // Disable all.
    endcase
  endfunction

  // Executes branch operation on condition.
  // PC <- ADDR.
  task exec_branch;
    input cond;
    if (cond) begin
      MuxBSel = 2'b11;
      ARF_RegSel = 3'b011;
      ARF_FunSel = 2'b01;
    end
    T_Reset = 1'b1;
  endtask

  //* Loads from source register to RF scratch
  task load_into_scr;
    input [3:0] inscr;
    input [2:0] regsel;  // SREG1 or SREG2
    RF_ScrSel = inscr;
    RF_FunSel = 2'b01;  // Set to Load
    if (arf_is_selected(regsel)) begin
      // Copy from ARF to RF Scr
      ARF_OutCSel = regsel[1:0];
      MuxASel = 2'b01;  // RF.I is set to MuxAOut
    end else begin
      // Copy from RF to RF Scr
      RF_OutASel = {1'b0, regsel[1:0]};
      ALU_FunSel = 4'b0000;  // Output A
    end
  endtask

  task unload_scr;
    input [2:0] outscr;
    ALU_FunSel = 4'b0000;
    RF_OutASel = outscr;
    if (arf_is_selected(DSTREG)) begin
      // Destination is ARF
      ARF_RegSel = arf_en_from_opcode(DSTREG);
      ARF_FunSel = 2'b01;  // Set to Load
      MuxBSel = 2'b00;  // MuxBOut is redirected into ARF
    end else begin
      // Destination is RF
      RF_RegSel = rf_en_from_opcode(DSTREG);
      RF_FunSel = 2'b01;  // Set to Load
      MuxASel   = 2'b00;
    end
  endtask

  task unload_alu;
    RF_OutASel = 3'b100;  // Scr1
    RF_OutBSel = 3'b101;  // Scr2
    if (arf_is_selected(DSTREG)) begin
      MuxBSel = 2'b00;     // Select ALUOut
      ARF_FunSel = 2'b01;  // Set to Load
      ARF_RegSel = arf_en_from_opcode(DSTREG);
    end else begin
      MuxASel   = 2'b00;  // Select ALUOut
      RF_FunSel = 2'b01;  // Set to Load
      RF_RegSel = rf_en_from_opcode(DSTREG);
    end
  endtask

  initial begin
    // Initialize sequence counter
    // ! It is important to do since T_Reset only activates on clock edge
    T <= 12'b0000_0000_0001;
  end

  // Sequence counter.
  // T[n]==1 => n'th sequence is running.
  always @(posedge Clock or negedge Reset) begin
    if (!Reset || T_Reset) T <= 12'b0000_0000_0001;
    else T <= {T[10:0], T[11]};
  end

  always @(*) begin
    RF_RegSel  = 4'b1111;
    RF_ScrSel  = 4'b1111;
    ARF_RegSel = 3'b111;
    RF_FunSel  = 2'b01;
    ARF_FunSel = 2'b01;
    case (OPC)
      6'h07:   ALU_FunSel = 4'b0100;
      6'h08:   ALU_FunSel = 4'b0110;
      6'h09:   ALU_FunSel = 4'b1011;
      6'h0A:   ALU_FunSel = 4'b1100;
      6'h0B:   ALU_FunSel = 4'b1101;
      6'h0C:   ALU_FunSel = 4'b1110;
      6'h0D:   ALU_FunSel = 4'b1111;
      6'h0E:   ALU_FunSel = 4'b0010;
      6'h0F:   ALU_FunSel = 4'b0111;
      6'h10:   ALU_FunSel = 4'b1000;
      6'h11:   ALU_FunSel = 4'b1001;
      6'h12:   ALU_FunSel = 4'b1010;
      6'h13:   ALU_FunSel = 4'b0100;
      6'h14:   ALU_FunSel = 4'b0101;
      6'h15:   ALU_FunSel = 4'b0110;
      6'h16:   ALU_FunSel = 4'b0000;
      default: ALU_FunSel = 4'b0000;
    endcase
    ALU_WF = 1'b0;
    DMU_CS = 1'b0;
    DMU_WR = 1'b0;
    DMU_FunSel = 1'b0;
    IMU_CS = 1'b0;
    IMU_LH = 1'b0;
    T_Reset = 1'b0;
    MuxASel = 2'b00;
    MuxBSel = 2'b00;
    MuxCSel = 1'b0;
    ARF_OutCSel = 2'b00;
    ARF_OutDSel = 1'b0;

    if (!Reset) begin
      RF_RegSel = 4'b0000;
      RF_ScrSel = 4'b0000;
      ARF_RegSel = 3'b000;
      RF_FunSel = 2'b00;
      ARF_FunSel = 2'b00;
      T_Reset = 1'b1;
    end else if (T[0]) begin
      // Read LSB of the opcode.
      IMU_CS = 1'b1;
      IMU_LH = 1'b0;
      ARF_RegSel = 3'b011;
      ARF_FunSel = 2'b10;
    end else if (T[1]) begin
      // Read MSB of the opcode.
      IMU_CS = 1'b1;
      IMU_LH = 1'b1;
      ARF_RegSel = 3'b011;
      ARF_FunSel = 2'b10;
    end else if (T[2]) begin
      case (OPC)
        6'h00: begin
          exec_branch(1);  // Unconditional branch.
          T_Reset = 1'b1;
        end
        6'h01: begin
          // nonzero.
          exec_branch(Flags[3] == 1'b0);  // Z==0.
          T_Reset = 1'b1;
        end
        6'h02: begin
          // zero.
          exec_branch(Flags[3] == 1'b1);  // Z==1.
          T_Reset = 1'b1;
        end
        6'h03: begin
          // negative.
          exec_branch(Flags[1] != Flags[0]);  // N!=O.
          T_Reset = 1'b1;
        end
        6'h04: begin
          // nonnegative and nonzero => positive.
          exec_branch((Flags[1] == Flags[0]) && (Flags[3] == 1'b0));  // N==O & Z==0.
          T_Reset = 1'b1;
        end
        6'h05: begin
          // negative or zero.
          exec_branch((Flags[1] != Flags[0]) || (Flags[3] == 1'b1));  // N!=O | Z==1.
          T_Reset = 1'b1;
        end
        6'h06: begin
          // nonnegative => positive or zero.
          exec_branch(Flags[1] == Flags[0]);  // N==0.
          T_Reset = 1'b1;
        end
        6'h16: begin
          // 6'h16: DSTREG <- SREG1
          // Configure unload
          ARF_OutCSel = SREG1[1:0];
          RF_OutASel  = {1'b0, SREG1[1:0]};
          if (arf_is_selected(SREG1)) begin
            // Data flowing from ARF
            //* ARF.OutC could be redirected towards both RF and ARF
            MuxASel = 2'b01;  // Select ARF.OutC
            MuxBSel = 2'b01;  // Select ARF.OutC
          end else begin
            // Data flowing from RF
            //* RF output could be redirected only via ALU
            MuxASel = 2'b00;  // Select ALUOut
            MuxBSel = 2'b00;  // Select ALUOut
          end
          // Configure load
          if (arf_is_selected(DSTREG)) begin
            // RF -> ARF
            ARF_FunSel = 2'b01;  // Set to Load
            ARF_RegSel = arf_en_from_opcode(DSTREG);
          end else begin
            // RF -> RF
            RF_FunSel = 2'b01;  // Set to Load
            RF_RegSel = rf_en_from_opcode(DSTREG);
          end
          T_Reset = 1'b1;
        end
        6'h07, 6'h08, 6'h09, 6'h0A, 6'h0B, 6'h0C, 6'h0D, 6'h0E, 6'h0F, 6'h10, 6'h11, 6'h12, 6'h13, 6'h14, 6'h15: begin
          // 6'h07: DSTREG <- SREG1 + 1
          // 6'h08: DSTREG <- SREG1 - 1
          // 6'h09: DSTREG <- LSL SREG1
          // 6'h0A: DSTREG <- LSR SREG1
          // 6'h0B: DSTREG <- ASR SREG1
          // 6'h0C: DSTREG <- CSL SREG1
          // 6'h0D: DSTREG <- CSR SREG1
          // 6'h0E: DSTREG <- NOT SREG1
          // 6'h0F: DSTREG <- SREG1 AND SREG2
          // 6'h10: DSTREG <- SREG1 OR SREG2
          // 6'h11: DSTREG <- SREG1 XOR SREG2
          // 6'h12: DSTREG <- SREG1 AND SREG2
          // 6'h13: DSTREG <- SREG1 + SREG2
          // 6'h14: DSTREG <- SREG1 + SREG2 + CARRY
          // 6'h15: DSTREG <- SREG1 - SREG2
          //! All operations above require loading SREG1 into Scr1
          // Check if DESTREG == SREG1
          // ! Only applicable for INC and DEC due to built-in register functionality
          if ((OPC == 6'h07 || OPC == 6'h08) && DestSrc1SameCond) begin
            // Just apply Inc inside the register
            if (arf_is_selected(SREG1)) begin
              ARF_RegSel = arf_en_from_opcode(SREG1);
              ARF_FunSel = (OPC == 6'h07) ? 2'b10 : 2'b11;
            end else begin
              RF_RegSel = rf_en_from_opcode(SREG1);
              RF_FunSel = (OPC == 6'h07) ? 2'b10 : 2'b11;
            end
            T_Reset = 1'b1;
          end else begin
            // Load SREG1 into Scr1
            load_into_scr(4'b0111, SREG1);
          end
        end
        6'h17: begin
          // 6'h17: Rx <- IMMEDIATE
          RF_FunSel = 2'b01;  // Set to Load
          RF_RegSel = rf_en_from_opcode({1'b1, RSEL});
          MuxASel   = 2'b11;  // Select IMUOut ({8'b0, IROut[7:0]})
          T_Reset   = 1'b1;
        end
        default: T_Reset = 1'b1;
      endcase
    end else if (T[3]) begin
      case (OPC)
        6'h07, 6'h08: begin
          // 6'h07: DSTREG <- SREG1 + 1
          // 6'h08: DSTREG <- SREG1 - 1
          // Use register's built-in functionality
          RF_ScrSel = 4'b0111;  // Select Scr1
          RF_FunSel = (OPC == 6'h07) ? 2'b10 : 2'b11;  // Set to Inc or Dec
        end
        6'h09, 6'h0A, 6'h0B, 6'h0C, 6'h0D, 6'h0E: begin
          // 6'h09: DSTREG <- LSL SREG1
          // 6'h0A: DSTREG <- LSR SREG1
          // 6'h0B: DSTREG <- ASR SREG1
          // 6'h0C: DSTREG <- CSL SREG1
          // 6'h0D: DSTREG <- CSR SREG1
          // 6'h0E: DSTREG <- NOT SREG1
          // All these operations rely on ALU for a single-variable operation
          RF_OutASel = 3'b100;  // Load Scr1 into ALU
          //* ALU_FunSel is set at the top based on opcode
          // Redirect ALUOut to DESTREG
          unload_alu();
          T_Reset = 1'b1;
        end
        6'h0F, 6'h10, 6'h11, 6'h12, 6'h13, 6'h14, 6'h15: begin
          // 6'h0F: DSTREG <- SREG1 AND SREG2
          // 6'h10: DSTREG <- SREG1 OR SREG2
          // 6'h11: DSTREG <- SREG1 XOR SREG2
          // 6'h12: DSTREG <- SREG1 AND SREG2
          // 6'h13: DSTREG <- SREG1 + SREG2
          // 6'h14: DSTREG <- SREG1 + SREG2 + CARRY
          // 6'h15: DSTREG <- SREG1 - SREG2
          //! All operations above require loading SREG2 into Scr2
          // Load SREG2 into Scr1
          load_into_scr(4'b1011, SREG2);
        end
        default: T_Reset = 1'b1;
      endcase
    end else if (T[4]) begin
      case (OPC)
        6'h07, 6'h08: begin
          // 6'h07: DSTREG <- SREG1 + 1
          // 6'h08: DSTREG <- SREG1 - 1
          //* Both operations require loading Scr1 into DESTREG
          // Load Scr1 into DSTREG
          unload_scr(3'b100);
          T_Reset = 1'b1;
        end
        6'h0F, 6'h10, 6'h11, 6'h12, 6'h13, 6'h14, 6'h15: begin
          // 6'h0F: DSTREG <- SREG1 AND SREG2
          // 6'h10: DSTREG <- SREG1 OR SREG2
          // 6'h11: DSTREG <- SREG1 XOR SREG2
          // 6'h12: DSTREG <- SREG1 AND SREG2
          // 6'h13: DSTREG <- SREG1 + SREG2
          // 6'h14: DSTREG <- SREG1 + SREG2 + CARRY
          // 6'h15: DSTREG <- SREG1 - SREG2
          unload_alu();
          T_Reset = 1'b1;
        end
        default: T_Reset = 1'b1;
      endcase
    end else begin
      T_Reset = 1'b1;
    end
  end

  ArithmeticLogicUnitSystem ALUSys (
      .Clock(Clock),
      .MuxASel(MuxASel),
      .MuxBSel(MuxBSel),
      .MuxCSel(MuxCSel),
      .RF_RegSel(RF_RegSel),
      .RF_ScrSel(RF_ScrSel),
      .RF_FunSel(RF_FunSel),
      .RF_OutASel(RF_OutASel),
      .RF_OutBSel(RF_OutBSel),
      .ARF_RegSel(ARF_RegSel),
      .ARF_FunSel(ARF_FunSel),
      .ARF_OutCSel(ARF_OutCSel),
      .ARF_OutDSel(ARF_OutDSel),
      .ALU_WF(ALU_WF),
      .ALU_FunSel(ALU_FunSel),
      .DMU_WR(DMU_WR),
      .DMU_FunSel(DMU_FunSel),
      .DMU_CS(DMU_CS),
      .IMU_LH(IMU_LH),
      .IMU_CS(IMU_CS),
      .ALUOut(),
      .FlagsOut(),
      .IROut(),
      .IMUOut()
  );

endmodule
