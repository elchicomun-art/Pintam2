
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

  void _setTheme(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1677FF);

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
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE7ECF3)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardTheme: CardThemeData(
          color: const Color(0xFF172033),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF263247)),
          ),
        ),
      ),
      home: MainShell(onThemeChanged: _setTheme),
    );
  }
}

class MainShell extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeChanged;

  const MainShell({super.key, required this.onThemeChanged});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  late final List<Widget> _screens = [
    HomeScreen(onOpenTab: (i) => setState(() => _index = i)),
    const ClientsScreen(),
    const BudgetsScreen(),
    MoreScreen(onThemeChanged: widget.onThemeChanged),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
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
            selectedIcon: Icon(Icons.more_horiz),
            label: 'Más',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final ValueChanged<int> onOpenTab;

  const HomeScreen({super.key, required this.onOpenTab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BrandAppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          children: [
            Text(
              '¡Buen día, Mario! 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              _today(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewBudgetFlow()),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Nuevo presupuesto',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _HomeActionCard(
              icon: Icons.people_alt_outlined,
              title: 'Clientes',
              subtitle: '3 registrados',
              onTap: () => onOpenTab(1),
            ),
            _HomeActionCard(
              icon: Icons.description_outlined,
              title: 'Presupuestos',
              subtitle: '1 pendiente',
              onTap: () => onOpenTab(2),
            ),
            _HomeActionCard(
              icon: Icons.dashboard_customize_outlined,
              title: 'Plantillas',
              subtitle: 'Plantillas base',
              color: const Color(0xFF7B61FF),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TemplatesScreen()),
                );
              },
            ),
            _HomeActionCard(
              icon: Icons.calculate_outlined,
              title: 'Calculadora',
              subtitle: 'Cálculo rápido',
              color: const Color(0xFF19A974),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Último presupuesto',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Juan Pérez',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const Text('Casa Barrio Dalvian'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Chip(
                          label: const Text('Pendiente'),
                          avatar: const Icon(Icons.schedule, size: 16),
                          backgroundColor:
                              Theme.of(context).colorScheme.secondaryContainer,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Consejo rápido: elegí el tipo de trabajo que más se ajuste para obtener un cálculo más preciso.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

class _HomeActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Icon(icon, color: c, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final clients = [
      ('Juan Pérez', 'Casa Barrio Dalvian', '3 presupuestos'),
      ('María González', 'Departamento Centro', '1 presupuesto'),
      ('Carlos Rodríguez', 'Quincho', '2 presupuestos'),
    ];

    return Scaffold(
      appBar: const BrandAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewClient(context),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Nuevo cliente'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar cliente...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 16),
          ...clients.map(
            (c) => Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(c.$1[0])),
                title: Text(c.$1,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${c.$2}\n${c.$3}'),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClientDetailScreen(name: c.$1),
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

  void _showNewClient(BuildContext context) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    showModalBottomSheet(
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
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Dirección de obra'),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cliente guardado (demo)')),
                );
              },
              child: const Text('Guardar cliente'),
            ),
          ],
        ),
      ),
    );
  }
}

class ClientDetailScreen extends StatelessWidget {
  final String name;

