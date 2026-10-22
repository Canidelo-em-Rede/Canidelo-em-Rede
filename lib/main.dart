import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Permite guardar fotografias no Firebase Storage.
import 'package:flutter_map/flutter_map.dart'; // Permite criar o mapa com OpenStreetMap.
import 'package:latlong2/latlong.dart'; // Permite trabalhar com coordenadas de latitude e longitude.
import 'mapa_selecao_page.dart'; // Permite abrir o mapa de seleção.

final ValueNotifier<double> escalaTextoAcessibilidade = ValueNotifier<double>(1.0);
final ValueNotifier<bool> altoContrasteAcessibilidade = ValueNotifier<bool>(false); // Controla a ativação do alto contraste.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  
  runApp(const CanideloEmRedeApp()); // Inicia a aplicação com o novo nome.

}


class CanideloEmRedeApp extends StatelessWidget {
  const CanideloEmRedeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: altoContrasteAcessibilidade,
      builder: (context, altoContraste, _) {
        final temaBase = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFC62828),
            brightness: altoContraste ? Brightness.dark : Brightness.light,
          ),
          useMaterial3: true,
          materialTapTargetSize: MaterialTapTargetSize.padded,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 56),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 56),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: OutlineInputBorder(),
          ),
        );

        final tema = altoContraste
            ? temaBase.copyWith(
                scaffoldBackgroundColor: Colors.black,
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.yellow,
                ),
                textTheme: temaBase.textTheme.apply(
                  bodyColor: Colors.white,
                  displayColor: Colors.white,
                ),
                iconTheme: const IconThemeData(color: Colors.yellow),
                dividerColor: Colors.white,
              )
            : temaBase;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Canidelo em Rede',
          theme: tema,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return ValueListenableBuilder<double>(
              valueListenable: escalaTextoAcessibilidade,
              builder: (context, escala, _) {
                final escalaSistema = mediaQuery.textScaler.scale(1.0);
                return MediaQuery(
                  data: mediaQuery.copyWith(
                    textScaler: TextScaler.linear(escalaSistema * escala),
                  ),
                  child: child!,
                );
              },
            );
          },
          home: const HomePage(),
        );
      },
    );
  }
}


class HomePage extends StatelessWidget { // Define a página inicial.
  const HomePage({super.key}); // Cria a página inicial.

  @override
  Widget build(BuildContext context) { // Constrói a interface inicial.
    return Scaffold(
      

appBar: AppBar(
  leading: IconButton(
    tooltip: 'Opções de acessibilidade',
    icon: const Icon(Icons.accessibility_new, size: 28),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => const AcessibilidadePage(),
        ),
      );
    },
  ),
  title: const Text(
    'Canidelo em Rede',
    style: TextStyle(fontWeight: FontWeight.bold),
  ),
  centerTitle: true,
),


      body: Padding(
        padding: const EdgeInsets.all(24), // Define o espaço interior.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Estica os elementos horizontalmente.
          children: [
            const SizedBox(height: 40), // Cria espaço superior.

            const Icon(
              Icons.location_city, // Mostra o ícone da freguesia.
              size: 90, // Define o tamanho do ícone.
              color: Color(0xFFC62828), // Aplica o vermelho da aplicação.
            ),

            const SizedBox(height: 25), // Separa o ícone do título.

            const Text(
              'Bem-vindo ao Canidelo em Rede', // Mostra a mensagem de boas-vindas.
              textAlign: TextAlign.center, // Centra o texto.
              style: TextStyle(
                fontSize: 28, // Define o tamanho do título.
                fontWeight: FontWeight.bold, // Destaca o título.
              ),
            ),

            const SizedBox(height: 15), // Separa o título da descrição.

            const Text(
              'Ajude a melhorar a freguesia de Canidelo comunicando problemas no espaço público.', // Explica o objetivo da aplicação.
              textAlign: TextAlign.center, // Centra a descrição.
              style: TextStyle(
                fontSize: 17, // Define o tamanho do texto.
                color: Colors.grey, // Aplica a cor cinzenta.
              ),
            ),

            const Spacer(), // Ocupa o espaço disponível antes dos botões.

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportPage(), // Abre o formulário de ocorrências.
                  ),
                );
              },
              icon: const Icon(Icons.report_problem), // Mostra o ícone de denúncia.
              label: const Text(
                'Comunicar um problema', // Identifica o botão.
                style: TextStyle(fontSize: 18), // Define o tamanho do texto.
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18), // Define a altura do botão.
              ),
            ),

            const SizedBox(height: 15), // Separa os botões.

            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MapPage(), // Abre o mapa de ocorrências.
                  ),
                );
              },
              icon: const Icon(Icons.map), // Mostra o ícone do mapa.
              label: const Text(
                'Ver mapa de ocorrências', // Identifica o botão.
                style: TextStyle(fontSize: 18), // Define o tamanho do texto.
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18), // Define a altura do botão.
              ),
            ),

            const SizedBox(height: 15), // Separa os botões.

            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminPage(), // Abre a administração.
                  ),
                );
              },
              icon: const Icon(Icons.admin_panel_settings), // Mostra o ícone de administração.
              label: const Text(
                'Administração', // Identifica o botão.
                style: TextStyle(fontSize: 18), // Define o tamanho do texto.
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18), // Define a altura do botão.
              ),
            ),

            const SizedBox(height: 30), // Cria espaço inferior.
          ],
        ),
      ),
    );
  }
}
class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final ImagePicker _picker = ImagePicker();

  Position? _position;
