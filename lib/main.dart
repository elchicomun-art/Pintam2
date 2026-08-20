import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

VoidCallback? pintaGoHome;

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
  String dni;
  String cuil;
  List<String> works;

  ClientData({
    required this.id,
    required this.name,
    this.address = '',
    this.phone = '',
    this.dni = '',
    this.cuil = '',
    List<String>? works,
  }) : works = works ?? [];

  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'address': address, 'phone': phone,
        'dni': dni, 'cuil': cuil, 'works': works,
      };

  factory ClientData.fromJson(Map<String, dynamic> json) {
    final address = (json['address'] ?? '').toString();
    final raw = json['works'];
    final works = raw is List ? raw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList() : <String>[];
    if (works.isEmpty && address.trim().isNotEmpty) works.add(address.trim());
    return ClientData(
      id: (json['id'] ?? '').toString(), name: (json['name'] ?? '').toString(),
      address: address, phone: (json['phone'] ?? '').toString(),
      dni: (json['dni'] ?? '').toString(), cuil: (json['cuil'] ?? '').toString(), works: works,
    );
  }
}

class ColorData {
  String id;
  String clientId;
  String workName;
  String sector;
  String name;
  String code;
  String preparation;
  String notes;

  ColorData({
    required this.id, required this.clientId, this.workName = '', this.sector = '',
    required this.name, this.code = '', this.preparation = '', this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id, 'clientId': clientId, 'workName': workName, 'sector': sector,
        'name': name, 'code': code, 'preparation': preparation, 'notes': notes,
      };

  factory ColorData.fromJson(Map<String, dynamic> json) => ColorData(
        id: (json['id'] ?? '').toString(), clientId: (json['clientId'] ?? '').toString(),
        workName: (json['workName'] ?? '').toString(), sector: (json['sector'] ?? '').toString(),
        name: (json['name'] ?? '').toString(), code: (json['code'] ?? '').toString(),
        preparation: (json['preparation'] ?? '').toString(), notes: (json['notes'] ?? '').toString(),
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

class AppointmentData {
  String id;
  String title;
  String client;
  String notes;
  String dateTime;
  bool reminder;

  AppointmentData({required this.id, required this.title, this.client = '', this.notes = '', required this.dateTime, this.reminder = false});
  Map<String,dynamic> toJson()=>{'id':id,'title':title,'client':client,'notes':notes,'dateTime':dateTime,'reminder':reminder};
  factory AppointmentData.fromJson(Map<String,dynamic> j)=>AppointmentData(
    id:(j['id']??'').toString(), title:(j['title']??'').toString(), client:(j['client']??'').toString(), notes:(j['notes']??'').toString(),
    dateTime:(j['dateTime']??DateTime.now().toIso8601String()).toString(), reminder:j['reminder']??false);
}

class TrashData {
  String id;
  String type;
  String label;
  String deletedAt;
  Map<String,dynamic> payload;
  TrashData({required this.id,required this.type,required this.label,required this.deletedAt,required this.payload});
  Map<String,dynamic> toJson()=>{'id':id,'type':type,'label':label,'deletedAt':deletedAt,'payload':payload};
  factory TrashData.fromJson(Map<String,dynamic> j)=>TrashData(
    id:(j['id']??'').toString(),type:(j['type']??'').toString(),label:(j['label']??'').toString(),deletedAt:(j['deletedAt']??DateTime.now().toIso8601String()).toString(),payload:Map<String,dynamic>.from(j['payload']??const{}));
}

class AppStore extends ChangeNotifier {
  AppStore._();
  static final AppStore instance = AppStore._();

  static const _setupKey='pintam2_setup_v07', _profileKey='pintam2_profile_v07', _clientsKey='pintam2_clients_v07', _colorsKey='pintam2_colors_v07', _budgetsKey='pintam2_budgets_v07';
  static const _appointmentsKey='pintam2_appointments_v010', _trashKey='pintam2_trash_v010', _phrasesKey='pintam2_phrases_v010', _draftKey='pintam2_budget_draft_v010';

  bool setupDone=false;
  UserProfile profile=UserProfile();
  final List<ClientData> clients=[];
  final List<ColorData> colors=[];
  final List<BudgetData> budgets=[];
  final List<AppointmentData> appointments=[];
  final List<TrashData> trash=[];
  List<String> budgetPhrases=[
    'Este presupuesto es válido por 15 días a partir de la fecha.',
    'Todo trabajo extra fuera del presupuesto se cobrará aparte.',
    'Los materiales serán provistos por el cliente, salvo aclaración.',
  ];
  Map<String,dynamic>? budgetDraft;

  Future<void> load() async {
    final sp=await SharedPreferences.getInstance(); setupDone=sp.getBool(_setupKey)??false;
    try{final r=sp.getString(_profileKey);if(r!=null)profile=UserProfile.fromJson(Map<String,dynamic>.from(jsonDecode(r)));}catch(_){}
    try{final r=sp.getString(_clientsKey);if(r!=null){clients..clear()..addAll((jsonDecode(r)as List).map((e)=>ClientData.fromJson(Map<String,dynamic>.from(e))));}}catch(_){}
    try{final r=sp.getString(_colorsKey);if(r!=null){colors..clear()..addAll((jsonDecode(r)as List).map((e)=>ColorData.fromJson(Map<String,dynamic>.from(e))));}}catch(_){}
    try{final r=sp.getString(_budgetsKey);if(r!=null){budgets..clear()..addAll((jsonDecode(r)as List).map((e)=>BudgetData.fromJson(Map<String,dynamic>.from(e))));}}catch(_){}
    try{final r=sp.getString(_appointmentsKey);if(r!=null){appointments..clear()..addAll((jsonDecode(r)as List).map((e)=>AppointmentData.fromJson(Map<String,dynamic>.from(e))));}}catch(_){}
    try{final r=sp.getString(_trashKey);if(r!=null){trash..clear()..addAll((jsonDecode(r)as List).map((e)=>TrashData.fromJson(Map<String,dynamic>.from(e))));}}catch(_){}
    try{final r=sp.getString(_phrasesKey);if(r!=null){final x=(jsonDecode(r)as List).map((e)=>e.toString()).toList();if(x.isNotEmpty)budgetPhrases=x;}}catch(_){}
    try{final r=sp.getString(_draftKey);if(r!=null)budgetDraft=Map<String,dynamic>.from(jsonDecode(r));}catch(_){}
    await cleanExpiredTrash();
  }

  Future<void> save() async {
    final sp=await SharedPreferences.getInstance();
    await sp.setBool(_setupKey,setupDone); await sp.setString(_profileKey,jsonEncode(profile.toJson()));
    await sp.setString(_clientsKey,jsonEncode(clients.map((e)=>e.toJson()).toList())); await sp.setString(_colorsKey,jsonEncode(colors.map((e)=>e.toJson()).toList()));
    await sp.setString(_budgetsKey,jsonEncode(budgets.map((e)=>e.toJson()).toList())); await sp.setString(_appointmentsKey,jsonEncode(appointments.map((e)=>e.toJson()).toList()));
    await sp.setString(_trashKey,jsonEncode(trash.map((e)=>e.toJson()).toList())); await sp.setString(_phrasesKey,jsonEncode(budgetPhrases)); notifyListeners();
  }

  Future<void> saveBudgetDraft(Map<String,dynamic> d)async{budgetDraft=d;final sp=await SharedPreferences.getInstance();await sp.setString(_draftKey,jsonEncode(d));}
  Future<void> clearBudgetDraft()async{budgetDraft=null;final sp=await SharedPreferences.getInstance();await sp.remove(_draftKey);}
  String nextBudgetNumber(){final y=DateTime.now().year;return '$y-${(budgets.length+1).toString().padLeft(4,'0')}';}
  Future<void> upsertBudget(BudgetData b)async{final i=budgets.indexWhere((x)=>x.id==b.id);if(i>=0)budgets[i]=b;else budgets.insert(0,b);await save();}

  Future<void> moveBudgetToTrash(BudgetData b)async{budgets.removeWhere((x)=>x.id==b.id);trash.add(TrashData(id:DateTime.now().microsecondsSinceEpoch.toString(),type:'budget',label:'Presupuesto ${b.number} · ${b.clientName}',deletedAt:DateTime.now().toIso8601String(),payload:b.toJson()));await save();}
  Future<void> moveClientToTrash(ClientData c)async{clients.removeWhere((x)=>x.id==c.id);trash.add(TrashData(id:DateTime.now().microsecondsSinceEpoch.toString(),type:'client',label:'Cliente ${c.name}',deletedAt:DateTime.now().toIso8601String(),payload:c.toJson()));await save();}
  Future<void> moveColorToTrash(ColorData c)async{colors.removeWhere((x)=>x.id==c.id);trash.add(TrashData(id:DateTime.now().microsecondsSinceEpoch.toString(),type:'color',label:'Color ${c.name.isEmpty?c.code:c.name}',deletedAt:DateTime.now().toIso8601String(),payload:c.toJson()));await save();}
  Future<void> moveAppointmentToTrash(AppointmentData a)async{appointments.removeWhere((x)=>x.id==a.id);trash.add(TrashData(id:DateTime.now().microsecondsSinceEpoch.toString(),type:'appointment',label:'Turno ${a.title}',deletedAt:DateTime.now().toIso8601String(),payload:a.toJson()));await save();}

  Future<void> restoreTrash(TrashData t)async{if(t.type=='budget')budgets.insert(0,BudgetData.fromJson(t.payload));if(t.type=='client')clients.add(ClientData.fromJson(t.payload));if(t.type=='color')colors.add(ColorData.fromJson(t.payload));if(t.type=='appointment')appointments.add(AppointmentData.fromJson(t.payload));trash.removeWhere((x)=>x.id==t.id);await save();}
  Future<void> permanentlyDeleteTrash(TrashData t)async{trash.removeWhere((x)=>x.id==t.id);if(t.type=='client'){final id=(t.payload['id']??'').toString();colors.removeWhere((c)=>c.clientId==id);}await save();}
  Future<void> emptyTrash()async{for(final t in List<TrashData>.from(trash)){if(t.type=='client'){final id=(t.payload['id']??'').toString();colors.removeWhere((c)=>c.clientId==id);}}trash.clear();await save();}
  Future<void> cleanExpiredTrash()async{final limit=DateTime.now().subtract(const Duration(days:7));final expired=trash.where((t){final d=DateTime.tryParse(t.deletedAt);return d!=null&&d.isBefore(limit);}).toList();if(expired.isEmpty)return;for(final t in expired){if(t.type=='client'){final id=(t.payload['id']??'').toString();colors.removeWhere((c)=>c.clientId==id);}trash.removeWhere((x)=>x.id==t.id);}await save();}

  String backupJson()=>jsonEncode({'version':10,'profile':profile.toJson(),'clients':clients.map((e)=>e.toJson()).toList(),'colors':colors.map((e)=>e.toJson()).toList(),'budgets':budgets.map((e)=>e.toJson()).toList(),'appointments':appointments.map((e)=>e.toJson()).toList(),'phrases':budgetPhrases,'trash':trash.map((e)=>e.toJson()).toList()});
  Future<void> restoreBackup(String raw)async{final d=Map<String,dynamic>.from(jsonDecode(raw));if(d['profile']is Map)profile=UserProfile.fromJson(Map<String,dynamic>.from(d['profile']));clients..clear()..addAll(((d['clients']as List?)??const[]).map((e)=>ClientData.fromJson(Map<String,dynamic>.from(e))));colors..clear()..addAll(((d['colors']as List?)??const[]).map((e)=>ColorData.fromJson(Map<String,dynamic>.from(e))));budgets..clear()..addAll(((d['budgets']as List?)??const[]).map((e)=>BudgetData.fromJson(Map<String,dynamic>.from(e))));appointments..clear()..addAll(((d['appointments']as List?)??const[]).map((e)=>AppointmentData.fromJson(Map<String,dynamic>.from(e))));if(d['phrases']is List)budgetPhrases=(d['phrases']as List).map((e)=>e.toString()).toList();trash..clear()..addAll(((d['trash']as List?)??const[]).map((e)=>TrashData.fromJson(Map<String,dynamic>.from(e))));setupDone=true;await save();}
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
      locale: const Locale('es', 'AR'),
      supportedLocales: const [
        Locale('es', 'AR'),
        Locale('es'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
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
  @override State<MainShell> createState()=>_MainShellState();
}
class _MainShellState extends State<MainShell>{
  int index=0; DateTime? lastBack;
  @override void initState(){super.initState();pintaGoHome=(){if(mounted)setState(()=>index=0);};}
  @override void dispose(){pintaGoHome=null;super.dispose();}
  @override Widget build(BuildContext context)=>PopScope(canPop:false,onPopInvokedWithResult:(didPop,result){if(didPop)return;if(index!=0){setState(()=>index=0);return;}final n=DateTime.now();if(lastBack!=null&&n.difference(lastBack!)<const Duration(seconds:2)){SystemNavigator.pop();}else{lastBack=n;ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Presioná atrás otra vez para salir de PintaM²')));}},child:Scaffold(
    body:IndexedStack(index:index,children:[HomeScreen(onTab:(i)=>setState(()=>index=i)),const ClientsScreen(),const BudgetsScreen(),MoreScreen(onThemeChanged:widget.onThemeChanged)]),
    bottomNavigationBar:NavigationBar(selectedIndex:index,onDestinationSelected:(i)=>setState(()=>index=i),destinations:const[
      NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'Inicio'),NavigationDestination(icon:Icon(Icons.people_outline),selectedIcon:Icon(Icons.people),label:'Clientes'),NavigationDestination(icon:Icon(Icons.description_outlined),selectedIcon:Icon(Icons.description),label:'Presupuestos'),NavigationDestination(icon:Icon(Icons.more_horiz),label:'Más')]),));
}

class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return AppBar(
      toolbarHeight: 76,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: -0.15,
            child: Icon(Icons.format_paint_rounded, size: 31, color: primary),
          ),
          const SizedBox(width: 2),
          Text(
            'P',
            style: TextStyle(
              fontSize: 32,
              height: 1,
              fontWeight: FontWeight.w900,
              color: primary,
            ),
          ),
          Text(
            'intaM²',
            style: TextStyle(
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: .2,
              color: primary,
            ),
          ),
          const SizedBox(width: 2),
          Transform.rotate(
            angle: 0.10,
            child: Icon(Icons.brush_rounded, size: 24, color: primary),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget{
  final ValueChanged<int> onTab; const HomeScreen({super.key,required this.onTab});
  @override Widget build(BuildContext context){final s=AppStore.instance;return AnimatedBuilder(animation:s,builder:(_,__) {final pending=s.budgets.where((b)=>b.status=='Pendiente').length;final now=DateTime.now();final upcoming=s.appointments.where((a){final d=DateTime.tryParse(a.dateTime);return d!=null&&d.isAfter(now)&&d.isBefore(now.add(const Duration(days:7)));}).length;return Scaffold(appBar:const BrandAppBar(),body:ListView(padding:const EdgeInsets.all(20),children:[
    Text(s.profile.userName.isEmpty?'¡Buen día! 👋':'¡Buen día, ${s.profile.userName}! 👋',style:const TextStyle(fontSize:24,fontWeight:FontWeight.w800)),const SizedBox(height:18),
    FilledButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const BudgetFlow())),icon:const Icon(Icons.add),label:const Text('Nuevo presupuesto'),style:FilledButton.styleFrom(minimumSize:const Size.fromHeight(58))),const SizedBox(height:14),
    _HomeCard(Icons.people_outline,'Clientes','${s.clients.length} registrados',()=>onTab(1)),_HomeCard(Icons.description_outlined,'Presupuestos','$pending pendientes de ${s.budgets.length}',()=>onTab(2)),
    _HomeCard(Icons.palette_outlined,'Colores / códigos','${s.colors.length} guardados',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ColorsScreen()))),
    _HomeCard(Icons.calculate_outlined,'Calculadora','Sectores, paredes y calculadora rápida',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AdvancedCalculatorScreen()))),
    _HomeCard(Icons.history_outlined,'Historial','Estados y ganancias por mes',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const HistoryScreen()))),
    _HomeCard(Icons.calendar_month_outlined,'Turnos, calendario y recordatorios','$upcoming próximos 7 días',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const CalendarScreen()))),
    _HomeCard(Icons.delete_outline,'Papelera','${s.trash.length} elementos · 7 días',()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const TrashScreen()))),]));});}
}
class _HomeCard extends StatelessWidget{final IconData icon;final String title,subtitle;final VoidCallback tap;const _HomeCard(this.icon,this.title,this.subtitle,this.tap);@override Widget build(BuildContext context)=>Card(child:ListTile(onTap:tap,leading:Icon(icon,color:Theme.of(context).colorScheme.primary),title:Text(title,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text(subtitle),trailing:const Icon(Icons.chevron_right)));}

class ClientsScreen extends StatefulWidget{
  const ClientsScreen({super.key}); @override State<ClientsScreen> createState()=>_ClientsScreenState();
  static void editClient(BuildContext context,{ClientData? client})=>_ClientsScreenState.showEditor(context,client:client);
}
class _ClientsScreenState extends State<ClientsScreen>{String q='';
  @override Widget build(BuildContext context){final s=AppStore.instance;return AnimatedBuilder(animation:s,builder:(_,__){final x=q.trim().toLowerCase();final list=s.clients.where((c)=>x.isEmpty||c.name.toLowerCase().contains(x)||c.phone.contains(x)||c.dni.contains(x)||c.cuil.contains(x)||c.works.any((w)=>w.toLowerCase().contains(x))).toList();return Scaffold(appBar:const BrandAppBar(),floatingActionButton:FloatingActionButton.extended(onPressed:()=>showEditor(context),icon:const Icon(Icons.person_add),label:const Text('Nuevo cliente')),body:ListView(padding:const EdgeInsets.fromLTRB(20,20,20,100),children:[TextField(onChanged:(v)=>setState(()=>q=v),decoration:const InputDecoration(hintText:'Buscar cliente...',prefixIcon:Icon(Icons.search))),const SizedBox(height:14),if(list.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(22),child:Text('No hay clientes para mostrar.'))),...list.map((c)=>Card(child:ListTile(leading:CircleAvatar(child:Text(c.name.isEmpty?'?':c.name[0].toUpperCase())),title:Text(c.name,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text(c.works.isEmpty?'Sin trabajos guardados':'${c.works.length} trabajo${c.works.length==1?'':'s'}'),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ClientDetailScreen(clientId:c.id))))))]));});}

  static Future<void> pickContact(
    BuildContext context,
    TextEditingController n,
    TextEditingController p,
  ) async {
    try {
      final status = await FlutterContacts.permissions.request(PermissionType.readWrite);
      final allowed =
          status == PermissionStatus.granted || status == PermissionStatus.limited;

      if (!allowed) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('PintaM² necesita permiso para leer la agenda.'),
              action: SnackBarAction(
                label: 'Ajustes',
                onPressed: () => FlutterContacts.permissions.openSettings(),
              ),
            ),
          );
        }
        return;
      }

      Contact? selected = await FlutterContacts.native.showPicker(
        properties: {ContactProperty.name, ContactProperty.phone},
      );
      if (selected == null) return;

      if (selected.phones.isEmpty && selected.id != null) {
        selected = await FlutterContacts.get(
          selected.id!,
          properties: {ContactProperty.name, ContactProperty.phone},
        );
      }
      if (selected == null) return;

      if ((selected.displayName ?? '').trim().isNotEmpty) {
        n.text = selected.displayName!.trim();
      }
      if (selected.phones.isNotEmpty) {
        p.text = selected.phones.first.number.trim();
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El contacto elegido no tiene número guardado.')),
        );
      }
    } on PlatformException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir la agenda: ${e.message ?? e.code}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo seleccionar el contacto.')),
        );
      }
    }
  }
  static void showEditor(BuildContext context,{ClientData? client}){final n=TextEditingController(text:client?.name??''),p=TextEditingController(text:client?.phone??''),dni=TextEditingController(text:client?.dni??''),cuil=TextEditingController(text:client?.cuil??''),work=TextEditingController(text:client==null?'':(client.works.isNotEmpty?client.works.first:client.address));showModalBottomSheet(context:context,isScrollControlled:true,showDragHandle:true,builder:(ctx)=>Padding(padding:EdgeInsets.fromLTRB(20,10,20,20+MediaQuery.of(ctx).viewInsets.bottom),child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[Text(client==null?'Nuevo cliente':'Editar cliente',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800)),const SizedBox(height:14),TextField(controller:n,decoration:const InputDecoration(labelText:'Nombre')),const SizedBox(height:10),TextField(controller:p,keyboardType:TextInputType.phone,decoration:InputDecoration(labelText:'Teléfono',suffixIcon:IconButton(onPressed:()=>pickContact(ctx,n,p),icon:const Icon(Icons.contacts_outlined),tooltip:'Elegir desde agenda'))),const SizedBox(height:10),TextField(controller:dni,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'DNI')),const SizedBox(height:10),TextField(controller:cuil,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'CUIL')),const SizedBox(height:10),TextField(controller:work,decoration:const InputDecoration(labelText:'Primer trabajo / lugar',hintText:'Casa, oficinas, local...')),const SizedBox(height:16),FilledButton(onPressed:()async{if(n.text.trim().isEmpty)return;final s=AppStore.instance;if(client==null){final w=work.text.trim();s.clients.add(ClientData(id:DateTime.now().microsecondsSinceEpoch.toString(),name:n.text.trim(),phone:p.text.trim(),dni:dni.text.trim(),cuil:cuil.text.trim(),address:w,works:w.isEmpty?[]:[w]));}else{client.name=n.text.trim();client.phone=p.text.trim();client.dni=dni.text.trim();client.cuil=cuil.text.trim();final w=work.text.trim();if(client.works.isEmpty&&w.isNotEmpty)client.works.add(w);else if(client.works.isNotEmpty&&w.isNotEmpty)client.works[0]=w;client.address=client.works.isEmpty?'':client.works.first;}await s.save();if(ctx.mounted)Navigator.pop(ctx);},child:const Text('Guardar'))]))));}
}

