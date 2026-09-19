# Pacote de lançamento — Play Store (CarLog)

Tudo pronto pra preencher o Google Play Console. **Copie e cole daqui.** Criado em 2026-09-17
(v0.38.0) e **atualizado em 2026-09-19 (v0.45.0)**. Mesmo padrão do `lista_app`/Save List.

> **Como ler:** a parte de cima é **material** (textos e respostas prontos pra colar). A parte
> de baixo (**"② No Play Console"**) é o **roteiro do que só você faz** logado na sua conta.
> Eu (Claude) não tenho acesso ao Console; preparo os arquivos, você faz os cliques.

---

## ⭐ Build a subir (o AAB)

A Play Store recebe um **AAB** (Android App Bundle), não o APK. O CI do CarLog compilava só
APK; criei um workflow dedicado **`build-aab.yml`** (roda sob demanda) que gera o **AAB
assinado** com a chave de upload.

- **Arquivo:** `app-release.aab` (renomear como `CarLog-v0.45.0.aab`).
- **Versão embutida:** `versionName 0.45.0`, `versionCode 55` (versão atual do `main`).
  ⚠️ **Regerar o AAB imediatamente antes de subir** (`gh workflow run build-aab.yml`): ele sai do
  `main` do momento e **cada upload exige versionCode maior** que o anterior — não reaproveitar um
  AAB antigo do `ci-latest` sem conferir a versão.
- **Assinatura:** chave de upload oficial (SHA-1
  `3E:DA:91:3A:E2:8B:B0:5E:C3:9E:64:94:1E:9B:45:BF:80:3B:CB:21`, registrada no Firebase → o
  Login Google segue funcionando).
- **De onde sai:** rode o workflow **Build AAB (Play Store)** no GitHub Actions
  (`gh workflow run build-aab.yml` ou botão *Run workflow*) e baixe o AAB do release rolling
  **`ci-latest`**:
  `https://github.com/viniciostristao1/carlog_app/releases/download/ci-latest/app-release.aab`
  (repo privado → precisa estar logado no GitHub).

> Opcional: dá pra subir o `versionName` pra **1.0.0** numa próxima atualização (fica mais
> "de lançamento"); não é obrigatório e não muda nada da revisão.

---

## Identidade da ficha

| Campo | Valor |
|---|---|
| **Nome do app (≤30):** | `CarLog: gastos do carro` |
| **Nome no ícone (launcher):** | `CarLog` |
| **Package (permanente):** | `com.vinyapps.carlog` |
| **Categoria:** | Automóveis e veículos (Auto & Vehicles) |
| **Tags/keywords:** | gastos do carro, consumo, combustível, revisão, FIPE, manutenção |
| **Monetização:** | Grátis · sem anúncios · sem compras no app |
| **E-mail de contato:** | viniciostristao@gmail.com |
| **Idioma do lançamento:** | Português (Brasil). EN/ES já existem no app → fichas traduzidas depois. |

## Descrição curta (≤80 caracteres)
```
Controle gastos, consumo, revisões e FIPE do seu carro. Simples e offline.
```

## Descrição completa (≤4000 caracteres)
```
CarLog é o diário do seu carro: em poucos toques você registra tudo e sabe quanto gasta, quanto anda e quando é a próxima revisão.

A tela inicial é toda atalho — abastecimento, consumo, revisões, FIPE, calibragem e lembretes a um toque, com temas (inclusive claro) e 6 modos de exibição.

O que você pode fazer:
• Abastecimento: anote litros e preço (ou o valor total) e veja o gasto do mês.
• Consumo/Média: o app calcula sua média km/L automaticamente entre tanques cheios.
• Revisões: histórico buscável de peças e serviços + previsão da próxima revisão (por km ou tempo).
• Ler foto (OCR): fotografe o orçamento da oficina e o app transcreve os itens e o total — funciona offline, no seu aparelho.
• Minha FIPE: consulte o valor do veículo pela Tabela FIPE (ou informe manualmente).
• Calibragem: pressão recomendada e quando você calibrou pela última vez.
• Lembretes: IPVA, seguro, licenciamento… com aviso de "faltam X dias".
• Vários veículos: gerencie até 3 carros.
• Temas e modos: escolha o visual (tem tema claro) e como a tela inicial mostra os atalhos.
• Backup: exporte e importe seus dados quando quiser.

Funciona 100% offline. Se quiser, entre com o Google para sincronizar seus dados entre aparelhos — sem anúncios.
```

