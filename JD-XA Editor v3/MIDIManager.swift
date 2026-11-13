import CoreMIDI
import SwiftUI

class MIDIManager: ObservableObject {
    private var client = MIDIClientRef()
    private var outputPort = MIDIPortRef()
    private var inputPort = MIDIPortRef()
    
    // Use private storage with public getter/setter
    private var _selectedDeviceID: Int?
    public var selectedDeviceID: Int? {
        get { _selectedDeviceID }
        set {
            _selectedDeviceID = newValue
            objectWillChange.send()
        }
    }
    
    @Published private(set) var availableDevices: [(id: Int, name: String)] = []
    
    init() {
        setupMIDI()
        scanForDevices()
    }
    
    private func setupMIDI() {
        var status = noErr
        
        // Create MIDI client
        let clientName = "JD-XA Test" as CFString
        status = MIDIClientCreate(clientName, nil, nil, &client)
        if status != noErr {
            print("Error creating MIDI client: \(status)")
            return
        }
        
        // Create output port
        let outputPortName = "Output Port" as CFString
        status = MIDIOutputPortCreate(client, outputPortName, &outputPort)
        if status != noErr {
            print("Error creating MIDI output port: \(status)")
            return
        }
        
        // Create input port with block
        let inputPortName = "Input Port" as CFString
        status = MIDIInputPortCreateWithBlock(client, inputPortName, &inputPort) { packetList, _ in
            let packets = UnsafePointer<MIDIPacketList>(packetList).pointee
            var packet = packets.packet
            
            for _ in 0..<packets.numPackets {
                // Get data bytes from packet
                let dataBytes = withUnsafePointer(to: packet.data) { ptr in
                    ptr.withMemoryRebound(to: UInt8.self, capacity: Int(packet.length)) { bytes in
                        Array(UnsafeBufferPointer(start: bytes, count: Int(packet.length)))
                    }
                }
                
                // Print received data
                let hexString = dataBytes.map { String(format: "%02X", $0) }.joined(separator: " ")
                print("MIDI In: \(hexString)")
                
                // Move to next packet
                packet = MIDIPacketNext(&packet).pointee
            }
        }
        
        if status != noErr {
            print("Error creating MIDI input port: \(status)")
            return
        }
    }
    
    func scanForDevices() {
        availableDevices.removeAll()
        
        // Scan outputs (destinations)
        let destinationCount = MIDIGetNumberOfDestinations()
        print("Found \(destinationCount) MIDI destinations")
        
        for i in 0..<destinationCount {
            let destination = MIDIGetDestination(i)
            var endpointName: Unmanaged<CFString>?
            MIDIObjectGetStringProperty(destination, kMIDIPropertyName, &endpointName)
            
            if let cfName = endpointName?.takeRetainedValue() {
                let name = cfName as String
                print("Found MIDI destination: \(name)")
                // Add all MIDI devices for now
                availableDevices.append((id: Int(i), name: name))
            }
        }

        // Connect to all available sources
        let sourceCount = MIDIGetNumberOfSources()
        for i in 0..<sourceCount {
            let source = MIDIGetSource(i)
            MIDIPortConnectSource(inputPort, source, nil)
        }
    }

    func selectDevice(_ deviceID: Int?) {
        selectedDeviceID = deviceID
    }

    func sendPacket(_ data: [UInt8]) {
        guard let deviceID = selectedDeviceID else {
            print("No device selected")
            return
        }
        
        let destination = MIDIGetDestination(deviceID)
        var packet = MIDIPacket()
        packet.timeStamp = 0
        packet.length = UInt16(data.count)
        
        // Safety check for packet size
        guard data.count <= 256 else {
            print("Packet too large")
            return
        }
        
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