class ClientDetailScreen extends StatelessWidget{final String clientId;const ClientDetailScreen({super.key,required this.clientId});
  @override Widget build(BuildContext context){final s=AppStore.instance;return AnimatedBuilder(animation:s,builder:(_,__){final c=s.clients.where((x)=>x.id==clientId).cast<ClientData?>().firstOrNull;if(c==null)return Scaffold(appBar:AppBar(),body:const Center(child:Text('Cliente eliminado')));return Scaffold(appBar:AppBar(title:Text(c.name),actions:[IconButton(onPressed:()=>ClientsScreen.editClient(context,client:c),icon:const Icon(Icons.edit_outlined)),IconButton(onPressed:()async{final ok=await showDialog<bool>(context:context,builder:(d)=>AlertDialog(title:const Text('Enviar a papelera'),content:Text('¿Mover a ${c.name} a la papelera?'),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('Mover'))]));if(ok==true){await s.moveClientToTrash(c);if(context.mounted)Navigator.pop(context);}},icon:const Icon(Icons.delete_outline))]),floatingActionButton:FloatingActionButton.extended(onPressed:()async{final t=TextEditingController();final v=await showDialog<String>(context:context,builder:(d)=>AlertDialog(title:const Text('Agregar trabajo / lugar'),content:TextField(controller:t,decoration:const InputDecoration(labelText:'Casa, oficinas, quincho...')),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(d,t.text.trim()),child:const Text('Agregar'))]));if(v!=null&&v.isNotEmpty){c.works.add(v);c.address=c.works.first;await s.save();}},icon:const Icon(Icons.add_home_work_outlined),label:const Text('Agregar trabajo')),body:ListView(padding:const EdgeInsets.fromLTRB(20,20,20,100),children:[if(c.phone.isNotEmpty)ListTile(leading:const Icon(Icons.phone_outlined),title:Text(c.phone)),if(c.dni.isNotEmpty)ListTile(leading:const Icon(Icons.badge_outlined),title:Text('DNI ${c.dni}')),if(c.cuil.isNotEmpty)ListTile(leading:const Icon(Icons.receipt_long_outlined),title:Text('CUIL ${c.cuil}')),const SizedBox(height:10),const Text('Trabajos / lugares',style:TextStyle(fontSize:20,fontWeight:FontWeight.w800)),...c.works.map((w){final count=s.colors.where((x)=>x.clientId==c.id&&(x.workName==w||(x.workName.isEmpty&&c.works.first==w))).length;return Card(child:ListTile(leading:const Icon(Icons.home_work_outlined),title:Text(w,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text('$count colores/códigos'),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>WorkColorScreen(clientId:c.id,workName:w)))));})]));});}
}

