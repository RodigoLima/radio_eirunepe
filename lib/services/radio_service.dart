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
      } catch (e) {
        // Ignora erros de configuração de audio session
        debugPrint('Erro ao configurar audio session: $e');
      }
    }

    _isConfigured = true;
  }

  Future<void> start() async {
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
          e.toString().contains('Network')) {
        throw Exception('Sem conexão com a internet');
      }
      rethrow;
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
