# JD-XA Editor

A native macOS editor for the **Roland JD-XA** synthesizer, written in Swift and SwiftUI. It talks to the JD-XA over MIDI with Roland System Exclusive (SysEx) messages, so you can change sound parameters from your computer instead of on the synth's front panel.

> **Status:** Early development. MIDI connectivity, SysEx message building and a test panel work. The Digital part editor is partly built: the oscillator and LFO sections exist, and the filter and amp sections are placeholders.

## Features

- **MIDI device selection.** Scans CoreMIDI for connected devices and lets you choose one from the sidebar.
- **Roland SysEx engine** (`JDXASysEx.swift`):
  - DT1 (Data Set 1) parameter changes and RQ1 (Data Request 1) parameter requests
  - Automatic Roland checksum calculation
  - Universal Device Inquiry (Identity Request)
  - Parsing of incoming Device Inquiry and DT1 responses
  - Hex formatting and validation of messages
- **Test panel** for sending individual messages and viewing a live message log:
  - Digital OSC basic waveforms and their variations
  - SuperNATURAL (PCM) waveforms
  - Program reverb type
  - Digital part HPF cutoff
- **Digital panel** (work in progress):
  - Tabs for Digital Parts 1–4
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
2. Choose the synth in the **MIDI Device** picker in the sidebar.
3. On the **Test Panel** tab, click **Send Device Inquiry** to check the connection. The synth's reply appears in the message log.
4. Send parameter changes from the Test Panel, or edit sounds on the **Digital** tab.

> On the JD-XA, make sure the SysEx receive setting is turned on. The editor uses device ID `10H`.

## Project structure

```
JD-XA Editor v3/
├── JD_XA_Editor_v3App.swift      # App entry point
├── ContentView.swift             # Main window: device sidebar + tabs
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
    ├── DigitalPanel/             # Digital part/partial editor, oscillator, theme
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
