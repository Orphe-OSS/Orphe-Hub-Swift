//
//  MIDIManager.swift
//  Orphe-Hub-Swift
//
//  Created by kyosuke on 2017/04/03.
//  Copyright © 2017 no new folk studio Inc. All rights reserved.
//

import Foundation
import CoreMIDI
import AudioToolbox


/**
 # MIDIManager
 
 > Here is an example of using virtual MIDI sources and destinations.
 
 */
class MIDIManager: NSObject {
    
    static var sharedInstance = MIDIManager()
    
    var midiClient = MIDIClientRef()
    var inputPort = MIDIPortRef()
    var virtualDestinationEndpointRef = MIDIEndpointRef()
    var virtualSourceEndpointRef = MIDIEndpointRef()
    
    var midiNotifier: MIDINotifyBlock?
    
    var midiReadBlock:MIDIReadBlock?
    
    /**
     This will initialize the midiClient, outputPort, and inputPort variables.
     */
    
    func initMIDI(midiNotifier: MIDINotifyBlock? = nil, reader: MIDIReadBlock? = nil) {
        
        
        var notifyBlock: MIDINotifyBlock
        
        if midiNotifier != nil {
            notifyBlock = midiNotifier!
        } else {
            notifyBlock = myNotifyCallback
        }
        
        var status = OSStatus(noErr)
        
        //client
        status = MIDIClientCreateWithBlock("com.no-new-folk.OrpheMIDIClient" as CFString, &midiClient, notifyBlock)
        if status == OSStatus(noErr) {
            print("created client")
        } else {
            print("error creating client : \(status)")
            CheckError(status)
        }
        
        //readblock
        var readBlock: MIDIReadBlock
        if reader != nil {
            readBlock = reader!
        } else {
            readBlock = MyMIDIReadBlock
        }
        
        printProperties(midiClient)
        
        if status == OSStatus(noErr) {
            
            //input port
//            status = MIDIInputPortCreateWithBlock(midiClient, "com.no-new-folk.OrpheMIDIInputPort" as CFString, &inputPort, readBlock)
//            if status == noErr {
//                print("created input port %d", inputPort)
//            } else {
//                print("error creating input port %@", status)
//                CheckError(status)
//            }
            
            //destination
            status = MIDIDestinationCreateWithBlock(midiClient,
                                                    "OrpheMIDI.Dest" as CFString,
                                                    &virtualDestinationEndpointRef,
                                                    readBlock)
            
            if status != noErr {
                print("error creating virtual destination: \(status)")
            } else {
                print("midi virtual destination created \(virtualDestinationEndpointRef)")
            }
            saveVirtualDestinationID()
            
            
            printProperties(virtualDestinationEndpointRef)
            
//            // or
//            let pn = getStringProperty(propertyName: kMIDIPropertyName, midiObject: virtualDestinationEndpointRef)
//            print("vd name is \(pn)")
            
            
            //use MIDIReceived to transmit MIDI messages from your virtual source to any clients connected to the virtual source. Since we're using a MusicSequence, we need to use a virtual dest to catch the events and forward them via MIDIReceived.
            status = MIDISourceCreate(midiClient,
                                      "OrpheMIDI.source" as CFString,
                                      &virtualSourceEndpointRef)
            
            if status != noErr {
                print("error creating virtual source: \(status)")
            } else {
                print("midi virtual source created \(virtualSourceEndpointRef)")
            }
            saveVirtualSourceID()
            
            printProperties(virtualSourceEndpointRef)
            
            allExternalDeviceProps()
            allDeviceProps()
            allDestinationProps()
            allSourceProps()
            
//            connectSourcesToInputPort()
            
        }
        
    }
    
    // MARK: ID chacha
    func saveVirtualSourceID() {
        
        
        let sid = UserDefaults.standard.integer(forKey:savedVirtualSourceKey)
        var uniqueID = MIDIUniqueID(sid)
        
        // it's not in defaults. get it and save it
        if sid == 0 {
            let (s,id) = getUniqueID(endpoint: virtualSourceEndpointRef)
            if s == noErr {
                print("saving id for src: \(id)")
                UserDefaults.standard.set(Int(id), forKey:savedVirtualSourceKey)
                uniqueID = MIDIUniqueID(id)
            }
        } else {
            
            let status = setUniqueID(endpoint: virtualSourceEndpointRef, id: uniqueID)
            if status == kMIDIIDNotUnique {
                print("oops. id not unique for src: \(uniqueID)")
                uniqueID = 0
            }
            else {
                print("set id for src: \(uniqueID)")
            }
        }
        
    }
    
