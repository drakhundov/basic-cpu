# Basic CPU Implementation

A fully-functional 16-bit CPU implemented in Verilog with an 8-bit external bus. Features 8 general-purpose registers, 3 address registers, a 16-function ALU with flags, ROM/RAM interfaces, and a 12-state control unit.

## Quick Start

### Full CPU Simulation

```bash
# Create output directory
mkdir -p logs

# Compile all Verilog files and run simulation
iverilog -o bin/simv *.v && vvp ./bin/simv | tee logs/run.log

# View output
tail -100 logs/run.log
```

**Output files:**
- `logs/run.log` - Real-time register state monitor

### Test Individual Modules

Test a specific component using its corresponding testbench:

```bash
# Test Register File
iverilog -o test_rf RegisterFile.v Register16bit.v sim/RegisterFileSimulation.v sim/Sim.v && vvp ./test_rf

# Test ALU
iverilog -o test_alu ArithmeticLogicUnit.v sim/ArithmeticLogicUnitSimulation.v sim/Sim.v && vvp ./test_alu

# Test Address Registers
iverilog -o test_arf AddressRegisterFile.v Register16bit.v sim/AddressRegisterFileSimulation.v sim/Sim.v && vvp ./test_arf

# Test Instruction Register
iverilog -o test_ir InstructionRegister.v sim/InstructionRegisterSimulation.v sim/Sim.v && vvp ./test_ir

# Test CPU Control Unit
iverilog -o test_cpu CPUSystem.v ArithmeticLogicUnitSystem.v ArithmeticLogicUnit.v RegisterFile.v AddressRegisterFile.v Register16bit.v InstructionMemoryUnit.v InstructionRegister.v DataMemoryUnit.v DataRegister.v sim/CPUSystemSimulation.v sim/Sim.v && vvp ./test_cpu
```

**Pattern:** Each test includes:
- `ModuleName.v` (the component to test)
- `sim/ModuleNameSimulation.v` (the testbench)
- `sim/Sim.v` (shared test infrastructure for file I/O and reporting)

---

## Overview

### Design Characteristics

| Feature | Details |
|---------|---------|
| **Word Size** | 16-bit internal |
| **Bus Width** | 8-bit external (requires 2-cycle transfers for 16-bit values) |
| **Address Space** | 64K (65,536 locations) |
| **Synchronous** | All operations clock-synchronized |
| **State Machine** | 12-state one-hot control unit |

### Why 16-bit / 8-bit mismatch?

Simulates real-world constraints where memory bus width differs from word size. Instructions and data are fetched in two 8-bit chunks:
- **Cycle 1**: Low byte (IMU_LH=0)
- **Cycle 2**: High byte (IMU_LH=1)

---

## How to Use This Project

### Workflow

1. **Write your program** → `ROM.mem`
2. **Set up memory** → `RAM.mem` (optional)
3. **Compile & run** → Full simulation or individual module tests
4. **Monitor output** → Check `logs/run.log` for register states

### Step 1: Load a Program

Edit `ROM.mem` with your program as hex bytes (one per line):

```
40      // Instruction 1, low byte
3A      // Instruction 1, high byte
D0      // Instruction 2, low byte
1E      // Instruction 2, high byte
```

### Step 2: Initialize Memory (Optional)

Edit `RAM.mem` with initial data values (same hex format as ROM.mem).

### Step 3: Run Simulation

**Option A: Full CPU Simulation**
```bash
mkdir -p logs
iverilog -o bin/simv *.v && vvp ./bin/simv | tee logs/run.log
```

**Option B: Test a Specific Module**
```bash
# Example: Test RegisterFile
iverilog -o test_rf RegisterFile.v Register16bit.v sim/RegisterFileSimulation.v sim/Sim.v && vvp ./test_rf
```

### Step 4: Monitor Execution

Output updates every clock cycle, showing:
- Current T-state and clock cycle count
- Register values (R1-R4, S1-S4, PC, AR, SP)
- ALU flags (Z, N, C, O)
- Instruction being executed

---

## Instruction Set

All instructions are **16-bit** with format:
```
[15:10] = Opcode (6 bits)
[9:8]   = Register Selection (2 bits)
[9:7]   = Destination register (3 bits)
[6:4]   = Source register 1 (3 bits)
[3:1]   = Source register 2 (3 bits)
[7:0]   = Address/Immediate (8 bits)
```

### Register Codes
```
000=PC  001=PC  010=AR  011=SP
100=R1  101=R2  110=R3  111=R4
```

