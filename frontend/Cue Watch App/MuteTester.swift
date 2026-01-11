//
//  MuteTester.swift
//  Cue Watch App
//
//  Created by Jackson Moody on 1/10/26.
//  Kind of a hacky way to detect if the Apple Watch is muted

import SwiftUI
import Combine

struct MuteTesterView: View {
    @Environment(NavigationRouter.self) private var router
    @State private var audioToolBoxHandle: UnsafeMutableRawPointer? = nil
    @State private var mod = MuteTester()
    
    var body: some View {
        Rectangle()
            .opacity(0)
        .onAppear {
            monitorMute()
        }
        .onReceive(updateSilentState) { silent in
            if silent {
                router.navigateToMuted()
            }
        }
    }
    func monitorMute() {
        mod.manageSystemSound(resource: "detection", withExtension: "aiff")
    }
}

let updateSilentState = PassthroughSubject<Bool, Never>()
fileprivate var startPlayTime: DispatchTime?

@MainActor
@Observable
class MuteTester {
    func manageSystemSound(resource: String, withExtension ext: String) {
        typealias SystemSoundID = UInt32
        let handle = dlopen("/System/Library/Frameworks/AudioToolbox.framework/AudioToolbox", RTLD_NOW)
        guard handle != nil else {
            print("Failed to load the library.")
            return
        }
        
        defer {
            dlclose(handle)
        }
        
        let createSymbol = dlsym(handle, "AudioServicesCreateSystemSoundID")
        guard createSymbol != nil else {
            print("Failed to find the symbol for AudioServicesCreateSystemSoundID.")
            return
        }
        typealias AudioServicesCreateSystemSoundIDType = @convention(c) (CFURL, UnsafeMutablePointer<SystemSoundID>) -> OSStatus
        let createFunction = unsafeBitCast(createSymbol, to: AudioServicesCreateSystemSoundIDType.self)
        
        let soundIDPointer = UnsafeMutablePointer<SystemSoundID>.allocate(capacity: 1)
        let url = Bundle.main.url(forResource: resource, withExtension: ext)! as CFURL
        let createStatus = createFunction(url, soundIDPointer)
        
        guard createStatus == noErr else {
            print("Error creating Sound ID: \(createStatus)")
            return
        }
        
        let soundID = soundIDPointer.pointee
        
        let addCompletionSymbol = dlsym(handle, "AudioServicesAddSystemSoundCompletion")
        guard addCompletionSymbol != nil else {
            print("Failed to find the symbol for AudioServicesAddSystemSoundCompletion.")
            return
        }
        typealias AudioServicesAddSystemSoundCompletionType = @convention(c) (
            SystemSoundID,
            CFRunLoop?,
            CFString?,
            @convention(c) (SystemSoundID, UnsafeMutableRawPointer?) -> Void,
            UnsafeMutableRawPointer?
        ) -> OSStatus
        let addCompletionFunction = unsafeBitCast(addCompletionSymbol, to: AudioServicesAddSystemSoundCompletionType.self)
        
        let completion: @convention(c) (SystemSoundID, UnsafeMutableRawPointer?) -> Void = { soundID, clientData in
            
            if let startTime = startPlayTime {
                let currentTime = DispatchTime.now()
                let duration: TimeInterval = calculateTimeInterval(from: startTime, to: currentTime)
                if duration < 0.1 { // If it finished almost immediately, the device is in silent mode
                    updateSilentState.send(true)
                } else {
                    updateSilentState.send(false)
                }
            }
            
            let handle = dlopen("/System/Library/Frameworks/AudioToolbox.framework/AudioToolbox", RTLD_NOW)
            guard handle != nil else {
                print("Failed to load the library.")
                return
            }

            defer {
                dlclose(handle)
            }
            
            let removeCompletionSymbol = dlsym(handle, "AudioServicesRemoveSystemSoundCompletion")
            guard removeCompletionSymbol != nil else {
                print("Failed to find the symbol for AudioServicesRemoveSystemSoundCompletion.")
                return
            }
            typealias AudioServicesRemoveSystemSoundCompletionType = @convention(c) (SystemSoundID) -> Void
            let removeCompletionFunction = unsafeBitCast(removeCompletionSymbol, to: AudioServicesRemoveSystemSoundCompletionType.self)
            
            removeCompletionFunction(soundID)
        }
        
        let runLoop: CFRunLoop? = nil
        let runLoopMode: CFString? = nil
        let clientData: UnsafeMutableRawPointer? = nil
        
        let addStatus = addCompletionFunction(soundID, runLoop, runLoopMode, completion, clientData)
        
        guard addStatus == noErr else {
            print("Error setting completion routine: \(addStatus)")
            return
        }
        
        let playSoundSymbol = dlsym(handle, "AudioServicesPlaySystemSound")
        guard playSoundSymbol != nil else {
            print("Failed to find the symbol for AudioServicesPlaySystemSound.")
            return
        }
        typealias AudioServicesPlaySystemSoundType = @convention(c) (SystemSoundID) -> Void
        let playSoundFunction = unsafeBitCast(playSoundSymbol, to: AudioServicesPlaySystemSoundType.self)
        
        playSoundFunction(soundID)
        startPlayTime = .now()
        
        soundIDPointer.deallocate()
    }
}

fileprivate func calculateTimeInterval(from start: DispatchTime, to end: DispatchTime) -> TimeInterval {
    let nanoseconds = end.uptimeNanoseconds - start.uptimeNanoseconds
    let timeInterval = TimeInterval(nanoseconds) / 1_000_000_000
    return timeInterval
}