    func saveVirtualDestinationID() {
        
        let sid = UserDefaults.standard.integer(forKey:savedVirtualDestinationKey)
        var uniqueID = MIDIUniqueID(sid)
        
        // it's not in defaults. get it and save it
        if sid == 0 {
            let (s,id) = getUniqueID(endpoint: virtualDestinationEndpointRef)
            if s == noErr {
                print("saving id for dest: \(id)")
                UserDefaults.standard.set(Int(id), forKey:savedVirtualDestinationKey)
                uniqueID = MIDIUniqueID(id)
            }
        } else {
            
            let status = setUniqueID(endpoint:virtualDestinationEndpointRef, id:uniqueID)
            if status == kMIDIIDNotUnique {
                print("oops. id not unique for dest: \(uniqueID)")
                uniqueID = 0
            }
            else {
                print("set id for dest: \(uniqueID)")
            }
        }
    }
    
    let savedVirtualDestinationKey = "savedVirtualDestinationKey"
    let savedVirtualSourceKey = "savedVirtualSourceKey"
    
    //MARK: - Callbacks
    func myNotifyCallback(message: UnsafePointer<MIDINotification>) -> Void {
        print("got a MIDINotification!")
        
        let notification = message.pointee
        print("MIDI Notify, messageId= \(notification.messageID)")
        
        switch (notification.messageID) {
        case MIDINotificationMessageID.msgSetupChanged:
            NSLog("MIDI setup changed")
            break
            
        case MIDINotificationMessageID.msgObjectAdded:
            NSLog("added")
            message.withMemoryRebound(to:MIDIObjectAddRemoveNotification.self, capacity:1) {
                let m:MIDIObjectAddRemoveNotification = $0.pointee
                print("id \(m.messageID)")
                print("size \(m.messageSize)")
                print("child \(m.child)")
                print("child type \(m.childType)")
                print("parent \(m.parent)")
                print("parentType \(m.parentType)")
            }
            
            break
            
        case MIDINotificationMessageID.msgObjectRemoved:
            NSLog("kMIDIMsgObjectRemoved")
            message.withMemoryRebound(to:MIDIObjectAddRemoveNotification.self, capacity:1) {
                let m:MIDIObjectAddRemoveNotification = $0.pointee
                print("id \(m.messageID)")
                print("size \(m.messageSize)")
                print("child \(m.child)")
                print("child type \(m.childType)")
                print("parent \(m.parent)")
                print("parentType \(m.parentType)")
            }
            
            break
            
        case MIDINotificationMessageID.msgPropertyChanged:
            NSLog("kMIDIMsgPropertyChanged")
            message.withMemoryRebound(to:MIDIObjectPropertyChangeNotification.self, capacity:1) {
                let m:MIDIObjectPropertyChangeNotification = $0.pointee
                print("id \(m.messageID)")
                print("size \(m.messageSize)")
                print("property name \(m.propertyName)")
                print("object type \(m.objectType)")
                print("object \(m.object)")
            }
            
            break
            
        case MIDINotificationMessageID.msgThruConnectionsChanged:
            NSLog("MIDI thru connections changed.")
            break
            
        case MIDINotificationMessageID.msgSerialPortOwnerChanged:
            NSLog("MIDI serial port owner changed.")
            break
            
        case MIDINotificationMessageID.msgIOError:
            NSLog("MIDI I/O error.")
            break
            
        }
        
    }
    
    //MARK: - input event?
    func MyMIDIReadBlock(packetList: UnsafePointer<MIDIPacketList>, srcConnRefCon: UnsafeMutableRawPointer?) -> Swift.Void {
        print("---------MyMIDIReadBlock--------")
        let packets = packetList.pointee
        
        let packet:MIDIPacket = packets.packet
        
        var ap = UnsafeMutablePointer<MIDIPacket>.allocate(capacity: 1)
        ap.initialize(to:packet)
        
        for _ in 0 ..< packets.numPackets {
            let p = ap.pointee
            print("timestamp \(p.timeStamp)", terminator: "")
            var hex = String(format:"0x%X", p.data.0)
            print(" \(hex)", terminator: "")
            hex = String(format:"0x%X", p.data.1)
            print(" \(hex)", terminator: "")
            hex = String(format:"0x%X", p.data.2)
            print(" \(hex)")
            
            handle(p)
            
            ap = MIDIPacketNext(ap)
        }
    }
    
