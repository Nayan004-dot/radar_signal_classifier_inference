# Hardware Accelerator for Radar Signal Classifier (Inference Engine)

This repository contains a high-performance **Verilog implementation** of a Multi-Layer Perceptron (MLP) optimized for real-time radar signal classification on FPGAs. The design utilizes a custom **Controller-Datapath** architecture to perform quantized inference with minimal hardware resource overhead.

## 🚀 Key Features
* **FSM-Based Controller:** Implements a robust 5-state synchronous Finite State Machine (nn_fsm.v) to manage sequential layer processing and resource reuse.
* **Q7 Fixed-Point Math:** Utilizes signed 8-bit weights and 32-bit accumulators with **7-bit arithmetic shifting** to simulate floating-point precision with integer-only logic.
* **Zero-Overhead ReLU:** Hardware-efficient activation function implemented via 32-bit comparison logic, optimized for high-frequency FPGA synthesis.
* **Hardware-in-the-Loop (HIL) Ready:** A top_level wrapper interfaces the AI core with physical FPGA buttons, switches, and LEDs for real-time, on-chip verification.

## 🏗️ Hardware Architecture

### 1. AI Core (nn_fsm.v)
The core inference engine processes a flattened input vector (100 features) through three fully-connected layers:
* **Layer 1:** 100 Inputs → 64 Neurons (ReLU)
* **Layer 2:** 64 Inputs → 32 Neurons (ReLU)
* **Layer 3:** 32 Inputs → 4 Neurons (Output Scores)
* **Argmax:** Determines the final classification based on the highest signed output score.

### 2. System Integration (top_level.v)
* **Edge Detection:** Synchronizes physical button presses (start_btn) to a single-cycle pulse.
* **On-Chip ROM:** Uses Block RAM (rom_style = "block") to store test vectors, allowing for portable, PC-free testing.

## 📂 Repository Structure
* **rtl/**: top_level.v (Wrapper), nn_fsm.v (Core Logic)
* **data/**: test_vectors.mem, weights_biases/ (.mem files)
* **tb/**: tb_top_level.sv (Testbench)
* **docs/**: inference_waveform.png, console_output.png

## 🧪 Functional Verification
The design is validated using a hierarchical testbench (tb_top_level.sv) in a Linux-based Vivado environment. The verification process ensures hardware-to-software parity across multiple radar signal classes.

### **Verification Methodology**
* **Self-Checking Testbench:** Monitors internal layer registers (l1, l2, l3) using hierarchical references to ensure correct intermediate computations.
* **Latency Analysis:** Validates timing-accurate state transitions from IDLE to DONE, ensuring real-time constraints are met.
* **HIL Simulation:** Mimics physical button debouncing and switch-based ROM addressing to prepare the design for bitstream generation.

### **Simulation Results (Xilinx Vivado)**
The following waveform demonstrates the successful execution of the inference cycle. The led_done flag pulses high only after the final classification is latched.

![Inference Waveform](docs/inference_waveform.png)

### **Classification Output Log**
The log below confirms the signed 32-bit scores for each class. The high score separation indicates strong model confidence and correct fixed-point scaling.

![Console Output](docs/console_output.png)

## 🛠️ Tech Stack
* **HDL:** Verilog / SystemVerilog
* **EDA Tools:** Xilinx Vivado (Synthesis & Simulation)
* **Environment:** Linux (Ubuntu)
* **Target Hardware:** Xilinx Artix-7 (Basys 3 / Nexys A7)

## 📝 License
Developed for the BITS Pilani FPGA Hackathon. Intended for academic and research purposes.
