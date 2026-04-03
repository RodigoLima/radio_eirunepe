import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'services/radio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configura orientação para portrait apenas (opcional)
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.radio_eirunepe.channel.audio',
    androidNotificationChannelName: 'Rádio Eirunepé',
    androidNotificationOngoing: true,
  );
  
  await RadioService().configure();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rádio Eirunepé',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF02457B),
          primary: const Color(0xFFB11E27),
          secondary: const Color(0xFFFBE926),
          background: Colors.white,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onBackground: Colors.black,
          onSurface: Colors.black,
        ),
        useMaterial3: true,
        brightness: Brightness.light,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF02457B),
          primary: const Color(0xFFB11E27),
          secondary: const Color(0xFFFBE926),
          background: const Color(0xFF1E1E1E),
          surface: const Color(0xFF1E1E1E),
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onBackground: Colors.white,
          onSurface: Colors.white,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.light,
      home: const RadioHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RadioHomePage extends StatefulWidget {
  const RadioHomePage({super.key});

  @override
  State<RadioHomePage> createState() => _RadioHomePageState();
}

class _RadioHomePageState extends State<RadioHomePage> with WidgetsBindingObserver {
  final RadioService _radioService = RadioService();
  bool _isPlaying = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Quando o app vai para background ou retorna
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App foi para background - garante que o áudio continue
      debugPrint('App foi para background - mantendo áudio ativo');
      // O just_audio já gerencia isso, mas garantimos que está tocando
      if (_isPlaying && !_radioService.player.playing) {
        _radioService.player.play();
      }
    } else if (state == AppLifecycleState.resumed) {
      // App voltou para foreground
      debugPrint('App voltou para foreground');
      // Verifica se ainda está tocando
      if (_isPlaying && !_radioService.player.playing) {
        _radioService.player.play();
      }
    }
  }

  void _setupListeners() {
    _radioService.player.playerStateStream.listen((playerState) {
      if (!mounted) return;

      if (playerState.processingState == ProcessingState.ready && playerState.playing) {
        setState(() {
          _isLoading = false;
          _isPlaying = true;
          _errorMessage = null;
        });
      } else if (playerState.processingState == ProcessingState.completed ||
                 playerState.processingState == ProcessingState.idle) {
        // Se estava tocando e ficou idle, pode estar reconectando
        // Não atualiza o estado imediatamente para evitar flicker
        if (!_isPlaying || playerState.playing) {
          setState(() {
            _isLoading = false;
            _isPlaying = playerState.playing;
          });
        }
      } else if (playerState.processingState == ProcessingState.loading) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }
    }, onError: (error, stackTrace) {
      debugPrint('Erro no playerStateStream: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isPlaying = false;
        _errorMessage = 'Erro ao reproduzir áudio';
      });
      _showSnackBar('Erro ao reproduzir áudio');
    });

    // Listener de playback removido - não é necessário, o playerStateStream já cobre tudo
  }

  Future<void> _startStream() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _radioService.start();
    } catch (e) {
      debugPrint('Erro ao iniciar streaming: $e');
      final errorMsg = e.toString().contains('conexão') 
          ? 'Sem conexão com a internet. Verifique sua conexão e tente novamente.'
          : 'Erro ao iniciar a transmissão. Tente novamente.';
      
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isPlaying = false;
        _errorMessage = errorMsg;
      });
      _showSnackBar(errorMsg);
    }
  }

  Future<void> _stopStream() async {
    try {
      await _radioService.stop();
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('Erro ao parar streaming: $e');
      _showSnackBar('Erro ao parar a transmissão');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rádio Eirunepé',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Programa Eone Cavalcante',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'logo_radio.jpg',
                    height: 160,
                    width: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 160,
                        width: 160,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.radio,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  _isPlaying ? 'Tocando agora' : 'Pausado',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 70,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          onPressed: _isPlaying ? _stopStream : _startStream,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          icon: Icon(
                            _isPlaying ? Icons.stop : Icons.play_arrow,
                            size: 32,
                          ),
                          label: Text(
                            _isPlaying ? 'Parar' : 'Tocar',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 40),
                _buildContactInfo(
                  icon: Icons.phone,
                  text: 'Participe pelo telefone: (97) 98410-6555',
                  onTap: () {
                    // Ação de ligação pode ser implementada com url_launcher
                  },
                ),
                const SizedBox(height: 20),
                _buildContactInfo(
                  icon: Icons.message,
                  text: 'Envie sua mensagem pelo WhatsApp!',
                  color: Colors.green,
                  onTap: () {
                    // Ação do WhatsApp pode ser implementada com url_launcher
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfo({
    required IconData icon,
    required String text,
    Color? color,
    VoidCallback? onTap,
  }) {
    final themeColor = color ?? Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: themeColor, size: 24),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Não dispose o player aqui pois é singleton
    super.dispose();
  }
}
