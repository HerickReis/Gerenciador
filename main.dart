// =============================
// pubspec.yaml (cole no seu projeto)
// =============================
// Observação: crie o projeto com: flutter create devedores_app
// Depois substitua o pubspec.yaml e o lib/main.dart conforme abaixo
// Rode: flutter pub get
// E execute: flutter run
/*
name: devedores_app
publish_to: 'none'
description: App simples para gerenciar devedores e vendas de produtos (Flutter)
version: 0.1.0+1
environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6
  shared_preferences: ^2.3.2
  uuid: ^4.5.1
  intl: ^0.19.0
  qr_flutter: ^4.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
*/

// =============================
// lib/main.dart
// =============================
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DevedoresApp());
}

final _currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

class DevedoresApp extends StatelessWidget {
  const DevedoresApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Devedores',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// =============================
// MODELOS
// =============================
class VendaItem {
  final String id;
  final String descricao;
  final int quantidade;
  final double precoUnitario;
  final DateTime data;

  VendaItem({
    String? id,
    required this.descricao,
    required this.quantidade,
    required this.precoUnitario,
    DateTime? data,
  })  : id = id ?? const Uuid().v4(),
        data = data ?? DateTime.now();

  double get total => quantidade * precoUnitario;

  Map<String, dynamic> toMap() => {
        'id': id,
        'descricao': descricao,
        'quantidade': quantidade,
        'precoUnitario': precoUnitario,
        'data': data.toIso8601String(),
      };

  factory VendaItem.fromMap(Map<String, dynamic> m) => VendaItem(
        id: m['id'] as String,
        descricao: m['descricao'] as String,
        quantidade: m['quantidade'] as int,
        precoUnitario: (m['precoUnitario'] as num).toDouble(),
        data: DateTime.parse(m['data'] as String),
      );
}

class Pagamento {
  final String id;
  final double valor;
  final DateTime data;

  Pagamento({String? id, required this.valor, DateTime? data})
      : id = id ?? const Uuid().v4(),
        data = data ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'valor': valor,
        'data': data.toIso8601String(),
      };

  factory Pagamento.fromMap(Map<String, dynamic> m) => Pagamento(
        id: m['id'] as String,
        valor: (m['valor'] as num).toDouble(),
        data: DateTime.parse(m['data'] as String),
      );
}

class Cliente {
  final String id;
  final String nome;
  final List<VendaItem> itens;
  final List<Pagamento> pagamentos;

  Cliente({String? id, required this.nome, List<VendaItem>? itens, List<Pagamento>? pagamentos})
      : id = id ?? const Uuid().v4(),
        itens = itens ?? [],
        pagamentos = pagamentos ?? [];

  double get totalCompras => itens.fold(0, (s, e) => s + e.total);
  double get totalPagamentos => pagamentos.fold(0, (s, e) => s + e.valor);
  double get saldo => totalCompras - totalPagamentos;

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'itens': itens.map((e) => e.toMap()).toList(),
        'pagamentos': pagamentos.map((e) => e.toMap()).toList(),
      };

  factory Cliente.fromMap(Map<String, dynamic> m) => Cliente(
        id: m['id'] as String,
        nome: m['nome'] as String,
        itens: (m['itens'] as List).map((e) => VendaItem.fromMap(Map<String, dynamic>.from(e))).toList(),
        pagamentos: (m['pagamentos'] as List).map((e) => Pagamento.fromMap(Map<String, dynamic>.from(e))).toList(),
      );
}

// =============================
// REPOSITÓRIO (SharedPreferences com JSON)
// =============================
class Repo {
  static const _kClientes = 'clientes_v1';
  static const _kPixKey = 'pix_key';
  static const _kPixNome = 'pix_nome';

  final SharedPreferences prefs;
  Repo(this.prefs);

  List<Cliente> loadClientes() {
    final raw = prefs.getString(_kClientes);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map((m) => Cliente.fromMap(Map<String, dynamic>.from(m))).toList();
  }

  Future<void> saveClientes(List<Cliente> clientes) async {
    final raw = jsonEncode(clientes.map((c) => c.toMap()).toList());
    await prefs.setString(_kClientes, raw);
  }

