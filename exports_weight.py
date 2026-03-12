import numpy as np

# Load weights and biases
w1 = np.loadtxt("w1.txt"); b1 = np.loadtxt("b1.txt")
w2 = np.loadtxt("w2.txt"); b2 = np.loadtxt("b2.txt")
w3 = np.loadtxt("w3.txt"); b3 = np.loadtxt("b3.txt")

# Scale by 128 (2^7)
SCALE_W = 128.0
SCALE_B = SCALE_W * SCALE_W

# Quantize and clip weights to 8-bit signed
q_w1 = np.clip(np.round(w1 * SCALE_W), -128, 127).astype(np.int8)
q_w2 = np.clip(np.round(w2 * SCALE_W), -128, 127).astype(np.int8)
q_w3 = np.clip(np.round(w3 * SCALE_W), -128, 127).astype(np.int8)

# Quantize biases to 32-bit signed
q_b1 = np.round(b1 * SCALE_B).astype(np.int32)
q_b2 = np.round(b2 * SCALE_B).astype(np.int32)
q_b3 = np.round(b3 * SCALE_B).astype(np.int32)

# Export Transposed (Neuron-Major) Weights
np.savetxt("w1_neuron_major.mem", q_w1.T.flatten().astype(np.uint8), fmt="%02x")
np.savetxt("w2_neuron_major.mem", q_w2.T.flatten().astype(np.uint8), fmt="%02x")
np.savetxt("w3_neuron_major.mem", q_w3.T.flatten().astype(np.uint8), fmt="%02x")

# Export Biases
np.savetxt("q_b1.mem", q_b1.flatten().astype(np.uint32), fmt="%08x")
np.savetxt("q_b2.mem", q_b2.flatten().astype(np.uint32), fmt="%08x")
np.savetxt("q_b3.mem", q_b3.flatten().astype(np.uint32), fmt="%08x")

print("Weights and Biases exported successfully!")