### Register Select Table
```
00=R1  01=R2  10=R3  11=R4
```

### Implemented Instructions

| Opcode | Mnemonic | Operation | Cycles |
|--------|----------|-----------|--------|
| 0x00 | BRA | PC ← Address | 1 |
| 0x01-0x06 | Cond. BRA | Conditional PC jump | 1 |
| 0x07 | INC | Dest ← Src + 1 | 1-3 |
| 0x08 | DEC | Dest ← Src - 1 | 1-3 |
| 0x09 | LSL | Dest ← Src << 1 | 2 |
| 0x0A | LSR | Dest ← Src >> 1 | 2 |
| 0x0B | ASR | Dest ← Src >>> 1 | 2 |
| 0x0C | CSL | Dest ← Src << 1 (with carry) | 2 |
| 0x0D | CSR | Dest ← Src >> 1 (with carry) | 2 |
| 0x0E | NOT | Dest ← ~Src | 2 |
| 0x0F | AND | Dest ← Src1 AND Src2 | 2 |
| 0x10 | ORR | Dest ← Src1 OR Src2 | 2 |
| 0x11 | XOR | Dest ← Src1 XOR Src2 | 2 |
| 0x12 | NAND | Dest ← ~(Src1 AND Src2) | 2 |
| 0x13 | ADD | Dest ← Src1 + Src2 | 2-3 |
| 0x14 | ADC | Dest ← Src1 + Src2 + C | 2-3 |
| 0x15 | SUB | Dest ← Src1 - Src2 | 2-3 |
| 0x16 | MOV | Dest ← Src1 | 1 |
| 0x17 | IMM | Rx ← Immediate | 1 |

**Example instruction:** INC R1 ← R2
```
Opcode=0x07, Dest=R1(4), Src1=R2(5)
→ [15:10]=07, [9:7]=4, [6:4]=5
→ Binary: 000111_100_101_xxx0 = 0x1E5X (X | X mod 2 == 0)
→ Stored in ROM: Low byte=0x50, High byte=0x1E
```

---

## Instruction Fetch Cycle

The CPU fetches 16-bit instructions over an 8-bit bus in **T[0] and T[1]**:

```
T[0] (Cycle 0):
  - Set PC address on address bus
  - Set IMU_LH=0 (read low byte)
  - Instruction register loads low byte

T[1] (Cycle 1):
  - PC auto-increments
  - Set IMU_LH=1 (read high byte)
  - Instruction register loads high byte
  - IR now has complete 16-bit instruction

T[2] (Cycle 2):
  - Decode opcode and execute
  - Control unit sets ALU function and routing
  - Results available (combinational ALU) or register writes occur

T[3+] (Optional):
  - Multi-cycle instructions continue
```

**Flowchart:**
```
Reset → T[0]: Fetch low → T[1]: Fetch high → T[2]: Decode & Execute → T[...] (loop)
```

---

## Project Architecture

### Core Modules

| Module | Purpose |
|--------|---------|
| **Top** | Top-level module; instantiates CPU, generates clock/reset, monitors state |
| **CPUSystem** | Master control unit; 12-state machine decodes and sequences operations |
| **ArithmeticLogicUnitSystem** | ALU integration with register/memory routing |
| **ArithmeticLogicUnit** | 16-function ALU; combinational output with flag latching |
| **RegisterFile** | 8 general-purpose registers with 2 read ports, 1 write port |
| **AddressRegisterFile** | PC (program counter), AR (address register), SP (stack pointer) |
| **InstructionMemoryUnit** | ROM interface; syncs with PC for instruction fetch |
| **DataMemory** | Raw RAM storage (64K × 8 bits); reads/writes via address/data lines |
| **DataMemoryUnit** | RAM interface wrapper; manages 8-bit to 16-bit data conversion via DataRegister |
| **DataRegister** | Latches 8-bit data from DataMemory for 16-bit word assembly |

### Data Flow

