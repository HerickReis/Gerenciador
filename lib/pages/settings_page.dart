import 'package:flutter/material.dart';

import '../app_state.dart';

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
                decoration:
                    const InputDecoration(labelText: 'Seu nome/loja (para o Pix)'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pixKey,
                decoration: const InputDecoration(
                    labelText:
                        'Sua chave Pix (e-mail, CPF, telefone ou aleatória)'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Informe a chave Pix' : null,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (!_form.currentState!.validate()) return;
                  await widget.app.editarPix(
                      key: _pixKey.text.trim(), nome: _pixNome.text.trim());
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Configurações salvas.')));
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
