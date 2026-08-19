import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStore.instance.load();
  runApp(const PintaM2App());
}

class UserProfile {
  String userName;
  String companyName;
  String logoBase64;
  Map<String, double> prices;

  UserProfile({
    this.userName = '',
    this.companyName = '',
    this.logoBase64 = '',
    Map<String, double>? prices,
  }) : prices = prices ?? {
          'Pintura interior': 0,
          'Pintura exterior': 0,
          'Pintura rápida': 0,
          'Barniz': 0,
          'Esmalte sintético': 0,
          'Membrana líquida': 0,
        };

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'companyName': companyName,
        'logoBase64': logoBase64,
        'prices': prices,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawPrices = json['prices'];
    final p = <String, double>{};
    if (rawPrices is Map) {
      for (final e in rawPrices.entries) {
        p[e.key.toString()] = (e.value as num?)?.toDouble() ?? 0;
      }
    }
    return UserProfile(
      userName: (json['userName'] ?? '').toString(),
      companyName: (json['companyName'] ?? '').toString(),
      logoBase64: (json['logoBase64'] ?? '').toString(),
      prices: p.isEmpty ? null : p,
    );
  }
}

class ClientData {
  String id;
  String name;
  String address;
  String phone;
  List<String> works;

  ClientData({
    required this.id,
    required this.name,
    this.address = '',
    this.phone = '',
    List<String>? works,
  }) : works = works ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'phone': phone,
        'works': works,
      };

  factory ClientData.fromJson(Map<String, dynamic> json) {
    final legacyAddress = (json['address'] ?? '').toString();
    final rawWorks = json['works'];
    final works = rawWorks is List
        ? rawWorks.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
        : <String>[];
    if (works.isEmpty && legacyAddress.trim().isNotEmpty) works.add(legacyAddress.trim());
    return ClientData(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      address: legacyAddress,
      phone: (json['phone'] ?? '').toString(),
      works: works,
    );
  }
}

class ColorData {
  String id;
  String clientId;
  String sector;
  String name;
  String code;
  String preparation;
  String notes;

  ColorData({
    required this.id,
    required this.clientId,
    this.sector = '',
    required this.name,
    this.code = '',
    this.preparation = '',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'sector': sector,
        'name': name,
        'code': code,
        'preparation': preparation,
        'notes': notes,
      };

  factory ColorData.fromJson(Map<String, dynamic> json) => ColorData(
        id: (json['id'] ?? '').toString(),
        clientId: (json['clientId'] ?? '').toString(),
        sector: (json['sector'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        code: (json['code'] ?? '').toString(),
        preparation: (json['preparation'] ?? '').toString(),
        notes: (json['notes'] ?? '').toString(),
      );
}

class BudgetData {
  String id;
  String number;
  String clientId;
  String clientName;
  String place;
  String workType;
  double area;
  String measurementDetail;
  double sectorPriceTotal;
  List<String> jobs;
  Map<String, String> materials;
  String extraMaterials;
  String notes;
  double total;
  String status;
  String createdAt;
  bool showUser;
  bool showCompany;
  bool showLogo;

  BudgetData({
    required this.id,
    required this.number,
    this.clientId = '',
    this.clientName = '',
    this.place = '',
    this.workType = '',
    this.area = 0,
    this.measurementDetail = '',
    this.sectorPriceTotal = 0,
    List<String>? jobs,
    Map<String, String>? materials,
    this.extraMaterials = '',
    this.notes = '',
    this.total = 0,
    this.status = 'Pendiente',
    required this.createdAt,
    this.showUser = false,
    this.showCompany = true,
    this.showLogo = true,
  })  : jobs = jobs ?? [],
        materials = materials ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'clientId': clientId,
        'clientName': clientName,
        'place': place,
        'workType': workType,
        'area': area,
        'measurementDetail': measurementDetail,
        'sectorPriceTotal': sectorPriceTotal,
        'jobs': jobs,
        'materials': materials,
        'extraMaterials': extraMaterials,
        'notes': notes,
        'total': total,
        'status': status,
        'createdAt': createdAt,
        'showUser': false,
        'showCompany': showCompany,
        'showLogo': showLogo,
      };

  factory BudgetData.fromJson(Map<String, dynamic> json) {
    final mats = <String, String>{};
    final rawMats = json['materials'];
    if (rawMats is Map) {
      for (final e in rawMats.entries) {
        mats[e.key.toString()] = e.value.toString();
      }
    }
    return BudgetData(
      id: (json['id'] ?? '').toString(),
      number: (json['number'] ?? '').toString(),
      clientId: (json['clientId'] ?? '').toString(),
      clientName: (json['clientName'] ?? '').toString(),
      place: (json['place'] ?? '').toString(),
      workType: (json['workType'] ?? '').toString(),
      area: (json['area'] as num?)?.toDouble() ?? 0,
      measurementDetail: (json['measurementDetail'] ?? '').toString(),
      sectorPriceTotal: (json['sectorPriceTotal'] as num?)?.toDouble() ?? 0,
      jobs: (json['jobs'] as List?)?.map((e) => e.toString()).toList() ?? [],
      materials: mats,
      extraMaterials: (json['extraMaterials'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
      total: (json['total'] as num?)?.toDouble() ?? 0,
      status: (json['status'] ?? 'Pendiente').toString(),
      createdAt: (json['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
      showUser: false,
      showCompany: json['showCompany'] ?? true,
      showLogo: json['showLogo'] ?? true,
    );
  }
}

class AppStore extends ChangeNotifier {
  AppStore._();
  static final AppStore instance = AppStore._();

  static const _setupKey = 'pintam2_setup_v07';
  static const _profileKey = 'pintam2_profile_v07';
  static const _clientsKey = 'pintam2_clients_v07';
  static const _colorsKey = 'pintam2_colors_v07';
  static const _budgetsKey = 'pintam2_budgets_v07';

  bool setupDone = false;
  UserProfile profile = UserProfile();
  final List<ClientData> clients = [];
  final List<ColorData> colors = [];
  final List<BudgetData> budgets = [];

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    setupDone = sp.getBool(_setupKey) ?? false;
    try {
      final raw = sp.getString(_profileKey);
      if (raw != null) profile = UserProfile.fromJson(Map<String, dynamic>.from(jsonDecode(raw)));
    } catch (_) {}
    try {
      final raw = sp.getString(_clientsKey);
      if (raw != null) {
        clients
          ..clear()
          ..addAll((jsonDecode(raw) as List).map((e) => ClientData.fromJson(Map<String, dynamic>.from(e))));
      }
    } catch (_) {}
    try {
      final raw = sp.getString(_colorsKey);
      if (raw != null) {
        colors
          ..clear()
          ..addAll((jsonDecode(raw) as List).map((e) => ColorData.fromJson(Map<String, dynamic>.from(e))));
      }
    } catch (_) {}
    try {
      final raw = sp.getString(_budgetsKey);
      if (raw != null) {
        budgets
          ..clear()
          ..addAll((jsonDecode(raw) as List).map((e) => BudgetData.fromJson(Map<String, dynamic>.from(e))));
      }
    } catch (_) {}
  }

  Future<void> save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_setupKey, setupDone);
    await sp.setString(_profileKey, jsonEncode(profile.toJson()));
    await sp.setString(_clientsKey, jsonEncode(clients.map((e) => e.toJson()).toList()));
    await sp.setString(_colorsKey, jsonEncode(colors.map((e) => e.toJson()).toList()));
    await sp.setString(_budgetsKey, jsonEncode(budgets.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  String nextBudgetNumber() {
    final year = DateTime.now().year;
    final n = budgets.length + 1;
    return '$year-${n.toString().padLeft(4, '0')}';
  }

  Future<void> upsertBudget(BudgetData budget) async {
    final i = budgets.indexWhere((b) => b.id == budget.id);
    if (i >= 0) {
      budgets[i] = budget;
    } else {
      budgets.insert(0, budget);
    }
    await save();
  }

  Future<void> deleteBudget(String id) async {
    budgets.removeWhere((b) => b.id == id);
    await save();
  }

  String backupJson() {
    return jsonEncode({
      'version': 8,
      'profile': profile.toJson(),
      'clients': clients.map((e) => e.toJson()).toList(),
      'colors': colors.map((e) => e.toJson()).toList(),
      'budgets': budgets.map((e) => e.toJson()).toList(),
    });
  }

  Future<void> restoreBackup(String raw) async {
    final data = Map<String, dynamic>.from(jsonDecode(raw));
    if (data['profile'] is Map) {
      profile = UserProfile.fromJson(Map<String, dynamic>.from(data['profile']));
    }
    clients
      ..clear()
      ..addAll(((data['clients'] as List?) ?? const [])
          .map((e) => ClientData.fromJson(Map<String, dynamic>.from(e))));
    colors
      ..clear()
      ..addAll(((data['colors'] as List?) ?? const [])
          .map((e) => ColorData.fromJson(Map<String, dynamic>.from(e))));
    budgets
      ..clear()
      ..addAll(((data['budgets'] as List?) ?? const [])
          .map((e) => BudgetData.fromJson(Map<String, dynamic>.from(e))));
    setupDone = true;
    await save();
  }
}

class PintaM2App extends StatefulWidget {
  const PintaM2App({super.key});
  @override
  State<PintaM2App> createState() => _PintaM2AppState();
}

class _PintaM2AppState extends State<PintaM2App> {
  ThemeMode mode = ThemeMode.system;
  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF5BC0EB);
    return MaterialApp(
      title: 'PintaM²',
      debugShowCheckedModeBanner: false,
      themeMode: mode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
        inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
      ),
      home: AnimatedBuilder(
        animation: AppStore.instance,
        builder: (context, _) => AppStore.instance.setupDone
            ? MainShell(onThemeChanged: (m) => setState(() => mode = m))
            : SetupScreen(onDone: () => setState(() {})),
      ),
    );
  }
}

class SetupScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SetupScreen({super.key, required this.onDone});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int step = 0;
  final name = TextEditingController();
  final company = TextEditingController();
  late Map<String, TextEditingController> priceCtrls;

  @override
  void initState() {
    super.initState();
    final p = AppStore.instance.profile;
    name.text = p.userName;
    company.text = p.companyName;
    priceCtrls = {for (final e in p.prices.entries) e.key: TextEditingController(text: e.value == 0 ? '' : e.value.toStringAsFixed(0))};
  }

  Future<void> pickLogo() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 1000);
    if (file != null) {
      AppStore.instance.profile.logoBase64 = base64Encode(await file.readAsBytes());
      setState(() {});
    }
  }