    func handle(_ packet:MIDIPacket) {
        
        let status = packet.data.0
        let d1 = packet.data.1
        let d2 = packet.data.2
        let rawStatus = status & 0xF0 // without channel
        let channel = status & 0x0F
        
        switch rawStatus {
            
        case 0x80:
            print("Note off. Channel \(channel) note \(d1) velocity \(d2)")
            // forward to sampler
//            playNoteOff(UInt32(channel), noteNum: UInt32(d1))
            
        case 0x90:
            print("Note on. Channel \(channel) note \(d1) velocity \(d2)")
            // forward to sampler
//            playNoteOn(UInt32(channel), noteNum:UInt32(d1), velocity: UInt32(d2))
            
        case 0xA0:
            print("Polyphonic Key Pressure (Aftertouch). Channel \(channel) note \(d1) pressure \(d2)")
            
        case 0xB0:
            print("Control Change. Channel \(channel) controller \(d1) value \(d2)")
            
        case 0xC0:
            print("Program Change. Channel \(channel) program \(d1)")
            
        case 0xD0:
            print("Channel Pressure (Aftertouch). Channel \(channel) pressure \(d1)")
            
        case 0xE0:
            print("Pitch Bend Change. Channel \(channel) lsb \(d1) msb \(d2)")
            
        default: print("Unhandled message \(status)")
        }
    }
    
    
    func connectSourcesToInputPort() {
        let sourceCount = MIDIGetNumberOfSources()
        print("source count \(sourceCount)")
        
        for srcIndex in 0 ..< sourceCount {
            let midiEndPoint = MIDIGetSource(srcIndex)
            
            let status = MIDIPortConnectSource(inputPort,
                                               midiEndPoint,
                                               nil)
            
            if status == noErr {
                print("yay connected endpoint to inputPort")
            } else {
                print("oh crap!")
                CheckError(status)
            }
        }
    }
    
    func disconnectSourceFromInputPort(_ sourceMidiEndPoint:MIDIEndpointRef) -> OSStatus {
        let status = MIDIPortDisconnectSource(inputPort,
                                              sourceMidiEndPoint
        )
        if status == noErr {
            print("yay disconnected endpoint \(sourceMidiEndPoint) from inputPort! \(inputPort)")
        } else {
            print("could not disconnect inputPort %@ endpoint %@ status %@", inputPort,sourceMidiEndPoint,status )
            CheckError(status)
        }
        return status
    }
    
    
    //MARK: - なにこれ
    ///  Take the packets emitted frome the MusicSequence and forward them to the virtual source.
    ///
    ///  - parameter packetList:    packets from the MusicSequence
    ///  - parameter srcConnRefCon: not used
    func MIDIPassThru(packetList: UnsafePointer<MIDIPacketList>, srcConnRefCon: Optional<UnsafeMutableRawPointer>) -> () {
        print("---------------MIDIPassThru---------------")
        print("sending packets to source \(packetList)")
        MIDIReceived(virtualSourceEndpointRef, packetList)
        
        dumpPacketList(packetlist: packetList.pointee)//情報を表示するだけの関数っぽい
    }
    
    func dumpPacketList(packetlist:MIDIPacketList) {
        let packet = packetlist.packet
        var ap = UnsafeMutablePointer<MIDIPacket>.allocate(capacity: 1)
        ap.initialize(to: packet)
        for _ in 0 ..< packetlist.numPackets {
            let p = ap.pointee
            dump(packet: p)
            ap = MIDIPacketNext(ap)
        }
    }
    
