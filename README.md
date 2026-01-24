# 📻 Rádio Eirunepé

Aplicativo oficial da Rádio Eirunepé para Android. Ouça ao vivo o Programa Eone Cavalcante e participe da programação.

## ✨ Características

- 🎵 **Reprodução de áudio em background** - Continue ouvindo mesmo com a tela bloqueada
- 📱 **Interface moderna e intuitiva** - Design Material 3
- 🌐 **Verificação de conectividade** - Avisa quando não há internet
- ⚡ **Performance otimizada** - Uso eficiente de recursos
- 🎨 **Suporte a tema claro e escuro**

## 🚀 Como usar

1. Abra o aplicativo
2. Toque no botão "Tocar" para iniciar a transmissão
3. A rádio continuará tocando mesmo com a tela bloqueada ou o app em segundo plano
4. Use o botão "Parar" para interromper a reprodução

## 📋 Requisitos

- Android 6.0 (API 23) ou superior
- Conexão com a internet

## 🛠️ Tecnologias

- **Flutter** - Framework multiplataforma
- **just_audio** - Reprodução de áudio
- **audio_session** - Controle de sessão de áudio
- **internet_connection_checker** - Verificação de conectividade

## 📦 Instalação

### Para desenvolvedores

```bash
# Clone o repositório
git clone [url-do-repositorio]

# Entre no diretório
cd radio_eirunepe

# Instale as dependências
flutter pub get

# Execute o app
flutter run
```

### Build para produção

```bash
# Gerar APK
flutter build apk --release

# Gerar AAB (para Google Play)
flutter build appbundle --release
```

## 📱 Publicação no Google Play

### Pré-requisitos

1. Conta de desenvolvedor no Google Play Console
2. Arquivo de assinatura (keystore) configurado
3. Arquivo `key.properties` na pasta `android/` com:
   ```
   storePassword=sua_senha
   keyPassword=sua_senha
   keyAlias=seu_alias
   storeFile=caminho/para/seu/keystore.jks
   ```

### Passos

1. Gere o AAB assinado:
   ```bash
   flutter build appbundle --release
   ```

2. O arquivo estará em: `build/app/outputs/bundle/release/app-release.aab`

3. Faça upload no Google Play Console:
   - Acesse [Google Play Console](https://play.google.com/console)
   - Crie um novo app ou selecione um existente
   - Vá em "Produção" > "Criar nova versão"
   - Faça upload do arquivo `.aab`
   - Preencha as informações necessárias
   - Envie para revisão

### Informações do App

- **Nome**: Rádio Eirunepé
- **Package Name**: com.radio_eirunepe.aab
- **Versão Atual**: 1.0.1+6

## 🔒 Permissões

O aplicativo solicita as seguintes permissões:

- **INTERNET** - Para reproduzir o stream de áudio
- **WAKE_LOCK** - Para manter o dispositivo acordado durante a reprodução
- **FOREGROUND_SERVICE** - Para reprodução em background (Android 9+)
- **FOREGROUND_SERVICE_MEDIA_PLAYBACK** - Para reprodução de mídia em background (Android 14+)

## 🐛 Solução de Problemas

### Áudio para ao bloquear a tela

- Verifique se as permissões foram concedidas
- Reinicie o aplicativo
- Verifique se há atualizações disponíveis

### Erro de conexão

- Verifique sua conexão com a internet
- Tente novamente após alguns segundos
- Verifique se o firewall não está bloqueando a conexão

## 📄 Licença

Este projeto é propriedade da Rádio Eirunepé.

## 👥 Contato

- **Telefone**: (97) 98410-6555
- **WhatsApp**: Disponível no app

## 🔄 Changelog

### Versão 1.0.1+6
- ✅ Reprodução em background implementada
- ✅ Verificação de conectividade
- ✅ Melhorias na interface
- ✅ Tratamento de erros aprimorado
- ✅ Otimizações de performance

---

Desenvolvido para a Rádio Eirunepé
