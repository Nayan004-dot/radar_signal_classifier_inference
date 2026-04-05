# Hardware Accelerator for Radar Signal Classifier (Inference Engine)

This repository contains a high-performance **Verilog implementation** of a Multi-Layer Perceptron (MLP) optimized for real-time radar signal classification on FPGAs. The design utilizes a custom **Controller-Datapath** architecture to perform quantized inference with minimal hardware resource overhead.

## 🚀 Key Features
* **FSM-Based Controller:** Implements a robust 5-state synchronous Finite State Machine (`nn_fsm.v`) to manage sequential layer processing and resource reuse.
* **Q7 Fixed-Point Math:** Utilizes signed 8-bit weights and 32-bit accumulators with **7-bit arithmetic shifting** to simulate floating-point precision with integer-only logic.
* **Zero-Overhead ReLU:** Hardware-efficient activation function implemented via 32-bit comparison logic, optimized for high-frequency FPGA synthesis.
* **Hardware-in-the-Loop (HIL) Ready:** A `top_level` wrapper interfaces the AI core with physical FPGA buttons, switches, and LEDs for real-time, on-chip verification.

## 🏗️ Hardware Architecture

### 1. AI Core (`nn_fsm.v`)
The core inference engine processes a flattened input vector (100 features) through three fully-connected layers:
* **Layer 1:** 100 Inputs → 64 Neurons (ReLU)
* **Layer 2:** 64 Inputs → 32 Neurons (ReLU)
* **Layer 3:** 32 Inputs → 4 Neurons (Output Scores)
* **Argmax:** Determines the final classification (Drone, Bird, Car, or Plane) based on the highest signed output score.

### 2. System Integration (`top_level.v`)
* **Edge Detection:** Synchronizes physical button presses (`start_btn`) to a single-cycle pulse, preventing multiple triggers.
* **On-Chip ROM:** Uses Block RAM (`rom_style = "block"`) to store test vectors, allowing for portable, PC-free testing via hardware switches.

## 📂 Repository Structure
```text
├── rtl/
│   ├── top_level.v         # FPGA Top-level Wrapper (I/O & ROM Interface)
│   └── nn_fsm.v            # MLP Inference Core & FSM Logic
├── data/                   # Hex-encoded parameters for $readmemh
│   ├── test_vectors.mem    # Sample radar signals for on-chip ROM
│   └── weights_biases/     # Quantized memory files (.mem)
├── tb/
│   └── tb_top_level.sv     # Hierarchical Top-level Testbench
└── docs/
    ├── inference_waveform.png
    └── console_output.png
