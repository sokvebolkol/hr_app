#!/usr/bin/env bash
#
# Verifies the TLS / cleartext hardening applied for the "weak cryptographic
# ciphers" security finding.
#
#   Part 1 — server TLS posture (the actual finding)
#   Part 2 — app-side config (cleartext + ATS declarations)
#
# Usage:
#   ./tool/verify_tls_hardening.sh
#   ./tool/verify_tls_hardening.sh hr-mobile.api.chokchey.com.kh
#
set -uo pipefail

HOSTS=("${@:-hr-mobile.api.chokchey.com.kh uat-coapp.chokchey.com.kh}")
# shellcheck disable=SC2206
HOSTS=(${HOSTS[*]})
PORT=443

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0
WARN=0

green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
red()   { printf '\033[0;31m%s\033[0m\n' "$1"; }
yellow(){ printf '\033[0;33m%s\033[0m\n' "$1"; }
head2() { printf '\n\033[1m%s\033[0m\n%s\n' "$1" "$(printf '─%.0s' {1..64})"; }

ok()   { green  "  PASS  $1"; PASS=$((PASS+1)); }
bad()  { red    "  FAIL  $1"; FAIL=$((FAIL+1)); }
warn() { yellow "  WARN  $1"; WARN=$((WARN+1)); }
info() { printf '  INFO  %s\n' "$1"; }

# Diagnose exactly WHY a host is unreachable: DNS, TCP, or TLS.
# Returns 0 if the host completes a TLS handshake.
diagnose_reachability() {
  local host="$1"

  # 1. DNS
  local ip=""
  if command -v dig >/dev/null 2>&1; then
    ip=$(timeout 8 dig +short "${host}" A | grep -E '^[0-9.]+$' | head -1)
  fi
  if [[ -z "${ip}" ]] && command -v getent >/dev/null 2>&1; then
    ip=$(timeout 8 getent hosts "${host}" 2>/dev/null | awk '{print $1}' | head -1)
  fi
  if [[ -z "${ip}" ]] && command -v host >/dev/null 2>&1; then
    ip=$(timeout 8 host "${host}" 2>/dev/null | awk '/has address/{print $NF}' | head -1)
  fi

  if [[ -z "${ip}" ]]; then
    bad "DNS: ${host} does not resolve"
    info "→ Host may be internal-only: connect to the company VPN and retry."
    info "→ Or the hostname is wrong; confirm it against lib/services/global_service.dart"
    return 1
  fi
  ok "DNS: ${host} resolves to ${ip}"

  # 2. TCP
  if timeout 8 bash -c "cat < /dev/null > /dev/tcp/${host}/${PORT}" 2>/dev/null; then
    ok "TCP: port ${PORT} reachable"
  else
    bad "TCP: cannot open ${host}:${PORT}"
    info "→ Firewall or the host is not listening on ${PORT}. Try: nc -vz ${host} ${PORT}"
    return 1
  fi

  # 3. TLS
  if timeout 12 openssl s_client -connect "${host}:${PORT}" \
      -servername "${host}" </dev/null >/dev/null 2>&1; then
    ok "TLS: handshake succeeds"
    return 0
  fi
  bad "TLS: handshake failed (port open, but TLS did not complete)"
  info "→ Inspect with: openssl s_client -connect ${host}:${PORT} -servername ${host}"
  return 1
}

# Returns 0 if a TLS handshake succeeds with the given openssl args.
handshake() {
  local host="$1"; shift
  timeout 15 openssl s_client -connect "${host}:${PORT}" \
    -servername "${host}" "$@" </dev/null >/dev/null 2>&1
}