---

## Materiais gráficos (em `store/`)

| Item | Especificação | Status |
|---|---|---|
| **Ícone** | 512×512 PNG, RGB | ✅ `store/icon_512.png` — **regerado em 19/09** com o ícone novo (hexágono, v0.43.0) |
| **Feature graphic** | 1024×500 PNG | ⚠️ `store/feature_graphic.png` é de **17/09** (arte antiga do ícone) → **refazer com a arte nova** antes de subir |
| **Screenshots (telefone)** | 2–8, PNG 24-bit s/ alpha, ≤2:1 | ⚠️ 4 prints de **16/09** (antes das v0.43–0.45) — válidos, mas sem os temas/modos novos; refazer é opcional |

**Screenshots** em `store/screenshots/` (≈1,98:1, RGB):
1. `01-home.png` — tela inicial (card do veículo com placa Mercosul + 6 stats + 6 atalhos)
2. `02-abastecimentos.png` — histórico de abastecimento + gasto/litros do mês
3. `03-revisoes.png` — histórico de revisões buscável (peças/serviços, do OCR)
4. `04-meu-carro.png` — cadastro do carro pela FIPE

> **Novidades desde o pacote inicial (v0.39 → v0.45)** — resumo em [`ATUALIZACOES.md`](ATUALIZACOES.md):
> revisão × reparo, histórico com 8 itens, check/previsão na Programar, **ícone novo (hexágono)**,
> temas **Neon Drift** e **Daylight** (Expresso saiu) e 3 **modos de home** (Racing/Lista/Teclas).
> Prints de conferência: https://viniciostristao1.github.io/adm-projetos-design/carlog-tema-neon-3-modos.html
> e https://viniciostristao1.github.io/adm-projetos-design/carlog-tema-daylight.html
>
> Crus do celular em `store/screenshots/originais/` (pra artes caprichadas depois). Trocar
> screenshots é edição de ficha: **não** exige novo AAB nem reinicia o teste de 14 dias.

## ✅ Checklist antes de publicar (revisado em 19/09)
- [ ] Regerar o **AAB** (`gh workflow run build-aab.yml`) e conferir `versionName 0.45.0+` / `versionCode 55+`.
- [ ] Refazer o **feature graphic** com o ícone novo (hexágono) — o atual ainda tem a arte antiga.
- [ ] (Opcional) Refazer os **screenshots** no celular com a v0.45 (mostram os temas e os modos novos).
- [ ] Conferir a **ficha** — as descrições abaixo já citam os temas/modos.
- [ ] Data Safety, classificação IARC, alarmes exatos e política/termos: **respostas abaixo seguem valendo**.

---

## Data Safety (Segurança dos dados) — respostas prontas

**O app coleta ou compartilha dados?** Coleta (só se você usar o login); não compartilha.

| Dado | Coletado? | Obrigatório? | Finalidade | Origem |
|---|---|---|---|---|
| **E-mail** | Sim (se logar) | Opcional | Login / conta | Login Google |
| **Nome** | Sim (se logar) | Opcional | Conta | Login Google |
| **Conteúdo do app** (veículos, abastec., revisões, FIPE, lembretes) | Sim (se logar/sync) | Opcional | Funcionalidade | Criado pelo usuário |

- **Fotos/câmera:** função "Ler foto" processa a imagem **no aparelho** (OCR offline). A foto
  **não é coletada, armazenada nem enviada** → **NÃO declarar** "Fotos e vídeos".
- **Localização:** não coleta.
- **Consulta FIPE:** envia só marca/modelo/ano (dado não-pessoal) → não é coleta de dado do usuário.
- Dados **criptografados em trânsito**? **Sim** (HTTPS/Firebase).
- Usuário pode **pedir exclusão**? **Sim** — página dedicada: https://viniciostristao1.github.io/carlog-privacidade/exclusao.html (cobre conta E dados sem apagar conta; serve os dois campos de URL do Data Safety).
- **Compartilhados com terceiros**? **Não** (Firebase = infraestrutura).
- Coleta para **publicidade**? **Não.** App para **crianças**? **Não.**

## Classificação de conteúdo (questionário IARC) — respostas prontas
Categoria: **Utilitário/Produtividade** (não é jogo). Responder **NÃO** a violência, sexo,
linguagem imprópria, drogas, jogos de azar, medo. Sem conteúdo gerado por usuários exibido
publicamente. → Resultado esperado: **Livre / Classificação L**.