    func dump(packet:MIDIPacket) {
        let status = packet.data.0
        let rawStatus = status & 0xF0 // without channel
        let channel = status & 0x0F
        print("--dump--")
        print("timeStamp: \(packet.timeStamp)")
        print("status: \(status)  \(String(format:"0x%X", status))")
        print("rawStatus: \(rawStatus) \(String(format:"0x%X", rawStatus))")
        print("channel: \(channel)")
        print("length: \(packet.length)")
        
        print("data: ", terminator:"")
        let mirror = Mirror(reflecting: packet.data)
        for (index,d) in mirror.children.enumerated() {
            if index == Int(packet.length) {
                print("")
                break
            }
            let hex = String(format:"0x%X", d.value as! UInt8)
            print("\(hex) ", terminator:"")
            //print("d: \(d.label) : \(d.value)")
        }
    }
    
    
    //MARK: - Utilities
    
    /**
     Not as detailed as Adamson's CheckError, but adequate.
     For other projects you can uncomment the Core MIDI constants.
     */
    func CheckError(_ error:OSStatus) {
        if error == 0 {return}
        
        switch(error) {
            // beta4 change
        //            switch(Int(error)) {
        case kMIDIInvalidClient :
            print( "kMIDIInvalidClient ")
            
        case kMIDIInvalidPort :
            print( "kMIDIInvalidPort ")
            
        case kMIDIWrongEndpointType :
            print( "kMIDIWrongEndpointType")
            
        case kMIDINoConnection :
            print( "kMIDINoConnection ")
            
        case kMIDIUnknownEndpoint :
            print( "kMIDIUnknownEndpoint ")
            
        case kMIDIUnknownProperty :
            print( "kMIDIUnknownProperty ")
            
        case kMIDIWrongPropertyType :
            print( "kMIDIWrongPropertyType ")
            
        case kMIDINoCurrentSetup :
            print( "kMIDINoCurrentSetup ")
            
        case kMIDIMessageSendErr :
            print( "kMIDIMessageSendErr ")
            
        case kMIDIServerStartErr :
            print( "kMIDIServerStartErr ")
            
        case kMIDISetupFormatErr :
            print( "kMIDISetupFormatErr ")
            
        case kMIDIWrongThread :
            print( "kMIDIWrongThread ")
            
        case kMIDIObjectNotFound :
            print( "kMIDIObjectNotFound ")
            
        case kMIDIIDNotUnique :
            print( "kMIDIIDNotUnique ")
            
        default: print( "huh? \(error) ")
        }
        
        
        switch(error) {
        //AUGraph.h
        case kAUGraphErr_NodeNotFound:
            print("Error:kAUGraphErr_NodeNotFound \n")
            
        case kAUGraphErr_OutputNodeErr:
            print( "Error:kAUGraphErr_OutputNodeErr \n")
            
        case kAUGraphErr_InvalidConnection:
            print("Error:kAUGraphErr_InvalidConnection \n")
            
        case kAUGraphErr_CannotDoInCurrentContext:
            print( "Error:kAUGraphErr_CannotDoInCurrentContext \n")
            
        case kAUGraphErr_InvalidAudioUnit:
            print( "Error:kAUGraphErr_InvalidAudioUnit \n")
            
            // core audio
            
        case kAudio_UnimplementedError:
            print("kAudio_UnimplementedError")
        case kAudio_FileNotFoundError:
            print("kAudio_FileNotFoundError")
        case kAudio_FilePermissionError:
            print("kAudio_FilePermissionError")
        case kAudio_TooManyFilesOpenError:
            print("kAudio_TooManyFilesOpenError")
        case kAudio_BadFilePathError:
            print("kAudio_BadFilePathError")
        case kAudio_ParamError:
            print("kAudio_ParamError")
        case kAudio_MemFullError:
            print("kAudio_MemFullError")
            
            
            // AudioToolbox
            
        case kAudioToolboxErr_InvalidSequenceType :
            print( " kAudioToolboxErr_InvalidSequenceType ")
            
        case kAudioToolboxErr_TrackIndexError :
            print( " kAudioToolboxErr_TrackIndexError ")
            
        case kAudioToolboxErr_TrackNotFound :
            print( " kAudioToolboxErr_TrackNotFound ")
            
        case kAudioToolboxErr_EndOfTrack :
            print( " kAudioToolboxErr_EndOfTrack ")
            
        case kAudioToolboxErr_StartOfTrack :
            print( " kAudioToolboxErr_StartOfTrack ")
            
        case kAudioToolboxErr_IllegalTrackDestination :
            print( " kAudioToolboxErr_IllegalTrackDestination")
            
        case kAudioToolboxErr_NoSequence :
            print( " kAudioToolboxErr_NoSequence ")
            
        case kAudioToolboxErr_InvalidEventType :
            print( " kAudioToolboxErr_InvalidEventType")
            
        case kAudioToolboxErr_InvalidPlayerState :
            print( " kAudioToolboxErr_InvalidPlayerState")
            
            // AudioUnit
            
            
        case kAudioUnitErr_InvalidProperty :
            print( " kAudioUnitErr_InvalidProperty")
            
        case kAudioUnitErr_InvalidParameter :
            print( " kAudioUnitErr_InvalidParameter")
            
        case kAudioUnitErr_InvalidElement :
            print( " kAudioUnitErr_InvalidElement")
            
        case kAudioUnitErr_NoConnection :
            print( " kAudioUnitErr_NoConnection")
            
        case kAudioUnitErr_FailedInitialization :
            print( " kAudioUnitErr_FailedInitialization")
            
        case kAudioUnitErr_TooManyFramesToProcess :
            print( " kAudioUnitErr_TooManyFramesToProcess")
            
        case kAudioUnitErr_InvalidFile :
            print( " kAudioUnitErr_InvalidFile")
            
        case kAudioUnitErr_FormatNotSupported :
            print( " kAudioUnitErr_FormatNotSupported")
            
        case kAudioUnitErr_Uninitialized :
            print( " kAudioUnitErr_Uninitialized")
            
        case kAudioUnitErr_InvalidScope :
            print( " kAudioUnitErr_InvalidScope")
            
        case kAudioUnitErr_PropertyNotWritable :
            print( " kAudioUnitErr_PropertyNotWritable")
            
        case kAudioUnitErr_InvalidPropertyValue :
            print( " kAudioUnitErr_InvalidPropertyValue")
            
        case kAudioUnitErr_PropertyNotInUse :
            print( " kAudioUnitErr_PropertyNotInUse")
            
        case kAudioUnitErr_Initialized :
            print( " kAudioUnitErr_Initialized")
            
        case kAudioUnitErr_InvalidOfflineRender :
            print( " kAudioUnitErr_InvalidOfflineRender")
            
        case kAudioUnitErr_Unauthorized :
            print( " kAudioUnitErr_Unauthorized")
            
        default:
            print("huh?")
        }
    }
    
