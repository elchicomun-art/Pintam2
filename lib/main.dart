
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const PintaM2App());
}

class PintaM2App extends StatefulWidget {
  const PintaM2App({super.key});

  @override
  State<PintaM2App> createState() => _PintaM2AppState();
}

class _PintaM2AppState extends State<PintaM2App> {
  ThemeMode _themeMode = ThemeMode.system;
  final AppStore _store = AppStore();

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF2F80ED);

    return MaterialApp(
      title: 'PintaM²',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE4EAF2)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF111827),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1F2937),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF1F2937),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF374151)),
          ),
        ),
      ),
      home: AnimatedBuilder(
        animation: _store,
        builder: (context, _) {
          if (!_store.loaded) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return MainShell(
            store: _store,
            onThemeChanged: (mode) => setState(() => _themeMode = mode),
          );
        },
      ),
    );
  }
}

class ClientData {
  final String id;
  final String name;
  final String address;
  final String phone;

  const ClientData({
    required this.id,
    required this.name,
    required this.address,
    this.phone = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'phone': phone,
      };

  factory ClientData.fromJson(Map<String, dynamic> json) {
    return ClientData(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
    );
  }
}

class BudgetData {
  final String id;
  final String number;
  final String client;
  final String place;
  final String workType;
  final String measurements;
  final String jobs;
  final String materials;
  final String notes;
  final String total;
  final String status;
  final String createdAt;

  const BudgetData({
    required this.id,
    required this.number,
    required this.client,
    required this.place,
    required this.workType,
    required this.measurements,
    required this.jobs,
    required this.materials,
    required this.notes,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'client': client,
        'place': place,
        'workType': workType,
        'measurements': measurements,
        'jobs': jobs,
        'materials': materials,
        'notes': notes,
        'total': total,
        'status': status,
        'createdAt': createdAt,
      };

  factory BudgetData.fromJson(Map<String, dynamic> json) {
    return BudgetData(
      id: (json['id'] ?? '').toString(),
      number: (json['number'] ?? '').toString(),
      client: (json['client'] ?? '').toString(),
      place: (json['place'] ?? '').toString(),
      workType: (json['workType'] ?? '').toString(),
      measurements: (json['measurements'] ?? '').toString(),
      jobs: (json['jobs'] ?? '').toString(),
      materials: (json['materials'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
      total: (json['total'] ?? '').toString(),
      status: (json['status'] ?? 'Pendiente').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }
}

class AppStore extends ChangeNotifier {
  static const _clientsKey = 'pintam2_clients_v2';
  static const _budgetsKey = 'pintam2_budgets_v1';

  bool loaded = false;
  final List<ClientData> clients = [];
  final List<BudgetData> budgets = [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final clientsRaw = prefs.getString(_clientsKey);
    if (clientsRaw != null && clientsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(clientsRaw) as List<dynamic>;
        clients
          ..clear()
          ..addAll(
            decoded.map(
              (e) => ClientData.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            ),
          );
      } catch (_) {
        clients.clear();
      }
    }

    final budgetsRaw = prefs.getString(_budgetsKey);
    if (budgetsRaw != null && budgetsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(budgetsRaw) as List<dynamic>;
        budgets
          ..clear()
          ..addAll(
            decoded.map(
              (e) => BudgetData.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            ),
          );
      } catch (_) {
        budgets.clear();
      }
    }

    loaded = true;
    notifyListeners();
  }

  Future<void> _saveClients() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _clientsKey,
      jsonEncode(clients.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _saveBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _budgetsKey,
      jsonEncode(budgets.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> addClient({
    required String name,
    required String address,
    String phone = '',
  }) async {
    final client = ClientData(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      address: address.trim(),
      phone: phone.trim(),
    );
    clients.add(client);
    await _saveClients();
    notifyListeners();
  }

  Future<void> deleteClient(String id) async {
    clients.removeWhere((c) => c.id == id);
    await _saveClients();
    notifyListeners();
  }

  Future<void> saveBudget(BudgetData budget) async {
    final existing = budgets.indexWhere((b) => b.id == budget.id);
    if (existing >= 0) {
      budgets[existing] = budget;
    } else {
      budgets.insert(0, budget);
    }
    await _saveBudgets();
    notifyListeners();
  }

  String nextBudgetNumber() {
    final now = DateTime.now();
    final n = budgets.length + 1;
    return '${now.year}-${n.toString().padLeft(4, '0')}';
  }
}

class BudgetDraft {
  String id;
  String number;
  String workType;
  String client;
  String place;
  String measurements;
  String jobs;
  String materials;
  String notes;
  String total;

  BudgetDraft({
    required this.id,
    required this.number,
    this.workType = '',
    this.client = '',
    this.place = '',
    this.measurements = '',
    this.jobs = '',
    this.materials = '',
    this.notes = '',
    this.total = '',
  });
}

class MainShell extends StatefulWidget {
  final AppStore store;
  final ValueChanged<ThemeMode> onThemeChanged;

  const MainShell({
    super.key,
    required this.store,
    required this.onThemeChanged,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  DateTime? _lastBackPress;

  Future<void> _handleBack() async {
    if (_index != 0) {
      setState(() => _index = 0);
      return;
    }

    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 2),
            content: Text('Presioná nuevamente para salir de PintaM²'),
          ),
        );
      }
      return;
    }

    await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        store: widget.store,
        onOpenTab: (i) => setState(() => _index = i),
      ),
      ClientsScreen(store: widget.store),
      BudgetsScreen(store: widget.store),
      MoreScreen(
        store: widget.store,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Clientes',
            ),
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description),
              label: 'Presupuestos',
            ),
            NavigationDestination(
              icon: Icon(Icons.more_horiz),
              label: 'Más',
            ),
          ],
        ),
      ),
    );
  }
}