  Future<void> finish() async {
    final s = AppStore.instance;
    s.profile.userName = name.text.trim();
    s.profile.companyName = company.text.trim();
    for (final e in priceCtrls.entries) {
      s.profile.prices[e.key] = double.tryParse(e.value.text.replaceAll(',', '.')) ?? 0;
    }
    s.setupDone = true;
    await s.save();
    widget.onDone();
  }

  void advance() {
    if (step < 3) setState(() => step++);
    else finish();
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['Tu nombre', 'Tu empresa', 'Logo', 'Precios por m²'];
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar PintaM²')),
      body: Column(children: [
        LinearProgressIndicator(value: (step + 1) / 4),
        Expanded(child: ListView(padding: const EdgeInsets.all(20), children: [
          Text(titles[step], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          if (step == 0) TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre del usuario')),
          if (step == 1) TextField(controller: company, decoration: const InputDecoration(labelText: 'Nombre de la empresa')),
          if (step == 2) ...[
            if (AppStore.instance.profile.logoBase64.isNotEmpty)
              Center(child: Image.memory(base64Decode(AppStore.instance.profile.logoBase64), height: 140)),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: pickLogo, icon: const Icon(Icons.image_outlined), label: const Text('Elegir logo de la empresa')),
          ],
          if (step == 3) ...[
            const Text('Estos valores se usan para calcular automáticamente el total según los m².'),
            const SizedBox(height: 12),
            ...priceCtrls.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: e.value,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: e.key, prefixText: '\$ ', suffixText: '/m²'),
                  ),
                )),
            OutlinedButton.icon(onPressed: _addCustomPrice, icon: const Icon(Icons.add), label: const Text('Otro tipo de trabajo')),
          ],
        ])),
        SafeArea(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: TextButton(onPressed: advance, child: const Text('Omitir'))),
            const SizedBox(width: 10),
            Expanded(child: FilledButton(onPressed: advance, child: Text(step == 3 ? 'Terminar' : 'Continuar'))),
          ]),
        )),
      ]),
    );
  }

  void _addCustomPrice() {
    final c = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Otro trabajo'),
      content: TextField(controller: c, decoration: const InputDecoration(labelText: 'Nombre del trabajo')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(onPressed: () {
          final v = c.text.trim();
          if (v.isNotEmpty) setState(() => priceCtrls[v] = TextEditingController());
          Navigator.pop(ctx);
        }, child: const Text('Agregar')),
      ],
    ));
  }
}

class MainShell extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeChanged;
  const MainShell({super.key, required this.onThemeChanged});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  DateTime? lastBack;
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (index != 0) {
          setState(() => index = 0);
          return;
        }
        final now = DateTime.now();
        if (lastBack != null && now.difference(lastBack!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
        } else {
          lastBack = now;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Presioná atrás otra vez para salir de PintaM²')));
        }
      },
      child: Scaffold(
        body: IndexedStack(index: index, children: [
          HomeScreen(onTab: (i) => setState(() => index = i)),
          const ClientsScreen(),
          const BudgetsScreen(),
          MoreScreen(onThemeChanged: widget.onThemeChanged),
        ]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => setState(() => index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
            NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Clientes'),
            NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: 'Presupuestos'),
            NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Más'),
          ],
        ),
      ),
    );
  }
}

class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandAppBar({super.key});
  @override Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) => AppBar(
    title: Row(children: [
      ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset('assets/app_icon.png', width: 34, height: 34)),
      const SizedBox(width: 9),
      Text('PintaM²', style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
    ]),
  );
}

class HomeScreen extends StatelessWidget {
  final ValueChanged<int> onTab;
  const HomeScreen({super.key, required this.onTab});
  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    return AnimatedBuilder(animation: s, builder: (_, __) {
      final pending = s.budgets.where((b) => b.status == 'Pendiente').length;
      return Scaffold(
        appBar: const BrandAppBar(),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text(s.profile.userName.isEmpty ? '¡Buen día! 👋' : '¡Buen día, ${s.profile.userName}! 👋', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetFlow())),
            icon: const Icon(Icons.add), label: const Text('Nuevo presupuesto'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(58)),
          ),
          const SizedBox(height: 14),
          _HomeCard(Icons.people_outline, 'Clientes', '${s.clients.length} registrados', () => onTab(1)),
          _HomeCard(Icons.description_outlined, 'Presupuestos', '$pending pendientes', () => onTab(2)),
          _HomeCard(Icons.palette_outlined, 'Colores / códigos', '${s.colors.length} guardados', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ColorsScreen()))),
          _HomeCard(Icons.calculate_outlined, 'Calculadora', 'Medir por sectores y paredes', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdvancedCalculatorScreen()))),
          _HomeCard(Icons.history_outlined, 'Historial', 'Estados y ganancias por mes', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()))),
        ]),
      );
    });
  }
}