bool _gettingLocation = false;

  File? _image;
  String? _selectedProblem;

  final TextEditingController _descriptionController =
      TextEditingController();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }
  
  Future<void> _chooseLocationOnMap() async { // Abre o mapa e recebe a localização escolhida.
    final LatLng? localizacao = await Navigator.push<LatLng>( // Abre o mapa e espera pela seleção.
      context,
      MaterialPageRoute(
        builder: (context) => const MapaSelecaoPage(), // Cria o ecrã do mapa.
      ),
    );

    if (localizacao == null || !mounted) return; // Não altera nada se o mapa for fechado sem confirmar.

    setState(() {
      _position = Position( // Guarda as coordenadas no formato usado pelo formulário.
        latitude: localizacao.latitude, // Guarda a latitude selecionada.
        longitude: localizacao.longitude, // Guarda a longitude selecionada.
        timestamp: DateTime.now(), // Regista a data e hora da seleção.
        accuracy: 0, // Não representa uma medição GPS, por isso não indica precisão real.
        altitude: 0, // Não foi obtida a altitude.
        altitudeAccuracy: 0, // Não foi calculada a precisão da altitude.
        heading: 0, // Não foi obtida a direção do movimento.
        headingAccuracy: 0, // Não foi calculada a precisão da direção.
        speed: 0, // Não foi obtida a velocidade.
        speedAccuracy: 0, // Não foi calculada a precisão da velocidade.
      );
    });

    ScaffoldMessenger.of(context).showSnackBar( // Mostra uma confirmação ao utilizador.
      const SnackBar(
        content: Text('Localização escolhida no mapa!'),
      ),
    );
  }

  
  Future<void> _getLocation() async {
  setState(() {
    _gettingLocation = true;
  });

  try {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Permissão de localização não concedida.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );

    setState(() {
      _position = position;
      _gettingLocation = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Localização obtida com sucesso!'),
      ),
    );
  } catch (e) {
    setState(() {
      _gettingLocation = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erro ao obter localização: $e'),
      ),
    );
  }
}

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tirar fotografia'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Escolher da galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Comunicar problema',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Que problema encontraste?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: _showPhotoOptions,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _image == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 55,
                            color: Colors.blue,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Adicionar fotografia',
                            style: TextStyle(fontSize: 17),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _image!,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20), // Cria espaço antes dos botões de localização.

            Row( // Coloca os dois botões lado a lado.
              children: [
                Expanded( // Faz o botão GPS ocupar metade do espaço disponível.
                  child: ElevatedButton.icon(
                    onPressed: _gettingLocation ? null : _getLocation, // Mantém a localização por GPS.
                    icon: const Icon(Icons.my_location), // Mostra o ícone do GPS.
                    label: const Text('Usar GPS'), // Identifica a opção GPS.
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18), // Define a altura do botão.
                    ),
                  ),
                ),
                const SizedBox(width: 10), // Cria espaço entre os botões.
                Expanded( // Faz o botão do mapa ocupar a outra metade.
                  child: ElevatedButton.icon(
                    onPressed: _gettingLocation ? null : _chooseLocationOnMap, // Abre o mapa de seleção.
                    icon: const Icon(Icons.map_outlined), // Mostra o ícone do mapa.
                    label: const Text('Escolher no mapa'), // Identifica a escolha manual.
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18), // Define a altura do botão.
                    ),
                  ),
                ),
              ],
            ),