# ─────────────────────────────────────────────────────────────────────────────
# Part 1 — Server TLS
# ─────────────────────────────────────────────────────────────────────────────
test_server() {
  local host="$1"
  head2 "SERVER: ${host}"

  if ! diagnose_reachability "${host}"; then
    warn "Skipping cipher tests for ${host} — not reachable (see above)"
    return
  fi

  # --- Deprecated protocol versions: these MUST be refused ---
  for proto in ssl3 tls1 tls1_1; do
    if handshake "${host}" "-${proto}"; then
      bad "${proto} is ENABLED — disable it on the server"
    else
      ok "${proto} refused"
    fi
  done

  # --- Modern protocols: these should be accepted ---
  for proto in tls1_2 tls1_3; do
    if handshake "${host}" "-${proto}"; then
      ok "${proto} supported"
    else
      warn "${proto} not supported (TLS 1.2 is the minimum the app requires)"
    fi
  done

  # --- Weak cipher families: all MUST be refused ---
  #     aNULL/eNULL = no auth / no encryption, EXPORT = 40-56 bit,
  #     RC4/3DES/DES/MD5 = broken or deprecated primitives.
  for suite in aNULL eNULL EXPORT DES 3DES RC4 MD5 SEED IDEA; do
    if handshake "${host}" -cipher "${suite}" 2>/dev/null; then
      bad "Weak cipher family accepted: ${suite}"
    else
      ok "Weak cipher family refused: ${suite}"
    fi
  done

  # --- What does it actually negotiate by default? ---
  local negotiated
  negotiated=$(timeout 15 openssl s_client -connect "${host}:${PORT}" \
    -servername "${host}" </dev/null 2>/dev/null \
    | grep -E '^\s*(Cipher|Protocol)\s*:' | tr -s ' ')
  if [[ -n "${negotiated}" ]]; then
    printf '  INFO  Negotiated by default:\n'
    echo "${negotiated}" | sed 's/^/          /'
  fi

  # --- Forward secrecy: iOS ATS requires ECDHE ---
  if handshake "${host}" -cipher 'ECDHE'; then
    ok "Forward secrecy (ECDHE) supported — required by iOS ATS"
  else
    bad "No ECDHE support — iOS ATS will BLOCK this connection"
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Part 2 — App configuration
# ─────────────────────────────────────────────────────────────────────────────
test_app_config() {
  head2 "APP CONFIG (source)"

  local nsc="${REPO_ROOT}/android/app/src/main/res/xml/network_security_config.xml"
  local manifest="${REPO_ROOT}/android/app/src/main/AndroidManifest.xml"
  local plist="${REPO_ROOT}/ios/Runner/Info.plist"

  if grep -q 'cleartextTrafficPermitted="false"' "${nsc}" 2>/dev/null; then
    ok "Android: cleartext disabled in network_security_config.xml"
  else
    bad "Android: cleartextTrafficPermitted=\"false\" missing in ${nsc}"
  fi

  if grep -q 'usesCleartextTraffic="false"' "${manifest}" 2>/dev/null; then
    ok "Android: usesCleartextTraffic=\"false\" in manifest"
  else
    bad "Android: usesCleartextTraffic=\"false\" missing in manifest"
  fi

  # Any cleartext exception that survived into the release config
  if grep -q 'cleartextTrafficPermitted="true"' "${nsc}" 2>/dev/null; then
    bad "Android: a cleartext EXCEPTION exists — scanners will flag this"
  else
    ok "Android: no cleartext exceptions"
  fi

  if command -v python3 >/dev/null 2>&1; then
    # Python emits "PASS|msg" / "FAIL|msg" so the bash counters stay accurate.
    while IFS='|' read -r verdict msg; do
      case "${verdict}" in
        PASS) ok   "${msg}" ;;
        FAIL) bad  "${msg}" ;;
        *)    warn "${msg}" ;;
      esac
    done < <(python3 - "${plist}" <<'PY'
import plistlib, sys
try:
    with open(sys.argv[1], 'rb') as f:
        d = plistlib.load(f)
except Exception as e:
    print(f"FAIL|iOS: cannot parse Info.plist ({e})"); sys.exit(0)

ats = d.get('NSAppTransportSecurity')
if ats is None:
    print("FAIL|iOS: NSAppTransportSecurity block missing"); sys.exit(0)
print("PASS|iOS: NSAppTransportSecurity present")

if ats.get('NSAllowsArbitraryLoads'):
    print("FAIL|iOS: NSAllowsArbitraryLoads is true — ATS is effectively OFF")
else:
    print("PASS|iOS: NSAllowsArbitraryLoads is false")

for domain, cfg in (ats.get('NSExceptionDomains') or {}).items():
    tls = cfg.get('NSExceptionMinimumTLSVersion', 'TLSv1.0 (default)')
    verdict = "PASS" if tls in ('TLSv1.2', 'TLSv1.3') else "FAIL"
    print(f"{verdict}|iOS: {domain} minimum TLS = {tls}")
    if cfg.get('NSExceptionAllowsInsecureHTTPLoads'):
        print(f"FAIL|iOS: {domain} allows insecure HTTP loads")
    if not cfg.get('NSExceptionRequiresForwardSecrecy', True):
        print(f"FAIL|iOS: {domain} has forward secrecy DISABLED")
PY
    )
  fi

  # Certificate validation bypass must be debug-only
  local mainfile="${REPO_ROOT}/lib/main.dart"
  if grep -q 'badCertificateCallback' "${mainfile}" 2>/dev/null; then
    if grep -B4 'HttpOverrides.global' "${mainfile}" | grep -q 'kDebugMode'; then
      ok "Dart: badCertificateCallback is gated behind kDebugMode"
    else
      bad "Dart: badCertificateCallback is NOT debug-gated — certs accepted in release!"
    fi
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Locate aapt2 from PATH or a standard Android SDK install.
find_aapt2() {
  if command -v aapt2 >/dev/null 2>&1; then command -v aapt2; return 0; fi
  local sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
  [[ -d "${sdk}" ]] || sdk="$HOME/Android/Sdk"
  # Highest build-tools version available
  local found
  found=$(find "${sdk}/build-tools" -maxdepth 2 -name aapt2 -type f 2>/dev/null \
          | sort -V | tail -1)
  [[ -n "${found}" ]] && { echo "${found}"; return 0; }
  return 1
}