  const ClientDetailScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Casa Barrio Dalvian'),
              subtitle: const Text('Av. del Sol 1234'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.home_work_outlined),
              title: const Text('Quincho'),
              subtitle: const Text('Barrio Dalvian'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewBudgetFlow()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Nuevo presupuesto'),
          ),
        ],
      ),
    );
  }
}

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('2026-0008', 'Juan Pérez', 'Pendiente', '\$356.800'),
      ('2026-0007', 'María González', 'Aceptado', '\$198.500'),
      ('2026-0006', 'Carlos Rodríguez', 'Rechazado', '\$420.000'),
    ];

    return Scaffold(
      appBar: const BrandAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Wrap(
            spacing: 8,
            children: const [
              FilterChip(label: Text('Todos'), selected: true, onSelected: null),
              FilterChip(label: Text('Pendientes'), selected: false, onSelected: null),
              FilterChip(label: Text('Aceptados'), selected: false, onSelected: null),
            ],
          ),
          const SizedBox(height: 14),
          ...items.map(
            (b) => Card(
              child: ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text('${b.$1} · ${b.$2}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(b.$3),
                trailing: Text(
                  b.$4,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BudgetPreviewScreen(
                        number: b.$1,
                        client: b.$2,
                        total: b.$4,
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
    const templates = [
      ('Pintura interior', Icons.home_outlined),
      ('Pintura exterior', Icons.house_siding_outlined),
      ('Barniz', Icons.chair_alt_outlined),
      ('Esmalte sintético', Icons.format_paint_outlined),
      ('Membrana líquida', Icons.water_drop_outlined),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Plantillas')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ...templates.map(
            (t) => Card(
              child: ListTile(
                leading: Icon(t.$2),
                title: Text(t.$1,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Tocá para usar o editar'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Plantilla "${t.$1}" seleccionada')),
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

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _length = TextEditingController(text: '5');
  final _width = TextEditingController(text: '4');
  final _height = TextEditingController(text: '2.8');

  double? _area;
  double? _liters;

  void _calculate() {
    final l = double.tryParse(_length.text.replaceAll(',', '.')) ?? 0;
    final w = double.tryParse(_width.text.replaceAll(',', '.')) ?? 0;
    final h = double.tryParse(_height.text.replaceAll(',', '.')) ?? 0;

    final walls = 2 * (l + w) * h;
    final ceiling = l * w;
    final area = walls + ceiling;
    final liters = area * 2 / 10;

    setState(() {
      _area = area;
      _liters = liters;
    });
  }

  @override
  void dispose() {
    _length.dispose();
    _width.dispose();
    _height.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calculadora')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Ambiente completo',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text('Paredes + cielorraso, 2 manos, rendimiento 10 m²/L.'),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _length,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Largo (m)'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _width,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ancho (m)'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _height,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Alto (m)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.calculate),
            label: const Text('Calcular'),
          ),
          if (_area != null) ...[
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Text(
                      '${_area!.toStringAsFixed(1)} m²',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text('Superficie aproximada'),
                    const Divider(height: 28),
                    Text(
                      '${_liters!.toStringAsFixed(1)} litros',
                      style: TextStyle(
                        fontSize: 24,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text('Pintura estimada'),
                  ],
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
  final ValueChanged<ThemeMode> onThemeChanged;

  const MoreScreen({super.key, required this.onThemeChanged});

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
              trailing: const Icon(Icons.chevron_right),
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
              trailing: const Icon(Icons.chevron_right),
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
              subtitle: const Text('Claro, oscuro o seguir el sistema'),
              onTap: () => _showThemePicker(context),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: const Text('Sugerir una mejora'),
              subtitle: const Text('Próximamente'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Función en preparación')),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Acerca de PintaM²'),
              subtitle: const Text('Versión de prueba 0.2'),
            ),
          ),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Apariencia',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
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
  const NewBudgetFlow({super.key});

  @override
  State<NewBudgetFlow> createState() => _NewBudgetFlowState();
}

class _NewBudgetFlowState extends State<NewBudgetFlow> {
  int step = 0;
  String workType = 'Pintura interior';
  String client = 'Juan Pérez';
  String work = 'Casa Barrio Dalvian';
  double area = 74.2;
  final totalController = TextEditingController(text: '356800');

  final steps = const [
    'Tipo',
    'Cliente',
    'Obra',
    'Medidas',
    'Trabajo',
    'Resumen',
  ];

  @override
  void dispose() {
    totalController.dispose();
    super.dispose();
  }

  void next() {
    if (step < steps.length - 1) {
      setState(() => step++);
    }
  }

  void back() {
    if (step > 0) {
      setState(() => step--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: back),
        title: const Text('Nuevo presupuesto'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
            child: Row(
              children: List.generate(
                steps.length,
                (i) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 5,
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
          ),
          Expanded(child: _stepBody(context)),
        ],
      ),
    );
  }

  Widget _stepBody(BuildContext context) {
    switch (step) {
      case 0:
        return _WorkTypeStep(
          selected: workType,
          onSelected: (v) {
            setState(() => workType = v);
            next();
          },
        );
      case 1:
        return _ChoiceStep(
          title: 'Seleccioná el cliente',
          choices: const ['Juan Pérez', 'María González', 'Carlos Rodríguez'],
          selected: client,
          onSelected: (v) => setState(() => client = v),
          onContinue: next,
        );
      case 2:
        return _ChoiceStep(
          title: 'Seleccioná la obra',
          choices: const [
            'Casa Barrio Dalvian',
            'Quincho',
            'Departamento Centro'
          ],
          selected: work,
          onSelected: (v) => setState(() => work = v),
          onContinue: next,
        );
      case 3:
        return _MeasureStep(
          area: area,
          onAreaChanged: (v) => setState(() => area = v),
          onContinue: next,
        );
      case 4:
        return _JobsStep(onContinue: next);
      default:
        return _SummaryStep(
          client: client,
          work: work,
          workType: workType,
          area: area,
          totalController: totalController,
          onFinish: () {
            final total = totalController.text.trim().isEmpty
                ? '0'
                : totalController.text.trim();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => BudgetPreviewScreen(
                  number: '2026-0009',
                  client: client,
                  total: '\$$total',
                ),
              ),
            );
          },
        );
    }
  }
}

class _WorkTypeStep extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _WorkTypeStep({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final types = [
      ('Pintura interior', Icons.home_outlined),
      ('Pintura exterior', Icons.house_siding_outlined),
      ('Pintura rápida', Icons.format_paint_outlined),
      ('Barniz', Icons.chair_alt_outlined),
      ('Esmalte sintético', Icons.format_color_fill_outlined),
      ('Membrana líquida', Icons.water_drop_outlined),
      ('Otro', Icons.more_horiz),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Seleccioná el tipo de trabajo',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        ...types.map(
          (t) => Card(
            child: ListTile(
              leading: Icon(t.$2),
              title: Text(t.$1,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              trailing: selected == t.$1
                  ? Icon(Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary)
                  : const Icon(Icons.chevron_right),
              onTap: () => onSelected(t.$1),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoiceStep extends StatelessWidget {
  final String title;
  final List<String> choices;
  final String selected;
  final ValueChanged<String> onSelected;
  final VoidCallback onContinue;

  const _ChoiceStep({
    required this.title,
    required this.choices,
    required this.selected,
    required this.onSelected,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 23, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              ...choices.map(
                (c) => Card(
                  child: RadioListTile<String>(
                    value: c,
                    groupValue: selected,
                    onChanged: (v) {
                      if (v != null) onSelected(v);
                    },
                    title: Text(c,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: FilledButton(
            onPressed: onContinue,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
            child: const Text('Continuar'),
          ),
        ),
      ],
    );
  }
}

class _MeasureStep extends StatelessWidget {
  final double area;
  final ValueChanged<double> onAreaChanged;
  final VoidCallback onContinue;

  const _MeasureStep({
    required this.area,
    required this.onAreaChanged,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(text: area.toStringAsFixed(1));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Medidas',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text('Podés escribir directamente los m² por ahora.'),
        const SizedBox(height: 18),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Superficie total',
            suffixText: 'm²',
          ),
          onChanged: (v) {
            final parsed = double.tryParse(v.replaceAll(',', '.'));
            if (parsed != null) onAreaChanged(parsed);
          },
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
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onContinue,
          child: const Text('Continuar'),
        ),
      ],
    );
  }
}

class _JobsStep extends StatefulWidget {
  final VoidCallback onContinue;

  const _JobsStep({required this.onContinue});

  @override
  State<_JobsStep> createState() => _JobsStepState();
}

class _JobsStepState extends State<_JobsStep> {
  final jobs = <String, bool>{
    'Protección de pisos y muebles': true,
    'Tapado de pequeñas imperfecciones': true,
    'Lijado donde sea necesario': true,
    'Aplicación de 2 manos de pintura látex': true,
    'Limpieza final': true,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Trabajos a realizar',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              ...jobs.entries.map(
                (e) => Card(
                  child: SwitchListTile(
                    value: e.value,
                    onChanged: (v) => setState(() => jobs[e.key] = v),
                    title: Text(e.key),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: FilledButton(
            onPressed: widget.onContinue,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
            child: const Text('Continuar'),
          ),
        ),
      ],
    );
  }
}

class _SummaryStep extends StatelessWidget {
  final String client;
  final String work;
  final String workType;
  final double area;
  final TextEditingController totalController;
  final VoidCallback onFinish;

  const _SummaryStep({
    required this.client,
    required this.work,
    required this.workType,
    required this.area,
    required this.totalController,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final liters = area * 2 / 10;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Resumen',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _SummaryRow('Cliente', client),
                _SummaryRow('Obra', work),
                _SummaryRow('Trabajo', workType),
                _SummaryRow('Superficie', '${area.toStringAsFixed(1)} m²'),
                _SummaryRow(
                  'Pintura aprox.',
                  '${liters.toStringAsFixed(1)} L',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: totalController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Total del presupuesto',
            prefixText: '\$ ',
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onFinish,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Finalizar presupuesto'),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}


class BudgetPreviewScreen extends StatelessWidget {
  final String number;
  final String client;
  final String total;

  const BudgetPreviewScreen({
    super.key,
    required this.number,
    required this.client,
    required this.total,
  });

  Future<Uint8List> _buildPdf() async {
    final pdf = pw.Document();
    final blue = PdfColor.fromHex('#1677FF');
    final lightBlue = PdfColor.fromHex('#EAF3FF');
    final grey = PdfColor.fromHex('#5B6573');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 42,
                height: 42,
                decoration: pw.BoxDecoration(
                  color: blue,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'P',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PintaM2',
                    style: pw.TextStyle(
                      color: blue,
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'PRESUPUESTO',
                    style: pw.TextStyle(
                      color: grey,
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'N.o $number',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _pdfDate(),
                    style: pw.TextStyle(color: grey, fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Divider(color: blue, thickness: 1.4),
          pw.SizedBox(height: 12),

          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: lightBlue,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: _pdfInfoBlock('CLIENTE', client),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: _pdfInfoBlock(
                    'OBRA',
                    'Casa Barrio Dalvian',
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),
          _pdfSectionTitle('TRABAJOS A REALIZAR', blue),
          pw.SizedBox(height: 8),
          _pdfBullet('Proteccion de pisos y muebles.'),
          _pdfBullet('Tapado de pequenas imperfecciones.'),
          _pdfBullet('Lijado donde sea necesario.'),
          _pdfBullet('Aplicacion de 2 manos de pintura latex.'),
          _pdfBullet('Limpieza final de la obra.'),

          pw.SizedBox(height: 18),
          _pdfSectionTitle('MATERIALES APROXIMADOS', blue),
          pw.SizedBox(height: 8),
          _pdfBullet('Pintura latex.'),
          _pdfBullet('Enduido.'),
          _pdfBullet('Lijas.'),
          _pdfBullet('Cinta de papel.'),

          pw.SizedBox(height: 18),
          _pdfSectionTitle('ACLARACIONES', blue),
          pw.SizedBox(height: 8),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#D9E1EA')),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Los materiales seran provistos por el cliente.',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Todo trabajo que se realice fuera de este presupuesto se cobrara aparte.',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 22),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
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
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Spacer(),
                pw.Text(
                  total,
                  style: pw.TextStyle(
                    color: blue,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 22),
          pw.Text(
            'Presupuesto valido por 15 dias.',
            style: pw.TextStyle(
              color: grey,
              fontSize: 9,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Gracias por confiar en nuestro trabajo.',
            style: pw.TextStyle(
              color: grey,
              fontSize: 9,
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Text(
              'Generado con PintaM2',
              style: pw.TextStyle(
                color: PdfColor.fromHex('#A8B3C2'),
                fontSize: 8,
              ),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pdfInfoBlock(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 8,
            color: PdfColor.fromHex('#5B6573'),
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static pw.Widget _pdfSectionTitle(String text, PdfColor color) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  static pw.Widget _pdfBullet(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('-  ', style: const pw.TextStyle(fontSize: 10)),
          pw.Expanded(
            child: pw.Text(
              text,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  static String _pdfDate() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(now.day)}/${two(now.month)}/${now.year}';
  }

  String get _fileName {
    final safe = number.replaceAll(RegExp(r'[^0-9A-Za-z_-]'), '_');
    return 'PintaM2_Presupuesto_$safe.pdf';
  }

  Future<void> _sharePdf(BuildContext context) async {
    try {
      final bytes = await _buildPdf();
      await Printing.sharePdf(
        bytes: bytes,
        filename: _fileName,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo compartir el PDF: $e')),
      );
    }
  }

  Future<void> _printPdf(BuildContext context) async {
    try {
      await Printing.layoutPdf(
        name: _fileName,
        onLayout: (_) => _buildPdf(),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir la impresion: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuesto'),
        actions: [
          IconButton(
            tooltip: 'Compartir',
            onPressed: () => _sharePdf(context),
            icon: const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfPreview(
              build: (_) => _buildPdf(),
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              pdfFileName: _fileName,
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
                      onPressed: () => _printPdf(context),
                      icon: const Icon(Icons.print_outlined),
                      label: const Text('Guardar / imprimir'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _sharePdf(context),
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Enviar por WhatsApp'),
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
