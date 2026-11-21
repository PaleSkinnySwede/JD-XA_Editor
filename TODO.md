# TODO

Where the project stands and what comes next. Last reviewed: 2026-11-21.

## Where we are

**Works**
- CoreMIDI client, output/input ports, device scanning and device picker (`MIDIManager.swift`). Devices are picked by CoreMIDI unique ID and rescanned on hot-plug; the JD-XA is selected automatically when it appears.
- Incoming SysEx is reassembled across packets (`SysExAssembler`), parsed and shown in the Test Panel log, with a note when the checksum is wrong.
- Roland SysEx building: DT1, RQ1, Device Inquiry, checksum (`JDXASysEx.swift`).
- Test Panel: device inquiry, basic/SuperNATURAL waveforms, reverb type, HPF cutoff, message log of sent and received messages (`JDXATestView.swift`).
- Main window: sidebar (Digital Parts 1–4, MIDI Test Panel) with a MIDI connection panel; JD-XA auto-selected when connected.
- Digital part editor: partial tiles (⌘1–3) and all sections of a partial on one page as color-coded cards. State lives in `DigitalEditorStore`, so it survives switching parts/partials.
- OSC tab sends waveform, variation, pitch, detune, PWM depth and pulse width.
- PCM waveform catalog (`Models/PCMWaveform.swift`).
- Python scripts in `Tests/` for poking the synth outside the app.

**UI only (not sent to the synth yet)**
- OSC: PW Shift, Super Saw detune, PCM wave gain, pitch envelope (depth/attack/decay).
- Partial On/Off toggle.
- Everything in the LFO and Mod LFO views.

**Not started**
- Analog part, drums, effects, program/common parameters.
- Reading patches from the synth (RQ1) and syncing the UI.
- Saving/loading patches.

## Bugs — fix first

- [x] **Checksum can crash.** `calculateChecksum` does `data.reduce(0, +)` on `[UInt8]`, which traps on overflow once address + data sum past 255 (e.g. high-offset params like `ampKeyFollow` 0x3C with a large value). Sum as `Int`. (`JDXASysEx.swift`)
- [x] **Part number is ignored.** `DigitalPartParameter.address` always used `1A 01 …`, so Parts 2–4 edited Part 1. *(Now uses the Temporary Tone starts 1A 00/20/40/60 + SN Synth Tone 01 + Partial 20–22, e.g. Part 2 Partial 3 = `1A 21 22 xx`.)*
- [x] **PCM wave clear is hard-coded** to Part 1 / Partial 1 in `MIDIService.setOscillatorWaveform`. *(Uses the part and partial's address now.)*
- [x] **PCM waves never get sent from the Digital panel.** `updatePCMWaveform` sets the waveform to `.superSaw` instead of PCM (7) and then calls `setOscillatorWaveform`, which *clears* the wave number. (`OscillatorView.swift`)
- [x] **Wave number encoding is wrong above 255.** `changeSuperNaturalWaveform` only fills two nibbles and masks `(value >> 4) & 0x0F`, so waves 256–450 come out wrong. Encode all four nibbles properly.
- [x] The PCM picker sheet was never presented (`showingPCMPicker` was set but nothing showed `PCMWaveformPicker`).
- [x] **Duplicate sends.** `updateWaveform`/`updatePCMWaveform` send MIDI *and* the `.onChange` handlers in `OscillatorView` send again.
- [x] **Out-of-bounds reads in the parser.** `processSysExMessage` checks `count >= 7` then reads `message[7]`; `processDT1Response` checks `>= 11` then reads `[8...11]` and from index 12. (`JDXASysEx.swift`)
- [x] Device Inquiry reply read the software version from bytes 9–12; it's in bytes 10–13.
- [x] `setOscWaveType` uses address `1A 00 20 00` (every other call uses `1A 01 …`). Fix or delete — it looks unused.
- [x] Device selection used the CoreMIDI destination *index*, which shifts when devices are plugged/unplugged. *(Uses the endpoint's unique ID now.)*

## Next up

1. [x] Fix the bugs above, with unit tests. *(Unit tests for checksum, nibbles, addresses and parsing are in `JD_XA_Editor_v3Tests.swift`; per-part addresses are covered by `testPartBlockAddresses`.)*
   - Checksum against known-good messages from the Python scripts / synth.
   - Address building for every part/partial.
   - Nibble encoding for wave numbers 1, 255, 256, 450.
2. [x] Route incoming MIDI to the app: reassemble SysEx across packets, parse it, and show it in the Test Panel log. *(Not yet tried against the synth: check that Device Inquiry shows a reply.)* Channel messages (notes, CCs) are ignored for now.
3. [ ] Wire the remaining OSC controls (PW Shift, Super Saw, Gain, pitch env).
4. [ ] Wire LFO and Mod LFO to MIDI (addresses already in `MIDIParameters.swift`). `LFOViewModel`/`ModLFOViewModel` live in `DigitalPartialState`, which knows the part/partial.
5. [x] Build the Filter card: type, slope, cutoff, resonance, HPF, envelope (depth + ADSR with graph), key follow, velocity and aftertouch sensitivity. All sent to the synth (`FilterView.swift`). *Value ranges follow the SuperNATURAL synth layout (mode 0–7, ±63 as 1–127, key follow 54–74); check them against the MIDI Implementation doc.*
6. [x] Build the Amp card: level, pan, envelope (ADSR with graph), key follow, velocity and aftertouch sensitivity. All sent to the synth (`AmpView.swift`). *Same encoding caveat as the filter; pan is sent as 0–127 with center 64.*
7. [ ] Wire the Partial On/Off toggle.

## Later

- [ ] RQ1: request the current program and populate the UI from the reply.
- [ ] Analog part editor.
- [ ] Effects editor (program reverb/delay/effects 1–2).
- [ ] Program common parameters (name, tempo, etc.).
- [ ] Save/load patches to disk (`.syx`).
- [ ] Throttle/coalesce messages while dragging knobs and sliders.
- [ ] `sendPacket` sends one `MIDIPacket` and rejects messages over 256 bytes; bulk dumps (patch send) will need `MIDISendSysex` or a larger packet list.
- [ ] Verify every value range/offset against the MIDI Implementation doc (e.g. detune, pitch env depth, PCM gain).

## Cleanup

- [x] Add a `.gitignore` (`.DS_Store`, `xcuserdata/`, `*.xcuserstate`) and untrack `UserInterfaceState.xcuserstate`.
- [x] One `MIDIService` per app instead of one per `DigitalPartialView` render *(owned by `DigitalEditorStore`)*. Still to consider: making the SysEx layer a `struct`.
- [x] Remove the duplicate device picker (sidebar and Test Panel).
- [x] Merge `buildPCMMessage` into `buildSysExMessage` — they do the same thing.
- [ ] Move loose files in the app root (`DialKnob`, `VerticalSlider`, `DOscWaveform`, …) into `Views/Components` and `Models`.
- [ ] Remove `oscPW`, which duplicates `oscPulseWidth`; fix the `fltEnvDecayTIme` typo.
- [ ] Replace `print` with `os.Logger`.
- [ ] Python scripts in `Tests/`:
  - `sysex.py` uses `//` comments, so it won't run; its checksum also includes the command byte (should start at the address, index 8).
  - `jdxa.py` is unfinished (wrong device ID `0x11`, broken model ID, `sum` used as a variable, duplicate `select_midi_port`). Fix or delete.
  - Add a `requirements.txt` (`mido`, `python-rtmidi`).
