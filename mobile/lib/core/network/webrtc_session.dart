import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../storage/api_endpoint.dart';

/// How far the call has got, mirroring `connectionState` in the web hook.
enum CallState { connecting, connected, disconnected }

/// Dart port of `frontend/src/hooks/useWebRTC.js`.
///
/// The backend's Socket.IO namespace (`backend/src/server.js`) is the only
/// signalling channel, and it is protocol-agnostic: `join-room` announces a
/// peer, `room-peers` tells a late joiner who is already there, and
/// `offer`/`answer`/`ice-candidate` are relayed verbatim between two socket
/// ids. A Flutter client that speaks the same events joins the very same rooms
/// the web client uses, so a parent on a phone and a doctor in a browser end up
/// in one call.
///
/// Whoever arrives second creates the offer — `room-peers` is only non-empty
/// for the later peer, which is what breaks the tie.
class WebRtcSession {
  WebRtcSession({required this.roomId, required this.userRole});

  /// The appointment id, used as the Socket.IO room name.
  final String roomId;

  /// `DOCTOR` or `PARENT`, echoed to the other peer on join.
  final String userRole;

  static const List<Map<String, String>> _iceServers = <Map<String, String>>[
    <String, String>{'urls': 'stun:stun.l.google.com:19302'},
    <String, String>{'urls': 'stun:stun1.l.google.com:19302'},
    <String, String>{'urls': 'stun:stun2.l.google.com:19302'},
  ];

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  io.Socket? _socket;
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  String? _peerId;

  /// ICE arriving before the remote description is set has nowhere to go yet.
  final List<RTCIceCandidate> _pendingIce = <RTCIceCandidate>[];

  bool _disposed = false;

  final ValueNotifier<CallState> state = ValueNotifier<CallState>(
    CallState.connecting,
  );
  final ValueNotifier<bool> isMuted = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isVideoOff = ValueNotifier<bool>(false);
  final ValueNotifier<String?> remoteUserRole = ValueNotifier<String?>(null);

  /// Set when the camera or microphone could not be opened, so the screen can
  /// say why instead of sitting on "connecting" forever.
  final ValueNotifier<String?> mediaError = ValueNotifier<String?>(null);

  /// Socket.IO runs on the API host itself, not under `/api/v1`.
  static String get signalUrl {
    final String base = ApiEndpoint.current;
    final int marker = base.indexOf('/api/');
    return marker == -1 ? base : base.substring(0, marker);
  }

  Future<void> connect() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();

    // 1. Camera and microphone. A refused permission ends the call here.
    try {
      _localStream = await navigator.mediaDevices.getUserMedia(
        <String, dynamic>{
          'audio': true,
          'video': <String, dynamic>{'facingMode': 'user'},
        },
      );
    } on Exception catch (error) {
      mediaError.value =
          'Could not open the camera or microphone. Check the app’s '
          'permissions and try again.\n\n$error';
      state.value = CallState.disconnected;
      return;
    }
    if (_disposed) {
      await _stopLocalStream();
      return;
    }
    localRenderer.srcObject = _localStream;

    // 2. Peer connection, with our tracks attached.
    final RTCPeerConnection pc = await createPeerConnection(<String, dynamic>{
      'iceServers': _iceServers,
      'sdpSemantics': 'unified-plan',
    });
    _pc = pc;

    pc.onIceCandidate = (RTCIceCandidate candidate) {
      final String? target = _peerId;
      if (target != null) {
        _socket?.emit('ice-candidate', <String, dynamic>{
          'target': target,
          'candidate': candidate.toMap(),
        });
      }
    };