    //The system assigns unique IDs to all objects
    func getUniqueID(endpoint:MIDIEndpointRef) -> (OSStatus, MIDIUniqueID) {
        var id = MIDIUniqueID(0)
        let s = MIDIObjectGetIntegerProperty(endpoint, kMIDIPropertyUniqueID, &id)
        if s != noErr {
            print("error getting unique id \(s)")
        }
        return (s,id)
    }
    
    func setUniqueID(endpoint:MIDIEndpointRef, id:MIDIUniqueID) -> OSStatus {
        let s = MIDIObjectSetIntegerProperty(endpoint, kMIDIPropertyUniqueID, id)
        if s != noErr {
            print("error getting unique id \(s)")
        }
        return s
    }
    
    //MARK: - print properties
    func allExternalDeviceProps() {
        
        let n = MIDIGetNumberOfExternalDevices()
        print("~~~~~~~external devices~~~~~~~ %d", n)
        
        for i in 0 ..< n {
            let midiDevice = MIDIGetExternalDevice(i)
            printProperties(midiDevice)
        }
    }
    
    func allDeviceProps() {
        
        let n = MIDIGetNumberOfDevices()
        print("~~~~~~~number of devices~~~~~~~ %d", n)
        
        for i in 0 ..< n {
            let midiDevice = MIDIGetDevice(i)
            printProperties(midiDevice)
        }
    }
    
    func allDestinationProps() {
        let numberOfDestinations  = MIDIGetNumberOfDestinations()
        print("~~~~~~~destinations~~~~~~~ %d", numberOfDestinations)
        
        for i in 0 ..< numberOfDestinations {
            let endpoint = MIDIGetDestination(i)
            printProperties(endpoint)
        }
    }
    
    func allSourceProps() {
        let numberOfSources  = MIDIGetNumberOfSources()
        print("~~~~~~~numberOfSources~~~~~~~ %d", numberOfSources)
        
        for i in 0 ..< numberOfSources {
            let endpoint = MIDIGetSource(i)
            printProperties(endpoint)
        }
    }
    