class WorkColorScreen extends StatelessWidget{final String clientId,workName;const WorkColorScreen({super.key,required this.clientId,required this.workName});
  @override Widget build(BuildContext context){final s=AppStore.instance;return AnimatedBuilder(animation:s,builder:(_,__){final c=s.clients.where((x)=>x.id==clientId).cast<ClientData?>().firstOrNull;final legacyFirst=c!=null&&c.works.isNotEmpty&&c.works.first==workName;final list=s.colors.where((x)=>x.clientId==clientId&&(x.workName==workName||(legacyFirst&&x.workName.isEmpty))).toList();return Scaffold(appBar:AppBar(title:Text(workName)),floatingActionButton:FloatingActionButton.extended(onPressed:()=>editColor(context,clientId:clientId,workName:workName),icon:const Icon(Icons.add),label:const Text('Agregar color')),body:ListView(padding:const EdgeInsets.fromLTRB(20,20,20,100),children:[if(c!=null)Text(c.name,style:TextStyle(color:Theme.of(context).colorScheme.primary,fontWeight:FontWeight.w800)),const SizedBox(height:10),if(list.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(22),child:Text('No hay colores guardados para este trabajo.'))),...list.map((x)=>Card(child:ListTile(leading:const Icon(Icons.palette_outlined),title:Text(x.name.isEmpty?x.code:x.name,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text([if(x.sector.isNotEmpty)'Sector: ${x.sector}',if(x.code.isNotEmpty)'Código: ${x.code}',if(x.preparation.isNotEmpty)x.preparation].join('\n')),onTap:()=>editColor(context,clientId:clientId,workName:workName,color:x))))]));});}
}