class _HomeCard extends StatelessWidget {
  final IconData icon; final String title, subtitle; final VoidCallback tap;
  const _HomeCard(this.icon, this.title, this.subtitle, this.tap);
  @override
  Widget build(BuildContext context) => Card(child: ListTile(
    onTap: tap, leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right),
  ));
}

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});
  @override
  State<ClientsScreen> createState() => _ClientsScreenState();

  static void editClient(BuildContext context, {ClientData? client}) {
    _ClientsScreenState.showClientEditor(context, client: client);
  }
}

class _ClientsScreenState extends State<ClientsScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    return AnimatedBuilder(animation: s, builder: (_, __) {
      final q = query.trim().toLowerCase();
      final visible = s.clients.where((c) {
        if (q.isEmpty) return true;
        return c.name.toLowerCase().contains(q) ||
            c.phone.toLowerCase().contains(q) ||
            c.works.any((w) => w.toLowerCase().contains(q));
      }).toList();

      return Scaffold(
        appBar: const BrandAppBar(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showClientEditor(context),
          icon: const Icon(Icons.person_add),
          label: const Text('Nuevo cliente'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: const InputDecoration(
                hintText: 'Buscar cliente...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 14),
            if (visible.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(22),
                  child: Center(child: Text('No hay clientes para mostrar.')),
                ),
              ),
            ...visible.map((c) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(c.name.isEmpty ? '?' : c.name[0].toUpperCase()),
                    ),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      c.works.isEmpty
                          ? (c.phone.isEmpty ? 'Sin trabajos guardados' : c.phone)
                          : '${c.works.length} trabajo${c.works.length == 1 ? '' : 's'} · ${c.works.take(2).join(' / ')}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ClientDetailScreen(clientId: c.id)),
                    ),
                  ),
                )),
          ],
        ),
      );
    });
  }

  static void showClientEditor(BuildContext context, {ClientData? client}) {
    final n = TextEditingController(text: client?.name ?? '');
    final p = TextEditingController(text: client?.phone ?? '');
    final firstWork = TextEditingController(
      text: client == null ? '' : (client.works.isNotEmpty ? client.works.first : client.address),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20, 10, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            client == null ? 'Nuevo cliente' : 'Editar cliente',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          TextField(controller: n, decoration: const InputDecoration(labelText: 'Nombre')),
          const SizedBox(height: 10),
          TextField(controller: p, decoration: const InputDecoration(labelText: 'Teléfono')),
          const SizedBox(height: 10),
          TextField(
            controller: firstWork,
            decoration: const InputDecoration(
              labelText: 'Primer trabajo / lugar',
              hintText: 'Ej.: Casa, oficinas, local...',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              if (n.text.trim().isEmpty) return;
              final s = AppStore.instance;
              if (client == null) {
                final work = firstWork.text.trim();
                s.clients.add(ClientData(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  name: n.text.trim(),
                  phone: p.text.trim(),
                  address: work,
                  works: work.isEmpty ? [] : [work],
                ));
              } else {
                client.name = n.text.trim();
                client.phone = p.text.trim();
                final work = firstWork.text.trim();
                if (client.works.isEmpty && work.isNotEmpty) {
                  client.works.add(work);
                } else if (client.works.isNotEmpty && work.isNotEmpty) {
                  client.works[0] = work;
                }
                client.address = client.works.isEmpty ? '' : client.works.first;
              }
              await s.save();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ]),
      ),
    );
  }
}

class ClientDetailScreen extends StatelessWidget {
  final String clientId;
  const ClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    return AnimatedBuilder(animation: s, builder: (_, __) {
      final c = s.clients.where((x) => x.id == clientId).cast<ClientData?>().firstOrNull;
      if (c == null) {
        return Scaffold(appBar: AppBar(), body: const Center(child: Text('Cliente eliminado')));
      }
      final colors = s.colors.where((x) => x.clientId == c.id).toList();

      return Scaffold(
        appBar: AppBar(
          title: Text(c.name),
          actions: [
            IconButton(
              onPressed: () => ClientsScreen.editClient(context, client: c),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: () => _deleteClient(context, c),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _addWork(context, c),
          icon: const Icon(Icons.add_home_work_outlined),
          label: const Text('Agregar trabajo'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            if (c.phone.isNotEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: Text(c.phone),
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'Trabajos / lugares',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (c.works.isEmpty)
              const Text('Todavía no hay trabajos o lugares guardados.'),
            ...c.works.asMap().entries.map((e) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.home_work_outlined),
                    title: Text(e.value),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'delete') {
                          c.works.removeAt(e.key);
                          c.address = c.works.isEmpty ? '' : c.works.first;
                          await s.save();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 16),
            Row(children: [
              const Expanded(
                child: Text(
                  'Colores y preparaciones',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: () => editColor(context, clientId: c.id),
                icon: const Icon(Icons.add),
                tooltip: 'Agregar color',
              ),
            ]),
            const SizedBox(height: 8),
            if (colors.isEmpty)
              const Text('Todavía no guardaste colores para este cliente.'),
            ...colors.map((color) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.color_lens_outlined),
                    title: Text(
                      color.name.isEmpty ? color.code : color.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text([
                      if (color.sector.isNotEmpty) 'Sector: ${color.sector}',
                      if (color.code.isNotEmpty) 'Código: ${color.code}',
                      if (color.preparation.isNotEmpty) color.preparation,
                    ].join('\n')),
                    onTap: () => editColor(context, clientId: c.id, color: color),
                  ),
                )),
          ],
        ),
      );
    });
  }

  Future<void> _addWork(BuildContext context, ClientData c) async {
    final ctrl = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar trabajo / lugar'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Ej.: Casa, oficinas, quincho...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
    if (value != null && value.isNotEmpty) {
      c.works.add(value);
      c.address = c.works.first;
      await AppStore.instance.save();
    }
  }

  Future<void> _deleteClient(BuildContext context, ClientData c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: Text('¿Eliminar a ${c.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) {
      final s = AppStore.instance;
      s.clients.removeWhere((x) => x.id == c.id);
      s.colors.removeWhere((x) => x.clientId == c.id);
      await s.save();
      if (context.mounted) Navigator.pop(context);
    }
  }
}

