#!/usr/bin/env bash
#
# create-tap.sh
#
# Creates a Microsoft Entra ID Temporary Access Pass (TAP) for a range of
# workshop student accounts, following the naming convention used by the
# Terraform deployment: <PREFIX>-student<N>@<SUFFIX>
#
# Requires:
#   - Azure CLI, logged in as an identity with the Microsoft Graph
#     "UserAuthenticationMethod.ReadWrite.All" APPLICATION permission,
#     admin-consented (delegated/user logins will hit accessDenied - see
#     az ad app permission add / admin-consent).
#   - Temporary Access Pass enabled tenant-wide
#     (Entra ID > Security > Authentication methods > Temporary Access Pass).
#
# Usage:
#   ./create-tap.sh --prefix ws01 --suffix contoso.com --count 20 \
#       [--start 0] [--lifetime 60] [--reusable] [--out-dir ./output]
#
# Example (matches the Terraform naming ${PREFIX}-student${count.index}@${CUSTOMDOMAIN}):
#   ./create-tap.sh --prefix ws01 --suffix contoso.com --count 15 --lifetime 480
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
START=0
LIFETIME=60        # minutes
USABLE_ONCE=true
OUT_DIR="./output"

usage() {
  cat <<EOF
Usage: $0 --prefix <prefix> --suffix <domain> --count <n> [options]

Required:
  --prefix     <string>  Prefix used in the UPN, e.g. "ws01" -> ws01-student0@...
  --suffix     <string>  Domain/UPN suffix used after the @, e.g. contoso.com
  --count      <int>     Number of student accounts to process

Options:
  --start      <int>     Starting index (default: 0)
  --lifetime   <int>     TAP lifetime in minutes (default: 60).
                          Graph's default allowed range is 10-43200 (30 days),
                          though your tenant's TAP policy may restrict it further.
  --reusable              Allow the TAP to be used more than once during its
                          lifetime (default: single-use)
  --out-dir    <path>     Directory to write per-student TAP codes to (default: ./output)
  -h, --help              Show this help
EOF
  exit 1
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix) PREFIX="$2"; shift 2 ;;
    --suffix) SUFFIX="$2"; shift 2 ;;
    --count) COUNT="$2"; shift 2 ;;
    --start) START="$2"; shift 2 ;;
    --lifetime) LIFETIME="$2"; shift 2 ;;
    --reusable) USABLE_ONCE=false; shift ;;
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown argument: $1"; usage ;;
  esac
done

: "${PREFIX:?Missing required --prefix}"
: "${SUFFIX:?Missing required --suffix}"
: "${COUNT:?Missing required --count}"

if ! [[ "$LIFETIME" =~ ^[0-9]+$ ]] || (( LIFETIME < 10 || LIFETIME > 43200 )); then
  echo "ERROR: --lifetime must be an integer between 10 and 43200 minutes." >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

# ---------------------------------------------------------------------------
# Pre-flight: confirm we're logged in
# ---------------------------------------------------------------------------
if ! az account show >/dev/null 2>&1; then
  echo "ERROR: Not logged in to Azure CLI. Run 'az login --service-principal ...' first." >&2
  exit 1
fi

echo "==> Creating TAPs for ${COUNT} account(s): ${PREFIX}-student{${START}..$((START + COUNT - 1))}@${SUFFIX}"
echo "==> Lifetime: ${LIFETIME} minutes | Usable once: ${USABLE_ONCE}"
echo ""

declare -a FAILED=()
declare -a SUCCEEDED=()

for (( i=START; i<START+COUNT; i++ )); do
  UPN="${PREFIX}-student${i}@${SUFFIX}"

  echo -n "[$UPN] Looking up user... "
  USER_ID=$(az ad user show --id "$UPN" --query id -o tsv 2>/dev/null) || {
    echo "NOT FOUND - skipping"
    FAILED+=("$UPN (user not found)")
    continue
  }
  echo "OK ($USER_ID)"

  BODY=$(cat <<JSON
{
  "lifetimeInMinutes": ${LIFETIME},
  "isUsableOnce": ${USABLE_ONCE}
}
JSON
)

  echo -n "[$UPN] Creating Temporary Access Pass... "
  if ! TAP_CODE=$(az rest --method post \
        --uri "https://graph.microsoft.com/v1.0/users/${USER_ID}/authentication/temporaryAccessPassMethods" \
        --headers "Content-Type=application/json" \
        --body "$BODY" \
        --query temporaryAccessPass -o tsv 2>/tmp/tap_error.log); then
    ERR=$(tr '\n' ' ' < /tmp/tap_error.log)
    echo "FAILED"
    echo "  --> $ERR"
    FAILED+=("$UPN ($ERR)")
    continue
  fi

  if [[ -z "$TAP_CODE" || "$TAP_CODE" == "null" ]]; then
    echo "FAILED (no passcode returned)"
    FAILED+=("$UPN (no passcode returned)")
    continue
  fi

  OUT_FILE="${OUT_DIR}/tap-${PREFIX}-student${i}.txt"
  echo "$TAP_CODE" > "$OUT_FILE"
  echo "OK -> $OUT_FILE"
  SUCCEEDED+=("$UPN|$TAP_CODE")
done

echo ""
echo "==> Summary"
echo ""
if (( ${#SUCCEEDED[@]} > 0 )); then
  printf "%-40s %s\n" "UPN" "Temporary Access Pass"
  printf "%-40s %s\n" "---" "---------------------"
  for entry in "${SUCCEEDED[@]}"; do
    IFS='|' read -r upn code <<< "$entry"
    printf "%-40s %s\n" "$upn" "$code"
  done
fi

if (( ${#FAILED[@]} > 0 )); then
  echo ""
  echo "==> ${#FAILED[@]} failure(s):"
  for f in "${FAILED[@]}"; do
    echo "  - $f"
  done
  exit 1
fi