void editColor(BuildContext context,{required String clientId,required String workName,ColorData? color}){final sector=TextEditingController(text:color?.sector??''),n=TextEditingController(text:color?.name??''),cc=TextEditingController(text:color?.code??''),prep=TextEditingController(text:color?.preparation??''),notes=TextEditingController(text:color?.notes??'');showModalBottomSheet(context:context,isScrollControlled:true,showDragHandle:true,builder:(ctx)=>Padding(padding:EdgeInsets.fromLTRB(20,10,20,20+MediaQuery.of(ctx).viewInsets.bottom),child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[Text(color==null?'Nuevo color':'Editar color',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800)),const SizedBox(height:12),TextField(controller:sector,decoration:const InputDecoration(labelText:'Sector')),const SizedBox(height:8),TextField(controller:n,decoration:const InputDecoration(labelText:'Nombre del color')),const SizedBox(height:8),TextField(controller:cc,decoration:const InputDecoration(labelText:'Código')),const SizedBox(height:8),TextField(controller:prep,minLines:3,maxLines:6,decoration:const InputDecoration(labelText:'Preparación / fórmula')),const SizedBox(height:8),TextField(controller:notes,minLines:2,maxLines:4,decoration:const InputDecoration(labelText:'Observaciones')),const SizedBox(height:14),FilledButton(onPressed:()async{if(n.text.trim().isEmpty&&cc.text.trim().isEmpty)return;final s=AppStore.instance;if(color==null)s.colors.add(ColorData(id:DateTime.now().microsecondsSinceEpoch.toString(),clientId:clientId,workName:workName,sector:sector.text.trim(),name:n.text.trim(),code:cc.text.trim(),preparation:prep.text.trim(),notes:notes.text.trim()));else{color.workName=workName;color.sector=sector.text.trim();color.name=n.text.trim();color.code=cc.text.trim();color.preparation=prep.text.trim();color.notes=notes.text.trim();}await s.save();if(ctx.mounted)Navigator.pop(ctx);},child:const Text('Guardar color')),if(color!=null)TextButton.icon(onPressed:()async{await AppStore.instance.moveColorToTrash(color);if(ctx.mounted)Navigator.pop(ctx);},icon:const Icon(Icons.delete_outline),label:const Text('Mover a papelera'))]))));}

