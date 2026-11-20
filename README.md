# JD-XA Editor

A native macOS editor for the **Roland JD-XA** synthesizer, written in Swift and SwiftUI. It talks to the JD-XA over MIDI with Roland System Exclusive (SysEx) messages, so you can change sound parameters from your computer instead of on the synth's front panel.

> **Status:** Early development. MIDI connectivity, SysEx message building and a test panel work. The Digital part editor is partly built: the oscillator and LFO sections exist, and the filter and amp sections are placeholders.

## Features

- **Sidebar navigation.** Digital Parts 1–4 and the MIDI Test Panel are one click away, and a connection panel at the bottom of the sidebar picks the MIDI output. The JD-XA is selected automatically when it's connected; without a device you can still edit offline.
- **Roland SysEx engine** (`JDXASysEx.swift`):
  - DT1 (Data Set 1) parameter changes and RQ1 (Data Request 1) parameter requests
  - Automatic Roland checksum calculation
  - Universal Device Inquiry (Identity Request)
  - Parsing of incoming Device Inquiry and DT1 responses
  - Hex formatting and validation of messages
- **MIDI Test Panel** for sending individual messages and viewing a message log:
  - Digital OSC basic waveforms and their variations
  - SuperNATURAL (PCM) waveforms
  - Program reverb type
  - Digital part HPF cutoff
- **Digital part editor** (work in progress):
  - Partial tiles for Partials 1–3 (⌘1–⌘3), each showing its waveform and an on/off switch
  - Every section of the partial on one scrolling page, color-coded like the hardware panel: OSC, FILTER, AMP, LFO and MOD LFO
  - Edits are kept per part and partial while you move around the app
  - Oscillator controls: waveform, PCM wave picker, pitch, detune, PWM depth, pulse width and pitch envelope
  - LFO and Mod LFO views with shape selection and tempo-synced rates
  - Custom controls: dial knobs and vertical sliders
  - A categorized catalog of the JD-XA's PCM waveforms

## Requirements

- macOS 13.6 or later
- Xcode 15 or later (Swift 5)
- A Roland JD-XA connected over USB or a MIDI interface

## Getting started

1. Clone the repository:
   ```sh
   git clone https://github.com/PaleSkinnySwede/JD-XA_Editor.git
   cd JD-XA_Editor
   ```
2. Open `JD-XA Editor v3.xcodeproj` in Xcode.
3. Select the **JD-XA Editor v3** scheme and a **My Mac** destination.
4. Build and run (⌘R).

### Usage

1. Connect the JD-XA and turn it on.
2. The editor picks the JD-XA automatically. If it doesn't, choose it in the MIDI output picker at the bottom of the sidebar (click ↻ to rescan).
3. Click **Send Device Inquiry** in the sidebar to check the connection.
4. Choose a Digital part in the sidebar and edit its partials, or send single messages from the **MIDI Test Panel**.

> On the JD-XA, make sure the SysEx receive setting is turned on. The editor uses device ID `10H`.

## Project structure

```
JD-XA Editor v3/
├── JD_XA_Editor_v3App.swift      # App entry point
├── ContentView.swift             # Main window: sidebar navigation + connection panel
├── MIDIManager.swift             # CoreMIDI client, ports, device scanning, send/receive
├── JDXASysEx.swift               # Roland SysEx message building and parsing
├── JDXATestView.swift            # Test panel and its view model
├── Constants.swift               # Shared constants (e.g. LFO tempo-sync rates)
├── DOscWaveform.swift            # Digital oscillator waveform types
├── DialKnob.swift                # Custom rotary knob control
├── VerticalSlider.swift          # Custom vertical slider control
├── Models/
│   ├── MIDIParameters.swift      # Parameter definitions and addresses
│   └── PCMWaveform.swift         # PCM waveform catalog and categories
├── Services/
│   └── MIDIService.swift         # Higher-level parameter send helpers
└── Views/
    ├── DigitalPanel/             # Digital part editor, partial tiles, oscillator, theme and shared components
    └── LFO/                      # LFO and Mod LFO views
```

## SysEx reference

Messages use the standard Roland format:

```
F0 41 10 00 00 00 0F <cmd> <address (4 bytes)> <data...> <checksum> F7
```

| Field        | Value                            |
|--------------|----------------------------------|
| Manufacturer | `41H` (Roland)                   |
| Device ID    | `10H`                            |
| Model ID     | `00 00 00 0FH` (JD-XA)           |
| Command      | `12H` = DT1, `11H` = RQ1         |
| Checksum     | `128 − (sum of address + data mod 128)` |

Parameter addresses come from the Roland JD-XA MIDI Implementation document.

## Roadmap

- Filter and amp sections of the Digital partial editor
- Analog part editor
- Effects editor
- Reading the current patch from the synth (RQ1) and syncing the UI
- Saving and loading patches

## License

This project is licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE) for details.

*Roland and JD-XA are trademarks of Roland Corporation. This project is not affiliated with or endorsed by Roland.*
