import CoreMIDI
import Combine
import SwiftUI

/// A MIDI output the app can send to. `id` is the endpoint's CoreMIDI unique ID,
/// which stays the same while devices are plugged in and out (unlike its index).
struct MIDIDevice: Identifiable, Hashable {
    let id: Int
    let name: String
}

class MIDIManager: ObservableObject {
    private var client = MIDIClientRef()
    private var outputPort = MIDIPortRef()
    private var inputPort = MIDIPortRef()

    /// Unique ID of the output messages go to, or `nil` for none.
    public var selectedDeviceID: Int? {
        willSet { objectWillChange.send() }
    }

    @Published private(set) var availableDevices: [MIDIDevice] = []

    /// Complete SysEx messages received from any source, delivered on the main queue.
    let receivedSysEx = PassthroughSubject<[UInt8], Never>()

    /// Reassembles SysEx per source. Only touched on `inputQueue`.
    private var assemblers: [Int: SysExAssembler] = [:]
    private let inputQueue = DispatchQueue(label: "JD-XA Editor.MIDI input")
    /// Unique IDs of the sources the input port is connected to.
    private var connectedSources: Set<MIDIUniqueID> = []

    init() {
        setupMIDI()
        scanForDevices()
    }

    private func setupMIDI() {
        var status = noErr

        // The notify block tells us when devices are added or removed.
        status = MIDIClientCreateWithBlock("JD-XA Editor" as CFString, &client) { [weak self] notification in
            guard notification.pointee.messageID == .msgSetupChanged else { return }
            DispatchQueue.main.async { self?.scanForDevices() }
        }
        if status != noErr {
            print("Error creating MIDI client: \(status)")
            return
        }

        status = MIDIOutputPortCreate(client, "Output Port" as CFString, &outputPort)
        if status != noErr {
            print("Error creating MIDI output port: \(status)")
            return
        }

        status = MIDIInputPortCreateWithBlock(client, "Input Port" as CFString, &inputPort) { [weak self] packetList, sourceRef in
            // Copy the bytes out now; the packet list is only valid during this call.
            let source = Int(bitPattern: sourceRef)
            var chunks: [[UInt8]] = []
            for packet in packetList.unsafeSequence() {
                let length = Int(packet.pointee.length)
                let dataOffset = MemoryLayout<MIDIPacket>.offset(of: \MIDIPacket.data)!
                let bytes = UnsafeRawPointer(packet).advanced(by: dataOffset)
                    .bindMemory(to: UInt8.self, capacity: length)
                chunks.append(Array(UnsafeBufferPointer(start: bytes, count: length)))
            }
            self?.inputQueue.async { self?.assemble(chunks, from: source) }
        }
        if status != noErr {
            print("Error creating MIDI input port: \(status)")
            return
        }
    }

    private func assemble(_ chunks: [[UInt8]], from source: Int) {
        var assembler = assemblers[source] ?? SysExAssembler()
        let messages = chunks.flatMap { assembler.feed($0) }
        assemblers[source] = assembler

        guard !messages.isEmpty else { return }
        DispatchQueue.main.async {
            messages.forEach { self.receivedSysEx.send($0) }
        }
    }

    func scanForDevices() {
        var devices: [MIDIDevice] = []
        for i in 0..<MIDIGetNumberOfDestinations() {
            let destination = MIDIGetDestination(i)
            guard let id = Self.uniqueID(of: destination) else { continue }
            var name: Unmanaged<CFString>?
            MIDIObjectGetStringProperty(destination, kMIDIPropertyDisplayName, &name)
            if name == nil {
                MIDIObjectGetStringProperty(destination, kMIDIPropertyName, &name)
            }
            guard let cfName = name?.takeRetainedValue() else { continue }
            devices.append(MIDIDevice(id: Int(id), name: cfName as String))
        }
        availableDevices = devices

        connectNewSources()
    }