## ⚠️ Permissão sensível: alarmes exatos (lembretes)
O app usa **USE_EXACT_ALARM / SCHEDULE_EXACT_ALARM** pra os lembretes (IPVA/seguro/revisão)
dispararem na hora certa. No Play Console, em *Política → App content → Permissões sensíveis*
(ou no envio), pode aparecer uma **declaração de "alarmes exatos"**: justifique que o CarLog
é um app de **lembretes/agenda de vencimentos do veículo** e precisa avisar em data/hora
exatas. É um caso de uso permitido — só declarar.

## Política de privacidade e Termos
- **Política (obrigatória):** https://viniciostristao1.github.io/carlog-privacidade/
- **Termos de uso (opcional na Play, já criados):** https://viniciostristao1.github.io/carlog-privacidade/termos.html
- **Exclusão de conta e dados (Data Safety):** https://viniciostristao1.github.io/carlog-privacidade/exclusao.html
- Repo público `viniciostristao1/carlog-privacidade` (GitHub Pages).

---

## ② No Play Console — passo a passo (o que só VOCÊ faz)

Pré-requisito ✅: conta de desenvolvedor paga **e aprovada** (a mesma do Save List).

1. **Criar o app** — *Criar app* → nome `CarLog: gastos do carro`, idioma Português (Brasil),
   tipo **App**, **Grátis**. Aceitar as declarações.
2. **Ficha da Store** (*Presença na loja → Ficha principal*): colar nome, descrição curta e
   completa; subir **ícone 512**, **feature graphic** e os **4 screenshots**. Salvar.
3. **App content** (*Política → App content*), um por um:
   - **Política de privacidade:** colar a URL.
   - **Anúncios:** *Não contém anúncios.*
   - **Acesso ao app:** o app funciona sem login; informe que o revisor pode usar tudo offline
     (o login Google é opcional, só para sync).
   - **Classificação de conteúdo:** questionário (respostas acima) → "Livre".
   - **Público-alvo:** 13+ / adultos (não infantil).
   - **Data safety:** preencher com a tabela acima.
   - **Permissões sensíveis (alarmes exatos):** declarar como acima (app de lembretes).
   - Governo/finanças/saúde/COVID: **Não**.
4. **Teste fechado (obrigatório p/ conta nova)** — *Testes → Teste fechado*: criar faixa, subir
   o **AAB**, cadastrar **≥12 testadores** (e-mails), compartilhar o link de opt-in; manter o
   teste **14 dias seguidos** → aí libera **"Solicitar acesso à produção"**.
5. **Produção** — criar release → subir o AAB → notas da versão → enviar para revisão.

> 💡 Ao subir o 1º AAB, aceite o **Play App Signing** (Google guarda a chave de assinatura;
> você usa a de upload). Guarde mesmo assim o backup da keystore.

---

## Backup da chave (⚠️ atenção)
- A **keystore de upload** existe local (`app/android/app/upload-keystore.jks`) e nos secrets do
  repo (`KEYSTORE_BASE64`), mas a **senha** (`KEYSTORE_PASSWORD`) fica **só no secret do
  GitHub** — não está em nenhum arquivo/documento acessível. Te entrego o `.jks`; a **senha**
  você precisa **recuperar/registrar** (você a definiu ao criar os secrets). Com o **Play App
  Signing** ligado, mesmo perdendo a chave de upload dá pra **resetar** — mas o ideal é anotar
  a senha em lugar seguro (gerenciador de senhas).

## Monetização — DECIDIDO (2026-09-17)
- Lança **grátis, sem anúncios** (grátis = **1 veículo**). **Premium = desbloqueio ÚNICO
  vitalício ~R$ 19,90** (não assinatura), igual ao Save List. Features Premium: **múltiplos
  veículos** (até 3), **gráficos/estatísticas avançadas**, **backup automático**, **exportar
  histórico**. Entra em **atualização** (v1.1),
  sem refazer o teste de 14 dias (Play Billing só testa após o app numa trilha). Detalhe/plano
  em `IDEIAS.md`.

## Futuro — App Store (iOS)
- Conta Apple Developer (US$99/ano) + Mac (ou build em nuvem tipo Codemagic) + ícones/prints no
  padrão Apple. ⚠️ ML Kit (OCR) e Firebase têm passos próprios no iOS. Fase depois do Android.