if (_position != null) ...[
  const SizedBox(height: 10),
  Text(
    'Localização: ${_position!.latitude.toStringAsFixed(6)}, '
    '${_position!.longitude.toStringAsFixed(6)}',
    textAlign: TextAlign.center,
  ),
],
            const SizedBox(height: 25),

            const Text(
              'Tipo de problema',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Selecionar problema',
              ),
              initialValue: _selectedProblem, // Define o valor inicial do campo.
              items: const [
                DropdownMenuItem(
                  value: 'Buraco',
                  child: Text('Buraco na estrada'),
                ),
                DropdownMenuItem(
                  value: 'Passeio',
                  child: Text('Passeio danificado'),
                ),
                DropdownMenuItem(
                  value: 'Iluminacao',
                  child: Text('Iluminação'),
                ),
                DropdownMenuItem(
                  value: 'Sinalizacao',
                  child: Text('Sinalização'),
                ),
                DropdownMenuItem(
                  value: 'Lixo',
                  child: Text('Lixo'),
                ),
                DropdownMenuItem(
                  value: 'Outro',
                  child: Text('Outro'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedProblem = value;
                });
              },
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Descreve o problema...',
              ),
            ),

            const SizedBox(height: 25),

            ElevatedButton.icon(
              onPressed: () async { // Permite esperar pelo envio para o Firestore.
  if (_selectedProblem == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Seleciona o tipo de problema.'),
      ),
    );
    return;
  }

  if (_descriptionController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Escreve uma descrição.'),
      ),
    );
    return;
  }

  // Verifica se a localização foi adicionada.
if (_position == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Adiciona a localização.'),
    ),
  );
  return;
}