  String get pixKey => prefs.getString(_kPixKey) ?? '';
  String get pixNome => prefs.getString(_kPixNome) ?? '';

  Future<void> setPix({required String key, required String nome}) async {
    await prefs.setString(_kPixKey, key);
    await prefs.setString(_kPixNome, nome);
  }
}

// =============================
// STATE (em memória + persistência)
// =============================
class AppState extends ChangeNotifier {
  final Repo repo;
  AppState(this.repo) {
    clientes = repo.loadClientes();
  }

  List<Cliente> clientes = [];

  List<String> get nomesExistentes => clientes.map((e) => e.nome).toList()..sort();

  bool existeNome(String nome) => clientes.any((c) => c.nome.toLowerCase().trim() == nome.toLowerCase().trim());

  Future<void> addVenda({required String nomeCliente, required String descricao, required int quantidade, required double precoUnitario}) async {
    Cliente cliente;
    if (existeNome(nomeCliente)) {
      cliente = clientes.firstWhere((c) => c.nome.toLowerCase().trim() == nomeCliente.toLowerCase().trim());
    } else {
      cliente = Cliente(nome: nomeCliente.trim());
      clientes.add(cliente);
      clientes.sort((a, b) => a.nome.compareTo(b.nome));
    }
    cliente.itens.add(VendaItem(descricao: descricao, quantidade: quantidade, precoUnitario: precoUnitario));
    await repo.saveClientes(clientes);
    notifyListeners();
  }

  Future<void> addPagamento({required Cliente cliente, required double valor}) async {
    cliente.pagamentos.add(Pagamento(valor: valor));
    await repo.saveClientes(clientes);
    notifyListeners();
  }

  Future<void> removerCliente(Cliente c) async {
    clientes.removeWhere((x) => x.id == c.id);
    await repo.saveClientes(clientes);
    notifyListeners();
  }

  Future<void> editarPix({required String key, required String nome}) async {
    await repo.setPix(key: key, nome: nome);
    notifyListeners();
  }

  String get pixKey => repo.pixKey;
  String get pixNome => repo.pixNome;
}

