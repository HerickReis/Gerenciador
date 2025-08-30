import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../app_state.dart';
import '../models.dart';
import '../utils.dart';

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
            Text('Valor: ${currency.format(valor)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
      ],
    );
  }
}