    pc.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams.first;
        state.value = CallState.connected;
      }
    };

    pc.onConnectionState = (RTCPeerConnectionState s) {
      if (s == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          s == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        state.value = CallState.disconnected;
      }
    };

    final MediaStream? stream = _localStream;
    if (stream != null) {
      for (final MediaStreamTrack track in stream.getTracks()) {
        await pc.addTrack(track, stream);
      }
    }

    if (_disposed) return;

    // 3. Signalling.
    final io.Socket socket = io.io(
      signalUrl,
      io.OptionBuilder()
          .setTransports(<String>['websocket', 'polling'])
          .enableForceNew()
          .build(),
    );
    _socket = socket;

    socket.onConnect((_) {
      socket.emit('join-room', <String, dynamic>{
        'roomId': roomId,
        'userRole': userRole,
      });
    });

    // Someone is already here, so we are the ones who offer.
    socket.on('room-peers', (dynamic data) async {
      final List<dynamic> peers = (data is Map && data['peers'] is List)
          ? data['peers'] as List<dynamic>
          : const <dynamic>[];
      if (peers.isEmpty) return;

      _peerId = peers.first.toString();
      final RTCSessionDescription offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      socket.emit('offer', <String, dynamic>{
        'target': _peerId,
        'offer': offer.toMap(),
      });
    });

    // A late joiner will offer to us; just remember who they are.
    socket.on('peer-joined', (dynamic data) {
      if (data is Map) {
        _peerId = data['socketId']?.toString();
        remoteUserRole.value = data['userRole']?.toString();
      }
    });

    socket.on('offer', (dynamic data) async {
      if (data is! Map) return;
      _peerId = data['from']?.toString();

      final Map<String, dynamic>? offer = _asMap(data['offer']);
      if (offer == null) return;

      await pc.setRemoteDescription(
        RTCSessionDescription(offer['sdp'] as String?, offer['type'] as String?),
      );
      await _flushPendingIce();

      final RTCSessionDescription answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      socket.emit('answer', <String, dynamic>{
        'target': _peerId,
        'answer': answer.toMap(),
      });
    });

    socket.on('answer', (dynamic data) async {
      final Map<String, dynamic>? answer = (data is Map)
          ? _asMap(data['answer'])
          : null;
      if (answer == null) return;

      await pc.setRemoteDescription(
        RTCSessionDescription(
          answer['sdp'] as String?,
          answer['type'] as String?,
        ),
      );
      await _flushPendingIce();
    });

    socket.on('ice-candidate', (dynamic data) async {
      if (data is! Map) return;
      _peerId ??= data['from']?.toString();

      final Map<String, dynamic>? json = _asMap(data['candidate']);
      if (json == null) return;

      final RTCIceCandidate candidate = RTCIceCandidate(
        json['candidate'] as String?,
        json['sdpMid'] as String?,
        (json['sdpMLineIndex'] as num?)?.toInt(),
      );

      // Adding a candidate before the remote description exists throws, so
      // hold them until the description lands.
      if (await pc.getRemoteDescription() != null) {
        try {
          await pc.addCandidate(candidate);
        } on Exception {
          // A late or duplicate candidate is harmless.
        }
      } else {
        _pendingIce.add(candidate);
      }
    });

    socket.on('peer-left', (_) {
      remoteRenderer.srcObject = null;
      state.value = CallState.disconnected;
    });
  }

  Future<void> _flushPendingIce() async {
    final RTCPeerConnection? pc = _pc;
    if (pc == null) return;
    while (_pendingIce.isNotEmpty) {
      try {
        await pc.addCandidate(_pendingIce.removeAt(0));
      } on Exception {
        // Ignore, same as the web hook.
      }
    }
  }

  static Map<String, dynamic>? _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;

  void toggleMic() {
    final List<MediaStreamTrack>? tracks = _localStream?.getAudioTracks();
    if (tracks == null || tracks.isEmpty) return;
    final bool enabled = !tracks.first.enabled;
    tracks.first.enabled = enabled;
    isMuted.value = !enabled;
  }

  void toggleCamera() {
    final List<MediaStreamTrack>? tracks = _localStream?.getVideoTracks();
    if (tracks == null || tracks.isEmpty) return;
    final bool enabled = !tracks.first.enabled;
    tracks.first.enabled = enabled;
    isVideoOff.value = !enabled;
  }

  Future<void> switchCamera() async {
    final List<MediaStreamTrack>? tracks = _localStream?.getVideoTracks();
    if (tracks == null || tracks.isEmpty) return;
    await Helper.switchCamera(tracks.first);
  }

  Future<void> _stopLocalStream() async {
    final MediaStream? stream = _localStream;
    if (stream == null) return;
    for (final MediaStreamTrack track in stream.getTracks()) {
      await track.stop();
    }
    await stream.dispose();
    _localStream = null;
  }

  /// Leaves the room and releases the camera. Safe to call more than once.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    _socket?.emit('leave-room', <String, dynamic>{'roomId': roomId});
    _socket?.dispose();
    _socket = null;

    await _stopLocalStream();
    await _pc?.close();
    _pc = null;

    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;
    await localRenderer.dispose();
    await remoteRenderer.dispose();

    state.value = CallState.disconnected;
  }
}