class ColorsScreen extends StatefulWidget{const ColorsScreen({super.key});@override State<ColorsScreen> createState()=>_ColorsScreenState();}
class _ColorsScreenState extends State<ColorsScreen>{String q='';@override Widget build(BuildContext context){final s=AppStore.instance;return AnimatedBuilder(animation:s,builder:(_,__){final x=q.trim().toLowerCase();final list=s.clients.where((c)=>x.isEmpty||c.name.toLowerCase().contains(x)).toList();return Scaffold(appBar:AppBar(title:const Text('Colores / códigos')),body:ListView(padding:const EdgeInsets.all(20),children:[TextField(onChanged:(v)=>setState(()=>q=v),decoration:const InputDecoration(hintText:'Buscar cliente...',prefixIcon:Icon(Icons.search))),const SizedBox(height:14),...list.map((c)=>Card(child:ListTile(leading:const Icon(Icons.person_outline),title:Text(c.name,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text('${c.works.length} trabajos'),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ClientWorksForColorsScreen(clientId:c.id))))))]));});}}
class ClientWorksForColorsScreen extends StatelessWidget{final String clientId;const ClientWorksForColorsScreen({super.key,required this.clientId});@override Widget build(BuildContext context){final s=AppStore.instance;final c=s.clients.where((x)=>x.id==clientId).cast<ClientData?>().firstOrNull;return Scaffold(appBar:AppBar(title:Text(c?.name??'Trabajos')),body:c==null?const Center(child:Text('Cliente no disponible')):ListView(padding:const EdgeInsets.all(20),children:[if(c.works.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(20),child:Text('Este cliente no tiene trabajos guardados.'))),...c.works.map((w)=>Card(child:ListTile(leading:const Icon(Icons.home_work_outlined),title:Text(w),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>WorkColorScreen(clientId:c.id,workName:w))))))]));}}

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

