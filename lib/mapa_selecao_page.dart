
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// Ecrã onde o utilizador escolhe a localização da ocorrência.
class MapaSelecaoPage extends StatefulWidget {
  const MapaSelecaoPage({super.key});

  @override
  State<MapaSelecaoPage> createState() => _MapaSelecaoPageState();
}

class _MapaSelecaoPageState extends State<MapaSelecaoPage> {
  // Coordenadas aproximadas do centro de Canidelo.
  static const LatLng _centroCanidelo = LatLng(41.1233, -8.6462);

  // Limites retangulares aproximados para manter o mapa na zona de Canidelo.
  // Estes limites ainda não representam a fronteira oficial da freguesia.
  static final LatLngBounds _limitesCanidelo = LatLngBounds(
    const LatLng(41.1000, -8.6900),
    const LatLng(41.1500, -8.6150),
  );

  // Controla a câmara do mapa para centrar a vista nos resultados da pesquisa.
  final MapController _mapController = MapController();

  // Controla o texto escrito na barra de pesquisa.
  final TextEditingController _pesquisaController = TextEditingController();

  // Guarda o ponto escolhido pelo utilizador.
  LatLng? _localizacaoEscolhida;

  // Indica se está a decorrer uma pesquisa.
  bool _aPesquisar = false;

  Timer? _temporizadorPesquisa; // Controla o atraso entre as teclas e a pesquisa.
  List<Map<String, dynamic>> _sugestoes = []; // Guarda as sugestões de moradas encontradas.

  // Guarda uma mensagem de erro ou de ajuda para o utilizador.
  String? _mensagem;

  
    Future<void> _atualizarSugestoes(String texto) async { // Atualiza as sugestões enquanto o utilizador escreve.
    _temporizadorPesquisa?.cancel(); // Cancela a pesquisa anterior que ainda esteja à espera.

    if (texto.trim().length < 3) { // Espera por pelo menos três caracteres.
      setState(() {
        _sugestoes = []; // Limpa as sugestões quando o texto é demasiado curto.
      });
      return;
    }

    _temporizadorPesquisa = Timer(const Duration(milliseconds: 700), () async { // Espera antes de enviar o pedido.
      try {
        final uri = Uri.https('nominatim.openstreetmap.org', '/search', { // Cria o endereço da pesquisa.
          'q': '$texto, Canidelo, Vila Nova de Gaia, Portugal', // Procura na zona de Canidelo.
          'format': 'jsonv2', // Solicita resultados em JSON.
          'limit': '5', // Limita a cinco sugestões.
          'countrycodes': 'pt', // Restringe os resultados a Portugal.
          'viewbox': '-8.6900,41.1500,-8.6150,41.1000', // Define a área aproximada de Canidelo.
          'bounded': '1', // Restringe a pesquisa à área definida.
        });

        final resposta = await http.get(uri, headers: { // Consulta o serviço OpenStreetMap.
          'User-Agent': 'CanideloEmRede/1.0 (app de participacao civica)', // Identifica a aplicação.
        });

        if (resposta.statusCode != 200 || !mounted) return; // Ignora respostas inválidas.

        final resultados = jsonDecode(utf8.decode(resposta.bodyBytes)) as List<dynamic>; // Lê os resultados recebidos.

        if (!mounted) return; // Confirma que o ecrã continua aberto antes de atualizar.

        setState(() {
          _sugestoes = resultados.map((item) => Map<String, dynamic>.from(item as Map)).toList(); // Guarda as sugestões.
        });
      } catch (_) {
        if (!mounted) return; // Evita atualizar um ecrã já fechado.

        setState(() {
          _sugestoes = []; // Limpa sugestões se a pesquisa falhar.
        });
      }
    });
  }

  Future<void> _pesquisarMorada() async { // Procura uma rua ou morada através do serviço Nominatim do OpenStreetMap.
    final pesquisa = _pesquisaController.text.trim();

    // Não envia pesquisas vazias.
    if (pesquisa.isEmpty) {
      setState(() {
        _mensagem = 'Escreve o nome de uma rua ou morada.';
      });
      return;
    }

    setState(() {
      _aPesquisar = true;
      _mensagem = null;
    });

    try {
      // Acrescenta Canidelo e Vila Nova de Gaia para tornar a pesquisa mais específica.
      final consulta = '$pesquisa, Canidelo, Vila Nova de Gaia, Portugal';

      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q': consulta,
          'format': 'jsonv2',
          'limit': '5',
          'countrycodes': 'pt',
          'viewbox': '-8.6900,41.1500,-8.6150,41.1000',
          'bounded': '1',
        },
      );

      // Faz o pedido HTTP ao serviço de pesquisa de moradas.
      final resposta = await http.get(
        uri,
        headers: {
          'User-Agent': 'CanideloEmRede/1.0 (app de participacao civica)',
        },
      );

      if (resposta.statusCode != 200) {
        throw Exception('Não foi possível pesquisar a morada.');
      }

      // Converte a resposta JSON numa lista de resultados.
      final List<dynamic> resultados =
          jsonDecode(utf8.decode(resposta.bodyBytes)) as List<dynamic>;

      if (!mounted) return;

      if (resultados.isEmpty) {
        setState(() {
          _mensagem = 'Não foram encontrados resultados em Canidelo.';
        });
        return;
      }

