import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MeuPlayerApp());
}

class MeuPlayerApp extends StatelessWidget {
  const MeuPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XPlayer Interno',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const HomeScreen(),
    );
  }
}

class Canal {
  final String nome;
  final String categoria;
  final String logoUrl;
  final String streamUrl;

  Canal({
    required this.nome,
    required this.categoria,
    required this.logoUrl,
    required this.streamUrl,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController(
    text: 'https://iptv-org.github.io/iptv/index.m3u',
  );
  
  List<Canal> _canais = [];
  bool _carregando = false;
  String _erro = '';

  Future<void> _carregarListaM3U() async {
    setState(() {
      _carregando = true;
      _erro = '';
    });

    try {
      final response = await http.get(Uri.parse(_urlController.text));
      if (response.statusCode == 200) {
        _canais = _parseM3U(response.body);
      } else {
        _erro = 'Erro ao baixar lista: ${response.statusCode}';
      }
    } catch (e) {
      _erro = 'Falha na conexão: $e';
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }

  List<Canal> _parseM3U(String content) {
    List<Canal> lista = [];
    List<String> linhas = content.split('\n');
    String nome = '';
    String categoria = 'Geral';
    String logo = '';

    for (var linha in linhas) {
      linha = linha.trim();
      if (linha.startsWith('#EXTINF:')) {
        if (linha.contains(',')) {
          nome = linha.split(',').last.trim();
        }
        if (linha.contains('tvg-logo="')) {
          try {
            logo = linha.split('tvg-logo="')[1].split('"')[0];
          } catch (_) {}
        }
        if (linha.contains('group-title="')) {
          try {
            categoria = linha.split('group-title="')[1].split('"')[0];
          } catch (_) {}
        }
      } else if (linha.isNotEmpty && !linha.startsWith('#')) {
        lista.add(Canal(
          nome: nome.isEmpty ? 'Canal' : nome,
          categoria: categoria.isEmpty ? 'Geral' : categoria,
          logoUrl: logo,
          streamUrl: linha,
        ));
        nome = '';
        logo = '';
        categoria = 'Geral';
      }
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('XPlayer Interno')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL da Lista M3U',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _carregando ? null : _carregarListaM3U,
              child: _carregando 
                ? const CircularProgressIndicator() 
                : const Text('Carregar Canais'),
            ),
            const SizedBox(height: 10),
            if (_erro.isNotEmpty)
              Text(_erro, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            Expanded(
              child: _canais.isEmpty
                ? const Center(child: Text('Insira a URL e clique em Carregar.'))
                : ListView.builder(
                    itemCount: _canais.length,
                    itemBuilder: (context, index) {
                      final canal = _canais[index];
                      return Card(
                        color: const Color(0xFF1E1E1E),
                        child: ListTile(
                          title: Text(canal.nome),
                          subtitle: Text(canal.categoria, style: const TextStyle(color: Colors.grey)),
                          trailing: const Icon(Icons.play_arrow, color: Colors.blue),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VideoPlayerScreen(canal: canal),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final Canal canal;
  const VideoPlayerScreen({super.key, required this.canal});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _inicializado = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.canal.streamUrl))
      ..initialize().then((_) {
        setState(() {
          _inicializado = true;
          _controller.play();
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(widget.canal.nome), backgroundColor: Colors.transparent),
      body: Center(
        child: _inicializado
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
