# Gerenciador de Devedores

Aplicativo Flutter simples para registrar vendas, pagamentos e gerar QR Code para pagamento via Pix.

## Pré‑requisitos
- [Flutter](https://flutter.dev) instalado (SDK e ferramentas de linha de comando)
- Android Studio ou outro editor compatível

## Como executar no Android Studio
1. **Clone o repositório**
   ```bash
   git clone <url-do-repo>
   cd Gerenciador
   ```
2. **Instale as dependências**
   ```bash
   flutter pub get
   ```
3. **Abra o projeto**
   - Inicie o Android Studio e escolha `Open an existing project`.
   - Selecione a pasta `Gerenciador`.
4. **Execute**
   - Conecte um dispositivo ou inicie um emulador.
   - Clique em `Run` para compilar e instalar o app.
5. **Gerar APK de release**
   ```bash
   flutter build apk
   ```
   O arquivo estará em `build/app/outputs/flutter-apk/app-release.apk`.

## Principais funcionalidades
- Cadastro automático de clientes ao registrar uma venda
- Sugestão de nomes de clientes já cadastrados
- Registro de vendas e pagamentos por cliente
- Cálculo automático do saldo devedor
- Remoção de vendas e pagamentos com confirmação
- Configuração de chave Pix e exibição de QR Code para pagamento

