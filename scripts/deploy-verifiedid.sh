#!/usr/bin/env bash
set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
SUBSCRIPTION="6d3054f8-7714-4dc4-991c-a5f9c19b1bf3"
RESOURCE_GROUP="rg-wt-scus-apps-win-01"
APP_NAME="as-wt-scus-barryu-verifiedid-01"
APP_URL="https://id.labs.barry.edu"

PROJECT_DIR="/Users/maramirez/repos/active-directory-verifiable-credentials-dotnet/1-asp-net-core-api-idtokenhint"
PUBLISH_DIR="$PROJECT_DIR/publish"

# ── Pre-flight ────────────────────────────────────────────────────────────────
echo "▶  Verified ID — deploy to $APP_NAME"
echo "   URL : $APP_URL"
echo "   Sub : $SUBSCRIPTION"
echo ""

if ! command -v az &>/dev/null; then
  echo "✗  Azure CLI not found. Install from https://aka.ms/installazurecli" >&2
  exit 1
fi

if ! command -v dotnet &>/dev/null; then
  echo "✗  dotnet not found." >&2
  exit 1
fi

# Ensure we're on the right subscription
az account set --subscription "$SUBSCRIPTION"
echo "✓  Subscription set"

# ── Build & publish ───────────────────────────────────────────────────────────
echo ""
echo "▶  Building..."
rm -rf "$PUBLISH_DIR"
dotnet publish "$PROJECT_DIR" \
  --configuration Release \
  --output "$PUBLISH_DIR" \
  --nologo \
  --verbosity quiet
echo "✓  Build succeeded"

# ── Zip ───────────────────────────────────────────────────────────────────────
ZIP_PATH="$PROJECT_DIR/deploy.zip"
rm -f "$ZIP_PATH"
(cd "$PUBLISH_DIR" && zip -r "$ZIP_PATH" . -q)
echo "✓  Package ready ($(du -sh "$ZIP_PATH" | cut -f1))"

# ── Deploy ────────────────────────────────────────────────────────────────────
echo ""
echo "▶  Deploying to App Service..."
az webapp deploy \
  --name "$APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --src-path "$ZIP_PATH" \
  --type zip \
  --async false \
  --output none
echo "✓  Deploy succeeded"

# ── Cleanup ───────────────────────────────────────────────────────────────────
rm -f "$ZIP_PATH"
rm -rf "$PUBLISH_DIR"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "✓  Live at $APP_URL"
