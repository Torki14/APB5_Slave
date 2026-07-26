# APB Slave with a Byte-Strobed Register File

A Verilog implementation of an AMBA APB slave peripheral, compliant with the classic 3-state APB operating model (`IDLE` → `SETUP` → `ACCESS`) from the [AMBA APB Protocol Specification (ARM IHI 0024D)](https://developer.arm.com/documentation/ihi0024/latest/). The slave exposes a configurable register file with byte-lane write strobes, address validation, and a `PSLVERR` error response.

## Features

- Full **IDLE / SETUP / ACCESS** APB operating state machine
- Configurable **wait states** via the `WAIT_STATES` parameter (extends `PREADY` low, per spec)
- **Byte-strobe writes** using `PSTRB` — supports sparse writes to individual bytes within a register
- **Address validation** — checks both alignment and range, asserting `PSLVERR` on invalid accesses
- Fully parameterized: address width, data width, and register count

## Architecture

```
   PCLK    ───────►┌───────────────────┐
   PRESETn ───────►│                   │
   PSEL    ───────►│                   │◄─── PREADY
   PENABLE ───────►│    apb_slave      │◄─── PRDATA
   PWRITE  ───────►│                   │◄─── PSLVERR
   PADDR   ───────►│   (Register File  │
   PWDATA  ───────►│    NUM_REGS x     │
   PSTRB   ───────►│    DATA_WIDTH)    │
                    └───────────────────┘
```

## Module Interface — `apb_slave`

### Parameters

| Parameter     | Default | Description                          |
|---------------|:-------:|----------------------------------------|
| `ADDR_WIDTH`  | 32      | Width of `PADDR`                       |
| `DATA_WIDTH`  | 32      | Width of `PWDATA` / `PRDATA`           |
| `NUM_REGS`    | 16      | Number of addressable registers        |
| `WAIT_STATES` | 0       | Extra cycles `PREADY` is held low per access |

### Ports

| Port      | Direction | Width         | Description                              |
|-----------|-----------|:-------------:|--------------------------------------------|
| `PCLK`    | input     | 1             | Clock                                       |
| `PRESETn` | input     | 1             | Active-low asynchronous reset               |
| `PSEL`    | input     | 1             | Slave select                                |
| `PENABLE` | input     | 1             | Enable — high during the ACCESS phase       |
| `PWRITE`  | input     | 1             | 1 = write, 0 = read                         |
| `PADDR`   | input     | `ADDR_WIDTH`  | Byte address                                |
| `PWDATA`  | input     | `DATA_WIDTH`  | Write data                                  |
| `PSTRB`   | input     | `DATA_WIDTH/8`| Byte-lane write strobes                     |
| `PRDATA`  | output    | `DATA_WIDTH`  | Read data                                   |
| `PREADY`  | output    | 1             | Transfer-complete handshake                 |
| `PSLVERR` | output    | 1             | Error response (misaligned / out-of-range)  |

## Addressing

`PADDR` is split into a register index and a byte-strobe offset:

- `PADDR[STRB_IDXs-1:0]` — must be `0` (word-aligned); otherwise the access is flagged invalid
- `PADDR[REGS_IDXs+STRB_IDXs-1:STRB_IDXs]` — selects the target register (`reg_idx`)

An access is valid only if it is **aligned** and `reg_idx` is **in range** (`< NUM_REGS`). Invalid accesses assert `PSLVERR` once `PREADY` completes the transfer.

## Verification

`apb_slave_tb.v` is a directed testbench that:
1. Preloads the register file from `regfile_init.dat`.
2. Applies reset, then performs a baseline read from address `0x0`.
3. Performs three back-to-back byte-strobed writes to register `0x0` (`PSTRB` = `0001`, `0010`, `1100`), building up a value one byte-lane at a time.
4. Reads back register `0x0` to confirm the accumulated write result.
5. Reads register `0x8` to confirm normal addressing across the register file.

## Running the Simulation

```bash
# ModelSim / QuestaSim
vlog apb_slave.v apb_slave_tb.v
vsim -c apb_slave_tb -do "run -all"
```

Make sure `regfile_init.dat` is in the simulation's working directory, since it's loaded via a relative path in the testbench.

## Tools

Verilog, ModelSim/QuestaSim

## Reference

[AMBA APB Protocol Specification, ARM IHI 0024D](https://developer.arm.com/documentation/ihi0024/latest/)

## Author

Mohamed Torki Bassuni — [LinkedIn](https://linkedin.com/in/muhammad-torki) · [GitHub](https://github.com/Torki14)
