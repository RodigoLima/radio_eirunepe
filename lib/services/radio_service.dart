import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:just_audio_background/just_audio_background.dart';

class RadioService {
  static final RadioService _instance = RadioService._internal();
  factory RadioService() => _instance;
  RadioService._internal();

  final just_audio.AudioPlayer _audioPlayer = just_audio.AudioPlayer();
  final String _streamUrl = 'https://s12.maxcast.com.br:8824/live?id=391239150545';

  bool _isConfigured = false;
  bool _sourceLoaded = false;
  bool _shouldBePlaying = false;
  bool _isReconnecting = false;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _playbackEventSubscription;

  just_audio.AudioPlayer get player => _audioPlayer;

  Future<void> configure() async {
    if (_isConfigured) return;

    if (!kIsWeb) {
      try {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.music,
            flags: AndroidAudioFlags.none,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: false,
        ));
        await session.setActive(true);
      } catch (e) {
        debugPrint('Erro ao configurar audio session: $e');
      }
    }

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (_shouldBePlaying &&
          !state.playing &&
          state.processingState == just_audio.ProcessingState.idle &&
          !_isReconnecting) {
        _reconnect();
      }
    });

    _playbackEventSubscription = _audioPlayer.playbackEventStream.listen((event) {
      if (event.bufferedPosition == Duration.zero && _shouldBePlaying && !_isReconnecting) {
        Future.delayed(const Duration(seconds: 2), () {
          if (_shouldBePlaying && !_audioPlayer.playing) {
            _reconnect();
          }
        });
      }
    }, onError: (error) {
      debugPrint('Erro no playback: $error');
      if (_shouldBePlaying && !_isReconnecting) {
        _reconnect();
      }
    });

    _isConfigured = true;
  }

  Future<void> start() async {
    _shouldBePlaying = true;

    if (!kIsWeb) {
      try {
        final session = await AudioSession.instance;
        await session.setActive(true);
      } catch (e) {
        debugPrint('Erro ao reativar sessão: $e');
      }
    }

    try {
      if (!_sourceLoaded) {
        await _audioPlayer.setAudioSource(
          just_audio.AudioSource.uri(
            Uri.parse(_streamUrl),
            tag: const MediaItem(
              id: 'radio_eirunepe',
              title: 'Rádio Eirunepé',
              artist: 'Ao Vivo',
              album: 'Programa Eone Cavalcante',
            ),
          ),
          preload: true,
        );
        _sourceLoaded = true;
      }

      await _audioPlayer.play();
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network') ||
          e.toString().contains('UnknownHostException')) {
        throw Exception('Sem conexão com a internet');
      }
      rethrow;
    }
  }

  Future<void> stop() async {
    _shouldBePlaying = false;
    await _audioPlayer.stop();
    _sourceLoaded = false;
  }

  Future<void> _reconnect() async {
    if (_isReconnecting || !_shouldBePlaying) return;

    _isReconnecting = true;

    try {
      await Future.delayed(const Duration(seconds: 2));
      if (!_shouldBePlaying) {
        _isReconnecting = false;
        return;
      }

      await _audioPlayer.stop();
      _sourceLoaded = false;
      await Future.delayed(const Duration(seconds: 1));

      await _audioPlayer.setAudioSource(
        just_audio.AudioSource.uri(
          Uri.parse(_streamUrl),
          tag: const MediaItem(
            id: 'radio_eirunepe',
            title: 'Rádio Eirunepé',
            artist: 'Ao Vivo',
            album: 'Programa Eone Cavalcante',
          ),
        ),
        preload: true,
      );
      _sourceLoaded = true;
      await _audioPlayer.play();
    } catch (e) {
      if (_shouldBePlaying) {
        Future.delayed(const Duration(seconds: 5), () {
          if (_shouldBePlaying) {
            _isReconnecting = false;
            _reconnect();
          }
        });
        return;
      }
    }

    _isReconnecting = false;
  }

  Future<void> dispose() async {
    await _playerStateSubscription?.cancel();
    await _playbackEventSubscription?.cancel();
    await _audioPlayer.dispose();
  }
}
