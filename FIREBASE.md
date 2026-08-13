# CarLog — Firebase (ligar a nuvem)

O app já vem **Firebase-ready**, mas roda 100% local até você provisionar o projeto e virar o
interruptor. Este é o passo a passo. (Aprendizados herdados de `lista_app`/`calistenia`.)

## Estado atual
- `app/lib/firebase_config.dart` → `kFirebaseConfigured = false` e `kGoogleServerClientId = ''`.
- `app/lib/firebase_options.dart` → **placeholder** (não conecta em nada).
- Enquanto o flag é `false`: `main.dart` não chama `Firebase.initializeApp`, o login não aparece e o
  `sync_service` fica inerte. Nada quebra.

## Passos para ligar

1. **Criar o projeto** no [console Firebase](https://console.firebase.google.com) (ex.: `carlog`).
2. **Registrar o app Android** com o pacote **`com.vinyapps.carlog`**.
   - Baixar o `google-services.json` → salvar em `app/android/app/google-services.json`
     (está no `.gitignore`; no CI virá do secret `GOOGLE_SERVICES_JSON`).
   - Pegar o **Web client ID** (oauth_client `client_type: 3` do json) → colar em
     `kGoogleServerClientId` no `firebase_config.dart`.
3. **Gerar `firebase_options.dart` real.** Opções:
   - `flutterfire configure` (se a CLI funcionar), **ou**
   - preencher à mão a partir do `google-services.json` (apiKey, appId, messagingSenderId, projectId).
   Substituir o placeholder por esse arquivo.
4. **Ativar o Auth Google:** Authentication → Get Started → **Google** → ativar + **e-mail de
   suporte** → Salvar. (Herança do lista_app: se pular o e-mail de suporte, dá
   `CONFIGURATION_NOT_FOUND`.) Verificar sem o app:
   `curl -X POST 'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=<APIKEY>'`
   → `ADMIN_ONLY_OPERATION` = provisionado OK; `CONFIGURATION_NOT_FOUND` = ainda não.
5. **Criar o Firestore** (modo produção, região `southamerica-east1`) e publicar as regras
   (`firestore.rules`, ver abaixo) colando na aba **Regras** do console.
6. **Registrar o SHA-1** da chave que assina o app (Configurações do app Android → impressões SHA).
   Sem isso o login Google nativo dá `invalid-cert-hash`. Use a keystore de upload (a mesma do CI).
7. **Virar o flag:** `kFirebaseConfigured = true`. Subir versão, commitar, push.
   - Adicionar os secrets no repo: `GOOGLE_SERVICES_JSON` e `FIREBASE_OPTIONS_DART` (base64 dos
     arquivos) — o CI já os injeta condicionalmente.

## Modelo de dados (Firestore)
Tudo num único documento por usuário — cada store local vira um **campo string JSON** (mesmo formato do
`shared_preferences`). O `sync_service` faz união por `id` no 1º sync e "última escrita vence" depois.

- `users/{uid}` — campos: `veiculo_v1`, `abastecimentos_v1`, `medias_v1`, `revisoes_v1`,
  `programacao_v1`, `lembretes_v1`, `calibragem_v1`, `updatedAt` (a lista canônica é `todosOsStores`
  em `store_keys.dart`).

## firestore.rules (cada um só vê o seu)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

## Gotcha herdado
`firebase login --no-localhost` costuma dar "Unable to verify client" → configurar via **console
manual** (não via flutterfire CLI). Deploy de regras = colar no console. Se precisar de CLI, usar
service account.
