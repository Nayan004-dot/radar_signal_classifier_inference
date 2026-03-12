def read_hex_file(filename):
    with open(filename, "r") as f:
        return f.read().split() # Reads all hex values into a list

# Load your 100-feature hex files
drone_hex = read_hex_file("input_drone.mem") 
bird_hex  = read_hex_file("input_bird.mem")
car_hex   = read_hex_file("input_car.mem")
noise_hex = read_hex_file("input_noise.mem")

def format_800bit_hex(hex_list):
    # Reverse the list so index 0 is LSB, join into a single 200-char hex string
    return "".join(hex_list[::-1])

# Write to the ROM file
with open("test_vectors.mem", "w") as f:
    f.write(format_800bit_hex(drone_hex) + "\n")
    f.write(format_800bit_hex(bird_hex)  + "\n")
    f.write(format_800bit_hex(car_hex)   + "\n")
    f.write(format_800bit_hex(noise_hex) + "\n")

print("test_vectors.mem created successfully!")