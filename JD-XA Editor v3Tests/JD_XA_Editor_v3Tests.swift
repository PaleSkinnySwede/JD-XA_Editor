//
//  JD_XA_Editor_v3Tests.swift
//  JD-XA Editor v3Tests
//
//  Created by David Lilja on 2024-12-27.
//

import XCTest
@testable import JD_XA_Editor_v3

/// Roland DT1 header for the JD-XA: F0 41 10 00 00 00 0F 12
private let dt1Header: [UInt8] = [0xF0, 0x41, 0x10, 0x00, 0x00, 0x00, 0x0F, 0x12]

// MARK: - Checksum

final class ChecksumTests: XCTestCase {

    func testChecksumOfKnownMessage() {
        // Program Reverb Type = 3: 18+00+02+01+03 = 0x1E (30), 128 - 30 = 98 = 0x62
        XCTAssertEqual(JDXASysEx.calculateChecksum([0x18, 0x00, 0x02, 0x01, 0x03]), 0x62)
    }

    func testChecksumIsZeroWhenSumIsMultipleOf128() {
        XCTAssertEqual(JDXASysEx.calculateChecksum([0x40, 0x40]), 0x00)
        XCTAssertEqual(JDXASysEx.calculateChecksum([]), 0x00)
    }

    func testChecksumDoesNotOverflowWhenSumExceeds255() {
        // 7F*5 = 635; 635 % 128 = 123; 128 - 123 = 5. Used to trap on UInt8 overflow.
        XCTAssertEqual(JDXASysEx.calculateChecksum([0x7F, 0x7F, 0x7F, 0x7F, 0x7F]), 0x05)
    }

    func testChecksumHighOffsetParameter() {
        // ampKeyFollow (0x3C) on Part 1 / Partial 1 with value 0x7F:
        // 1A+01+20+3C+7F = 246; 246 % 128 = 118; 128 - 118 = 10
        XCTAssertEqual(JDXASysEx.calculateChecksum([0x1A, 0x01, 0x20, 0x3C, 0x7F]), 0x0A)
    }
}

// MARK: - Message building

final class MessageBuildingTests: XCTestCase {
    let sysEx = JDXASysEx()

    func testReverbTypeMessageBytes() {
        let message = sysEx.changeProgramReverbType(to: 3)
        XCTAssertEqual(message, dt1Header + [0x18, 0x00, 0x02, 0x01, 0x03, 0x62, 0xF7])
        XCTAssertTrue(sysEx.validateMessage(message))
    }

    func testMultiByteParameterChange() {
        let message = sysEx.createParameterChange(address: [0x1A, 0x01, 0x20, 0x35],
                                                  data: [0x00, 0x01, 0x0C, 0x02])
        // 1A+01+20+35+00+01+0C+02 = 127 -> checksum 1
        XCTAssertEqual(message, dt1Header + [0x1A, 0x01, 0x20, 0x35, 0x00, 0x01, 0x0C, 0x02, 0x01, 0xF7])
    }

    func testParameterRequestUsesRQ1() {
        let message = sysEx.createParameterRequest(address: [0x18, 0x00, 0x00, 0x00],
                                                   size: [0x00, 0x00, 0x00, 0x10])
        XCTAssertEqual(message[7], 0x11)
        XCTAssertTrue(sysEx.validateMessage(message))
    }

    func testValidateRejectsBadChecksum() {
        var message = sysEx.changeProgramReverbType(to: 3)
        message[message.count - 2] = 0x00
        XCTAssertFalse(sysEx.validateMessage(message))
    }

    func testDeviceInquiry() {
        XCTAssertEqual(sysEx.createDeviceInquiry(), [0xF0, 0x7E, 0x7F, 0x06, 0x01, 0xF7])
    }
}

// MARK: - Wave number nibble encoding

final class WaveNumberEncodingTests: XCTestCase {
    let sysEx = JDXASysEx()

    func testNibbleEncoding() {
        XCTAssertEqual(JDXASysEx.encodeNibbles(0), [0x00, 0x00, 0x00, 0x00])
        XCTAssertEqual(JDXASysEx.encodeNibbles(1), [0x00, 0x00, 0x00, 0x01])
        XCTAssertEqual(JDXASysEx.encodeNibbles(255), [0x00, 0x00, 0x0F, 0x0F])
        XCTAssertEqual(JDXASysEx.encodeNibbles(256), [0x00, 0x01, 0x00, 0x00])
        XCTAssertEqual(JDXASysEx.encodeNibbles(450), [0x00, 0x01, 0x0C, 0x02])
        XCTAssertEqual(JDXASysEx.encodeNibbles(0xFFFF), [0x0F, 0x0F, 0x0F, 0x0F])
    }

