import Foundation
#if arch(arm64)
import MediaRemoteAdapter
#endif

/// Service that wraps MediaRemoteAdapter's MediaController to provide
/// controlled pause/resume functionality during transcription.
///
/// This service ensures we only pause media if it's currently playing,
/// and only resume if we were the ones who paused it.
@MainActor
final class MediaPlaybackService {
    static let shared = MediaPlaybackService()

    #if arch(arm64)
    private let mediaController = MediaController()
    #endif

    private init() {}

    // MARK: - Public API

    #if arch(arm64)
    /// Pauses system media playback if something is currently playing.
    ///
    /// - Returns: `true` if we successfully paused playback, `false` if nothing was playing
    ///   or if we couldn't determine playback state.
    ///
    /// - Note: Uses a local one-shot gate to protect against `MediaRemoteAdapter`
    ///   firing the `getTrackInfo` callback more than once, which would otherwise
    ///   crash with `EXC_BREAKPOINT` (SIGTRAP) due to double-resume of a
    ///   `CheckedContinuation`.
    func pauseIfPlaying() async -> Bool {
        // Media auto-pause during dictation is intentionally DISABLED.
        // We never pause the user's currently-playing audio (podcast/music/etc.)
        // just because they started dictating. Returning false means
        // resumeIfWePaused(_:) is always a no-op as well.
        DebugLogger.shared.debug(
            "MediaPlaybackService: Auto-pause disabled, leaving media playback untouched",
            source: "MediaPlaybackService"
        )
        return false
    }

    /// Resumes media playback only if we were the ones who paused it.
    ///
    /// - Parameter wePaused: `true` if `pauseIfPlaying()` returned `true` for this session.
    func resumeIfWePaused(_ wePaused: Bool) async {
        guard wePaused else {
            DebugLogger.shared.debug(
                "MediaPlaybackService: We didn't pause media, not resuming",
                source: "MediaPlaybackService"
            )
            return
        }

        DebugLogger.shared.info(
            "MediaPlaybackService: Resuming media playback (we paused it)",
            source: "MediaPlaybackService"
        )

        // Use explicit play() command - never toggle
        self.mediaController.play()
    }
    #else
    // Intel Mac stub - media control not available
    func pauseIfPlaying() async -> Bool {
        DebugLogger.shared.debug(
            "MediaPlaybackService: Not available on Intel Macs",
            source: "MediaPlaybackService"
        )
        return false
    }

    func resumeIfWePaused(_ wePaused: Bool) async {
        // No-op on Intel
    }
    #endif
}