void editColor(BuildContext context, {required String clientId, ColorData? color}) {
  final sector = TextEditingController(text: color?.sector ?? '');
  final n = TextEditingController(text: color?.name ?? '');
  final codeCtrl = TextEditingController(text: color?.code ?? '');
  final prep = TextEditingController(text: color?.preparation ?? '');
  final notes = TextEditingController(text: color?.notes ?? '');

  final client = AppStore.instance.clients.where((c) => c.id == clientId).cast<ClientData?>().firstOrNull;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        20, 10, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            color == null ? 'Nuevo color' : 'Editar color',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          if (client != null) ...[
            const SizedBox(height: 4),
            Text(client.name, style: TextStyle(color: Theme.of(ctx).colorScheme.primary)),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: sector,
            decoration: const InputDecoration(
              labelText: 'Sector',
              hintText: 'Ej.: Living, oficina, dormitorio...',
            ),
          ),
          const SizedBox(height: 10),
          TextField(controller: n, decoration: const InputDecoration(labelText: 'Nombre del color')),
          const SizedBox(height: 10),
          TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Código del color')),
          const SizedBox(height: 10),
          TextField(
            controller: prep,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Preparación / fórmula',
              hintText: 'Ej.: Base blanca 4 L + 35 ml negro + 10 ml ocre',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: notes,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Observaciones'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              if (n.text.trim().isEmpty && codeCtrl.text.trim().isEmpty) return;
              final s = AppStore.instance;
              if (color == null) {
                s.colors.add(ColorData(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  clientId: clientId,
                  sector: sector.text.trim(),
                  name: n.text.trim(),
                  code: codeCtrl.text.trim(),
                  preparation: prep.text.trim(),
                  notes: notes.text.trim(),
                ));
              } else {
                color.sector = sector.text.trim();
                color.name = n.text.trim();
                color.code = codeCtrl.text.trim();
                color.preparation = prep.text.trim();
                color.notes = notes.text.trim();
              }
              await s.save();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar color'),
          ),
          if (color != null)
            TextButton.icon(
              onPressed: () async {
                AppStore.instance.colors.removeWhere((x) => x.id == color.id);
                await AppStore.instance.save();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar color'),
            ),
        ]),
      ),
    ),
  );
}

class ColorsScreen extends StatefulWidget {
  const ColorsScreen({super.key});
  @override
  State<ColorsScreen> createState() => _ColorsScreenState();
}

class _ColorsScreenState extends State<ColorsScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    return AnimatedBuilder(animation: s, builder: (_, __) {
      final q = query.trim().toLowerCase();
      final clients = s.clients.where((c) {
        if (q.isEmpty) return true;
        return c.name.toLowerCase().contains(q);
      }).toList();

      return Scaffold(
        appBar: AppBar(title: const Text('Colores / códigos')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: const InputDecoration(
                hintText: 'Buscar cliente...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 14),
            if (clients.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(22),
                  child: Center(child: Text('No se encontraron clientes.')),
                ),
              ),
            ...clients.map((c) {
              final count = s.colors.where((x) => x.clientId == c.id).length;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('$count código${count == 1 ? '' : 's'} de color'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ClientColorCodesScreen(clientId: c.id)),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}

class ClientColorCodesScreen extends StatelessWidget {
  final String clientId;
  const ClientColorCodesScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    return AnimatedBuilder(animation: s, builder: (_, __) {
      final client = s.clients.where((c) => c.id == clientId).cast<ClientData?>().firstOrNull;
      final colors = s.colors.where((x) => x.clientId == clientId).toList();
      final sectors = <String, List<ColorData>>{};
      for (final color in colors) {
        final key = color.sector.trim().isEmpty ? 'Sin sector' : color.sector.trim();
        sectors.putIfAbsent(key, () => []).add(color);
      }

      return Scaffold(
        appBar: AppBar(title: Text(client?.name ?? 'Colores')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => editColor(context, clientId: clientId),
          icon: const Icon(Icons.add),
          label: const Text('Agregar color'),
        ),
        body: colors.isEmpty
            ? const Center(child: Text('Todavía no hay códigos guardados para este cliente.'))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: sectors.entries.map((entry) => Card(
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w800)),
                    children: entry.value.map((color) => ListTile(
                      leading: const Icon(Icons.palette_outlined),
                      title: Text(color.name.isEmpty ? color.code : color.name),
                      subtitle: Text([
                        if (color.code.isNotEmpty) 'Código: ${color.code}',
                        if (color.preparation.isNotEmpty) color.preparation,
                      ].join('\n')),
                      onTap: () => editColor(context, clientId: clientId, color: color),
                    )).toList(),
                  ),
                )).toList(),
              ),
      );
    });
  }
}

class MeasurementLine {
  String label;
  double area;
  MeasurementLine(this.label, this.area);
}

class MeasurementSector {
  String name;
  final List<MeasurementLine> lines = [];
  double price;
  MeasurementSector(this.name, {this.price = 0});
  double get total => lines.fold(0, (a, b) => a + b.area);
}

class MeasurementResult {
  final double total;
  final String detail;
  final double sectorPriceTotal;
  const MeasurementResult(this.total, this.detail, this.sectorPriceTotal);
}

class AdvancedCalculatorScreen extends StatefulWidget {
  final bool returnResult;
  const AdvancedCalculatorScreen({super.key, this.returnResult = false});
  @override
  State<AdvancedCalculatorScreen> createState() => _AdvancedCalculatorScreenState();
}

class _AdvancedCalculatorScreenState extends State<AdvancedCalculatorScreen> {
  final List<MeasurementSector> sectors = [];

  double get total => sectors.fold(0, (a, b) => a + b.total);
  double get sectorPriceTotal => sectors.fold(0, (a, b) => a + b.price);

  String get detail => sectors.map((s) {
        final priceText = s.price > 0 ? '\n  Precio sector: \$${s.price.toStringAsFixed(0)}' : '';
        return '${s.name}: ${s.total.toStringAsFixed(2)} m²$priceText\n'
            '${s.lines.map((l) => '  ${l.label}: ${l.area.toStringAsFixed(2)} m²').join('\n')}';
      }).join('\n\n');

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Calculadora por sectores')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: addSector,
          icon: const Icon(Icons.add_home_work_outlined),
          label: const Text('Agregar sector'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          children: [
            const Text(
              'Medí pared por pared',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Separá living, cocina, dormitorios, baño u otros sectores. '
              'También podés cargar m² directamente y, si querés, asignar un precio a cada sector.',
            ),
            const SizedBox(height: 14),
            if (sectors.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Empezá agregando un sector de la casa.'),
                ),
              ),
            ...sectors.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(
                            s.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          '${s.total.toStringAsFixed(2)} m²',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        IconButton(
                          tooltip: 'Eliminar sector',
                          onPressed: () => setState(() => sectors.removeAt(i)),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ]),
                      if (s.price > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'Precio del sector: \$${s.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ...s.lines.asMap().entries.map((line) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(line.value.label),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${line.value.area.toStringAsFixed(2)} m²'),
                                IconButton(
                                  onPressed: () => setState(() => s.lines.removeAt(line.key)),
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          )),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => addWall(s),
                            icon: const Icon(Icons.square_foot),
                            label: const Text('Pared'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => addDirect(s),
                            icon: const Icon(Icons.add),
                            label: const Text('m² directo'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => setSectorPrice(s),
                            icon: const Icon(Icons.attach_money),
                            label: Text(s.price > 0 ? 'Editar precio' : 'Precio sector'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (sectors.isNotEmpty) ...[
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(children: [
                    const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w800)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SelectableText(
                          '${total.toStringAsFixed(2)} m²',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                        ),
                        IconButton(
                          tooltip: 'Copiar m²',
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: total.toStringAsFixed(2)),
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('m² copiados')),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy_outlined, size: 20),
                        ),
                      ],
                    ),
                    if (sectorPriceTotal > 0) ...[
                      const Divider(height: 24),
                      const Text('TOTAL POR SECTORES'),
                      Text(
                        '\$${sectorPriceTotal.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ]),
                ),
              ),
              if (widget.returnResult)
                FilledButton.icon(
                  onPressed: () => Navigator.pop(
                    context,
                    MeasurementResult(total, detail, sectorPriceTotal),
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Usar estos datos'),
                ),
            ],
          ],
        ),
      );

  Future<void> addSector() async {
    final c = TextEditingController();
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar sector'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Ej.: Living, cocina, dormitorio...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
    if (v != null && v.isNotEmpty) setState(() => sectors.add(MeasurementSector(v)));
  }

  Future<void> addWall(MeasurementSector s) async {
    final label = TextEditingController(text: 'Pared ${s.lines.length + 1}');
    final l = TextEditingController();
    final h = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.name),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: label, decoration: const InputDecoration(labelText: 'Nombre')),
          const SizedBox(height: 8),
          TextField(
            controller: l,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Largo (m)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: h,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Alto (m)'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Agregar')),
        ],
      ),
    );
    if (ok == true) {
      final area = (double.tryParse(l.text.replaceAll(',', '.')) ?? 0) *
          (double.tryParse(h.text.replaceAll(',', '.')) ?? 0);
      if (area > 0) {
        setState(() => s.lines.add(
              MeasurementLine(label.text.trim().isEmpty ? 'Pared' : label.text.trim(), area),
            ));
      }
    }
  }

  Future<void> addDirect(MeasurementSector s) async {
    final label = TextEditingController(text: 'Superficie');
    final a = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.name),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: label, decoration: const InputDecoration(labelText: 'Nombre')),
          const SizedBox(height: 8),
          TextField(
            controller: a,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'm²'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Agregar')),
        ],
      ),
    );
    if (ok == true) {
      final area = double.tryParse(a.text.replaceAll(',', '.')) ?? 0;
      if (area > 0) {
        setState(() => s.lines.add(
              MeasurementLine(label.text.trim().isEmpty ? 'Superficie' : label.text.trim(), area),
            ));
      }
    }
  }

  Future<void> setSectorPrice(MeasurementSector s) async {
    final ctrl = TextEditingController(text: s.price == 0 ? '' : s.price.toStringAsFixed(0));
    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Precio · ${s.name}'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Precio del sector', prefixText: '\$ '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(
              ctx,
              double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (value != null) setState(() => s.price = value);
  }
}