class TraditionalCalculatorScreen extends StatefulWidget {
  const TraditionalCalculatorScreen({super.key});
  @override
  State<TraditionalCalculatorScreen> createState() => _TraditionalCalculatorScreenState();
}

class _TraditionalCalculatorScreenState extends State<TraditionalCalculatorScreen> {
  String display = '0';
  double? first;
  String? op;
  bool replace = true;

  void digit(String d) => setState(() {
        if (replace || display == '0') {
          display = d;
          replace = false;
        } else {
          display += d;
        }
      });

  void decimal() => setState(() {
        if (replace) {
          display = '0,';
          replace = false;
        } else if (!display.contains(',')) {
          display += ',';
        }
      });

  void operation(String value) {
    first = double.tryParse(display.replaceAll(',', '.')) ?? 0;
    op = value;
    setState(() => replace = true);
  }

  void clear() => setState(() {
        display = '0';
        first = null;
        op = null;
        replace = true;
      });

  void equals() {
    if (first == null || op == null) return;
    final second = double.tryParse(display.replaceAll(',', '.')) ?? 0;
    double result = second;
    if (op == '+') result = first! + second;
    if (op == '-') result = first! - second;
    if (op == '×') result = first! * second;
    if (op == '÷') result = second == 0 ? 0 : first! / second;
    setState(() {
      display = (result.truncateToDouble() == result
              ? result.toStringAsFixed(0)
              : result.toStringAsFixed(2))
          .replaceAll('.', ',');
      first = null;
      op = null;
      replace = true;
    });
  }