    func printProperties(_ midiobject:MIDIObjectRef) {
        var unmanagedProperties: Unmanaged<CFPropertyList>?
        let status = MIDIObjectGetProperties(midiobject, &unmanagedProperties, true)
        CheckError(status)
        
        if let midiProperties: CFPropertyList = unmanagedProperties?.takeUnretainedValue() {
            if let midiDictionary = midiProperties as? Dictionary<String, Any> {
                print("MIDI properties %{public}@", midiDictionary)
                
            }
        } else {
            print("Couldn't load properties for %@", midiobject)
        }
    }
    
//    func getStringProperty(propertyName: CFString, midiObject: MIDIObjectRef) -> String {
//        var property: Unmanaged<CFString>?
//        let status = MIDIObjectGetStringProperty(midiObject, propertyName, &property)
//        defer { property?.release() }
//        if status != noErr {
//            print("error getting string \(propertyName) : \(status)")
//            CheckError(status)
//            return "status error"
//        }
//        let cfstring = Unmanaged.fromOpaque(
//            property!.toOpaque()).takeUnretainedValue() as CFString
//        if CFGetTypeID(cfstring) == CFStringGetTypeID() {
//            return cfstring as String
//        }
//        
//        return "unknown error"
//    }
    
    // send directly to the midi source
    func noteOnReceive() {
        var packet       = MIDIPacket()
        packet.timeStamp = MIDITimeStamp(AudioConvertHostTimeToNanos(AudioGetCurrentHostTime()))
        packet.length    = 3
        packet.data.0    = UInt8(0x90)
        packet.data.1    = UInt8(60)
        packet.data.2    = UInt8(100)
        
        var packetlist = MIDIPacketList(numPackets: 1,
                                        packet: packet)
        let status = MIDIReceived(virtualSourceEndpointRef, &packetlist)
        if status != noErr {
            print("bad status \(status) receiving msg")
            CheckError(status)
        }
    }
    
    func noteOffReceive() {
        var packet       = MIDIPacket()
        packet.timeStamp = MIDITimeStamp(AudioConvertHostTimeToNanos(AudioGetCurrentHostTime()))
        packet.length    = 3
        packet.data.0    = UInt8(0x90) // note on with vel 0 turns off
        packet.data.1    = UInt8(60)
        packet.data.2    = UInt8(0)
        
        var packetlist = MIDIPacketList(numPackets: 1,
                                        packet: packet)
        let status = MIDIReceived(virtualSourceEndpointRef, &packetlist)
        if status != noErr {
            print("bad status \(status) receiving msg")
            CheckError(status)
        }
    }
    
    
    // add
    func ccPitchbendReceive(ch:Int, pitchbendValue:UInt16) {
        var packet       = MIDIPacket()
        packet.timeStamp = MIDITimeStamp(AudioConvertHostTimeToNanos(AudioGetCurrentHostTime()))
        packet.length    = 3
        
        packet.data.0    = UInt8(0xE0) + UInt8(ch)                              // 0 is channel number
        packet.data.1    = UInt8(pitchbendValue & 0x007f)           // lowwer
        packet.data.2    = UInt8((pitchbendValue >> 7) & 0x007f)    // upper
        
        var packetlist = MIDIPacketList(numPackets: 1, packet: packet)
        let status = MIDIReceived(virtualSourceEndpointRef, &packetlist)
        if status != noErr {
            print("bad status \(status) receiving msg")
            CheckError(status)
        }
    }
    
    func controlChangeReceive(ch:Int, ctNum:UInt8, value:UInt8) {
        var packet       = MIDIPacket()
        packet.timeStamp = MIDITimeStamp(AudioConvertHostTimeToNanos(AudioGetCurrentHostTime()))
        packet.length    = 3
        
        print("cc:",value)
        packet.data.0    = UInt8(0xB0) + UInt8(ch)                              // 0 is channel number
        packet.data.1    = ctNum
        packet.data.2    = value
        var packetlist = MIDIPacketList(numPackets: 1, packet: packet)
        let status = MIDIReceived(virtualSourceEndpointRef, &packetlist)
        if status != noErr {
            print("bad status \(status) receiving msg")
            CheckError(status)
        }
    }
}