// =============================
// HOME PAGE
// =============================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AppState? app;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => app = AppState(Repo(prefs)));
  }

  @override
  Widget build(BuildContext context) {
    if (app == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return AnimatedBuilder(
      animation: app!,
      builder: (context, _) {
        final totalAberto = app!.clientes.fold<double>(0, (s, c) => s + c.saldo);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Devedores'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage(app: app!)));
                  setState(() {});
                },
              ),
            ],
          ),
          body: Column(
            children: [
              if (totalAberto > 0)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total em aberto:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(_currency.format(totalAberto), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              Expanded(
                child: app!.clientes.isEmpty
                    ? const Center(child: Text('Nenhum cliente cadastrado ainda.'))
                    : ListView.separated(
                        itemCount: app!.clientes.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final c = app!.clientes[i];
                          return ListTile(
                            title: Text(c.nome),
                            subtitle: Text('Compras: ${_currency.format(c.totalCompras)}  |  Pagos: ${_currency.format(c.totalPagamentos)}'),
                            trailing: Text(
                              _currency.format(c.saldo),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: c.saldo > 0 ? Colors.red[700] : Colors.green[700],
                              ),
                            ),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientePage(app: app!, clienteId: c.id))),
                            onLongPress: () async {
                              if (c.saldo == 0) {
                                final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Remover cliente?'),
                                        content: Text('Deseja remover ${c.nome}? (Saldo zerado)'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remover')),
                                        ],
                                      ),
                                    ) ??
                                    false;
                                if (ok) app!.removerCliente(c);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Só é possível remover com saldo zerado.')));
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.extended(
                heroTag: 'venda',
                onPressed: () => showDialog(context: context, builder: (_) => AddVendaDialog(app: app!)),
                label: const Text('Adicionar venda'),
                icon: const Icon(Icons.add_shopping_cart),
              ),
              const SizedBox(height: 12),
              FloatingActionButton.extended(
                heroTag: 'pagamento',
                onPressed: () => showDialog(context: context, builder: (_) => AddPagamentoDialog(app: app!)),
                label: const Text('Registrar pagamento'),
                icon: const Icon(Icons.payments),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =============================
// PÁGINA DO CLIENTE
// =============================
class ClientePage extends StatelessWidget {
  final AppState app;
  final String clienteId;
  const ClientePage({super.key, required this.app, required this.clienteId});

  @override
  Widget build(BuildContext context) {
    final c = app.clientes.firstWhere((e) => e.id == clienteId);
    return Scaffold(
      appBar: AppBar(
        title: Text(c.nome),
        actions: [
          IconButton(
            tooltip: 'QR Pix',
            icon: const Icon(Icons.qr_code_2),
            onPressed: () => showDialog(context: context, builder: (_) => PixDialog(app: app, cliente: c)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              title: const Text('Total devido'),
              trailing: Text(_currency.format(c.saldo), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Produtos', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ...c.itens
              .map((i) => Card(
                    child: ListTile(
                      title: Text('${i.quantidade}x ${i.descricao}'),
                      subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(i.data)),
                      trailing: Text(_currency.format(i.total)),
                    ),
                  ))
              .toList(),
          const SizedBox(height: 12),
          const Text('Pagamentos', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ...c.pagamentos
              .map((p) => Card(
                    child: ListTile(
                      title: Text(_currency.format(p.valor)),
                      subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(p.data)),
                    ),
                  ))
              .toList(),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'addv-${1}',
            onPressed: () => showDialog(context: context, builder: (_) => AddVendaDialog(app: app, nomeInicial: c.nome)),
            label: const Text('Adicionar produto'),
            icon: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'pag-${1}',
            onPressed: () => showDialog(context: context, builder: (_) => AddPagamentoDialog(app: app, nomeInicial: c.nome)),
            label: const Text('Pagamento'),
            icon: const Icon(Icons.attach_money),
          ),
        ],
      ),
    );
  }
}

// =============================
// DIALOG: ADICIONAR VENDA (com "autocomplete" de nomes)
// =============================
class AddVendaDialog extends StatefulWidget {
  final AppState app;
  final String? nomeInicial;
  const AddVendaDialog({super.key, required this.app, this.nomeInicial});

  @override
  State<AddVendaDialog> createState() => _AddVendaDialogState();
}

class _AddVendaDialogState extends State<AddVendaDialog> {
  final _form = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _produtoCtrl = TextEditingController();
  final _qtdCtrl = TextEditingController(text: '1');
  final _precoCtrl = TextEditingController();

  List<String> _sugestoes = [];

  @override
  void initState() {
    super.initState();
    _nomeCtrl.text = widget.nomeInicial ?? '';
    _recalcularSugestoes('');
    _nomeCtrl.addListener(() => _recalcularSugestoes(_nomeCtrl.text));
  }

  void _recalcularSugestoes(String q) {
    final nomes = widget.app.nomesExistentes;
    setState(() {
      _sugestoes = nomes.where((n) => n.toLowerCase().contains(q.toLowerCase().trim())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar venda'),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome do cliente'),
                validator: (v) {
                  final nome = v?.trim() ?? '';
                  if (nome.isEmpty) return 'Informe o nome';
                  // Regra: só aceitar nova entrada se for diferente dos existentes (case-insensitive)
                  // Se o nome for igual a existente, tudo bem (vai acumular), só não cria duplicado.
                  return null;
                },
              ),
              if (_sugestoes.isNotEmpty) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    children: _sugestoes
                        .take(6)
                        .map((s) => ActionChip(
                              label: Text(s),
                              onPressed: () => setState(() => _nomeCtrl.text = s),
                            ))
                        .toList(),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextFormField(
                controller: _produtoCtrl,
                decoration: const InputDecoration(labelText: 'Produto (ex: Pão de mel)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o produto' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _qtdCtrl,
                decoration: const InputDecoration(labelText: 'Quantidade'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final x = int.tryParse(v ?? '');
                  if (x == null || x <= 0) return 'Quantidade inválida';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _precoCtrl,
                decoration: const InputDecoration(labelText: 'Preço unitário (R$)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final x = double.tryParse((v ?? '').replaceAll(',', '.'));
                  if (x == null || x <= 0) return 'Preço inválido';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () async {
            if (!_form.currentState!.validate()) return;
            final nome = _nomeCtrl.text.trim();
            final qtd = int.parse(_qtdCtrl.text);
            final preco = double.parse(_precoCtrl.text.replaceAll(',', '.'));
            await widget.app.addVenda(
              nomeCliente: nome,
              descricao: _produtoCtrl.text.trim(),
              quantidade: qtd,
              precoUnitario: preco,
            );
            if (!mounted) return;
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

// =============================
// DIALOG: REGISTRAR PAGAMENTO
// =============================
class AddPagamentoDialog extends StatefulWidget {
  final AppState app;
  final String? nomeInicial;
  const AddPagamentoDialog({super.key, required this.app, this.nomeInicial});

  @override
  State<AddPagamentoDialog> createState() => _AddPagamentoDialogState();
}

class _AddPagamentoDialogState extends State<AddPagamentoDialog> {
  final _form = GlobalKey<FormState>();
  String? _clienteSel;
  final _valorCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _clienteSel = widget.nomeInicial ?? (widget.app.clientes.isNotEmpty ? widget.app.clientes.first.nome : null);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar pagamento'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _clienteSel,
              items: widget.app.clientes.map((c) => DropdownMenuItem(value: c.nome, child: Text(c.nome))).toList(),
              onChanged: (v) => setState(() => _clienteSel = v),
              decoration: const InputDecoration(labelText: 'Cliente'),
              validator: (v) => v == null ? 'Selecione um cliente' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _valorCtrl,
              decoration: const InputDecoration(labelText: 'Valor (R$)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final x = double.tryParse((v ?? '').replaceAll(',', '.'));
                if (x == null || x <= 0) return 'Valor inválido';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () async {
            if (!_form.currentState!.validate()) return;
            final c = widget.app.clientes.firstWhere((e) => e.nome == _clienteSel);
            final valor = double.parse(_valorCtrl.text.replaceAll(',', '.'));
            await widget.app.addPagamento(cliente: c, valor: valor);
            if (!mounted) return;
            Navigator.pop(context);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

// =============================
// SETTINGS + PIX
// =============================
class SettingsPage extends StatefulWidget {
  final AppState app;
  const SettingsPage({super.key, required this.app});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _pixKey;
  late final TextEditingController _pixNome;

  @override
  void initState() {
    super.initState();
    _pixKey = TextEditingController(text: widget.app.pixKey);
    _pixNome = TextEditingController(text: widget.app.pixNome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: _pixNome,
                decoration: const InputDecoration(labelText: 'Seu nome/loja (para o Pix)'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pixKey,
                decoration: const InputDecoration(labelText: 'Sua chave Pix (e-mail, CPF, telefone ou aleatória)'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Informe a chave Pix' : null,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (!_form.currentState!.validate()) return;
                  await widget.app.editarPix(key: _pixKey.text.trim(), nome: _pixNome.text.trim());
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configurações salvas.')));
                },
                child: const Text('Salvar'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// =============================
// DIALOGO: QR PIX
// Nota: O payload oficial EMVCo/BR Code é mais complexo. Aqui geramos
// um QR simples com texto contendo chave + nome + valor. Para produção,
// substitua por um gerador BR Code (Pix copia e cola) de fato.
// =============================
class PixDialog extends StatelessWidget {
  final AppState app;
  final Cliente cliente;
  const PixDialog({super.key, required this.app, required this.cliente});

  @override
  Widget build(BuildContext context) {
    final valor = cliente.saldo;
    final hasPix = app.pixKey.isNotEmpty && app.pixNome.isNotEmpty;

    final conteudo = hasPix
        ? 'PAGAMENTO PIX\nNOME:${app.pixNome}\nCHAVE:${app.pixKey}\nCLIENTE:${cliente.nome}\nVALOR:${valor.toStringAsFixed(2)}'
        : 'Configure sua chave Pix nas Configurações';

    return AlertDialog(
      title: const Text('QR para pagamento'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasPix)
            QrImageView(
              data: conteudo,
              version: QrVersions.auto,
              size: 220,
            )
          else
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text('Você ainda não configurou sua chave Pix.'),
            ),
          const SizedBox(height: 8),
          SelectableText(conteudo, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          if (hasPix)
            Text('Valor: ${_currency.format(valor)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
      ],
    );
  }
}
