//
//  IconManager.swift
//  FinderHover
//
//  Centralized icon management for SF Symbols used throughout the app
//

import Foundation

/// Manages all SF Symbol icons used in the application
enum IconManager {

    // MARK: - File & Folder Icons
    enum FileSystem {
        static let folder = "folder"
        static let doc = "doc"
        static let fileText = "doc.text"
    }

    // MARK: - Display & Settings Icons
    enum Display {
        static let eye = "eye"
        static let eyeSlash = "eye.slash"
        static let textformat = "textformat"
        static let clock = "clock"
        static let calendar = "calendar"
        static let lock = "lock"
        static let person = "person"
        static let ruler = "ruler"
        static let photo = "photo"
    }

    // MARK: - EXIF & Photo Icons
    enum Photo {
        static let camera = "camera"
        static let cameraFill = "camera.fill"
        static let lens = "camera.aperture"
        static let calendarClock = "calendar.badge.clock"
        static let dimensions = "arrow.up.left.and.arrow.down.right"
        static let location = "location"
        static let locationFill = "location.fill"
        static let settings = "slider.horizontal.3"
    }

    // MARK: - Video Icons
    enum Video {
        static let video = "video"
        static let videoFill = "video.fill"
        static let film = "film"
        static let duration = "clock"
        static let resolution = "arrow.up.left.and.arrow.down.right"
        static let frameRate = "speedometer"
        static let bitrate = "speedometer"
        static let codec = "film"
    }

    // MARK: - Audio Icons
    enum Audio {
        static let music = "music.note"
        static let musicNote = "music.note.list"
        static let songTitle = "textformat"
        static let artist = "person"
        static let album = "square.stack"
        static let genre = "music.note.list"
        static let year = "calendar"
        static let duration = "clock"
        static let bitrate = "waveform"
        static let sampleRate = "waveform.path"
        static let channels = "speaker.wave.2"
    }

    // MARK: - UI & Navigation Icons
    enum UI {
        static let gear = "gear"
        static let star = "star"
        static let starFill = "star.fill"
        static let info = "info.circle"
        static let checkmark = "checkmark"
        static let xmark = "xmark"
        static let chevronRight = "chevron.right"
        static let chevronLeft = "chevron.left"
        static let chevronUp = "chevron.up"
        static let chevronDown = "chevron.down"
        static let ellipsis = "ellipsis"
        static let line3Horizontal = "line.3.horizontal"
    }

    // MARK: - Menu Bar Icons
    enum MenuBar {
        static let appWindow = "appwindow.swipe.rectangle"
    }

}
