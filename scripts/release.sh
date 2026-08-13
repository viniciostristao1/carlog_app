#!/usr/bin/env bash
# release.sh — corta um release nomeado a partir do build mais recente do CI.
#
# Uso:
#   scripts/release.sh <versao> "<nota de changelog em 1 linha>"
#   ex: scripts/release.sh v0.1.0 "Primeira versão: home + abastecimento + média"
#
# Pré-requisito: o commit já foi PUSHADO e o CI ficou VERDE (publica em 'ci-latest').
#   Acompanhe:  gh run watch <id> --exit-status   antes de chamar isto.
#
# O que faz:
#   1. baixa o APK arm64 + AAB do release rolling 'ci-latest';
#   2. cria o release <versao> com assets versionados + de NOME FIXO (carlog.apk).
#
# O nome fixo faz o link abaixo apontar SEMPRE pro APK mais novo (sem trocar de URL):
#   https://github.com/viniciostristao1/carlog_app/releases/latest/download/carlog.apk
set -euo pipefail
REPO=viniciostristao1/carlog_app

VER="${1:?uso: scripts/release.sh <versao> \"<nota>\"  (ex: v0.1.0)}"
NOTA="${2:-$VER}"
NUM="${VER#v}"; NUM="${NUM%%-*}"   # "0.1.0" a partir de "v0.1.0"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
cd "$tmp"

echo "→ Baixando o build de 'ci-latest'…"
gh release download ci-latest -R "$REPO" \
  -p app-arm64-v8a-release.apk -p app-release.aab --clobber

# sanidade: APK íntegro e assinado (v2)
unzip -t app-arm64-v8a-release.apk >/dev/null || { echo "APK corrompido"; exit 1; }
grep -aq 'APK Sig Block 42' app-arm64-v8a-release.apk || { echo "APK sem assinatura v2"; exit 1; }

cp app-arm64-v8a-release.apk "carlog-${NUM}-arm64.apk"
cp app-release.aab           "carlog-${NUM}.aab"
cp app-arm64-v8a-release.apk "carlog.apk"    # NOME FIXO (link /latest/download)
cp app-release.aab           "carlog.aab"     # NOME FIXO

echo "→ Criando release ${VER}…"
gh release create "$VER" -R "$REPO" --title "$VER" --notes "$NOTA" \
  "carlog-${NUM}-arm64.apk" "carlog-${NUM}.aab" "carlog.apk" "carlog.aab"

echo
echo "✓ Release ${VER} publicado."
echo "  APK SEMPRE-A-ÚLTIMA (link fixo p/ o usuário):"
echo "      https://github.com/$REPO/releases/latest/download/carlog.apk"
