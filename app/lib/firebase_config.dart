/// Interruptor da nuvem. Enquanto `false`, o CarLog roda 100% local: NÃO inicializa
/// o Firebase e NÃO mostra login/sincronização — o app funciona por completo offline.
///
/// Vire para `true` SÓ depois de:
///   1. provisionar o projeto Firebase (Auth Google + Firestore) — ver FIREBASE.md;
///   2. preencher `firebase_options.dart` com os valores reais;
///   3. preencher `kGoogleServerClientId` abaixo (Web client ID, oauth_client type 3).
const bool kFirebaseConfigured = true;

/// Web client ID (oauth_client type 3 do google-services.json). Necessário para o
/// login Google nativo. Não é segredo (vai embutido no app de qualquer forma).
const String kGoogleServerClientId =
    '214781359126-q2jdib8tuiq2j8cuao2nv6jh2oepgccd.apps.googleusercontent.com';
