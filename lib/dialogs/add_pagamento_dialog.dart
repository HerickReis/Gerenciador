import 'package:flutter/material.dart';

import '../app_state.dart';

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
    _clienteSel =
        widget.nomeInicial ?? (widget.app.clientes.isNotEmpty ? widget.app.clientes.first.nome : null);
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
              initialValue: _clienteSel,
              items: widget.app.clientes
                  .map((c) => DropdownMenuItem(value: c.nome, child: Text(c.nome)))
                  .toList(),
              onChanged: (v) => setState(() => _clienteSel = v),
              decoration: const InputDecoration(labelText: 'Cliente'),
              validator: (v) => v == null ? 'Selecione um cliente' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _valorCtrl,
              decoration: const InputDecoration(labelText: 'Valor (RS)'),
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
