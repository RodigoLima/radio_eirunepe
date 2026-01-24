import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:async';

class RadioService {
  static final RadioService _instance = RadioService._internal();
  factory RadioService() => _instance;
  RadioService._internal();

  final just_audio.AudioPlayer _audioPlayer = just_audio.AudioPlayer();
  final String _streamUrl = 'https://s12.maxcast.com.br:8824/live?id=391239150545';
  
  bool _isConfigured = false;
  bool _shouldBePlaying = false;
  bool _isReconnecting = false;
  AudioHandler? _audioHandler;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _playbackEventSubscription;

  just_audio.AudioPlayer get player => _audioPlayer;

  Future<void> configure() async {
    if (_isConfigured) return;
    
    // Configura o AudioService para notificações de mídia (não funciona na web)
    if (!kIsWeb) {
      try {
        _audioHandler = await AudioService.init(
          builder: () => RadioAudioHandler(_audioPlayer, _streamUrl),
          config: AudioServiceConfig(
            androidNotificationChannelId: 'com.radio_eirunepe.aab.channel.audio',
            androidNotificationChannelName: 'Rádio Eirunepé',
            androidNotificationChannelDescription: 'Reprodução de áudio da Rádio Eirunepé',
            androidNotificationOngoing: true,
            androidShowNotificationBadge: true,
            androidStopForegroundOnPause: false,
            androidNotificationIcon: 'mipmap/ic_launcher',
          ),
        );
        
        // Configura a fila de mídia inicial
        _audioHandler!.updateQueue([
          MediaItem(
            id: 'radio_eirunepe',
            title: 'Rádio Eirunepé',
            artist: 'Ao Vivo',
            album: 'Programa Eone Cavalcante',
            playable: true,
          ),
        ]);
        
        debugPrint('AudioService inicializado com sucesso');
      } catch (e) {
        debugPrint('Erro ao inicializar AudioService: $e');
      }
    }
    
    // AudioSession não funciona na web, então só configura em outras plataformas
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
        
        // Garante que a sessão permaneça ativa mesmo em background
        await session.setActive(true);
        
        // Mantém a sessão ativa continuamente
        session.becomingNoisyEventStream.listen((_) {
          // Se o áudio ficar "ruidoso" (perde foco), tenta manter tocando
          if (_shouldBePlaying && !_audioPlayer.playing) {
            _audioPlayer.play();
          }
        });

        session.interruptionEventStream.listen((event) {
          // Não pausa automaticamente quando o app vai para background
          // Só trata interrupções de volume (duck) para não interferir com outros apps
          if (event.begin) {
            switch (event.type) {
              case AudioInterruptionType.duck:
                // Reduz volume temporariamente quando outro app precisa de foco
                _audioPlayer.setVolume(0.5);
                break;
              case AudioInterruptionType.pause:
              case AudioInterruptionType.unknown:
                // Não pausa - mantém o áudio tocando mesmo em background
                // O just_audio já gerencia isso automaticamente
                break;
            }
          } else {
            // Quando a interrupção termina
            switch (event.type) {
              case AudioInterruptionType.duck:
                // Restaura volume normal
                _audioPlayer.setVolume(1.0);
                break;
              case AudioInterruptionType.pause:
              case AudioInterruptionType.unknown:
                // Não faz nada - deixa o player continuar normalmente
                break;
            }
          }
        });

        // Monitora erros de conexão e tenta reconectar automaticamente
        _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
          // Se estava tocando e parou por erro, tenta reconectar
          if (_shouldBePlaying && 
              !state.playing && 
              state.processingState == just_audio.ProcessingState.idle &&
              !_isReconnecting) {
            _reconnect();
          }
        });

        // Monitora erros de playback
        _playbackEventSubscription = _audioPlayer.playbackEventStream.listen((event) {
          // Se houver erro de rede, tenta reconectar
          if (event.bufferedPosition == Duration.zero && 
              _shouldBePlaying && 
              !_isReconnecting) {
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
      } catch (e) {
        // Ignora erros de configuração de audio session
        debugPrint('Erro ao configurar audio session: $e');
      }
    }

    _isConfigured = true;
  }

  Future<void> start() async {
    _shouldBePlaying = true;
    
    // Reativa a sessão de áudio antes de iniciar
    if (!kIsWeb) {
      try {
        final session = await AudioSession.instance;
        await session.setActive(true);
      } catch (e) {
        debugPrint('Erro ao reativar sessão: $e');
      }
    }
    
    // Tenta iniciar o stream - se não houver conexão, o próprio player lançará erro
    // Isso é mais leve que verificar conexão separadamente
    try {
      await _audioPlayer.setUrl(_streamUrl);
      await _audioPlayer.setLoopMode(just_audio.LoopMode.one);
      await _audioPlayer.setAutomaticallyWaitsToMinimizeStalling(false);
      
      // Configurações adicionais para manter em background
      await _audioPlayer.setSpeed(1.0);
      
      // Usa o AudioHandler para iniciar (isso mostra a notificação)
      if (!kIsWeb && _audioHandler != null) {
        await _audioHandler!.play();
        debugPrint('Áudio iniciado via AudioHandler');
      } else {
        await _audioPlayer.play();
        debugPrint('Áudio iniciado via AudioPlayer');
      }
      
      // Atualiza a notificação com informações da rádio
      if (!kIsWeb && _audioHandler != null) {
        _audioHandler!.updateQueue([
          MediaItem(
            id: 'radio_eirunepe',
            title: 'Rádio Eirunepé',
            artist: 'Ao Vivo',
            album: 'Programa Eone Cavalcante',
            playable: true,
          ),
        ]);
        debugPrint('Fila de mídia atualizada');
      }
      
      // Força a sessão a permanecer ativa após iniciar
      if (!kIsWeb) {
        try {
          final session = await AudioSession.instance;
          await session.setActive(true);
        } catch (e) {
          debugPrint('Erro ao manter sessão ativa: $e');
        }
      }
    } catch (e) {
      // Converte erros de rede em mensagem amigável
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
    if (!kIsWeb && _audioHandler != null) {
      await _audioHandler!.stop();
    } else {
      await _audioPlayer.stop();
    }
  }

  Future<void> _reconnect() async {
    if (_isReconnecting || !_shouldBePlaying) return;
    
    _isReconnecting = true;
    debugPrint('Tentando reconectar...');
    
    try {
      // Aguarda um pouco antes de reconectar
      await Future.delayed(const Duration(seconds: 2));
      
      if (!_shouldBePlaying) {
        _isReconnecting = false;
        return;
      }

      // Para o player atual
      try {
        await _audioPlayer.stop();
      } catch (e) {
        debugPrint('Erro ao parar player: $e');
      }

      // Aguarda um pouco
      await Future.delayed(const Duration(seconds: 1));

      // Reconecta
      await _audioPlayer.setUrl(_streamUrl);
      await _audioPlayer.setLoopMode(just_audio.LoopMode.one);
      await _audioPlayer.setAutomaticallyWaitsToMinimizeStalling(false);
      await _audioPlayer.play();
      
      debugPrint('Reconectado com sucesso');
    } catch (e) {
      debugPrint('Erro ao reconectar: $e');
      // Tenta novamente após 5 segundos
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
    _playerStateSubscription?.cancel();
    _playbackEventSubscription?.cancel();
    if (_audioHandler != null) {
      await _audioHandler!.stop();
    }
    await _audioPlayer.dispose();
  }
}

// Handler para o AudioService - implementação corrigida
class RadioAudioHandler extends BaseAudioHandler with SeekHandler {
  final just_audio.AudioPlayer _player;
  final String _streamUrl;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _playbackEventSub;

  RadioAudioHandler(this._player, this._streamUrl) {
    // Escuta mudanças no player e atualiza o estado da notificação
    _playerStateSub = _player.playerStateStream.listen((state) {
      _updatePlaybackState();
    });
    
    _playbackEventSub = _player.playbackEventStream.listen((event) {
      _updatePlaybackState();
    });
    
    // Atualiza estado inicial
    _updatePlaybackState();
  }

  @override
  Future<void> play() async {
    await _player.setUrl(_streamUrl);
    await _player.setLoopMode(just_audio.LoopMode.one);
    await _player.play();
    _updatePlaybackState();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _updatePlaybackState();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _updatePlaybackState();
  }

  void _updatePlaybackState() {
    final state = _player.playerState;
    final position = _player.position;
    final bufferedPosition = _player.bufferedPosition;
    final speed = _player.speed;
    
    // Mapeia ProcessingState corretamente
    final processingState = _mapProcessingState(state.processingState);
    
    // Atualiza o estado de reprodução na notificação
    playbackState.value = PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (state.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: processingState,
      playing: state.playing,
      updatePosition: position,
      bufferedPosition: bufferedPosition,
      speed: speed,
      queueIndex: 0,
    );
  }

  dynamic _mapProcessingState(just_audio.ProcessingState state) {
    // ProcessingState é um enum no audio_service
    // Mapeia os valores do just_audio para os valores do audio_service
    // Usa os índices do enum ProcessingState do audio_service (0-4)
    switch (state) {
      case just_audio.ProcessingState.idle:
        return 0; // ProcessingState.idle
      case just_audio.ProcessingState.loading:
        return 1; // ProcessingState.loading
      case just_audio.ProcessingState.buffering:
        return 2; // ProcessingState.buffering
      case just_audio.ProcessingState.ready:
        return 3; // ProcessingState.ready
      case just_audio.ProcessingState.completed:
        return 4; // ProcessingState.completed
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    // Mantém o serviço rodando mesmo quando a task é removida
    await super.onTaskRemoved();
  }
}
