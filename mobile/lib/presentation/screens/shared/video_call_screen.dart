import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../core/network/webrtc_session.dart';
import '../../../data/models/enums.dart';
import '../../providers/providers.dart';

/// Port of `frontend/src/pages/dashboard/TeleconsultSession.jsx`.
///
/// Joins the appointment's Socket.IO room through [WebRtcSession], so the peer
/// on the other side can equally be a doctor sitting in the web app — both
/// clients speak the same signalling protocol.
class VideoCallScreen extends ConsumerStatefulWidget {
  const VideoCallScreen({super.key, required this.roomId});

  /// The appointment id, which doubles as the room name.
  final String roomId;

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  WebRtcSession? _session;

  @override
  void initState() {
    super.initState();
    // Read the role once — the peer is told who joined, exactly as on the web.
    final UserRole? role = ref.read(currentRoleProvider);
    final WebRtcSession session = WebRtcSession(
      roomId: widget.roomId,
      userRole: (role ?? UserRole.parent).wire,
    );
    _session = session;
    WidgetsBinding.instance.addPostFrameCallback((_) => session.connect());
  }

  @override
  void dispose() {
    _session?.dispose();
    super.dispose();
  }

  Future<void> _hangUp() async {
    await _session?.dispose();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final WebRtcSession? session = _session;
    if (session == null) return const SizedBox.shrink();

    final bool isDoctor = ref.watch(currentRoleProvider) == UserRole.doctor;

    return PopScope(
      // Leaving by the back gesture must still release the camera.
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (didPop) session.dispose();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1120),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(child: _remote(session, isDoctor)),
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: _selfView(session),
                    ),
                  ],
                ),
              ),
              _controls(session, isDoctor),
            ],
          ),
        ),
      ),
    );
  }

  // ── Remote peer, or the waiting state ────────────────────────────────────

  Widget _remote(WebRtcSession session, bool isDoctor) {
    return ValueListenableBuilder<String?>(
      valueListenable: session.mediaError,
      builder: (BuildContext context, String? mediaError, Widget? _) {
        if (mediaError != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.videocam_off_rounded,
                    size: 46,
                    color: Colors.white38,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    mediaError,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ValueListenableBuilder<CallState>(
          valueListenable: session.state,
          builder: (BuildContext context, CallState state, Widget? _) {
            if (state == CallState.connected) {
              return RTCVideoView(
                session.remoteRenderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              );
            }

            final bool ended = state == CallState.disconnected;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 110,
                    height: 110,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E293B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 56,
                      color: Colors.white24,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    ended
                        ? 'Call ended'
                        : 'Waiting for ${isDoctor ? 'patient' : 'doctor'} '
                              'to join...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!ended) ...<Widget>[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF34D399),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Establishing encrypted tunnel...',
                          style: TextStyle(
                            color: const Color(0xFF34D399).withValues(
                              alpha: 0.9,
                            ),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Self view ────────────────────────────────────────────────────────────

  Widget _selfView(WebRtcSession session) {
    return ValueListenableBuilder<bool>(
      valueListenable: session.isVideoOff,
      builder: (BuildContext context, bool videoOff, Widget? _) {
        return Container(
          width: 108,
          height: 148,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (!videoOff)
                RTCVideoView(
                  session.localRenderer,
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                )
              else
                const Center(
                  child: Icon(
                    Icons.videocam_off_rounded,
                    color: Colors.white38,
                    size: 26,
                  ),
                ),
              const Positioned(
                left: 6,
                bottom: 5,
                child: Text(
                  'YOU',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Mic / camera / switch / hang up ──────────────────────────────────────

  Widget _controls(WebRtcSession session, bool isDoctor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      color: const Color(0xFF0F172A),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ValueListenableBuilder<bool>(
                valueListenable: session.isMuted,
                builder: (BuildContext context, bool muted, Widget? _) {
                  return _circleButton(
                    icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    tooltip: muted ? 'Unmute' : 'Mute',
                    background: muted
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF1E293B),
                    onTap: session.toggleMic,
                  );
                },
              ),
              const SizedBox(width: 16),
              ValueListenableBuilder<bool>(
                valueListenable: session.isVideoOff,
                builder: (BuildContext context, bool off, Widget? _) {
                  return _circleButton(
                    icon: off
                        ? Icons.videocam_off_rounded
                        : Icons.videocam_rounded,
                    tooltip: off ? 'Turn camera on' : 'Turn camera off',
                    background: off
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF1E293B),
                    onTap: session.toggleCamera,
                  );
                },
              ),
              const SizedBox(width: 16),
              _circleButton(
                icon: Icons.cameraswitch_rounded,
                tooltip: 'Switch camera',
                background: const Color(0xFF1E293B),
                onTap: session.switchCamera,
              ),
              const SizedBox(width: 16),
              _circleButton(
                icon: Icons.call_end_rounded,
                tooltip: 'End call',
                background: const Color(0xFFDC2626),
                size: 62,
                onTap: _hangUp,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            isDoctor
                ? '"Terminate Session For All" — ends the room for both parties'
                : 'Leaving the call does not close the room — your doctor can '
                      'reopen it.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required String tooltip,
    required Color background,
    required VoidCallback onTap,
    double size = 54,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: Colors.white, size: size * 0.4),
          ),
        ),
      ),
    );
  }
}