  Future<void> m2() async {
    final largo = TextEditingController();
    final alto = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('M² rápido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresá largo y alto. PintaM² hace la multiplicación.'),
            const SizedBox(height: 12),
            TextField(
              controller: largo,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Largo', suffixText: 'm'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: alto,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Alto', suffixText: 'm'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final l = double.tryParse(largo.text.replaceAll(',', '.')) ?? 0;
              final h = double.tryParse(alto.text.replaceAll(',', '.')) ?? 0;
              Navigator.pop(ctx, l * h);
            },
            child: const Text('Calcular m²'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        display = result.toStringAsFixed(2).replaceAll('.', ',');
        replace = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const keys = ['7','8','9','÷','4','5','6','×','1','2','3','-','0',',','=','+'];
    return Scaffold(
      appBar: AppBar(title: const Text('Calculadora')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SelectableText(
                      display,
                      style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: clear,
                      icon: const Icon(Icons.backspace_outlined),
                      label: const Text('Borrar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: m2,
                      icon: const Icon(Icons.square_foot),
                      label: const Text('M² rápido'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: keys.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (context, index) {
                  final key = keys[index];
                  final isOperator = ['÷', '×', '-', '+', '='].contains(key);
                  return FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if ('0123456789'.contains(key)) {
                        digit(key);
                      } else if (key == ',') {
                        decimal();
                      } else if (key == '=') {
                        equals();
                      } else {
                        operation(key);
                      }
                    },
                    child: Text(
                      key,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: isOperator ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
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
            Row(children:[const Expanded(child:Text('Medí pared por pared',style:TextStyle(fontSize:24,fontWeight:FontWeight.w800))),OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const TraditionalCalculatorScreen())),icon:const Icon(Icons.calculate_outlined),label:const Text('Calculadora'))]),
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

class CalendarScreen extends StatefulWidget{const CalendarScreen({super.key});@override State<CalendarScreen> createState()=>_CalendarScreenState();}
class _CalendarScreenState extends State<CalendarScreen>{DateTime selected=DateTime.now();bool same(DateTime a,DateTime b)=>a.year==b.year&&a.month==b.month&&a.day==b.day;@override Widget build(BuildContext context){final s=AppStore.instance;return AnimatedBuilder(animation:s,builder:(_,__){final list=s.appointments.where((a){final d=DateTime.tryParse(a.dateTime);return d!=null&&same(d,selected);}).toList()..sort((a,b)=>a.dateTime.compareTo(b.dateTime));return Scaffold(appBar:AppBar(title:const Text('Turnos y recordatorios')),floatingActionButton:FloatingActionButton.extended(onPressed:()=>editAppointment(context,initialDate:selected),icon:const Icon(Icons.add),label:const Text('Nuevo turno')),body:ListView(padding:const EdgeInsets.fromLTRB(16,12,16,100),children:[Card(child:CalendarDatePicker(initialDate:selected,firstDate:DateTime(2024),lastDate:DateTime(2035),onDateChanged:(d)=>setState(()=>selected=d))),const SizedBox(height:10),Text('Turnos del ${selected.day}/${selected.month}/${selected.year}',style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800)),if(list.isEmpty)const Card(child:Padding(padding:EdgeInsets.all(18),child:Text('No hay turnos para este día.'))),...list.map((a){final d=DateTime.tryParse(a.dateTime)!;return Card(child:ListTile(leading:Icon(a.reminder?Icons.notifications_active_outlined:Icons.event_outlined),title:Text(a.title),subtitle:Text('${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}${a.client.isEmpty?'':' · ${a.client}'}${a.reminder?' · recordatorio':''}'),trailing:const Icon(Icons.chevron_right),onTap:()=>editAppointment(context,appointment:a)));})]));});}}
Future<void> editAppointment(BuildContext context,{AppointmentData? appointment,DateTime? initialDate})async{final title=TextEditingController(text:appointment?.title??''),client=TextEditingController(text:appointment?.client??''),notes=TextEditingController(text:appointment?.notes??'');DateTime dt=DateTime.tryParse(appointment?.dateTime??'')??DateTime((initialDate??DateTime.now()).year,(initialDate??DateTime.now()).month,(initialDate??DateTime.now()).day,9);bool rem=appointment?.reminder??false;await showModalBottomSheet(context:context,isScrollControlled:true,showDragHandle:true,builder:(ctx)=>StatefulBuilder(builder:(ctx,setL)=>Padding(padding:EdgeInsets.fromLTRB(20,10,20,20+MediaQuery.of(ctx).viewInsets.bottom),child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[Text(appointment==null?'Nuevo turno':'Editar turno',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800)),const SizedBox(height:12),TextField(controller:title,decoration:const InputDecoration(labelText:'Título')),const SizedBox(height:8),TextField(controller:client,decoration:const InputDecoration(labelText:'Cliente (opcional)')),ListTile(leading:const Icon(Icons.calendar_today_outlined),title:Text('${dt.day}/${dt.month}/${dt.year}'),onTap:()async{final d=await showDatePicker(context:ctx,firstDate:DateTime(2024),lastDate:DateTime(2035),initialDate:dt);if(d!=null)setL(()=>dt=DateTime(d.year,d.month,d.day,dt.hour,dt.minute));}),ListTile(leading:const Icon(Icons.access_time),title:Text('${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}'),onTap:()async{final t=await showTimePicker(context:ctx,initialTime:TimeOfDay.fromDateTime(dt));if(t!=null)setL(()=>dt=DateTime(dt.year,dt.month,dt.day,t.hour,t.minute));}),SwitchListTile(value:rem,onChanged:(v)=>setL(()=>rem=v),title:const Text('Recordatorio'),subtitle:const Text('Queda marcado dentro de PintaM²')),TextField(controller:notes,minLines:2,maxLines:5,decoration:const InputDecoration(labelText:'Notas')),const SizedBox(height:12),FilledButton(onPressed:()async{if(title.text.trim().isEmpty)return;final s=AppStore.instance;if(appointment==null)s.appointments.add(AppointmentData(id:DateTime.now().microsecondsSinceEpoch.toString(),title:title.text.trim(),client:client.text.trim(),notes:notes.text.trim(),dateTime:dt.toIso8601String(),reminder:rem));else{appointment.title=title.text.trim();appointment.client=client.text.trim();appointment.notes=notes.text.trim();appointment.dateTime=dt.toIso8601String();appointment.reminder=rem;}await s.save();if(ctx.mounted)Navigator.pop(ctx);},child:const Text('Guardar turno')),if(appointment!=null)TextButton.icon(onPressed:()async{await AppStore.instance.moveAppointmentToTrash(appointment);if(ctx.mounted)Navigator.pop(ctx);},icon:const Icon(Icons.delete_outline),label:const Text('Mover a papelera'))])))));}

class TrashScreen extends StatelessWidget{const TrashScreen({super.key});@override Widget build(BuildContext context){final s=AppStore.instance;return AnimatedBuilder(animation:s,builder:(_,__)=>(Scaffold(appBar:AppBar(title:const Text('Papelera'),actions:[TextButton(onPressed:s.trash.isEmpty?null:()async{final ok=await showDialog<bool>(context:context,builder:(d)=>AlertDialog(title:const Text('Vaciar papelera'),content:const Text('Se eliminará todo definitivamente.'),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('Vaciar'))]));if(ok==true)await s.emptyTrash();},child:const Text('Vaciar'))]),body:s.trash.isEmpty?const Center(child:Text('La papelera está vacía.')):ListView(padding:const EdgeInsets.all(20),children:s.trash.map((t){final d=DateTime.tryParse(t.deletedAt)??DateTime.now();final days=(7-DateTime.now().difference(d).inDays).clamp(0,7);return Card(child:ListTile(leading:const Icon(Icons.delete_outline),title:Text(t.label),subtitle:Text('Se elimina en $days días'),trailing:PopupMenuButton<String>(onSelected:(v)async{if(v=='restore')await s.restoreTrash(t);if(v=='delete')await s.permanentlyDeleteTrash(t);},itemBuilder:(_)=>const[PopupMenuItem(value:'restore',child:Text('Restaurar')),PopupMenuItem(value:'delete',child:Text('Eliminar definitivamente'))])));}).toList()))));}}

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

  late final Map<String, bool> phraseEnabled;
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
    phraseEnabled = {for (final p in AppStore.instance.budgetPhrases) p: true};
    phraseCtrls = {for (final k in phraseEnabled.keys) k: TextEditingController(text: k)};
    materialCtrls = {
      for (final k in materialUnits.keys) k: TextEditingController(),
    };
    if (widget.existing == null && AppStore.instance.budgetDraft != null) {
      final d=AppStore.instance.budgetDraft!; type=(d['type']??'').toString(); otherType.text=(d['otherType']??'').toString(); clientId=(d['clientId']??'').toString(); clientName.text=(d['clientName']??'').toString(); place.text=(d['place']??'').toString(); area.text=(d['area']??'').toString(); measurementDetail.text=(d['measurementDetail']??'').toString(); manualJobs.text=(d['manualJobs']??'').toString(); extraMaterials.text=(d['extraMaterials']??'').toString(); notes.text=(d['notes']??'').toString(); total.text=(d['total']??'').toString(); sectorPriceTotal=(d['sectorPriceTotal'] as num?)?.toDouble()??0; showCompany=d['showCompany']??true; showLogo=d['showLogo']??true; saveNewClient=d['saveNewClient']??false; step=(d['step'] as num?)?.toInt()??0; final sj=d['selectedJobs']; if(sj is Map){for(final k in selectedJobs.keys){selectedJobs[k]=sj[k]??selectedJobs[k]!;}} final mm=d['materials']; if(mm is Map){for(final e in mm.entries){if(materialCtrls.containsKey(e.key.toString()))materialCtrls[e.key.toString()]!.text=e.value.toString();}}
    }
    for(final c in [otherType,clientName,place,area,measurementDetail,manualJobs,extraMaterials,notes,total]){c.addListener(_autosave);}

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

  void _autosave(){if(widget.existing!=null)return;AppStore.instance.saveBudgetDraft({'type':type,'otherType':otherType.text,'clientId':clientId,'clientName':clientName.text,'place':place.text,'area':area.text,'measurementDetail':measurementDetail.text,'manualJobs':manualJobs.text,'extraMaterials':extraMaterials.text,'notes':notes.text,'total':total.text,'sectorPriceTotal':sectorPriceTotal,'showCompany':showCompany,'showLogo':showLogo,'saveNewClient':saveNewClient,'step':step,'selectedJobs':selectedJobs,'materials':{for(final e in materialCtrls.entries)e.key:e.value.text}});}

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
    _autosave();
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
                  onChanged: (v) { setState(() => type = v ?? ''); _autosave(); },
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
                  onChanged: (v) { setState(() => selectedJobs[k] = v ?? false); _autosave(); },
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
              onChanged: (v) { setState(() => showCompany = v); _autosave(); },
              title: const Text('Nombre de la empresa'),
              subtitle: Text(p.companyName.isEmpty ? 'Sin completar' : p.companyName),
            ),
            SwitchListTile(
              value: showLogo,
              onChanged: (v) { setState(() => showLogo = v); _autosave(); },
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
    AppStore.instance.budgetPhrases = phraseCtrls.values.map((c)=>c.text.trim()).where((x)=>x.isNotEmpty).toList();
    await AppStore.instance.save();
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
    await s.clearBudgetDraft();

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
              children: [
                Card(child: ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text('${s.budgets.where((x) => x.status == 'Pendiente').length} pendientes de ${s.budgets.length}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${s.budgets.where((x) => x.status == 'Aceptado').length} aceptados · ${s.budgets.where((x) => x.status == 'Rechazado').length} rechazados'),
                )),
                const SizedBox(height: 8),
                ...s.budgets.map((b) => Card(
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
              ],
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
    ListTile(leading: const Icon(Icons.delete_outline), title: const Text('Eliminar'), onTap: () async { Navigator.pop(ctx); final ok = await showDialog<bool>(context: context, builder: (d) => AlertDialog(title: const Text('Eliminar presupuesto'), content: Text('¿Eliminar ${b.number}?'), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Eliminar'))])); if (ok == true) await AppStore.instance.moveBudgetToTrash(b); }),
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
          pw.Container(height:3,color:blue),
          info('CLIENTE', b.clientName),
          pw.SizedBox(height: 14),
          section('TIPO DE TRABAJO', blue),
          pw.Text(b.workType.isEmpty ? '-' : b.workType),
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
                  color: PdfColors.black,
                ),
              ),
            ]),
          ),
          if (b.notes.isNotEmpty) ...[
            pw.SizedBox(height: 22),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('#B9C7D5')),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ACLARACIONES',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: blue,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  ...b.notes.split('\n').where((e) => e.trim().isNotEmpty).map(
                        (e) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Text('• ${e.trim()}', style: const pw.TextStyle(fontSize: 9)),
                        ),
                      ),
                ],
              ),
            ),
          ],
          pw.SizedBox(height: 24),
          pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Text(
              'PintaM²',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#B6BDC5'),
              ),
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

  static pw.Widget info(String a, String b) => pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#F7FAFC'),
          border: pw.Border.all(color: PdfColor.fromHex('#E4EAF2')),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(a, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.SizedBox(height: 3),
            pw.Text(b.isEmpty ? '-' : b, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );

  static pw.Widget section(String s, PdfColor c) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#EEF8FC'),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Text(s, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: c)),
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
          child: InteractiveViewer(minScale:1,maxScale:4,child:PdfPreview(
            build: (_) => buildPdf(),
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            pdfFileName: 'PintaM2_${b.number}.pdf',
          )),
        ),
        SafeArea(top:false,child:Padding(padding:const EdgeInsets.all(12),child:Row(children:[Expanded(child:OutlinedButton.icon(onPressed:(){pintaGoHome?.call();Navigator.of(context).popUntil((r)=>r.isFirst);},icon:const Icon(Icons.home_outlined),label:const Text('Volver al inicio'))),const SizedBox(width:8),Expanded(child:FilledButton.icon(onPressed:()async=>Printing.sharePdf(bytes:await buildPdf(),filename:'PintaM2_${b.number}.pdf'),icon:const Icon(Icons.share_outlined),label:const Text('Compartir PDF')))]))),
      ]),
    );
  }
}

