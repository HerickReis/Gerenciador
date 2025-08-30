import 'package:uuid/uuid.dart';

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
        itens: (m['itens'] as List)
            .map((e) => VendaItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        pagamentos: (m['pagamentos'] as List)
            .map((e) => Pagamento.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
