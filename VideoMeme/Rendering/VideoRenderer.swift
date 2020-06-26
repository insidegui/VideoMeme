//
//  VideoRenderer.swift
//  VideoMeme
//
//  Created by Guilherme Rambo on 26/06/20.
//

import Cocoa
import AVFoundation
import os.log
import Combine

final class VideoRenderer: ObservableObject {
    
    init() { }

    private let log = OSLog(subsystem: "VideoText", category: String(describing: VideoRenderer.self))

    private func error(with message: String) -> Error {
        NSError(domain: "codes.rambo.VideoRenderer", code: 0, userInfo: [NSLocalizedRecoverySuggestionErrorKey: message])
    }

    typealias RenderProgressBlock = (Float) -> Void
    typealias RenderCompletionBlock = (Result<URL, Error>) -> Void

    private var completionHandler: RenderCompletionBlock?

    private var currentSession: AVAssetExportSession?

    func renderClip(playerItem: AVPlayerItem, title: String, outputURL: URL, completion: @escaping RenderCompletionBlock) {
        os_log("%{public}@", log: log, type: .debug, #function)

        completionHandler = completion

        let preset = AVAssetExportPreset640x480

        do {
            let comp = try VideoComposition(
                video: playerItem.asset,
                title: title
            )

            guard let session = AVAssetExportSession(asset: comp, presetName: preset) else {
                completion(.failure(error(with: "The export session couldn't be initialized.")))
                return
            }

            session.videoComposition = comp.videoComposition

            currentSession = session

            startExport(with: session, playerItem: playerItem, title: title, outputURL: outputURL)

            startProgressReporting()
        } catch {
            os_log("Composition initialization failed: %{public}@", log: self.log, type: .error, String(describing: error))

            reportCompletion(with: .failure(self.error(with: "Couldn't create video composition for clip.")))
        }
    }

    private func startExport(with session: AVAssetExportSession, playerItem: AVPlayerItem, title: String, outputURL: URL) {
        session.outputFileType = .mp4
        session.outputURL = outputURL

        os_log("Will output to %@", log: self.log, type: .debug, outputURL.path)

        let startTime = playerItem.reversePlaybackEndTime
        let endTime = playerItem.forwardPlaybackEndTime
        let timeRange = CMTimeRangeFromTimeToTime(start: startTime, end: endTime)
        session.timeRange = timeRange

        session.exportAsynchronously { [weak session, weak self] in
            guard let self = self else { return }
            guard let session = session else { return }

            switch session.status {
            case .unknown:
                os_log("Export session received unknown status")
            case .waiting:
                os_log("Export session waiting")
            case .exporting:
                os_log("Export session started")
            case .completed:
                os_log("Export session finished")
                self.progressUpdateTimer?.invalidate()
                
                self.reportCompletion(with: .success(outputURL))
            case .failed:
                if let error = session.error {
                    os_log("Export session failed with error: %{public}@", log: self.log, type: .error, String(describing: error))
                } else {
                    os_log("Export session failed with an unknown error", log: self.log, type: .error)
                }

                self.reportCompletion(with: .failure(self.error(with: "The export failed.")))
            case .cancelled:
                self.progressUpdateTimer?.invalidate()
                os_log("Cancelled", log: self.log, type: .debug)
                return
            @unknown default:
                fatalError("Unknown case")
            }
        }
    }

    private var progressUpdateTimer: Timer?

    @Published private(set) var currentProgress: Float = 0

    private func startProgressReporting() {
        let progressCheckInterval: TimeInterval = 0.1

        progressUpdateTimer = Timer.scheduledTimer(withTimeInterval: progressCheckInterval, repeats: true, block: { [weak self] timer in
            guard let self = self else { return }

            guard self.currentSession?.status == .exporting else {
                timer.invalidate()
                self.progressUpdateTimer = nil
                return
            }

            DispatchQueue.main.async {
                self.currentProgress = self.currentSession?.progress ?? 0
            }
        })
    }

    func cancel() {
        currentSession?.cancelExport()
        currentSession = nil
    }

    private func reportCompletion(with result: Result<URL, Error>) {
        DispatchQueue.main.async {
            self.completionHandler?(result)
        }
    }

}