class MoreScreen extends StatelessWidget{
  final ValueChanged<ThemeMode> onThemeChanged; const MoreScreen({super.key,required this.onThemeChanged});
  @override Widget build(BuildContext context)=>Scaffold(appBar:const BrandAppBar(),body:ListView(padding:const EdgeInsets.all(20),children:[
    Card(child:ListTile(leading:const Icon(Icons.manage_accounts_outlined),title:const Text('Editar datos'),subtitle:const Text('Usuario, empresa, logo y precios'),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const EditProfileScreen())))),
    Card(child:ListTile(leading:const Icon(Icons.backup_outlined),title:const Text('Exportar / guardar datos'),subtitle:const Text('Copia de seguridad para cambiar de celular'),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const BackupScreen())))),
    Card(child:ListTile(leading:const Icon(Icons.palette_outlined),title:const Text('Apariencia'),onTap:()=>showModalBottomSheet(context:context,builder:(ctx)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[ListTile(title:const Text('Seguir el sistema'),onTap:(){onThemeChanged(ThemeMode.system);Navigator.pop(ctx);}),ListTile(title:const Text('Claro'),onTap:(){onThemeChanged(ThemeMode.light);Navigator.pop(ctx);}),ListTile(title:const Text('Oscuro'),onTap:(){onThemeChanged(ThemeMode.dark);Navigator.pop(ctx);})]))))),
    const Card(child:ListTile(leading:Icon(Icons.info_outline),title:Text('Acerca de PintaM²'),subtitle:Text('Versión de prueba 0.11'))),
  ]));
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
