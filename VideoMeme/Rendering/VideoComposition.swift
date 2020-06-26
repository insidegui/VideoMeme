//
//  VideoComposition.swift
//  VideoMeme
//
//  Created by Guilherme Rambo on 26/06/20.
//

import Cocoa
import AVFoundation
import CoreMedia

final class VideoComposition: AVMutableComposition {

    let title: String
    let video: AVAsset

    var videoComposition: AVMutableVideoComposition?

    init(video: AVAsset, title: String) throws {
        self.video = video
        self.title = title

        super.init()

        guard let newVideoTrack = addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            // Should this ever fail in real life? Who knows...
            preconditionFailure("Failed to add video track to composition")
        }

        if let videoTrack = video.tracks(withMediaType: .video).first {
            try newVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: video.duration), of: videoTrack, at: .zero)
        }

        if let newAudioTrack = addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            if let audioTrack = video.tracks(withMediaType: .audio).first {
                try newAudioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: video.duration), of: audioTrack, at: .zero)
            }
        }

        configureComposition(videoTrack: newVideoTrack)
    }

    private func configureComposition(videoTrack: AVMutableCompositionTrack) {
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRange(start: .zero, duration: video.duration)

        let videolayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        mainInstruction.layerInstructions = [videolayerInstruction]

        videoComposition = AVMutableVideoComposition(propertiesOf: video)
        videoComposition?.instructions = [mainInstruction]

        composeText(with: videoTrack.naturalSize)
    }

    private func composeText(with renderSize: CGSize) {
        let titleLayer = CATextLayer()

        titleLayer.string = attributedTitle
        titleLayer.shadowColor = NSColor.black.cgColor
        titleLayer.shadowOpacity = 0.7
        titleLayer.shadowRadius = 1
        titleLayer.shadowOffset = CGSize(width: 0.5, height: 0.5)

        // Compute final title layer width based on title.

        let titleSize = attributedTitle.size()
        
        titleLayer.frame = CGRect(
            x: renderSize.width / 2 - titleSize.width / 2,
            y: 60,
            width: titleSize.width,
            height: titleSize.height
        )

        let container = CALayer()
        container.frame = CGRect(origin: .zero, size: renderSize)
        
        let videoLayer = CALayer()
        videoLayer.frame = container.bounds
        container.addSublayer(videoLayer)

        container.addSublayer(titleLayer)

        container.isGeometryFlipped = true

        videoComposition?.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: container)

        titleLayer.minificationFilter = .trilinear

        /// Workaround rdar://32718905
        titleLayer.display()
    }

    private lazy var attributedTitle: NSAttributedString = {
        NSAttributedString.create(
            with: title,
            font: .roundedSystemFont(ofSize: 16, weight: .medium),
            color: .white
        )
    }()

}

extension NSAttributedString {
    static func create(with string: String,
                       font: NSFont,
                       color: NSColor,
                       lineHeightMultiple: CGFloat = 1,
                       alignment: NSTextAlignment = .left,
                       lineBreakMode: NSLineBreakMode = .byWordWrapping) -> NSAttributedString {
        let pStyle = NSMutableParagraphStyle()
        pStyle.lineHeightMultiple = lineHeightMultiple
        pStyle.alignment = alignment
        pStyle.lineBreakMode = lineBreakMode

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: pStyle
        ]

        return NSAttributedString(string: string, attributes: attrs)
    }
    
}

extension NSFont {

    static func roundedSystemFont(ofSize size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
        guard let desc = NSFont.systemFont(ofSize: size, weight: weight).fontDescriptor.withDesign(.rounded) else {
            assertionFailure("Failed to get font descriptor")
            return NSFont.systemFont(ofSize: size, weight: weight)
        }

        return NSFont(descriptor: desc, size: size) ?? NSFont.systemFont(ofSize: size, weight: weight)
    }

}