      // Mostra os resultados para o utilizador escolher a morada correta.
      await showModalBottomSheet<void>(
        context: context,
        builder: (context) {
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                const ListTile(
                  title: Text(
                    'Resultados da pesquisa',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...resultados.map((resultado) {
                  final dados = resultado as Map<String, dynamic>;
                  final latitude = double.tryParse('${dados['lat']}');
                  final longitude = double.tryParse('${dados['lon']}');
                  final nome = '${dados['display_name'] ?? 'Morada encontrada'}';

                  // Ignora resultados sem coordenadas válidas.
                  if (latitude == null || longitude == null) {
                    return const SizedBox.shrink();
                  }

                  // Mostra cada morada como uma opção selecionável.
                  return ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(nome),
                    onTap: () {
                      Navigator.pop(context);

                      final ponto = LatLng(latitude, longitude);

                      // Não aceita resultados fora do retângulo aproximado.
                      if (!_limitesCanidelo.contains(ponto)) {
                        setState(() {
                          _mensagem =
                              'Escolhe uma localização dentro da área de Canidelo.';
                        });
                        return;
                      }

                      setState(() {
                        _localizacaoEscolhida = ponto;
                        _mensagem = 'Localização selecionada.';
                      });

                      // Centra o mapa na morada escolhida.
                      _mapController.move(ponto, 17);
                    },
                  );
                }),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _mensagem = 'Ocorreu um erro na pesquisa. Tenta novamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _aPesquisar = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Liberta os recursos utilizados pelos controladores.
    _mapController.dispose();
    _pesquisaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolher localização'),
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Barra para pesquisar ruas e moradas.
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pesquisaController,
                    onChanged: _atualizarSugestoes, // Atualiza as sugestões enquanto escreves.
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _pesquisarMorada(),
                    decoration: const InputDecoration(
                      hintText: 'Pesquisar rua ou morada em Canidelo',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _aPesquisar ? null : _pesquisarMorada,
                  icon: _aPesquisar
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  tooltip: 'Pesquisar',
                ),
              ],
            ),
          ),

          // Mostra sugestões de ruas e locais enquanto o utilizador escreve.
          if (_sugestoes.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200), // Limita a altura da lista.
              margin: const EdgeInsets.symmetric(horizontal: 12), // Alinha a lista com a pesquisa.
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface, // Usa a cor de fundo do tema.
                border: Border.all(color: Colors.grey.shade300), // Delimita a lista.
                borderRadius: BorderRadius.circular(8), // Arredonda os cantos.
              ),
              child: ListView.builder(
                shrinkWrap: true, // Ajusta a lista ao número de sugestões.
                itemCount: _sugestoes.length, // Define quantas sugestões mostrar.
                itemBuilder: (context, index) {
                  final sugestao = _sugestoes[index]; // Obtém a sugestão atual.
                  final nome = '${sugestao['display_name'] ?? 'Local encontrado'}'; // Obtém o nome da morada.
                  final latitude = double.tryParse('${sugestao['lat']}'); // Lê a latitude.
                  final longitude = double.tryParse('${sugestao['lon']}'); // Lê a longitude.

                  return ListTile(
                    dense: true, // Torna cada opção mais compacta.
                    leading: const Icon(Icons.location_on), // Identifica a morada.
                    title: Text(nome, maxLines: 2, overflow: TextOverflow.ellipsis), // Mostra o nome da sugestão.
                    onTap: () {
                      if (latitude == null || longitude == null) return; // Ignora coordenadas inválidas.
                      final ponto = LatLng(latitude, longitude); // Cria o ponto escolhido.

                      if (!_limitesCanidelo.contains(ponto)) { // Verifica a área aproximada de Canidelo.
                        setState(() {
                          _mensagem = 'Escolhe uma localização dentro da área de Canidelo.'; // Explica o limite.
                          _sugestoes = []; // Fecha as sugestões.
                        });
                        return;
                      }

                      setState(() {
                        _localizacaoEscolhida = ponto; // Guarda a localização selecionada.
                        _mensagem = 'Localização selecionada.'; // Confirma a seleção.
                        _pesquisaController.text = nome; // Coloca a morada escolhida na pesquisa.
                        _sugestoes = []; // Fecha a lista de sugestões.
                      });

                      FocusScope.of(context).unfocus(); // Fecha o teclado.
                      _mapController.move(ponto, 17); // Centra o mapa na morada.
                    },
                  );
                },
              ),
            ),
            
          // Mostra instruções ou mensagens da pesquisa.
          if (_mensagem != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                _mensagem!,
                textAlign: TextAlign.center,
              ),
            ),

          // O mapa ocupa o espaço restante do ecrã.
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _centroCanidelo,
                initialZoom: 14,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate), // Permite mover e aplicar zoom, mas impede rodar o mapa.
                cameraConstraint: CameraConstraint.contain(
                  bounds: _limitesCanidelo,
                ),

                // Tocar no mapa coloca ou move o marcador.
                onTap: (tapPosition, ponto) {
                  if (!_limitesCanidelo.contains(ponto)) {
                    setState(() {
                      _mensagem =
                          'Escolhe uma localização dentro da área de Canidelo.';
                    });
                    return;
                  }

                  setState(() {
                    _localizacaoEscolhida = ponto;
                    _mensagem = 'Localização selecionada.';
                  });
                },
              ),
              children: [
                // Carrega as ruas e o mapa base do OpenStreetMap.
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.gaia_alerta',
                ),

                // Mostra um marcador no ponto escolhido.
                if (_localizacaoEscolhida != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _localizacaoEscolhida!,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.location_pin,
                          color: Color(0xFFC62828),
                          size: 46,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Botão para devolver as coordenadas ao formulário.
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _localizacaoEscolhida == null
                      ? null
                      : () {
                          // Devolve o ponto escolhido ao formulário anterior.
                          Navigator.pop(context, _localizacaoEscolhida);
                        },
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar localização'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC62828),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