class BudgetFlow extends StatefulWidget {
  final BudgetData? existing;
  const BudgetFlow({super.key, this.existing});
  @override
  State<BudgetFlow> createState() => _BudgetFlowState();
}

class _BudgetFlowState extends State<BudgetFlow> {
  int step = 0;
  String type = '';
  String clientId = '';
  bool saveNewClient = false;
  bool showCompany = true;
  bool showLogo = true;
  double sectorPriceTotal = 0;

  final otherType = TextEditingController();
  final clientName = TextEditingController();
  final place = TextEditingController();
  final area = TextEditingController();
  final measurementDetail = TextEditingController();
  final manualJobs = TextEditingController();
  final extraMaterials = TextEditingController();
  final notes = TextEditingController();
  final total = TextEditingController();

  final Map<String, bool> selectedJobs = {
    'Protección de pisos y muebles': false,
    'Tapado de pequeñas imperfecciones': false,
    'Lijado donde sea necesario': false,
    'Aplicación de 2 manos de pintura': false,
    'Limpieza final': false,
  };

  final Map<String, bool> phraseEnabled = {
    'Este presupuesto es válido por 15 días a partir de la fecha.': true,
    'Todo trabajo extra fuera del presupuesto se cobrará aparte.': true,
    'Los materiales serán provistos por el cliente, salvo aclaración.': false,
  };

  late final Map<String, TextEditingController> phraseCtrls;
  late final Map<String, TextEditingController> materialCtrls;

  final materialUnits = const {
    'Látex interior': 'L',
    'Látex exterior': 'L',
    'Enduido interior': 'kg',
    'Enduido exterior': 'kg',
    'Cinta de papel': 'rollos',
  };

  @override
  void initState() {
    super.initState();
    phraseCtrls = {
      for (final k in phraseEnabled.keys) k: TextEditingController(text: k),
    };
    materialCtrls = {
      for (final k in materialUnits.keys) k: TextEditingController(),
    };

    final b = widget.existing;
    if (b != null) {
      if (AppStore.instance.profile.prices.containsKey(b.workType)) {
        type = b.workType;
      } else {
        type = b.workType.isEmpty ? '' : 'Otro';
        otherType.text = b.workType;
      }
      clientId = b.clientId;
      clientName.text = b.clientName;
      place.text = b.place;
      area.text = b.area == 0 ? '' : b.area.toStringAsFixed(2);
      measurementDetail.text = b.measurementDetail;
      sectorPriceTotal = b.sectorPriceTotal;
      for (final k in selectedJobs.keys) {
        selectedJobs[k] = b.jobs.contains(k);
      }
      manualJobs.text = b.jobs.where((j) => !selectedJobs.containsKey(j)).join('\n');
      for (final e in b.materials.entries) {
        if (materialCtrls.containsKey(e.key)) materialCtrls[e.key]!.text = e.value;
      }
      extraMaterials.text = b.extraMaterials;
      notes.text = b.notes;
      total.text = b.total == 0 ? '' : b.total.toStringAsFixed(0);
      showCompany = b.showCompany;
      showLogo = b.showLogo;
      phraseEnabled.updateAll((key, value) => false);
    }
  }

