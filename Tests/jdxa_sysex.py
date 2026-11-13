# Python script to generate sysex messages for the Roland JD-XA

import sys
import os
import struct
import binascii


# JD-XA sysex message format
# F0 41 11 00 00 00 0F 12

# F0: Start of sysex message
# 41: Roland manufacturer ID
# 11: Device ID (JD-XA)
# 00: Model ID (00 = JD-XA)
# 00: Model ID (00 = JD-XA)
# 00: Model ID (00 = JD-XA)
# 0F: Model ID (0F = JD-XA)
# 12: Command ID (DT1)

# Scan for JD-XA MIDI device
def scan_midi_devices():
    import rtmidi
    midi_in = rtmidi.MidiIn()
    midi_out = rtmidi.MidiOut()
    print("Available MIDI input ports:")
    for i, port_name in enumerate(midi_in.get_ports()):
        print(f"{i}: {port_name}")
    print("Available MIDI output ports:")
    for i, port_name in enumerate(midi_out.get_ports()):
        print(f"{i}: {port_name}")

# Select the MIDI input port
def select_midi_port():
    import rtmidi
    midi_in = rtmidi.MidiIn()
    port_index = int(input("Select the MIDI input port index: "))
    port_name = midi_in.get_ports()[port_index]
    return port_name

# Select the MIDI output port
def select_midi_port():
    import rtmidi
    midi_out = rtmidi.MidiOut()
    port_index = int(input("Select the MIDI output port index: "))
    port_name = midi_out.get_ports()[port_index]
    return port_name

# Send a sysex message
def send_sysex(port, sysex):
    print (f"Sending sysex message: {binascii.hexlify(sysex)}")
    port.send_message(sysex)

# Generate a sysex message
def generate_sysex():
    # JD-XA sysex message format
    # F0 41 10 00 00 12
    sysex = bytearray() # Create a bytearray to store the sysex message
    sysex.append(0xF0)        # Start of sysex message
    sysex.append(0x41)        # Roland manufacturer ID
    sysex.append(0x11)        # Device ID (JD-XA)
    sysex.append(0x00 & 0x00 & 0x00 & 0x0F)        # Model ID (00 = JD-XA)
    sysex.append(0x12)        # Command ID (DT1)
    # Choose the address for the reverb type
    sysex.append(0x18)        # Temporary Program
    sysex.append(0x00 & 0x02) # Program Reverb
    sysex.append(0x00 & 0x02) # Reverb Type

    # Calculate the checksum
    checksum = 0
    for byte in sysex[8:]:
        checksum += byte
    checksum = (128 - (sum % 128))
    checksum = checksum & 0x7F

    return sysex

# Receive a sysex message
def receive_sysex(port):
    print("Waiting for sysex message...")
    while True:
        msg = port.get_message()
        if msg:
            print(f"Received sysex message: {binascii.hexlify(msg[0])}")
            break

# Main function
def main():
    # Scan for MIDI devices
    scan_midi_devices()

    # Select the MIDI output port
    port_name = select_midi_port()

    # Open the selected MIDI output port
    import rtmidi
    midi_out = rtmidi.MidiOut()
    port = midi_out.open_port(port_name)

    # Generate a sysex message
    sysex = generate_sysex()