    /// Listens to every source; sources that went away drop out by themselves.
    private func connectNewSources() {
        guard inputPort != 0 else { return }
        var current: Set<MIDIUniqueID> = []
        for i in 0..<MIDIGetNumberOfSources() {
            let source = MIDIGetSource(i)
            guard let id = Self.uniqueID(of: source) else { continue }
            current.insert(id)
            guard !connectedSources.contains(id) else { continue }
            // The source's unique ID comes back as the callback's refCon, so
            // each source gets its own SysEx assembler.
            let refCon = UnsafeMutableRawPointer(bitPattern: Int(id))
            MIDIPortConnectSource(inputPort, source, refCon)
        }
        connectedSources = current
    }

    private static func uniqueID(of endpoint: MIDIEndpointRef) -> MIDIUniqueID? {
        var id: MIDIUniqueID = 0
        guard MIDIObjectGetIntegerProperty(endpoint, kMIDIPropertyUniqueID, &id) == noErr else { return nil }
        return id
    }

    func selectDevice(_ deviceID: Int?) {
        selectedDeviceID = deviceID
    }

    func sendPacket(_ data: [UInt8]) {
        guard let deviceID = selectedDeviceID else {
            print("No device selected")
            return
        }

        var object = MIDIObjectRef()
        var type = MIDIObjectType.other
        guard MIDIObjectFindByUniqueID(MIDIUniqueID(deviceID), &object, &type) == noErr,
              type == .destination || type == .externalDestination else {
            print("Selected MIDI device is not available")
            return
        }
        let destination = MIDIEndpointRef(object)

        // Safety check for packet size
        guard data.count <= 256 else {
            print("Packet too large")
            return
        }

        var packet = MIDIPacket()
        packet.timeStamp = 0
        packet.length = UInt16(data.count)

        // Copy data bytes
        withUnsafeMutablePointer(to: &packet.data) { ptr in
            ptr.withMemoryRebound(to: UInt8.self, capacity: 256) { bytes in
                for (index, byte) in data.enumerated() {
                    bytes[index] = byte
                }
            }
        }

        var packetList = MIDIPacketList(numPackets: 1, packet: packet)
        let result = MIDISend(outputPort, destination, &packetList)

        if result != noErr {
            print("Send failed: \(result)")
        } else {
            let hexString = data.map { String(format: "%02X", $0) }.joined(separator: " ")
            print("Sent: \(hexString)")
        }
    }

    deinit {
        if inputPort != 0 {
            MIDIPortDispose(inputPort)
        }
        if outputPort != 0 {
            MIDIPortDispose(outputPort)
        }
        if client != 0 {
            MIDIClientDispose(client)
        }
    }
}

// MARK: - SysEx reassembly

/// Collects SysEx messages from a stream of MIDI bytes. A message can be split
/// across packets, and real-time bytes (clock, active sensing) can appear inside it.
struct SysExAssembler {
    /// Messages longer than this are dropped so a missing F7 can't grow forever.
    static let maxLength = 64 * 1024

    private var buffer: [UInt8] = []
    private var inMessage = false

    /// Feeds bytes in and returns every message that was completed, F0 to F7.
    mutating func feed(_ bytes: [UInt8]) -> [[UInt8]] {
        var complete: [[UInt8]] = []
        for byte in bytes {
            switch byte {
            case 0xF8...0xFF:
                continue                          // real-time: may interleave, ignore
            case 0xF0:
                buffer = [byte]                   // a new F0 abandons any unfinished message
                inMessage = true
            case 0xF7 where inMessage:
                buffer.append(byte)
                complete.append(buffer)
                reset()
            case 0x80...0xF7:
                reset()                           // any other status byte ends SysEx
            default:
                guard inMessage else { continue } // running-status data outside SysEx
                buffer.append(byte)
                if buffer.count > Self.maxLength { reset() }
            }
        }
        return complete
    }

    private mutating func reset() {
        buffer.removeAll(keepingCapacity: true)
        inMessage = false
    }
}