    func testEveryNibbleIsAValidDataByte() {
        for value in 0...450 {
            XCTAssertTrue(JDXASysEx.encodeNibbles(value).allSatisfy { $0 <= 0x0F }, "value \(value)")
        }
    }

    func testSuperNaturalWaveformMessages() {
        let messages = sysEx.changeSuperNaturalWaveform(to: 450)
        XCTAssertEqual(messages.count, 3)
        // OSC wave = PCM (7), variation = A (0)
        XCTAssertEqual(Array(messages[0][8...12]), [0x1A, 0x01, 0x20, 0x00, 0x07])
        XCTAssertEqual(Array(messages[1][8...12]), [0x1A, 0x01, 0x20, 0x01, 0x00])
        // Wave number 450 = 0x1C2
        XCTAssertEqual(messages[2], dt1Header + [0x1A, 0x01, 0x20, 0x35, 0x00, 0x01, 0x0C, 0x02, 0x01, 0xF7])
        messages.forEach { XCTAssertTrue(sysEx.validateMessage($0)) }
    }

    func testSuperNaturalWaveNumberIsClamped() {
        XCTAssertEqual(Array(sysEx.changeSuperNaturalWaveform(to: 0)[2][12...15]), [0x00, 0x00, 0x00, 0x01])
        XCTAssertEqual(Array(sysEx.changeSuperNaturalWaveform(to: 999)[2][12...15]), [0x00, 0x01, 0x0C, 0x02])
    }

    func testBasicWaveformClearsWaveNumber() {
        let messages = sysEx.changeDigitalOscWaveform(to: .saw, variation: .a)
        XCTAssertEqual(Array(messages[2][8...15]), [0x1A, 0x01, 0x20, 0x35, 0x00, 0x00, 0x00, 0x00])
        messages.forEach { XCTAssertTrue(sysEx.validateMessage($0)) }
    }
}

// MARK: - Address building

final class AddressTests: XCTestCase {

    private func address(part: Int, partial: Int, offset: [UInt8]) -> [UInt8] {
        DigitalPartParameter(partNumber: part, partialNumber: partial,
                             parameterOffset: offset, value: 0).address
    }

    func testPartialOffsets() {
        let offset = DigitalPartParameter.ParameterAddress.oscWaveform
        XCTAssertEqual(address(part: 1, partial: 1, offset: offset), [0x1A, 0x01, 0x20, 0x00])
        XCTAssertEqual(address(part: 1, partial: 2, offset: offset), [0x1A, 0x01, 0x21, 0x00])
        XCTAssertEqual(address(part: 1, partial: 3, offset: offset), [0x1A, 0x01, 0x22, 0x00])
    }

    func testParameterOffsetIsLastByte() {
        XCTAssertEqual(address(part: 1, partial: 1, offset: DigitalPartParameter.ParameterAddress.fltHPCutoff),
                       [0x1A, 0x01, 0x20, 0x39])
    }

    func testAllAddressBytesAreSevenBit() {
        for part in 1...4 {
            for partial in 1...3 {
                let addr = address(part: part, partial: partial,
                                   offset: DigitalPartParameter.ParameterAddress.modLfoRateCtrl)
                XCTAssertEqual(addr.count, 4)
                XCTAssertTrue(addr.allSatisfy { $0 <= 0x7F })
            }
        }
    }

    /// Known bug: `partNumber` isn't part of the address yet, so Parts 2–4 edit Part 1.
    /// Remove the XCTExpectFailure once the real per-part base addresses are in.
    func testEachPartHasItsOwnAddress() {
        XCTExpectFailure("Per-part base addresses not implemented yet (see TODO.md)")
        let offset = DigitalPartParameter.ParameterAddress.oscWaveform
        let addresses = (1...4).map { address(part: $0, partial: 1, offset: offset) }
        XCTAssertEqual(Set(addresses.map { $0.description }).count, 4)
    }
}

// MARK: - Incoming message parsing

final class ParsingTests: XCTestCase {
    let sysEx = JDXASysEx()

    func testParsesDT1() {
        let message = dt1Header + [0x18, 0x00, 0x02, 0x01, 0x03, 0x62, 0xF7]
        XCTAssertEqual(sysEx.processSysExMessage(message),
                       "Parameter Change - Address: 18 00 02 01, Data: 03")
    }

    func testParsesMultiByteDT1() {
        let message = sysEx.createParameterChange(address: [0x1A, 0x01, 0x20, 0x35],
                                                  data: [0x00, 0x01, 0x0C, 0x02])
        XCTAssertEqual(sysEx.processSysExMessage(message),
                       "Parameter Change - Address: 1A 01 20 35, Data: 00 01 0C 02")
    }

