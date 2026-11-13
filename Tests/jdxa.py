import mido
import rtmidi

# Function to send a MIDI Control Change message
def send_midi_cc(port, channel, control, value):
    msg = mido.Message('control_change', channel=channel, control=control, value=value)
    print(f"Sending MIDI CC: Channel={channel+1}, Control={control}, Value={value}")
    port.send(msg)

# Function to send NRPN messages
def send_nrpn(port, channel, msb, lsb, value):
    send_midi_cc(port, channel, 99, msb)  # NRPN MSB
    send_midi_cc(port, channel, 98, lsb)  # NRPN LSB
    send_midi_cc(port, channel, 6, value)  # Data Entry MSB
    send_midi_cc(port, channel, 38, 0)  # Data Entry LSB (if needed)
    # Reset NRPN
    send_midi_cc(port, channel, 99, 127)
    send_midi_cc(port, channel, 98, 127)

# List available MIDI output ports
midi_out = mido.get_output_names()
print("Available MIDI output ports:")
for i, port_name in enumerate(midi_out):
    print(f"{i}: {port_name}")

# Select the MIDI output port
port_index = int(input("Select the MIDI output port index: "))
port_name = midi_out[port_index]

# Open the selected MIDI output port
with mido.open_output(port_name) as port:
    # Set the MIDI channel (0-15)
    channel = 4  # MIDI channel 5

    # NRPN MSB and LSB for D-OSC waveform in a Digital Partial
    nrpn_msb = 0x00  # Correct MSB for waveform change
    nrpn_lsb = 0x18  # Correct LSB for waveform change

    # Value to set the waveform (0-127)
    waveform_value = 3  # Example value for a specific waveform

    # Send the NRPN message
    send_nrpn(port, channel, nrpn_msb, nrpn_lsb, waveform_value)

print("NRPN message sent to change the D-OSC waveform in a Digital Partial.")