class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 18,
      title: Row(
        children: [
          Icon(
            Icons.format_paint_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'PintaM²',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final AppStore store;
  final ValueChanged<int> onOpenTab;

  const HomeScreen({
    super.key,
    required this.store,
    required this.onOpenTab,
  });

  @override
  Widget build(BuildContext context) {
    final pending =
        store.budgets.where((b) => b.status == 'Pendiente').length;

    return Scaffold(
      appBar: const BrandAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        children: [
          Text(
            '${_greeting()}, Mario 👋',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            _today(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NewBudgetFlow(store: store),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text(
              'Nuevo presupuesto',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _HomeCard(
            icon: Icons.people_alt_outlined,
            title: 'Clientes',
            subtitle: '${store.clients.length} registrados',
            onTap: () => onOpenTab(1),
          ),
          _HomeCard(
            icon: Icons.description_outlined,
            title: 'Presupuestos',
            subtitle: pending == 0 ? '0 pendientes' : '$pending pendientes',
            onTap: () => onOpenTab(2),
          ),
          _HomeCard(
            icon: Icons.dashboard_customize_outlined,
            title: 'Plantillas',
            subtitle: 'Textos rápidos',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TemplatesScreen()),
              );
            },
          ),
          _HomeCard(
            icon: Icons.calculate_outlined,
            title: 'Calculadora',
            subtitle: 'Largo × alto',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalculatorScreen()),
              );
            },
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: store.budgets.isEmpty
                  ? const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Último presupuesto',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 10),
                        Text('Todavía no creaste ningún presupuesto.'),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Último presupuesto',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          store.budgets.first.client.isEmpty
                              ? 'Sin cliente'
                              : store.budgets.first.client,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(store.budgets.first.number),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buen día';
    if (hour < 20) return 'Buenas tardes';
    return 'Buenas noches';
  }

  static String _today() {
    final now = DateTime.now();
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    return '${now.day} de ${months[now.month - 1]} de ${now.year}';
  }
}

class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class ClientsScreen extends StatefulWidget {
  final AppStore store;

  const ClientsScreen({super.key, required this.store});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _search = TextEditingController();
  String query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final visible = widget.store.clients.where((c) {
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) ||
          c.address.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: const BrandAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newClient,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Nuevo cliente'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          TextField(
            controller: _search,
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
                child: Column(
                  children: [
                    Icon(Icons.people_outline, size: 42),
                    SizedBox(height: 10),
                    Text(
                      'No hay clientes guardados',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ...visible.map(
            (client) => Dismissible(
              key: ValueKey(client.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) async {
                return await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Eliminar cliente'),
                        content: Text(
                          '¿Querés eliminar a ${client.name}?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    ) ??
                    false;
              },
              onDismissed: (_) => widget.store.deleteClient(client.id),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 22),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete_outline),
              ),
              child: Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      client.name.isEmpty ? '?' : client.name[0].toUpperCase(),
                    ),
                  ),
                  title: Text(
                    client.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    [
                      if (client.address.isNotEmpty) client.address,
                      if (client.phone.isNotEmpty) client.phone,
                    ].join('\n'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _newClient() async {
    final name = TextEditingController();
    final address = TextEditingController();
    final phone = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          20 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nuevo cliente',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Nombre del cliente',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: address,
              decoration: const InputDecoration(
                labelText: 'Dirección de la obra',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono (opcional)',
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Ingresá el nombre del cliente'),
                    ),
                  );
                  return;
                }
                await widget.store.addClient(
                  name: name.text,
                  address: address.text,
                  phone: phone.text,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Guardar cliente'),
            ),
          ],
        ),
      ),
    );
  }
}