  String get workType => type == 'Otro' ? otherType.text.trim() : type;
  double get areaValue => double.tryParse(area.text.replaceAll(',', '.')) ?? 0;
  double get pricePerM2 => AppStore.instance.profile.prices[workType] ?? 0;
  double get suggestedTotal {
    if (sectorPriceTotal > 0) return sectorPriceTotal;
    if (areaValue > 0 && pricePerM2 > 0) return areaValue * pricePerM2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    const titles = [
      'Trabajo',
      'Cliente',
      'Obra',
      'Medidas',
      'Trabajos',
      'Materiales',
      'Identidad',
      'Resumen',
    ];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(onPressed: back, icon: const Icon(Icons.arrow_back)),
          title: Text(
            '${widget.existing == null ? 'Nuevo' : 'Editar'} presupuesto · ${step + 1}/${titles.length}',
          ),
        ),
        body: Column(children: [
          LinearProgressIndicator(value: (step + 1) / titles.length),
          Expanded(child: body()),
          if (step < titles.length - 1)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => next(skip: true),
                      child: const Text('Omitir'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => next(),
                      child: const Text('Continuar'),
                    ),
                  ),
                ]),
              ),
            ),
        ]),
      ),
    );
  }

  Future<void> next({bool skip = false}) async {
    if (step == 1 && !skip && saveNewClient && clientName.text.trim().isNotEmpty) {
      final s = AppStore.instance;
      final existingClient = s.clients
          .where((c) => c.name.trim().toLowerCase() == clientName.text.trim().toLowerCase())
          .cast<ClientData?>()
          .firstOrNull;
      if (existingClient != null) {
        clientId = existingClient.id;
      } else {
        final newClient = ClientData(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: clientName.text.trim(),
        );
        s.clients.add(newClient);
        clientId = newClient.id;
        await s.save();
      }
    }
    if (step < 7) setState(() => step++);
  }

  void back() {
    if (step > 0) {
      setState(() => step--);
    } else {
      Navigator.pop(context);
    }
  }

  Widget body() {
    switch (step) {
      case 0:
        final types = [...AppStore.instance.profile.prices.keys, 'Otro'];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Tipo de trabajo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ...types.map((t) => RadioListTile<String>(
                  value: t,
                  groupValue: type,
                  title: Text(t),
                  subtitle: t != 'Otro' && (AppStore.instance.profile.prices[t] ?? 0) > 0
                      ? Text('\$${AppStore.instance.profile.prices[t]!.toStringAsFixed(0)} /m²')
                      : null,
                  onChanged: (v) => setState(() => type = v ?? ''),
                )),
            if (type == 'Otro')
              TextField(
                controller: otherType,
                decoration: const InputDecoration(labelText: 'Nombre del trabajo'),
              ),
          ],
        );

      case 1:
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Cliente', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(
              controller: clientName,
              decoration: const InputDecoration(labelText: 'Nombre del cliente'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: saveNewClient,
              onChanged: (v) => setState(() => saveNewClient = v ?? false),
              title: const Text('Guardar este cliente'),
              subtitle: const Text('Quedará disponible para futuros presupuestos.'),
            ),
            if (AppStore.instance.clients.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Clientes guardados', style: TextStyle(fontWeight: FontWeight.w700)),
              ...AppStore.instance.clients.map((c) => ListTile(
                    title: Text(c.name),
                    subtitle: c.works.isEmpty ? null : Text(c.works.join(' / ')),
                    onTap: () => setState(() {
                      clientId = c.id;
                      clientName.text = c.name;
                      saveNewClient = false;
                    }),
                  )),
            ],
          ],
        );

      case 2:
        final selectedClient = AppStore.instance.clients
            .where((c) => c.id == clientId)
            .cast<ClientData?>()
            .firstOrNull;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Obra / lugar', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(
              controller: place,
              decoration: const InputDecoration(
                labelText: 'Ej.: Casa, quincho, departamento, local...',
              ),
            ),
            if (selectedClient != null && selectedClient.works.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Trabajos guardados del cliente', style: TextStyle(fontWeight: FontWeight.w700)),
              ...selectedClient.works.map((w) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.home_work_outlined),
                      title: Text(w),
                      onTap: () => setState(() => place.text = w),
                    ),
                  )),
            ],
          ],
        );

      case 3:
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Medidas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            TextField(
              controller: area,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'm² totales', suffixText: 'm²'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: measurementDetail,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Detalle por sectores'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                final r = await Navigator.push<MeasurementResult>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdvancedCalculatorScreen(returnResult: true),
                  ),
                );
                if (r != null) {
                  setState(() {
                    area.text = r.total.toStringAsFixed(2);
                    measurementDetail.text = r.detail;
                    sectorPriceTotal = r.sectorPriceTotal;
                    if (r.sectorPriceTotal > 0) {
                      total.text = r.sectorPriceTotal.toStringAsFixed(0);
                    }
                  });
                }
              },
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Calcular pared por pared'),
            ),
            if (suggestedTotal > 0)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(children: [
                      Text(
                        sectorPriceTotal > 0 ? 'Total por sectores' : 'Precio sugerido',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '\$${suggestedTotal.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      if (sectorPriceTotal == 0)
                        Text(
                          '${areaValue.toStringAsFixed(2)} m² × \$${pricePerM2.toStringAsFixed(0)}/m²',
                        ),
                    ]),
                  ),
                ),
              ),
          ],
        );

      case 4:
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Trabajos a realizar', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            TextField(
              controller: manualJobs,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Trabajo manual'),
            ),
            const SizedBox(height: 10),
            ...selectedJobs.keys.map((k) => CheckboxListTile(
                  value: selectedJobs[k],
                  title: Text(k),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (v) => setState(() => selectedJobs[k] = v ?? false),
                )),
          ],
        );

      case 5:
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Materiales aproximados', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Completá solamente lo que necesites.'),
            const SizedBox(height: 12),
            ...materialCtrls.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: e.value,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: e.key,
                      suffixText: materialUnits[e.key],
                    ),
                  ),
                )),
            TextField(
              controller: extraMaterials,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Otros materiales'),
            ),
          ],
        );

      case 6:
        final p = AppStore.instance.profile;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Datos que aparecerán',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: showCompany,
              onChanged: (v) => setState(() => showCompany = v),
              title: const Text('Nombre de la empresa'),
              subtitle: Text(p.companyName.isEmpty ? 'Sin completar' : p.companyName),
            ),
            SwitchListTile(
              value: showLogo,
              onChanged: (v) => setState(() => showLogo = v),
              title: const Text('Logo de la empresa'),
              subtitle: Text(p.logoBase64.isEmpty ? 'Sin logo cargado' : 'Logo cargado'),
            ),
          ],
        );

      default:
        if (total.text.isEmpty && suggestedTotal > 0) {
          total.text = suggestedTotal.toStringAsFixed(0);
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Resumen', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  summary('Cliente', clientName.text),
                  summary('Obra', place.text),
                  summary('Trabajo', workType),
                  summary('m²', areaValue == 0 ? '' : areaValue.toStringAsFixed(2)),
                  summary(
                    sectorPriceTotal > 0 ? 'Precio sectores' : 'Precio/m²',
                    sectorPriceTotal > 0
                        ? '\$${sectorPriceTotal.toStringAsFixed(0)}'
                        : (pricePerM2 == 0 ? '' : '\$${pricePerM2.toStringAsFixed(0)}'),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: total,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Total del presupuesto',
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Frases / aclaraciones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text('Marcá las que querés incluir. También podés editar el texto.'),
            const SizedBox(height: 8),
            ...phraseEnabled.keys.map((key) => Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 12, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: phraseEnabled[key],
                          onChanged: (v) => setState(() => phraseEnabled[key] = v ?? false),
                        ),
                        Expanded(
                          child: TextField(
                            controller: phraseCtrls[key],
                            minLines: 1,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Texto',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 8),
            TextField(
              controller: notes,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Otra aclaración'),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: saveAndPreview,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Finalizar presupuesto'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
            ),
          ],
        );
    }
  }

  Widget summary(String a, String b) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(child: Text(a)),
          Expanded(
            child: Text(
              b,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ]),
      );

  Future<void> saveAndPreview() async {
    final s = AppStore.instance;
    if (clientId.isEmpty && clientName.text.trim().isNotEmpty) {
      final existingClient = s.clients
          .where((c) => c.name.toLowerCase() == clientName.text.trim().toLowerCase())
          .cast<ClientData?>()
          .firstOrNull;
      if (existingClient != null) clientId = existingClient.id;
    }

    final jobs = <String>[
      if (manualJobs.text.trim().isNotEmpty) manualJobs.text.trim(),
      ...selectedJobs.entries.where((e) => e.value).map((e) => e.key),
    ];
    final mats = <String, String>{
      for (final e in materialCtrls.entries)
        if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
    };
    final phraseText = phraseEnabled.entries
        .where((e) => e.value)
        .map((e) => phraseCtrls[e.key]!.text.trim())
        .where((e) => e.isNotEmpty)
        .join('\n');
    final allNotes = [
      if (phraseText.isNotEmpty) phraseText,
      if (notes.text.trim().isNotEmpty) notes.text.trim(),
    ].join('\n');

    final old = widget.existing;
    final b = BudgetData(
      id: old?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      number: old?.number ?? s.nextBudgetNumber(),
      clientId: clientId,
      clientName: clientName.text.trim(),
      place: place.text.trim(),
      workType: workType,
      area: areaValue,
      measurementDetail: measurementDetail.text.trim(),
      sectorPriceTotal: sectorPriceTotal,
      jobs: jobs,
      materials: mats,
      extraMaterials: extraMaterials.text.trim(),
      notes: allNotes,
      total: double.tryParse(total.text.replaceAll(',', '.')) ?? 0,
      status: old?.status ?? 'Pendiente',
      createdAt: old?.createdAt ?? DateTime.now().toIso8601String(),
      showUser: false,
      showCompany: showCompany,
      showLogo: showLogo,
    );
    await s.upsertBudget(b);

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BudgetPreviewScreen(budgetId: b.id)),
    );
    if (mounted && widget.existing != null) Navigator.pop(context);
  }
}

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    return AnimatedBuilder(animation: s, builder: (_, __) => Scaffold(
      appBar: const BrandAppBar(),
      body: s.budgets.isEmpty
          ? const Center(child: Text('Todavía no hay presupuestos.'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: s.budgets.map((b) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(
                        '${b.number} · ${b.clientName.isEmpty ? 'Sin cliente' : b.clientName}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text('${b.place}\n${b.status}'),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _statusIcon(b.status),
                          const SizedBox(height: 3),
                          Text(
                            '\$${b.total.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      onTap: () => budgetActions(context, b),
                    ),
                  )).toList(),
            ),
    ));
  }

  static Widget _statusIcon(String status) {
    if (status == 'Aceptado') {
      return const Icon(Icons.check_circle, color: Colors.green, size: 22);
    }
    if (status == 'Rechazado') {
      return const Icon(Icons.cancel, color: Colors.red, size: 22);
    }
    return const Icon(Icons.schedule, color: Colors.orange, size: 22);
  }
}

