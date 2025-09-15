import 'package:flutter/material.dart';

import '../app_state.dart';

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
      _sugestoes =
          nomes.where((n) => n.toLowerCase().contains(q.toLowerCase().trim())).toList();
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
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe o produto'
                    : null,
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
                decoration: const InputDecoration(labelText: 'Preço unitário (RS)'),
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