class BudgetsScreen extends StatelessWidget {
  final AppStore store;

  const BudgetsScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (store.budgets.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(22),
                child: Column(
                  children: [
                    Icon(Icons.description_outlined, size: 42),
                    SizedBox(height: 10),
                    Text(
                      'Todavía no hay presupuestos',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ...store.budgets.map(
            (b) => Card(
              child: ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(
                  '${b.number} · ${b.client.isEmpty ? 'Sin cliente' : b.client}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${b.place}\n${b.status}',
                ),
                isThreeLine: true,
                trailing: Text(
                  b.total.isEmpty ? '' : '\$${b.total}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                onTap: () {
                  final draft = BudgetDraft(
                    id: b.id,
                    number: b.number,
                    workType: b.workType,
                    client: b.client,
                    place: b.place,
                    measurements: b.measurements,
                    jobs: b.jobs,
                    materials: b.materials,
                    notes: b.notes,
                    total: b.total,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BudgetPreviewScreen(
                        store: store,
                        draft: draft,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      'Protección de pisos y muebles',
      'Tapado de pequeñas imperfecciones',
      'Lijado donde sea necesario',
      'Aplicación de 2 manos de pintura látex',
      'Limpieza final',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Plantillas')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: items
            .map(
              (e) => Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(e),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final length = TextEditingController();
  final height = TextEditingController();
  double? area;

  @override
  void dispose() {
    length.dispose();
    height.dispose();
    super.dispose();
  }

  void calculate() {
    final l = double.tryParse(length.text.replaceAll(',', '.')) ?? 0;
    final h = double.tryParse(height.text.replaceAll(',', '.')) ?? 0;
    setState(() => area = l * h);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calculadora')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Calcular pared',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text('Ingresá largo × alto.'),
          const SizedBox(height: 18),
          TextField(
            controller: length,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Largo (m)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: height,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Alto (m)'),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: calculate,
            icon: const Icon(Icons.calculate),
            label: const Text('Calcular'),
          ),
          if (area != null) ...[
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    '${area!.toStringAsFixed(2)} m²',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MoreScreen extends StatelessWidget {
  final AppStore store;
  final ValueChanged<ThemeMode> onThemeChanged;

  const MoreScreen({
    super.key,
    required this.store,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.dashboard_customize_outlined),
              title: const Text('Plantillas'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TemplatesScreen()),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calculate_outlined),
              title: const Text('Calculadora'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CalculatorScreen()),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Apariencia'),
              subtitle: const Text('Claro, oscuro o sistema'),
              onTap: () => _themePicker(context),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: const Text('Sugerir una mejora'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Esta función se conectará más adelante.'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _themePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text('Seguir el sistema'),
              onTap: () {
                onThemeChanged(ThemeMode.system);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode_outlined),
              title: const Text('Claro'),
              onTap: () {
                onThemeChanged(ThemeMode.light);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Oscuro'),
              onTap: () {
                onThemeChanged(ThemeMode.dark);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class NewBudgetFlow extends StatefulWidget {
  final AppStore store;

  const NewBudgetFlow({super.key, required this.store});

  @override
  State<NewBudgetFlow> createState() => _NewBudgetFlowState();
}

class _NewBudgetFlowState extends State<NewBudgetFlow> {
  int step = 0;
  late final BudgetDraft draft;

  final otherWorkController = TextEditingController();
  final clientController = TextEditingController();
  final placeController = TextEditingController();
  final jobsController = TextEditingController();
  final materialsController = TextEditingController();
  final measurementsController = TextEditingController();
  final notesController = TextEditingController();
  final totalController = TextEditingController();

  final List<String> presetJobs = const [
    'Protección de pisos y muebles',
    'Tapado de pequeñas imperfecciones',
    'Lijado donde sea necesario',
    'Aplicación de 2 manos de pintura látex',
    'Limpieza final',
  ];

  String selectedWorkType = '';
  bool saveNewClient = false;

  @override
  void initState() {
    super.initState();
    draft = BudgetDraft(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      number: widget.store.nextBudgetNumber(),
    );
  }

  @override
  void dispose() {
    otherWorkController.dispose();
    clientController.dispose();
    placeController.dispose();
    jobsController.dispose();
    materialsController.dispose();
    measurementsController.dispose();
    notesController.dispose();
    totalController.dispose();
    super.dispose();
  }

  Future<void> _back() async {
    if (step > 0) {
      setState(() => step--);
    } else {
      Navigator.pop(context);
    }
  }

  void _next() {
    _syncDraft();
    if (step < 5) {
      setState(() => step++);
    }
  }

  void _skip() {
    if (step == 0) {
      selectedWorkType = '';
      otherWorkController.clear();
    } else if (step == 1) {
      clientController.clear();
    } else if (step == 2) {
      placeController.clear();
    } else if (step == 3) {
      measurementsController.clear();
    } else if (step == 4) {
      jobsController.clear();
    } else if (step == 5) {
      materialsController.clear();
    }
    _next();
  }

  void _syncDraft() {
    draft.workType = selectedWorkType == 'Otro'
        ? otherWorkController.text.trim()
        : selectedWorkType;
    draft.client = clientController.text.trim();
    draft.place = placeController.text.trim();
    draft.measurements = measurementsController.text.trim();
    draft.jobs = jobsController.text.trim();
    draft.materials = materialsController.text.trim();
    draft.notes = notesController.text.trim();
    draft.total = totalController.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _back,
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('Nuevo presupuesto'),
        ),
        body: Column(
          children: [
            _progress(context),
            Expanded(child: _stepBody()),
          ],
        ),
      ),
    );
  }

  Widget _progress(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: List.generate(
          7,
          (i) => Expanded(
            child: Container(
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: i <= step
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepBody() {
    switch (step) {
      case 0:
        return _typeStep();
      case 1:
        return _clientStep();
      case 2:
        return _placeStep();
      case 3:
        return _measurementsStep();
      case 4:
        return _jobsStep();
      case 5:
        return _materialsStep();
      default:
        return _summaryStep();
    }
  }

  Widget _screenScaffold({
    required String title,
    required Widget child,
    bool showSkip = true,
    String continueText = 'Continuar',
    VoidCallback? onContinue,
  }) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            child: Row(
              children: [
                if (showSkip)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _skip,
                      child: const Text('Omitir'),
                    ),
                  ),
                if (showSkip) const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onContinue ?? _next,
                    child: Text(continueText),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _typeStep() {
    const types = [
      'Pintura interior',
      'Pintura exterior',
      'Pintura rápida',
      'Barniz',
      'Esmalte sintético',
      'Membrana líquida',
      'Otro',
    ];

    return _screenScaffold(
      title: 'Seleccioná el tipo de trabajo',
      child: Column(
        children: [
          ...types.map(
            (t) => Card(
              child: RadioListTile<String>(
                value: t,
                groupValue: selectedWorkType,
                onChanged: (v) {
                  setState(() => selectedWorkType = v ?? '');
                },
                title: Text(
                  t,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          if (selectedWorkType == 'Otro') ...[
            const SizedBox(height: 10),
            TextField(
              controller: otherWorkController,
              decoration: const InputDecoration(
                labelText: 'Nombre del trabajo',
                hintText: 'Ej.: Microcemento, reparación...',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _clientStep() {
    return _screenScaffold(
      title: 'Nombre del cliente',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: clientController,
            decoration: const InputDecoration(
              labelText: 'Nombre del cliente',
              hintText: 'Escribilo manualmente',
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: saveNewClient,
            onChanged: (v) => setState(() => saveNewClient = v ?? false),
            title: const Text('Guardar cliente para futuros presupuestos'),
          ),
          const SizedBox(height: 18),
          const Text(
            'Clientes guardados',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (widget.store.clients.isEmpty)
            const Text('Todavía no hay clientes guardados.'),
          ...widget.store.clients.map(
            (client) => Card(
              child: ListTile(
                title: Text(
                  client.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: client.address.isEmpty
                    ? null
                    : Text(client.address),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  setState(() {
                    clientController.text = client.name;
                    saveNewClient = false;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      onContinue: () async {
        if (saveNewClient && clientController.text.trim().isNotEmpty) {
          final alreadyExists = widget.store.clients.any(
            (c) =>
                c.name.trim().toLowerCase() ==
                clientController.text.trim().toLowerCase(),
          );
          if (!alreadyExists) {
            await widget.store.addClient(
              name: clientController.text,
              address: '',
            );
          }
        }
        _next();
      },
    );
  }

  Widget _placeStep() {
    return _screenScaffold(
      title: '¿Dónde es el trabajo?',
      child: TextField(
        controller: placeController,
        decoration: const InputDecoration(
          labelText: 'Obra / lugar del trabajo',
          hintText: 'Ej.: Casa, quincho, local, departamento...',
        ),
      ),
    );
  }

  Widget _measurementsStep() {
    return _screenScaffold(
      title: 'Medidas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: measurementsController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Medidas o m²',
              hintText: 'Ej.: Pared 1: 4,20 × 2,60 = 10,92 m²',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalculatorScreen()),
              );
            },
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Abrir calculadora'),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => measurementsController.clear(),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Borrar medidas'),
          ),
        ],
      ),
    );
  }

  Widget _jobsStep() {
    return _screenScaffold(
      title: 'Trabajos a realizar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: jobsController,
            minLines: 5,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'Escribí el trabajo a realizar',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Opciones preestablecidas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...presetJobs.map(
            (job) => Card(
              child: ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: Text(job),
                onTap: () {
                  final current = jobsController.text.trim();
                  jobsController.text =
                      current.isEmpty ? '• $job' : '$current\n• $job';
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _materialsStep() {
    return _screenScaffold(
      title: 'Materiales aproximados',
      child: TextField(
        controller: materialsController,
        minLines: 6,
        maxLines: 12,
        decoration: const InputDecoration(
          labelText: 'Materiales necesarios',
          hintText:
              'Ej.: 20 L látex interior\n5 kg enduido\n2 cintas\nLijas',
          alignLabelWithHint: true,
        ),
      ),
    );
  }

  Widget _summaryStep() {
    _syncDraft();

    return _screenScaffold(
      title: 'Revisá el presupuesto',
      showSkip: false,
      continueText: 'Vista previa',
      onContinue: () async {
        _syncDraft();

        final edited = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => BudgetPreviewScreen(
              store: widget.store,
              draft: draft,
            ),
          ),
        );

        if (edited == true && mounted) {
          setState(() {
            selectedWorkType = draft.workType;
            if (!const [
              'Pintura interior',
              'Pintura exterior',
              'Pintura rápida',
              'Barniz',
              'Esmalte sintético',
              'Membrana líquida',
            ].contains(draft.workType)) {
              selectedWorkType = draft.workType.isEmpty ? '' : 'Otro';
              otherWorkController.text = draft.workType;
            }
            clientController.text = draft.client;
            placeController.text = draft.place;
            measurementsController.text = draft.measurements;
            jobsController.text = draft.jobs;
            materialsController.text = draft.materials;
            notesController.text = draft.notes;
            totalController.text = draft.total;
          });
        }
      },
      child: Column(
        children: [
          TextField(
            controller: clientController,
            decoration: const InputDecoration(labelText: 'Cliente'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: placeController,
            decoration: const InputDecoration(labelText: 'Obra / lugar'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: jobsController,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Trabajos a realizar',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: materialsController,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Materiales aproximados',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: notesController,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Aclaraciones',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: totalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Total',
              prefixText: '\$ ',
            ),
          ),
        ],
      ),
    );
  }
}

class BudgetPreviewScreen extends StatefulWidget {
  final AppStore store;
  final BudgetDraft draft;

  const BudgetPreviewScreen({
    super.key,
    required this.store,
    required this.draft,
  });

  @override
  State<BudgetPreviewScreen> createState() => _BudgetPreviewScreenState();
}

class _BudgetPreviewScreenState extends State<BudgetPreviewScreen> {
  bool saving = false;

  Future<Uint8List> _buildPdf() async {
    final d = widget.draft;
    final pdf = pw.Document();
    final blue = PdfColor.fromHex('#2F80ED');
    final lightBlue = PdfColor.fromHex('#EAF3FF');
    final grey = PdfColor.fromHex('#596579');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => [
          pw.Row(
            children: [
              pw.Text(
                'PintaM2',
                style: pw.TextStyle(
                  color: blue,
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Spacer(),
              pw.Text(
                'PRESUPUESTO ${d.number}',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(color: blue),
          pw.SizedBox(height: 12),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: lightBlue,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (d.client.isNotEmpty)
                  pw.Text('Cliente: ${d.client}'),
                if (d.place.isNotEmpty) pw.Text('Obra: ${d.place}'),
                if (d.workType.isNotEmpty)
                  pw.Text('Tipo de trabajo: ${d.workType}'),
              ],
            ),
          ),
          if (d.jobs.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _pdfTitle('TRABAJOS A REALIZAR', blue),
            pw.SizedBox(height: 8),
            pw.Text(d.jobs),
          ],
          if (d.materials.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _pdfTitle('MATERIALES APROXIMADOS', blue),
            pw.SizedBox(height: 8),
            pw.Text(d.materials),
          ],
          if (d.notes.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _pdfTitle('ACLARACIONES', blue),
            pw.SizedBox(height: 8),
            pw.Text(d.notes),
          ],
          if (d.total.isNotEmpty) ...[
            pw.SizedBox(height: 22),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: lightBlue,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                children: [
                  pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(
                      color: blue,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Spacer(),
                  pw.Text(
                    '\$${d.total}',
                    style: pw.TextStyle(
                      color: blue,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          pw.SizedBox(height: 28),
          pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Text(
              'Generado con PintaM2',
              style: pw.TextStyle(color: grey, fontSize: 8),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pdfTitle(String text, PdfColor color) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  Future<void> _saveBudget() async {
    if (saving) return;
    setState(() => saving = true);

    final d = widget.draft;
    final data = BudgetData(
      id: d.id,
      number: d.number,
      client: d.client,
      place: d.place,
      workType: d.workType,
      measurements: d.measurements,
      jobs: d.jobs,
      materials: d.materials,
      notes: d.notes,
      total: d.total,
      status: 'Pendiente',
      createdAt: DateTime.now().toIso8601String(),
    );

    await widget.store.saveBudget(data);

    if (mounted) {
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Presupuesto guardado')),
      );
    }
  }

  Future<void> _sharePdf() async {
    final bytes = await _buildPdf();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'PintaM2_${widget.draft.number}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista previa'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfPreview(
              build: (_) => _buildPdf(),
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              pdfFileName: 'PintaM2_${widget.draft.number}.pdf',
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: saving ? null : _saveBudget,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(saving ? 'Guardando...' : 'Guardar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _sharePdf,
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