```
┌──────────────────────────────────────────────────────┐
│ CPUSystem (Control Unit)                             │
│ • Decodes IR                                         │
│ • Generates control signals                          │
│ • Manages T-state sequence                           │
└────────────────────────┬─────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────┐
│ ArithmeticLogicUnitSystem                            │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ┌─────────────────┐      ┌──────────────────┐       │
│  │ RegisterFile    │      │ AddressRegFile   │       │
│  │ (R1-R4, S1-S4)  │      │ (PC, AR, SP)     │       │
│  │ OutA, OutB      │      │ OutC, OutD, OutE │       │
│  └────────┬────────┘      └────────┬─────────┘       │
│           │                        │                 │
│           └────────┬───────────────┘                 │
│                    ↓                                 │
│             ┌──────────────┐                         │
│             │  ALU Input   │                         │
│             │  Multiplexer │                         │
│             └──────┬───────┘                         │
│                    ↓                                 │
│            ┌──────────────────┐                      │
│            │     ALU          │                      │
│            │   (16 functions) │                      │
│            └──────┬───────────┘                      │
│                   ↓                                  │
│            ALUOut, Flags                             │
│                   ↓                                  │
│  ┌─────────────────────────────────────┐             │
│  │ InstructionMemory (ROM)             │             │
│  │ DataMemory (RAM)                    │             │
│  └─────────────────────────────────────┘             │
│                                                      │
└──────────────────────────────────────────────────────┘
```

### Register Layout

**General Purpose:**
- R1, R2, R3, R4 (regular registers)
- S1, S2, S3, S4 (scratch registers)

**Address Registers:**
- PC (Program Counter) - points to next instruction
- AR (Address Register) - memory address for load/store
- SP (Stack Pointer) - stack location

---

## ALU Operations

The ALU is **combinational** (output ready in nanoseconds, no clock needed):

| FunSel | Operation |
|--------|-----------|
| 0x0 | A (passthrough) |
| 0x1 | B (passthrough) |
| 0x2 | NOT A |
| 0x3 | NOT B |
| 0x4 | A + B |
| 0x5 | A + B + Carry |
| 0x6 | A - B |
| 0x7 | A AND B |
| 0x8 | A OR B |
| 0x9 | A XOR B |
| 0xA | A NAND B |
| 0xB | A << 1 (LSL) |
| 0xC | A >> 1 (LSR) |
| 0xD | A >>> 1 (ASR) |
| 0xE | A << 1 (CSL) |
| 0xF | A >> 1 (CSR) |

**Flags** (updated when WF=1):
- Z (Zero): Result = 0
- N (Negative): Result[15] = 1
- C (Carry): Overflow from arithmetic/shift
- O (Overflow): Signed overflow

---

## Testing Strategy

The project supports two testing approaches:

### Full System Simulation
Run the entire CPU with your program in `ROM.mem`. Best for verifying instruction fetch, decode, and execution on real workloads.

### Module-Level Testing
Test individual components in isolation. Best for debugging specific subsystems or verifying a component before integrating it.

All module tests use the same infrastructure: the testbench (`sim/ModuleNameSimulation.v`) includes the module being tested and defines test cases. The `sim/Sim.v` file provides shared functionality for file I/O and test result reporting.

---

## Project Structure

```
basic_cpu/
├── Top.v                          # Testbench with clock/reset/monitoring
├── CPUSystem.v                       # Control unit & instruction decoder
├── ArithmeticLogicUnitSystem.v       # ALU integration
├── ArithmeticLogicUnit.v             # 16-function ALU
├── RegisterFile.v                    # 8 general-purpose registers
├── AddressRegisterFile.v             # PC, AR, SP registers
├── Register16bit.v                   # Single register primitive
├── InstructionMemoryUnit.v           # ROM interface
├── InstructionRegister.v             # Instruction buffering
├── DataMemoryUnit.v                  # RAM interface wrapper
├── DataMemory.v                      # Raw RAM
├── DataRegister.v                    # Data buffering
├── ROM.mem                           # Program memory (hex)
├── RAM.mem                           # Data memory (hex)
└── sim/                              # Individual test benches
    ├── CPUSystemSimulation.v
    ├── RegisterFileSimulation.v
    ├── ArithmeticLogicUnitSimulation.v
    └── [other module tests]
```

---

## Key Design Decisions

1. **One-hot T-state encoding**: T[n] = 1 when in state n, makes control logic simple
2. **Active-low enables**: Register selectors use 0 to enable, 1 to disable (common hardware convention)
3. **Combinational ALU**: Output immediately available; flags latch on clock edge if WF=1
4. **Multi-cycle memory**: 8-bit bus requires 2 cycles per 16-bit value (LH signal selects byte)
5. **Synchronous registers**: All state updates occur on rising clock edge

---

## Performance Notes

- **Clock period**: 10ns
- **Instruction fetch**: 2 cycles (T[0] + T[1])
- **Instruction decode/execute**: 1+ cycles (T[2+])
- **Total per instruction**: 3 cycles minimum
  
---
