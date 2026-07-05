//
//  HeadsUpVolumeMonitor.swift
//  Couch Games
//

import AVFoundation
import MediaPlayer
import SwiftUI
import UIKit

@MainActor
final class HeadsUpVolumeMonitor {
    private var observation: NSKeyValueObservation?
    private weak var volumeSlider: UISlider?
    private let anchorVolume: Float = 0.5
    private var suppressUntil = Date.distantPast
    private let cooldown: TimeInterval = 0.22

    var onVolumeUp: (() -> Void)?
    var onVolumeDown: (() -> Void)?

    func attach(volumeView: MPVolumeView) {
        volumeSlider = volumeView.subviews.compactMap { $0 as? UISlider }.first
    }

    func start() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        if session.outputVolume <= 0.05 || session.outputVolume >= 0.95 {
            setSystemVolume(anchorVolume)
        }

        observation?.invalidate()
        observation = session.observe(\.outputVolume, options: [.old, .new]) { session, change in
            let oldValue = change.oldValue ?? session.outputVolume
            let newValue = change.newValue ?? session.outputVolume
            Task { @MainActor [weak self] in
                self?.handleVolumeChange(oldValue: oldValue, newValue: newValue)
            }
        }
    }

    func stop() {
        observation?.invalidate()
        observation = nil
    }

    private func handleVolumeChange(oldValue: Float, newValue: Float) {
        guard Date() >= suppressUntil else { return }
        guard abs(newValue - oldValue) > 0.001 else { return }

        if newValue > oldValue {
            onVolumeUp?()
        } else {
            onVolumeDown?()
        }

        suppressUntil = Date().addingTimeInterval(cooldown)
        setSystemVolume(anchorVolume)
    }

    private func setSystemVolume(_ volume: Float) {
        volumeSlider?.value = volume
    }
}

struct HiddenVolumeView: UIViewRepresentable {
    var onViewCreated: (MPVolumeView) -> Void

    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView(frame: .zero)
        view.alpha = 0.001
        view.isUserInteractionEnabled = false
        DispatchQueue.main.async {
            onViewCreated(view)
        }
        return view
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