void budgetActions(BuildContext context, BudgetData b) {
  showModalBottomSheet(context: context, showDragHandle: true, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
    ListTile(title: Text(b.number, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(b.clientName)),
    ListTile(leading: const Icon(Icons.visibility_outlined), title: const Text('Ver presupuesto'), onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => BudgetPreviewScreen(budgetId: b.id))); }),
    ListTile(leading: const Icon(Icons.edit_outlined), title: const Text('Editar'), onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => BudgetFlow(existing: b))); }),
    ListTile(leading: const Icon(Icons.schedule), title: const Text('Pendiente'), trailing: b.status == 'Pendiente' ? const Icon(Icons.check) : null, onTap: () => setBudgetStatus(ctx, b, 'Pendiente')),
    ListTile(leading: const Icon(Icons.check_circle_outline), title: const Text('Aceptado'), trailing: b.status == 'Aceptado' ? const Icon(Icons.check) : null, onTap: () => setBudgetStatus(ctx, b, 'Aceptado')),
    ListTile(leading: const Icon(Icons.cancel_outlined), title: const Text('Rechazado'), trailing: b.status == 'Rechazado' ? const Icon(Icons.check) : null, onTap: () => setBudgetStatus(ctx, b, 'Rechazado')),
    ListTile(leading: const Icon(Icons.delete_outline), title: const Text('Eliminar'), onTap: () async { Navigator.pop(ctx); final ok = await showDialog<bool>(context: context, builder: (d) => AlertDialog(title: const Text('Eliminar presupuesto'), content: Text('¿Eliminar ${b.number}?'), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Eliminar'))])); if (ok == true) await AppStore.instance.deleteBudget(b.id); }),
  ])));
}
Future<void> setBudgetStatus(BuildContext ctx, BudgetData b, String status) async { b.status = status; await AppStore.instance.save(); if (ctx.mounted) Navigator.pop(ctx); }

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  String monthName(int m) => const ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'][m-1];
  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    return AnimatedBuilder(animation: s, builder: (_, __) {
      final groups = <String, List<BudgetData>>{};
      for (final b in s.budgets) { final d = DateTime.tryParse(b.createdAt) ?? DateTime.now(); final k = '${d.year}-${d.month.toString().padLeft(2,'0')}'; groups.putIfAbsent(k, () => []).add(b); }
      final keys = groups.keys.toList()..sort((a,b) => b.compareTo(a));
      return Scaffold(appBar: AppBar(title: const Text('Historial')), body: keys.isEmpty ? const Center(child: Text('Todavía no hay historial.')) : ListView(padding: const EdgeInsets.all(20), children: keys.map((k) {
        final list = groups[k]!; final d = DateTime.parse('$k-01'); final earned = list.where((b) => b.status == 'Aceptado').fold<double>(0, (a,b) => a+b.total);
        final accepted = list.where((b) => b.status == 'Aceptado').length; final rejected = list.where((b) => b.status == 'Rechazado').length; final pending = list.where((b) => b.status == 'Pendiente').length;
        return Card(child: ExpansionTile(title: Text('${monthName(d.month)} ${d.year}', style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('Ganado: \$${earned.toStringAsFixed(0)} · $accepted aceptados · $rejected rechazados · $pending pendientes'), children: list.map((b) => ListTile(title: Text('${b.number} · ${b.clientName}'), subtitle: Text(b.status), trailing: Text('\$${b.total.toStringAsFixed(0)}'), onTap: () => budgetActions(context, b))).toList()));
      }).toList()));
    });
  }
}

class BudgetPreviewScreen extends StatefulWidget {
  final String budgetId;
  const BudgetPreviewScreen({super.key, required this.budgetId});
  @override
  State<BudgetPreviewScreen> createState() => _BudgetPreviewScreenState();
}

class _BudgetPreviewScreenState extends State<BudgetPreviewScreen> {
  BudgetData? get budget => AppStore.instance.budgets
      .where((b) => b.id == widget.budgetId)
      .cast<BudgetData?>()
      .firstOrNull;

