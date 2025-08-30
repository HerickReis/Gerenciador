import 'package:flutter/material.dart';

import 'models.dart';
import 'repository.dart';

class AppState extends ChangeNotifier {
  final Repo repo;
  AppState(this.repo) {
    clientes = repo.loadClientes();
  }

  List<Cliente> clientes = [];

  List<String> get nomesExistentes => clientes.map((e) => e.nome).toList()..sort();

  bool existeNome(String nome) =>
      clientes.any((c) => c.nome.toLowerCase().trim() == nome.toLowerCase().trim());

  Future<void> addVenda({
    required String nomeCliente,
    required String descricao,
    required int quantidade,
    required double precoUnitario,
  }) async {
    Cliente cliente;
    if (existeNome(nomeCliente)) {
      cliente = clientes.firstWhere(
          (c) => c.nome.toLowerCase().trim() == nomeCliente.toLowerCase().trim());
    } else {
      cliente = Cliente(nome: nomeCliente.trim());
      clientes.add(cliente);
      clientes.sort((a, b) => a.nome.compareTo(b.nome));
    }
    cliente.itens.add(VendaItem(
      descricao: descricao,
      quantidade: quantidade,
      precoUnitario: precoUnitario,
    ));
    await repo.saveClientes(clientes);
    notifyListeners();
  }

  Future<void> addPagamento({required Cliente cliente, required double valor}) async {
    cliente.pagamentos.add(Pagamento(valor: valor));
    await repo.saveClientes(clientes);
    notifyListeners();
  }

  Future<void> removerVenda({required Cliente cliente, required VendaItem item}) async {
    cliente.itens.removeWhere((e) => e.id == item.id);
    await repo.saveClientes(clientes);
    notifyListeners();
  }

  Future<void> removerPagamento({required Cliente cliente, required Pagamento pagamento}) async {
    cliente.pagamentos.removeWhere((p) => p.id == pagamento.id);
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