// Guarda a ocorrência no Firestore.
try {
  await FirebaseFirestore.instance.collection('ocorrencias').add({
    
    'tipo': _selectedProblem,// Guarda o tipo de problema selecionado.

    'descricao': _descriptionController.text.trim(),    // Guarda a descrição escrita pelo utilizador.


   
    'latitude': _position!.latitude, // Guarda a latitude da localização.

    
    'longitude': _position!.longitude,// Guarda a longitude da localização.

    
    'data': FieldValue.serverTimestamp(),// Guarda a data e hora em que a ocorrência foi enviada.
    'estado': 'Pendente', // Define o estado inicial da ocorrência.
  });

  // Mostra uma mensagem quando a ocorrência foi guardada.
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Ocorrência enviada com sucesso!'),
    ),
  );
} catch (e) {
  // Mostra uma mensagem caso aconteça algum erro.
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Erro ao enviar ocorrência: $e'),
    ),
  );
}
},
              icon: const Icon(Icons.send),
              label: const Text(
                'Enviar ocorrência',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class MapPage extends StatefulWidget { // Cria a página do mapa.
  final double? latitudeInicial; // Guarda a latitude inicial opcional.
  final double? longitudeInicial; // Guarda a longitude inicial opcional.

  const MapPage({ // Cria o construtor da página do mapa.
    super.key, // Define a chave da página.
    this.latitudeInicial, // Recebe a latitude inicial.
    this.longitudeInicial, // Recebe a longitude inicial.
  });

  @override
  State<MapPage> createState() => _MapPageState(); // Cria o estado da página.
}

class _MapPageState extends State<MapPage> {
  String _formatarData(DateTime data) { // Formata a data para o formato usado em Portugal.
  final dia = data.day.toString().padLeft(2, '0'); // Obtém o dia com dois algarismos.
  final mes = data.month.toString().padLeft(2, '0'); // Obtém o mês com dois algarismos.
  final hora = data.hour.toString().padLeft(2, '0'); // Obtém a hora com dois algarismos.
  final minuto = data.minute.toString().padLeft(2, '0'); // Obtém os minutos com dois algarismos.

  return '$dia/$mes/${data.year} às $hora:$minuto'; // Devolve a data no formato 07/10/2026 às 16:12.
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de ocorrências'), // Define o título da página.
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('ocorrencias').snapshots(), // Lê as ocorrências do Firebase.
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(), // Mostra o carregamento.
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar ocorrências: ${snapshot.error}'), // Mostra o erro.
            );
          }

          final ocorrencias = snapshot.data?.docs ?? []; // Obtém as ocorrências.

          return FlutterMap(
            
options: MapOptions(
  initialCenter: LatLng(
    widget.latitudeInicial ?? 41.1233, // Centra o mapa em Canidelo, exceto quando é indicada uma ocorrência.
    widget.longitudeInicial ?? -8.6462, // Usa a longitude de referência de Canidelo.
  ),
  initialZoom: widget.latitudeInicial != null ? 17 : 14, // Aproxima para uma ocorrência ou mostra Canidelo.
  interactionOptions: const InteractionOptions(
  flags: InteractiveFlag.all & ~InteractiveFlag.rotate, // Permite mover e fazer zoom, mas impede rodar o mapa.
),
  cameraConstraint: CameraConstraint.contain(
    bounds: LatLngBounds(
      const LatLng(41.1000, -8.6900), // Limite sul e oeste aproximado da área.
      const LatLng(41.1500, -8.6150), // Limite norte e este aproximado da área.
    ),
  ), // Restringe a navegação do mapa ao retângulo definido.
),

            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // Carrega o OpenStreetMap.
                userAgentPackageName: 'com.example.gaia_alerta', // Identifica a aplicação.
              ),
              MarkerLayer(
  markers: ocorrencias.map((doc) { // Cria um marcador para cada ocorrência do Firestore.
    final dados = doc.data(); // Obtém os dados da ocorrência.
    final latitude = dados['latitude']; // Obtém a latitude.
    final longitude = dados['longitude']; // Obtém a longitude.
    final estado = dados['estado'] ?? 'Pendente'; // Obtém o estado da ocorrência.
    Color corMarcador = Colors.orange; // Define laranja como cor padrão para ocorrências pendentes.

if (estado == 'Em análise') {
  corMarcador = Colors.blue; // Define azul para ocorrências em análise.
} else if (estado == 'Resolvida') {
  corMarcador = Colors.green; // Define verde para ocorrências resolvidas.
}

    if (latitude == null || longitude == null) {
      return null; // Ignora ocorrências sem localização.
    }

    return Marker(
  point: LatLng(
    (latitude as num).toDouble(), // Converte a latitude para número decimal.
    (longitude as num).toDouble(), // Converte a longitude para número decimal.
  ),
  width: 50, // Define a largura do marcador.
  height: 50, // Define a altura do marcador.
  child: GestureDetector(
    onTap: () { // Deteta quando o utilizador toca no marcador.
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              dados['tipo'] ?? 'Ocorrência', // Mostra o tipo de problema.
            ),
            content: Column(
  mainAxisSize: MainAxisSize.min, // Faz a janela ocupar apenas o espaço necessário.
  crossAxisAlignment: CrossAxisAlignment.start, // Alinha o texto à esquerda.
  children: [
    Text(
      'Descrição:', // Mostra o título da descrição.
      style: const TextStyle(fontWeight: FontWeight.bold), // Coloca o título a negrito.
    ),
    const SizedBox(height: 5), // Adiciona espaço entre o título e a descrição.
    Text(
      dados['descricao'] ?? 'Sem descrição', // Mostra a descrição da ocorrência.
    ),
    const SizedBox(height: 15), // Adiciona espaço antes da data.
    Text(
      'Data:', // Mostra o título da data.
      style: const TextStyle(fontWeight: FontWeight.bold), // Coloca o título a negrito.
    ),
    const SizedBox(height: 5), // Adiciona espaço entre o título e a data.
    Text(
  dados['data'] != null // Verifica se existe uma data.
      ? _formatarData(dados['data'].toDate()) // Converte a data para o formato português.
      : 'Data indisponível', // Mostra esta mensagem se a data ainda não existir.
),
const SizedBox(height: 15), // Adiciona espaço antes do estado.

Text(
  'Estado:', // Mostra o título do estado.
  style: const TextStyle(fontWeight: FontWeight.bold), // Coloca o título a negrito.
),

const SizedBox(height: 5), // Adiciona espaço entre o título e o estado.

Text(
  dados['estado'] ?? 'Pendente', // Mostra o estado da ocorrência.
),
  ],
),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Fecha a janela.
                },
                child: const Text('Fechar'), // Botão para fechar.
              ),
            ],
          );
        },
      );
    },
    child: Icon(
  Icons.location_on, // Mostra o ícone de localização.
  size: 45, // Define o tamanho do marcador.
  color: corMarcador, // Define a cor conforme o estado da ocorrência.
),
  ),
);
  }).whereType<Marker>().toList(), // Remove os valores nulos e cria a lista final de marcadores.
),
            ],
          );
        },
      ),
    );
  }
}
class AdminPage extends StatelessWidget { // Cria a página de administração.
  const AdminPage({super.key}); // Define o construtor da página.

