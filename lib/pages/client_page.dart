import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../dialogs/add_pagamento_dialog.dart';
import '../dialogs/add_venda_dialog.dart';
import '../dialogs/pix_dialog.dart';
import '../utils.dart';

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
            onPressed: () =>
                showDialog(context: context, builder: (_) => PixDialog(app: app, cliente: c)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              title: const Text('Total devido'),
              trailing: Text(currency.format(c.saldo),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Produtos', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ...c.itens.map((i) => Card(
                child: ListTile(
                  title: Text('${i.quantidade}x ${i.descricao}'),
                  subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(i.data)),
                  trailing: Text(currency.format(i.total)),
                  onLongPress: () async {
                    final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Remover produto?'),
                            content: Text('Deseja remover ${i.descricao}?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancelar')),
                              FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Remover')),
                            ],
                          ),
                        ) ??
                        false;
                    if (ok) await app.removerVenda(cliente: c, item: i);
                  },
                ),
              )),
          const SizedBox(height: 12),
          const Text('Pagamentos', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ...c.pagamentos.map((p) => Card(
                child: ListTile(
                  title: Text(currency.format(p.valor)),
                  subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(p.data)),
                  onLongPress: () async {
                    final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Remover pagamento?'),
                            content: const Text('Deseja remover este pagamento?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancelar')),
                              FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Remover')),
                            ],
                          ),
                        ) ??
                        false;
                    if (ok) await app.removerPagamento(cliente: c, pagamento: p);
                  },
                ),
              )),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'addv-$clienteId',
            onPressed: () => showDialog(
                context: context, builder: (_) => AddVendaDialog(app: app, nomeInicial: c.nome)),
            label: const Text('Adicionar produto'),
            icon: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'pag-$clienteId',
            onPressed: () => showDialog(
                context: context, builder: (_) => AddPagamentoDialog(app: app, nomeInicial: c.nome)),
            label: const Text('Pagamento'),
            icon: const Icon(Icons.attach_money),
          ),
        ],
      ),
    );
  }
}
