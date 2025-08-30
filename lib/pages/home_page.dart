import 'package:flutter/material.dart';

import '../app_state.dart';
import '../dialogs/add_pagamento_dialog.dart';
import '../dialogs/add_venda_dialog.dart';
import '../models.dart';
import '../utils.dart';
import 'client_page.dart';
import 'settings_page.dart';

class HomePage extends StatelessWidget {
  final AppState app;
  const HomePage({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        final totalAberto = app.clientes.fold<double>(0, (s, c) => s + c.saldo);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Devedores'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SettingsPage(app: app)),
                  );
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
                      const Text('Total em aberto:',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(currency.format(totalAberto),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              Expanded(
                child: app.clientes.isEmpty
                    ? const Center(child: Text('Nenhum cliente cadastrado ainda.'))
                    : ListView.separated(
                        itemCount: app.clientes.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final c = app.clientes[i];
                          return ListTile(
                            title: Text(c.nome),
                            subtitle: Text(
                                'Compras: ${currency.format(c.totalCompras)}  |  Pagos: ${currency.format(c.totalPagamentos)}'),
                            trailing: Text(
                              currency.format(c.saldo),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: c.saldo > 0
                                    ? Colors.red[700]
                                    : Colors.green[700],
                              ),
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClientePage(app: app, clienteId: c.id),
                              ),
                            ),
                            onLongPress: () async {
                              if (c.saldo == 0) {
                                final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Remover cliente?'),
                                        content: Text('Deseja remover ${c.nome}? (Saldo zerado)'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancelar')),
                                          FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Remover')),
                                        ],
                                      ),
                                    ) ??
                                    false;
                                if (ok) app.removerCliente(c);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Só é possível remover com saldo zerado.')));
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
                onPressed: () => showDialog(
                    context: context,
                    builder: (_) => AddVendaDialog(app: app)),
                label: const Text('Adicionar venda'),
                icon: const Icon(Icons.add_shopping_cart),
              ),
              const SizedBox(height: 12),
              FloatingActionButton.extended(
                heroTag: 'pagamento',
                onPressed: () => showDialog(
                    context: context,
                    builder: (_) => AddPagamentoDialog(app: app)),
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
