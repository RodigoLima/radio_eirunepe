import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class RadioService {
  static final RadioService _instance = RadioService._internal();
  factory RadioService() => _instance;
  RadioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final String _streamUrl = 'https://s12.maxcast.com.br:8824/live?id=391239150545';
  
  bool _isConfigured = false;
  bool _shouldBePlaying = false;
  bool _isReconnecting = false;

  AudioPlayer get player => _audioPlayer;

  Future<void> configure() async {
    if (_isConfigured) return;
    
    // AudioSession não funciona na web, então só configura em outras plataformas
    if (!kIsWeb) {
      try {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.none,
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
        _audioPlayer.playerStateStream.listen((state) {
          // Se estava tocando e parou por erro, tenta reconectar
          if (_shouldBePlaying && 
              !state.playing && 
              state.processingState == ProcessingState.idle &&
              !_isReconnecting) {
            _reconnect();
          }
        });

        // Monitora erros de playback
        _audioPlayer.playbackEventStream.listen((event) {
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
    // Tenta iniciar o stream - se não houver conexão, o próprio player lançará erro
    // Isso é mais leve que verificar conexão separadamente
    try {
      await _audioPlayer.setUrl(_streamUrl);
      await _audioPlayer.setLoopMode(LoopMode.one);
      await _audioPlayer.setAutomaticallyWaitsToMinimizeStalling(false);
      await _audioPlayer.play();
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
    await _audioPlayer.stop();
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
      await _audioPlayer.setLoopMode(LoopMode.one);
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
    await _audioPlayer.dispose();
  }
}