  Future<Uint8List> buildPdf() async {
    final b = budget!;
    final p = AppStore.instance.profile;
    final doc = pw.Document();
    final blue = PdfColor.fromHex('#5BC0EB');

    pw.MemoryImage? logo;
    if (b.showLogo && p.logoBase64.isNotEmpty) {
      try {
        logo = pw.MemoryImage(base64Decode(p.logoBase64));
      } catch (_) {}
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: b.showCompany && p.companyName.isNotEmpty
                    ? pw.Text(
                        p.companyName,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: blue,
                        ),
                      )
                    : pw.SizedBox(),
              ),
              pw.Container(
                width: 130,
                alignment: pw.Alignment.center,
                child: logo == null
                    ? pw.SizedBox(height: 65)
                    : pw.Container(
                        width: 110,
                        height: 75,
                        child: pw.Image(logo, fit: pw.BoxFit.contain),
                      ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'PRESUPUESTO ${b.number}',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(_date(), style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: blue),
          pw.Row(children: [
            pw.Expanded(child: info('CLIENTE', b.clientName)),
            pw.SizedBox(width: 12),
            pw.Expanded(child: info('OBRA', b.place)),
          ]),
          pw.SizedBox(height: 14),
          section('TIPO DE TRABAJO', blue),
          pw.Text(b.workType.isEmpty ? '-' : b.workType),
          if (b.area > 0) ...[
            pw.SizedBox(height: 12),
            section('SUPERFICIE', blue),
            pw.Text('${b.area.toStringAsFixed(2)} m²'),
          ],
          if (b.jobs.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            section('TRABAJOS A REALIZAR', blue),
            pw.SizedBox(height: 5),
            ...b.jobs.map((e) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text('- $e'),
                )),
          ],
          if (b.materials.isNotEmpty || b.extraMaterials.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            section('MATERIALES APROXIMADOS', blue),
            pw.SizedBox(height: 5),
            ...b.materials.entries.map(
              (e) => pw.Text('- ${e.key}: ${e.value} ${materialUnit(e.key)}'),
            ),
            if (b.extraMaterials.isNotEmpty) pw.Text(b.extraMaterials),
          ],
          if (b.notes.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            section('ACLARACIONES', blue),
            ...b.notes.split('\n').where((e) => e.trim().isNotEmpty).map(
                  (e) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text('- ${e.trim()}'),
                  ),
                ),
          ],
          pw.SizedBox(height: 22),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            color: PdfColor.fromHex('#EAF6FC'),
            child: pw.Row(children: [
              pw.Text(
                'TOTAL',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: blue),
              ),
              pw.Spacer(),
              pw.Text(
                '\$ ${b.total.toStringAsFixed(0)}',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: blue,
                ),
              ),
            ]),
          ),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Text(
              'Generado con PintaM2',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
          ),
        ],
      ),
    );
    return doc.save();
  }

  static String materialUnit(String k) => {
        'Látex interior': 'L',
        'Látex exterior': 'L',
        'Enduido interior': 'kg',
        'Enduido exterior': 'kg',
        'Cinta de papel': 'rollos',
      }[k] ??
      '';

  static pw.Widget info(String a, String b) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(a, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.Text(
            b.isEmpty ? '-' : b,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
        ],
      );

  static pw.Widget section(String s, PdfColor c) => pw.Text(
        s,
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: c),
      );

  static String _date() {
    final d = DateTime.now();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final b = budget;
    if (b == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Presupuesto eliminado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(b.number),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BudgetFlow(existing: b)),
              );
              if (mounted) setState(() {});
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar'),
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: PdfPreview(
            build: (_) => buildPdf(),
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            pdfFileName: 'PintaM2_${b.number}.pdf',
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: () async => Printing.sharePdf(
                bytes: await buildPdf(),
                filename: 'PintaM2_${b.number}.pdf',
              ),
              icon: const Icon(Icons.share_outlined),
              label: const Text('Compartir PDF'),
            ),
          ),
        ),
      ]),
    );
  }
}

class MoreScreen extends StatelessWidget {
  final ValueChanged<ThemeMode> onThemeChanged;
  const MoreScreen({super.key, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const BrandAppBar(),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.manage_accounts_outlined),
                title: const Text('Editar datos'),
                subtitle: const Text('Usuario, empresa, logo y precios'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Colores / códigos'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ColorsScreen()),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calculate_outlined),
                title: const Text('Calculadora'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdvancedCalculatorScreen()),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.history_outlined),
                title: const Text('Historial'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: const Text('Exportar / guardar datos'),
                subtitle: const Text('Copia de seguridad para cambiar de celular'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BackupScreen()),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Apariencia'),
                onTap: () => showModalBottomSheet(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      ListTile(
                        title: const Text('Seguir el sistema'),
                        onTap: () {
                          onThemeChanged(ThemeMode.system);
                          Navigator.pop(ctx);
                        },
                      ),
                      ListTile(
                        title: const Text('Claro'),
                        onTap: () {
                          onThemeChanged(ThemeMode.light);
                          Navigator.pop(ctx);
                        },
                      ),
                      ListTile(
                        title: const Text('Oscuro'),
                        onTap: () {
                          onThemeChanged(ThemeMode.dark);
                          Navigator.pop(ctx);
                        },
                      ),
                    ]),
                  ),
                ),
              ),
            ),
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Acerca de PintaM²'),
                subtitle: Text('Versión de prueba 0.8'),
              ),
            ),
          ],
        ),
      );
}

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});
  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool busy = false;
  String lastBackup = '';

  Future<void> exportFile() async {
    setState(() => busy = true);
    try {
      final now = DateTime.now();
      final stamp =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}';
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/PintaM2_Backup_$stamp.json');
      await file.writeAsString(AppStore.instance.backupJson(), flush: true);

      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Copia de seguridad PintaM²',
        text: 'Copia de seguridad de PintaM². Guardala en un lugar seguro.',
      );
      setState(() => lastBackup =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo exportar la copia: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> importFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;

    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar copia'),
        content: const Text(
          'La copia reemplazará los datos actuales de PintaM². '
          'Conviene exportar una copia actual antes de continuar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Importar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => busy = true);
    try {
      final raw = await File(result.files.single.path!).readAsString();
      await AppStore.instance.restoreBackup(raw);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos restaurados correctamente.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('La copia no se pudo importar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Copia de seguridad')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.cloud_done_outlined, size: 64),
            const SizedBox(height: 12),
            const Text(
              'Protegé los datos de PintaM²',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'La copia incluye clientes, trabajos, colores y fórmulas, '
              'presupuestos, turnos, precios y configuración.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: busy ? null : exportFile,
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('Exportar datos'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: busy ? null : importFile,
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('Importar datos'),
            ),
            if (lastBackup.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Última copia creada: $lastBackup',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'Consejo: guardá el archivo .json en Google Drive, correo '
                  'o en otra ubicación fuera del teléfono.',
                ),
              ),
            ),
          ],
        ),
      );
}


class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override State<EditProfileScreen> createState() => _EditProfileScreenState();
}
class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController name, company;
  late Map<String, TextEditingController> prices;
  @override
  void initState() { super.initState(); final p = AppStore.instance.profile; name = TextEditingController(text: p.userName); company = TextEditingController(text: p.companyName); prices = {for (final e in p.prices.entries) e.key: TextEditingController(text: e.value == 0 ? '' : e.value.toStringAsFixed(0))}; }
  Future<void> pickLogo() async { final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 1000); if (f != null) { AppStore.instance.profile.logoBase64 = base64Encode(await f.readAsBytes()); setState(() {}); } }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Editar datos')), body: ListView(padding: const EdgeInsets.all(20), children: [
    TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre del usuario')), const SizedBox(height: 10), TextField(controller: company, decoration: const InputDecoration(labelText: 'Nombre de la empresa')), const SizedBox(height: 12),
    if (AppStore.instance.profile.logoBase64.isNotEmpty) Center(child: Image.memory(base64Decode(AppStore.instance.profile.logoBase64), height: 100)), OutlinedButton.icon(onPressed: pickLogo, icon: const Icon(Icons.image_outlined), label: const Text('Cambiar logo de la empresa')),
    const SizedBox(height: 18), const Text('Precios por m²', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 10),
    ...prices.entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: e.value, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: e.key, prefixText: '\$ ', suffixText: '/m²')))),
    OutlinedButton.icon(onPressed: () { final c = TextEditingController(); showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Otro trabajo'), content: TextField(controller: c, decoration: const InputDecoration(labelText: 'Nombre del trabajo')), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')), FilledButton(onPressed: () { if (c.text.trim().isNotEmpty) setState(() => prices[c.text.trim()] = TextEditingController()); Navigator.pop(ctx); }, child: const Text('Agregar'))])); }, icon: const Icon(Icons.add), label: const Text('Otro tipo de trabajo')),
    const SizedBox(height: 16), FilledButton(onPressed: () async { final p = AppStore.instance.profile; p.userName = name.text.trim(); p.companyName = company.text.trim(); p.prices = {for (final e in prices.entries) e.key: double.tryParse(e.value.text.replaceAll(',', '.')) ?? 0}; await AppStore.instance.save(); if (context.mounted) Navigator.pop(context); }, child: const Text('Guardar cambios')),
  ]));
}

extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
