//
//  VideoViewModel.swift
//  VideoMeme
//
//  Created by Guilherme Rambo on 26/06/20.
//

import Foundation
import AVFoundation

final class VideoViewModel: ObservableObject {
    
    var videoURL: URL? {
        didSet {
            guard let url = videoURL else { return }
            player = AVPlayer(url: url)
        }
    }
    
    @Published private(set) var player = AVPlayer()
    
    init() { }
    
}
