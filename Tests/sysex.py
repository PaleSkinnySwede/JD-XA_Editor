# Send and receive sysex from a Roland JD-XA

'''
Device Inquiry SysEx Message:   [F0 7E 7F 06 01 F7]
Roland JD-XA response:          [7E 10 06 02 41 0F 03 00 00 00 03 00 00]
'''

import mido
import signal
import sys
import time

# List available MIDI output ports
output_ports = mido.get_output_names()
print("Available MIDI output ports:")
for i, port in enumerate(output_ports):
    print(f"{i}: {port}")

# Select the MIDI output port
output_port_index = int(input("Select the MIDI output port index: "))
output = mido.open_output(output_ports[output_port_index])

# Define the Universal System Exclusive Message (Device Inquiry)
# sysex_message = [0xF0, 0x7E, 0x7F, 0x06, 0x01, 0xF7] // Device Inquiry Request
# sysex_message = [0xF0, 0x41, 0x10, 0x00, 0x00, 0x00, 0x0F, 0x12, 0x18, 0x00, 0x02, 0x01, 0x02] // "Program Reverb Type 'Room 2'"
# sysex_message = [0xF0, 0x41, 0x10, 0x00, 0x00, 0x00, 0x0F, 0x12, 0x1A, 0x01, 0x20, 0x39, 0x40] // "Digital Part 1, Digital Partial 1, HPF Cutoff '64'"
sysex_message = [0xF0, 0x41, 0x10, 0x00, 0x00, 0x00, 0x0F, 0x12, 0x1A, 0x01, 0x20, 0x00, 0x04] // "Sine-A, for Digital Part 1, Digital Partial 1, D-OSC Waveform"
checksum = (128 - (sum(sysex_message[7:]) % 128)) % 128
sysex_message.append(checksum)
sysex_message.append(0xF7)

# List available MIDI input ports
input_ports = mido.get_input_names()
print("Available MIDI input ports:")
for i, port in enumerate(input_ports):
    print(f"{i}: {port}")

# Select the MIDI input port
input_port_index = int(input("Select the MIDI input port index: "))
input = mido.open_input(input_ports[input_port_index])

# Send the SysEx message
print(f"Sending SysEx message: {sysex_message}")
output.send(mido.Message.from_bytes(sysex_message))

# Function to handle termination signal
def signal_handler(sig, frame):
    print('Terminating program...')
    output.close()
    input.close()
    sys.exit(0)

# Register the signal handler for SIGINT (Ctrl+C)
signal.signal(signal.SIGINT, signal_handler)

# Wait for a response and print it
print('Waiting for response... Press Ctrl+C to terminate.')
try:
    while True:
        for msg in input.iter_pending():
            print(msg)
        time.sleep(0.1)
except KeyboardInterrupt:
    signal_handler(None, None)

# Close the ports
output.close()
input.close()
