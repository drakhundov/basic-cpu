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

  wire [5:0] Opcode;
  wire [1:0] RegSel;
  wire [2:0] DestReg;
  wire [2:0] SrcReg1;
  wire [2:0] SrcReg2;
  wire [7:0] Address;

  assign IR_Out  = ALUSys.IROut;
  assign Flags   = ALUSys.FlagsOut;

  assign Opcode  = IR_Out[15:10];
  assign RegSel  = IR_Out[9:8];
  assign DestReg = IR_Out[9:7];
  assign SrcReg1 = IR_Out[6:4];
  assign SrcReg2 = IR_Out[3:1];
  assign Address = IR_Out[7:0];

  // Conditions.
  wire DestSrc1SameCond;
  assign DestSrc1SameCond = DestReg == SrcReg1;

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
    case (Opcode)
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
      case (Opcode)
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
        6'h07: begin
          // DSTREG <- SREG1 + 1
          // First sequence
          // Check if DESTREG == SREG1
          if (DestSrc1SameCond) begin
            // Just apply Inc inside the register
            if (arf_is_selected(SrcReg1)) begin
              ARF_RegSel = arf_en_from_opcode(SrcReg1);
              ARF_FunSel = 2'b10;
            end else begin
              RF_RegSel = rf_en_from_opcode(SrcReg1);
              RF_FunSel = 2'b10;
            end
            T_Reset = 1'b1;
          end else begin
            // Load SREG1 into Scr1
            RF_ScrSel = 4'b0111;  // Select Src1
            RF_FunSel = 2'b01;  // Set to Load
            if (arf_is_selected(SrcReg1)) begin
              // Copy from ARF to RF Scr
              ARF_OutCSel = SrcReg1[1:0];
              MuxASel = 2'b01;  // RF.I is set to MuxAOut
            end else begin
              // Copy from RF to RF Scr
              RF_OutASel = {1'b0, SrcReg1[1:0]};
              ALU_FunSel = 4'b0000;  // Output A
            end
          end
        end
        default: T_Reset = 1'b1;
      endcase
    end else if (T[3]) begin
      case (Opcode)
        6'h07: begin
          // DSTREG <- SREG1 + 1
          // Second sequence
          // Compute Scr1 + 1
          RF_ScrSel = 4'b0111;  // Select Scr1
          RF_FunSel = 2'b10;  // Set to Inc
        end
        default: T_Reset = 1'b1;
      endcase
    end else if (T[4]) begin
      case (Opcode)
        6'h07: begin
          // DSTREG <- SREG1 + 1
          // Third sequence
          // Load Scr1 into DSTREG
          ALU_FunSel = 4'b0000;
          RF_OutASel = 3'b100;
          if (arf_is_selected(DestReg)) begin
            // Destination is ARF
            ARF_RegSel = arf_en_from_opcode(DestReg);
            ARF_FunSel = 2'b01;  // Set to Load
            MuxBSel = 2'b00;  // MuxBOut is redirected into ARF
          end else begin
            // Destination is RF
            RF_RegSel = rf_en_from_opcode(DestReg);
            RF_FunSel = 2'b01;  // Set to Load
            MuxASel   = 2'b00;
          end
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
