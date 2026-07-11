#!/usr/bin/env bash
#
# promote.sh — evo-catalogue-schemas release publish.
#
# This repo is authored directly on public foonerd/evo-catalogue-schemas
# (no private eng-side split). promote.sh does not scrub or squash;
# it does the tag + release + signed bundle + channel-pointer publish
# flow.
#
# Steps:
#   1. Verify the tag exists locally + working tree clean.
#   2. Build the release tarball: schemas/ tree at the tagged commit,
#      SHA-256 hashed, ed25519-signed with the project release key.
#   3. Push the tag + create the GitHub release + upload the tarball.
#   4. Advance the pointer in evo-catalogue-schemas-artefacts (per
#      channel: dev / test / prod).
#
# Usage:
#   scripts/release/promote.sh \
#     --tag VERSION \
#     --artefacts-repo PATH \
#     --channel {dev|test|prod} \
#     --signing-key PATH \
#     [--no-push]

set -euo pipefail

TAG=""
ARTEFACTS_REPO=""
CHANNEL=""
SIGNING_KEY=""
NO_PUSH=0

usage() {
    cat <<EOF >&2
Usage: $(basename "$0") \\
    --tag VERSION \\
    --artefacts-repo PATH \\
    --channel {dev|test|prod} \\
    --signing-key PATH \\
    [--no-push]

Publishes an evo-catalogue-schemas release + advances the named
channel's pointer in evo-catalogue-schemas-artefacts.
EOF
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --tag)            TAG="$2"; shift 2 ;;
        --artefacts-repo) ARTEFACTS_REPO="$2"; shift 2 ;;
        --channel)        CHANNEL="$2"; shift 2 ;;
        --signing-key)    SIGNING_KEY="$2"; shift 2 ;;
        --no-push)        NO_PUSH=1; shift ;;
        -h|--help)        usage ;;
        *)                echo "unknown argument: $1" >&2; usage ;;
    esac
done

[[ -z "${TAG}" ]]            && { echo "--tag required" >&2; exit 1; }
[[ -z "${ARTEFACTS_REPO}" ]] && { echo "--artefacts-repo required" >&2; exit 1; }
[[ -z "${CHANNEL}" ]]        && { echo "--channel required" >&2; exit 1; }
[[ -z "${SIGNING_KEY}" ]]    && { echo "--signing-key required" >&2; exit 1; }
[[ -r "${SIGNING_KEY}" ]]    || { echo "signing key not readable" >&2; exit 1; }

case "${CHANNEL}" in
    dev|test|prod) ;;
    *) echo "invalid --channel: ${CHANNEL} (must be dev|test|prod)" >&2; exit 1 ;;
esac

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${REPO_ROOT}"

log() { printf '[promote] %s\n' "$*" >&2; }
die() { printf '[promote] REFUSE: %s\n' "$*" >&2; exit 1; }

# ---- Preconditions ----

if ! git tag --list | grep -qx "${TAG}"; then
    die "tag ${TAG} does not exist locally"
fi

if [[ -n "$(git status --porcelain)" ]]; then
    die "working tree not clean"
fi

if [[ ! -d "${ARTEFACTS_REPO}/.git" ]]; then
    die "artefacts repo not a git checkout: ${ARTEFACTS_REPO}"
fi

# ---- Build bundle ----

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

BUNDLE_NAME="evo-catalogue-schemas-${TAG#v}.tar.gz"
BUNDLE_PATH="${WORK_DIR}/${BUNDLE_NAME}"

log "building ${BUNDLE_NAME} from tag ${TAG}"
git archive --format=tar.gz --prefix="evo-catalogue-schemas-${TAG#v}/" "${TAG}" schemas/ > "${BUNDLE_PATH}"

log "hashing bundle"
BUNDLE_SHA256="$(sha256sum "${BUNDLE_PATH}" | awk '{print $1}')"
log "sha256 ${BUNDLE_SHA256}"

log "signing bundle"
SIG_PATH="${BUNDLE_PATH}.sig"
openssl pkeyutl -sign -inkey "${SIGNING_KEY}" -rawin -in "${BUNDLE_PATH}" -out "${SIG_PATH}"

# ---- Push tag + GitHub release ----

if (( NO_PUSH == 0 )); then
    log "pushing tag ${TAG}"
    git push origin "refs/tags/${TAG}"

    log "creating GitHub release"
    if command -v gh >/dev/null 2>&1; then
        gh release create "${TAG}" \
            "${BUNDLE_PATH}" \
            "${SIG_PATH}" \
            --title "${TAG}" \
            --notes "Release ${TAG} of evo-catalogue-schemas. Bundle SHA-256: ${BUNDLE_SHA256}."
    else
        log "gh CLI not available; upload manually"
    fi
else
    log "--no-push set: skipping tag push + GitHub release"
fi

# ---- Advance channel pointer in artefacts repo ----

POINTER="${ARTEFACTS_REPO}/channels/${CHANNEL}.toml"
log "advancing ${POINTER} to schema_set_version = ${TAG#v}"

if [[ ! -f "${POINTER}" ]]; then
    die "pointer file not found: ${POINTER}"
fi

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
python3 - <<PY
import re, pathlib
p = pathlib.Path("${POINTER}")
text = p.read_text()
text = re.sub(r'schema_set_version = "[^"]*"', f'schema_set_version = "${TAG#v}"', text)
text = re.sub(r'updated_at = "[^"]*"', f'updated_at = "${TS}"', text)
p.write_text(text)
PY

log "signing pointer"
SIG_POINTER="${POINTER}.sig"
openssl pkeyutl -sign -inkey "${SIGNING_KEY}" -rawin -in "${POINTER}" -out "${SIG_POINTER}"

(cd "${ARTEFACTS_REPO}" && git add channels/ && \
    git commit --signoff -m "channels/${CHANNEL}: advance to schema_set_version ${TAG#v}")

if (( NO_PUSH == 0 )); then
    (cd "${ARTEFACTS_REPO}" && git push origin HEAD:refs/heads/main)
fi

log "PASS. ${TAG} published; ${CHANNEL} channel advanced."