test_built_artifacts() {
  head2 "BUILT ARTIFACTS (optional)"
  local apk="${REPO_ROOT}/build/app/outputs/flutter-apk/app-release.apk"

  if [[ ! -f "${apk}" ]]; then
    warn "No release APK found — skipping"
    info "→ Build one first: flutter build apk --release"
    return
  fi

  local aapt2
  if ! aapt2=$(find_aapt2); then
    warn "aapt2 not found — skipping packaged-manifest check"
    info "→ Install via Android Studio > SDK Manager > SDK Tools > Android SDK Build-Tools"
    info "→ Then either add it to PATH or export ANDROID_HOME=~/Library/Android/sdk"
    info "→ Alternative check: unzip -p '${apk}' AndroidManifest.xml | strings | grep -i cleartext"
    return
  fi
  info "Using aapt2: ${aapt2}"

  # In a compiled manifest, android:usesCleartextTraffic=false shows as
  # (type 0x12)0x0  — i.e. boolean false.
  local dump
  dump=$("${aapt2}" dump xmltree --file AndroidManifest.xml "${apk}" 2>/dev/null)
  if [[ -z "${dump}" ]]; then
    warn "Release APK: aapt2 could not read the manifest"
    return
  fi

  local line
  line=$(echo "${dump}" | grep -i 'usesCleartextTraffic' | head -1)
  if [[ -z "${line}" ]]; then
    warn "Release APK: usesCleartextTraffic not present in packaged manifest"
    info "→ Cleartext is still blocked by network_security_config, but add the"
    info "  attribute so scanners can see it explicitly."
  elif echo "${line}" | grep -qE '0x0( |$)|=false'; then
    ok "Release APK: usesCleartextTraffic=false in packaged manifest"
  else
    bad "Release APK: usesCleartextTraffic appears ENABLED — ${line}"
  fi

  if echo "${dump}" | grep -qi 'networkSecurityConfig'; then
    ok "Release APK: networkSecurityConfig is wired up"
  else
    bad "Release APK: networkSecurityConfig missing from packaged manifest"
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
printf '\033[1mTLS / cleartext hardening verification\033[0m\n'
printf 'openssl: %s\n' "$(openssl version)"

test_app_config
for h in "${HOSTS[@]}"; do test_server "${h}"; done
test_built_artifacts

head2 "SUMMARY"
printf '  passed: %s   failed: %s   warnings: %s\n\n' "${PASS}" "${FAIL}" "${WARN}"

if [[ ${WARN} -gt 0 ]]; then
  yellow "  A WARN means a check could not RUN, not that it failed."
  printf '  Warnings are environmental (no network / VPN / missing tool).\n'
  printf '  Resolve them so the check actually executes — it may then FAIL,\n'
  printf '  which is the point: the weak-cipher finding is server-side.\n\n'
fi

cat <<'NOTE'
  IMPORTANT — openssl 3.x has removed support for many legacy protocols and
  ciphers, so a "refused" result can mean *your openssl* would not offer it,
  not that the server rejects it. Treat this script as a smoke test and use
  one of these as the authoritative check:

      nmap --script ssl-enum-ciphers -p 443 <host>
      docker run --rm drwetter/testssl.sh <host>
      https://www.ssllabs.com/ssltest/     (public hosts only)

NOTE

[[ ${FAIL} -eq 0 ]] && exit 0 || exit 1