  @override
  Widget build(BuildContext context) { // Constrói a interface da página.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administração'), // Define o título da página.
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ocorrencias')
            .orderBy('data', descending: true)
            .snapshots(), // Obtém as ocorrências em tempo real.
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(), // Mostra carregamento enquanto procura os dados.
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar ocorrências: ${snapshot.error}', // Mostra o erro caso exista.
              ),
            );
          }

          final ocorrencias = snapshot.data?.docs ?? []; // Obtém a lista de ocorrências.

          if (ocorrencias.isEmpty) {
            return const Center(
              child: Text(
                'Não existem ocorrências.', // Mostra esta mensagem se não houver ocorrências.
                style: TextStyle(fontSize: 18), // Define o tamanho do texto.
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12), // Adiciona espaço à volta da lista.
            itemCount: ocorrencias.length, // Define o número de ocorrências.
            itemBuilder: (context, index) {
              final dados = ocorrencias[index].data() as Map<String, dynamic>; // Obtém os dados da ocorrência.

              final estado = dados['estado'] ?? 'Pendente'; // Obtém o estado atual da ocorrência.
              Color corEstado = Colors.orange; // Define laranja para ocorrências pendentes.

              if (estado == 'Em análise') {
                corEstado = Colors.blue; // Define azul para ocorrências em análise.
              } else if (estado == 'Resolvida') {
                corEstado = Colors.green; // Define verde para ocorrências resolvidas.
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12), // Adiciona espaço entre ocorrências.
                child: Row(
                  children: [
                    Container(
                      width: 6, // Define a largura da barra lateral.
                      height: 90, // Define a altura da barra lateral.
                      color: corEstado, // Define a cor da barra conforme o estado.
                    ),
                    Expanded(
                      child: ListTile(
                        leading: const Icon(
                          Icons.report_problem, // Mostra o ícone de ocorrência.
                          size: 35, // Define o tamanho do ícone.
                        ),
                        title: Text(
                          dados['tipo'] ?? 'Ocorrência', // Mostra o tipo de problema.
                          style: const TextStyle(fontWeight: FontWeight.bold), // Coloca o tipo a negrito.
                        ),
                        subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start, // Alinha o conteúdo à esquerda.
  mainAxisSize: MainAxisSize.min, // Ocupa apenas o espaço necessário.
  children: [
    Text(
      dados['descricao'] ?? 'Sem descrição', // Mostra a descrição da ocorrência.
    ),
    const SizedBox(height: 5), // Adiciona espaço entre a descrição e o estado.
    Text(
      'Estado: $estado', // Mostra o estado atual da ocorrência.
      style: TextStyle(
        color: corEstado, // Usa a mesma cor da barra lateral.
        fontWeight: FontWeight.bold, // Destaca o estado.
      ),
    ),
    const SizedBox(height: 5), // Adiciona espaço entre o estado e a data.
Text(
  dados['data'] != null
      ? 'Data: ${dados['data'].toDate().day.toString().padLeft(2, '0')}/${dados['data'].toDate().month.toString().padLeft(2, '0')}/${dados['data'].toDate().year} às ${dados['data'].toDate().hour.toString().padLeft(2, '0')}:${dados['data'].toDate().minute.toString().padLeft(2, '0')}' // Mostra a data e hora da ocorrência.
      : 'Data: indisponível', // Mostra esta mensagem se a data ainda não existir.
  style: const TextStyle(fontSize: 12), // Define um tamanho mais pequeno para a data.
),
const SizedBox(height: 5), // Adiciona espaço entre a data e a localização.
Text(
  dados['latitude'] != null && dados['longitude'] != null
      ? 'Localização: ${dados['latitude'].toStringAsFixed(5)}, ${dados['longitude'].toStringAsFixed(5)}' // Mostra as coordenadas da ocorrência.
      : 'Localização: indisponível', // Mostra esta mensagem se não existirem coordenadas.
  style: const TextStyle(fontSize: 12), // Define um tamanho mais pequeno para a localização.
),
  ],
),
trailing: Column( // Cria uma coluna com o botão do mapa e o seletor de estado.
  mainAxisAlignment: MainAxisAlignment.center, // Centra os controlos verticalmente.
  children: [
    IconButton(
      onPressed: () { // Abre o mapa na localização da ocorrência.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapPage( // Abre a página do mapa.
              latitudeInicial: (dados['latitude'] as num).toDouble(), // Envia a latitude da ocorrência.
              longitudeInicial: (dados['longitude'] as num).toDouble(), // Envia a longitude da ocorrência.
            ),
          ),
        );
      },
      icon: const Icon(Icons.map), // Mostra o ícone do mapa.
      tooltip: 'Ver no mapa', // Mostra uma descrição do botão.
    ),
    DropdownButton<String>(
      value: estado, // Mostra o estado atual.
      items: const [
        DropdownMenuItem(
          value: 'Pendente',
          child: Text(
            'Pendente',
            style: TextStyle(color: Colors.orange), // Mostra Pendente a laranja.
          ),
        ),
        DropdownMenuItem(
          value: 'Em análise',
          child: Text(
            'Em análise',
            style: TextStyle(color: Colors.blue), // Mostra Em análise a azul.
          ),
        ),
        DropdownMenuItem(
          value: 'Resolvida',
          child: Text(
            'Resolvida',
            style: TextStyle(color: Colors.green), // Mostra Resolvida a verde.
          ),
        ),
      ],
      onChanged: (novoEstado) async {
        if (novoEstado == null) return; // Ignora valores inválidos.

        await FirebaseFirestore.instance
            .collection('ocorrencias')
            .doc(ocorrencias[index].id)
            .update({
          'estado': novoEstado, // Atualiza o estado no Firestore.
        });
      },
    ),
  ],
),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AcessibilidadePage extends StatelessWidget {
  const AcessibilidadePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acessibilidade'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(
            Icons.accessibility_new,
            size: 70,
            color: Color(0xFFC62828),
          ),
          const SizedBox(height: 24),
          
ValueListenableBuilder<bool>( // Atualiza a opção quando o alto contraste muda.
  valueListenable: altoContrasteAcessibilidade, // Lê o estado atual do alto contraste.
  builder: (context, altoContraste, _) { // Recebe o estado atual da opção.
    return SwitchListTile( // Cria um interruptor para ativar e desativar o contraste.
      contentPadding: EdgeInsets.zero, // Remove o espaçamento lateral adicional.
      secondary: const Icon(Icons.contrast), // Mostra o ícone do contraste.
      title: const Text( // Define o título da opção.
        'Alto contraste', // Texto apresentado ao utilizador.
        style: TextStyle(fontWeight: FontWeight.bold), // Destaca o título.
      ),
      subtitle: const Text( // Explica a finalidade da opção.
        'Melhora a diferença entre as cores do texto e do fundo.', // Descrição do alto contraste.
      ),
      value: altoContraste, // Mostra se o interruptor está ligado ou desligado.
      onChanged: (ativo) { // Executa quando o utilizador altera o interruptor.
        altoContrasteAcessibilidade.value = ativo; // Atualiza o tema da aplicação.
      },
    );
  },
),
const SizedBox(height: 16), // Adiciona espaço antes da opção seguinte.

          const Text(
            'Tamanho do texto',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajusta o tamanho do texto para facilitar a leitura em toda a aplicação.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 24),
          ValueListenableBuilder<double>(
            valueListenable: escalaTextoAcessibilidade,
            builder: (context, escala, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tamanho atual: ${(escala * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: escala,
                    min: 0.8,
                    max: 1.5,
                    divisions: 7,
                    label: '${(escala * 100).round()}%',
                    onChanged: (novoValor) {
                      escalaTextoAcessibilidade.value = novoValor;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Exemplo de texto',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Este texto permite experimentar o tamanho antes de escolher.',
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () {
                      escalaTextoAcessibilidade.value = 1.0;
                    },
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Repor tamanho original'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
