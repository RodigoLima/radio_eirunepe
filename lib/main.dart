import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() {
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
          seedColor: const Color(0xFF02457B), // Indigo dye
          primary: const Color(0xFFB11E27), // Tom de vermelho
          secondary: const Color(0xFFFBE926), // Aureolin
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
      home: const MyHomePage(title: 'Rádio Eirunepé'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;

  // Em caso de querer controlar se o widget está montado.
  bool _disposed = false;

  final String _streamUrl = 'https://s12.maxcast.com.br:8824/live?id=391239150545';

  @override
  void initState() {
    super.initState();

    // Listener principal para o estado do player
    _audioPlayer.playerStateStream.listen((playerState) {
      // Se o widget foi dispose, não execute mais nada.
      if (!mounted) return;

      if (playerState.processingState == ProcessingState.ready && playerState.playing) {
        setState(() {
          _isLoading = false;
          _isPlaying = true;
        });
      } else if (playerState.processingState == ProcessingState.completed ||
                 playerState.processingState == ProcessingState.idle) {
        // Quando o streaming termina ou fica idle
        setState(() {
          _isLoading = false;
          _isPlaying = false;
        });
      }
      // Você pode tratar mais casos conforme sua necessidade.
    }, onError: (error, stackTrace) {
      // Captura de erros do playerStateStream
      debugPrint('Erro no playerStateStream: $error');
      _showSnackBar('Ocorreu um erro no player: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isPlaying = false;
      });
    });

    // Listener para eventos de playback (outro stream que pode indicar falhas)
    _audioPlayer.playbackEventStream.listen((event) {
      // Normalmente não é preciso usar setState aqui, apenas se desejar exibir informações de buffer etc.
    }, onError: (error, stackTrace) {
      // Captura de erros no playbackEventStream
      debugPrint('Erro no playbackEventStream: $error');
      _showSnackBar('Ocorreu um erro de reprodução: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isPlaying = false;
      });
    });
  }

  Future<void> _startStream() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Exemplo: verificar conectividade antes de iniciar
      // final connectivityResult = await (Connectivity().checkConnectivity());
      // if (connectivityResult == ConnectivityResult.none) {
      //   _showSnackBar('Sem conexão com a internet!');
      //   setState(() => _isLoading = false);
      //   return;
      // }

      await _audioPlayer.setUrl(_streamUrl);
      await _audioPlayer.play();
    } catch (e, st) {
      debugPrint('Erro ao iniciar o streaming: $e\n$st');
      _showSnackBar('Erro ao iniciar o streaming: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isPlaying = false;
      });
    }
  }

  Future<void> _stopStream() async {
    try {
      await _audioPlayer.stop();
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('Erro ao parar o streaming: $e\n$st');
      _showSnackBar('Erro ao parar o streaming: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Theme.of(context).colorScheme.background,
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Programa Eone Cavalcante',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'logo_radio.jpg',
                    height: 140,
                    width: 140,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _isPlaying ? 'Tocando agora' : 'Pausado',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _isPlaying ? _stopStream : _startStream,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isPlaying ? Icons.stop : Icons.play_arrow,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 30,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isPlaying ? 'Parar' : 'Tocar',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Icon(
                      Icons.phone,
                      color: Theme.of(context).colorScheme.primary,
                      size: 30,
                    ),
                    Text(
                      'Participe pelo telefone: (97) 98410-6555',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Icon(
                      Icons.message,
                      color: Colors.green,
                      size: 30,
                    ),
                    Text(
                      'Envie sua mensagem pelo WhatsApp!',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Método prático para exibir SnackBar sem repetição de código
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _audioPlayer.dispose();
    super.dispose();
  }
}