    /// Truncated DT1 messages used to read past the end of the array and crash.
    func testTruncatedDT1DoesNotCrash() {
        for extra in 0...5 {
            let message = dt1Header + Array(repeating: 0x00, count: extra) + [0xF7]
            _ = sysEx.processSysExMessage(message)
        }
        XCTAssertEqual(sysEx.processSysExMessage(dt1Header + [0x1A, 0x01, 0xF7]),
                       "Unknown SysEx message type")
    }

    func testShortRolandMessageDoesNotCrash() {
        _ = sysEx.processSysExMessage([0xF0, 0x41, 0x10, 0x00, 0x00, 0x00, 0xF7])
        _ = sysEx.processSysExMessage([0xF0, 0xF7])
    }

    func testParsesDeviceInquiryResponse() {
        // F0 7E dev 06 02 41 <family 2> <number 2> <version 4> F7
        let reply: [UInt8] = [0xF0, 0x7E, 0x10, 0x06, 0x02, 0x41,
                              0x0E, 0x03, 0x00, 0x00,
                              0x01, 0x02, 0x03, 0x04, 0xF7]
        XCTAssertEqual(sysEx.processSysExMessage(reply),
                       "JD-XA Identity Response - Software Version: v1.2.3.4")
    }

    func testRejectsNonSysEx() {
        XCTAssertEqual(sysEx.processSysExMessage([0x90, 0x40, 0x7F]), "Invalid SysEx message format")
    }
}

// MARK: - Oscillator waveform sending

/// Records every message instead of sending it to a device.
private final class RecordingMIDISender: MIDISending {
    var sent: [[UInt8]] = []
    func sendPacket(_ data: [UInt8]) { sent.append(data) }

    /// Address + data bytes of each message (drops header, checksum and F7)
    var payloads: [[UInt8]] { sent.map { Array($0[8..<($0.count - 2)]) } }
}

final class OscillatorWaveformTests: XCTestCase {
    private var recorder: RecordingMIDISender!
    private var viewModel: OscillatorViewModel!
    private let sysEx = JDXASysEx()

    override func setUp() {
        recorder = RecordingMIDISender()
        viewModel = OscillatorViewModel(partNumber: 1, partialNumber: 2,
                                        midiService: MIDIService(midiManager: recorder))
    }

    func testSelectingPCMWaveSendsPCMModeAndWaveNumber() {
        viewModel.updatePCMWaveform(number: 300)  // 300 = 0x12C

        XCTAssertEqual(recorder.payloads, [
            [0x1A, 0x01, 0x21, 0x00, 0x07],                    // OSC Wave = PCM
            [0x1A, 0x01, 0x21, 0x01, 0x00],                    // Variation = A
            [0x1A, 0x01, 0x21, 0x35, 0x00, 0x01, 0x02, 0x0C],  // Wave number 300
        ])
        recorder.sent.forEach { XCTAssertTrue(sysEx.validateMessage($0)) }
        XCTAssertEqual(viewModel.pcmWaveNumber, 300)
        XCTAssertFalse(viewModel.isSuperSaw)
    }

    func testPCMWaveNumberIsClamped() {
        viewModel.updatePCMWaveform(number: 9999)
        XCTAssertEqual(recorder.payloads.last, [0x1A, 0x01, 0x21, 0x35, 0x00, 0x01, 0x0C, 0x02])
    }

    func testSelectingBasicWaveformSendsOnceAndClearsWaveNumber() {
        viewModel.updatePCMWaveform(number: 12)
        recorder.sent.removeAll()

        viewModel.updateWaveform(waveform: .superSaw, variation: .a)

        XCTAssertEqual(recorder.payloads, [
            [0x1A, 0x01, 0x21, 0x00, 0x06],                    // OSC Wave = Super Saw
            [0x1A, 0x01, 0x21, 0x01, 0x00],                    // Variation = A
            [0x1A, 0x01, 0x21, 0x35, 0x00, 0x00, 0x00, 0x00],  // Wave number cleared
        ])
        XCTAssertNil(viewModel.pcmWaveNumber)
        XCTAssertTrue(viewModel.isSuperSaw)
    }

    func testClearingPCMGoesBackToBasicWaveform() {
        viewModel.updateWaveform(waveform: .triangle, variation: .b)
        viewModel.updatePCMWaveform(number: 5)
        recorder.sent.removeAll()

        viewModel.updatePCMWaveform(number: nil)

        XCTAssertEqual(recorder.payloads.first, [0x1A, 0x01, 0x21, 0x00, 0x03])
        XCTAssertEqual(recorder.payloads.count, 3)
        XCTAssertNil(viewModel.pcmWaveNumber)
    }
}
