# ✅ Checklist de Conformidade Google Play

## 📋 Status Atual do App

### ✅ CONFORMES

#### 1. Permissões
- ✅ `INTERNET` - Justificada (streaming de áudio)
- ✅ `WAKE_LOCK` - Justificada (manter áudio em background)
- ✅ `FOREGROUND_SERVICE` - Justificada (reprodução em background)
- ✅ `FOREGROUND_SERVICE_MEDIA_PLAYBACK` - Justificada (Android 14+)
- ✅ Todas as permissões são necessárias e declaradas corretamente

#### 2. Segurança
- ✅ `usesCleartextTraffic="false"` - Apenas HTTPS
- ✅ `requestLegacyExternalStorage="false"` - Scoped storage
- ✅ ProGuard habilitado (minifyEnabled, shrinkResources)
- ✅ Service com `exported="false"` (seguro)

#### 3. Configurações Técnicas
- ✅ minSdk = 21 (Android 5.0) - Boa compatibilidade
- ✅ targetSdk atualizado (via Flutter)
- ✅ Versionamento correto (versionCode + versionName)
- ✅ Assinatura configurada para release

#### 4. Manifest
- ✅ Activity principal exportada corretamente
- ✅ Intent filters configurados
- ✅ Service de foreground declarado
- ✅ Meta-data do Flutter presente

### ⚠️ MELHORIAS RECOMENDADAS

#### 1. Declaração de Dados Coletados
**Status**: ⚠️ Necessário declarar no Google Play Console

O app **NÃO coleta dados pessoais**, mas você precisa declarar isso:
- No Google Play Console → Política → Privacidade
- Marque: "Não coletamos dados"
- Ou crie política de privacidade simples

#### 2. Política de Privacidade
**Status**: ⚠️ Obrigatória para publicação

Crie uma página web com política de privacidade:
```
Exemplo de conteúdo mínimo:
- Nome do app: Rádio Eirunepé
- Não coletamos dados pessoais
- Usamos apenas conexão de internet para streaming
- Não compartilhamos dados com terceiros
```

#### 3. Ícone do App
**Status**: ✅ Configurado (via flutter_launcher_icons)
- Certifique-se de que o ícone está gerado: `flutter pub run flutter_launcher_icons`

#### 4. Screenshots
**Status**: ⚠️ Necessário para publicação
- Mínimo: 2 screenshots
- Recomendado: 4-8 screenshots
- Tamanhos: 16:9 ou 9:16 (mínimo 320px altura)

### 📝 Informações para Preencher no Google Play Console

#### Informações do App
- **Nome**: Rádio Eirunepé
- **Descrição curta** (80 caracteres):
  ```
  Ouça ao vivo a Rádio Eirunepé e o Programa Eone Cavalcante
  ```
- **Descrição completa**: (já no README.md)
- **Categoria**: Música e Áudio
- **Classificação de conteúdo**: Todos (ou conforme conteúdo)

#### Declaração de Dados
- **Coleta de dados**: Não
- **Compartilhamento**: Não
- **Segurança**: Não aplicável (sem dados)

#### Política de Privacidade
- **URL obrigatória**: (crie uma página web)
- Exemplo: `https://seusite.com.br/politica-privacidade`

### 🎯 Ações Necessárias Antes de Publicar

1. ✅ **Gerar ícones do app**
   ```bash
   flutter pub run flutter_launcher_icons
   ```

2. ⚠️ **Criar política de privacidade**
   - Criar página web simples
   - Ou usar gerador online
   - URL deve estar acessível

3. ⚠️ **Preparar screenshots**
   - Tirar screenshots do app em funcionamento
   - Mínimo 2, recomendado 4-8
   - Tamanhos corretos (16:9 ou 9:16)

4. ✅ **Gerar AAB assinado**
   ```bash
   flutter build appbundle --release
   ```

5. ⚠️ **Preencher informações no Console**
   - Todas as seções obrigatórias
   - Declaração de dados
   - Política de privacidade

### 🔒 Segurança e Privacidade

#### Dados Coletados: NENHUM
- ✅ Não coleta dados pessoais
- ✅ Não usa analytics
- ✅ Não usa publicidade
- ✅ Apenas streaming de áudio público

#### Permissões Justificadas
Todas as permissões são necessárias para funcionalidade:
- Internet: streaming
- Wake Lock: manter áudio em background
- Foreground Service: reprodução contínua

### ✅ Conclusão

**Status Geral**: ✅ **CONFORME** (após criar política de privacidade)

O app está tecnicamente pronto para publicação. Faltam apenas:
1. Política de privacidade (URL)
2. Screenshots para a loja
3. Preencher informações no Google Play Console

---

**Última atualização**: Baseado nas políticas do Google Play de 2024
