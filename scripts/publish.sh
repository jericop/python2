#!/usr/bin/env bash

set -eu
set -o pipefail

readonly ROOT_DIR="$(cd "$(dirname "${0}")/.." && pwd)"
readonly BIN_DIR="${ROOT_DIR}/.bin"

# shellcheck source=SCRIPTDIR/.util/tools.sh
source "${ROOT_DIR}/scripts/.util/tools.sh"

# shellcheck source=SCRIPTDIR/.util/print.sh
source "${ROOT_DIR}/scripts/.util/print.sh"

function main {
  local image_ref token
  token=""

  while [[ "${#}" != 0 ]]; do
    case "${1}" in
    --image-ref | -i)
      image_ref="${2}"
      shift 2
      ;;

    --token | -t)
      token="${2}"
      shift 2
      ;;

    --help | -h)
      shift 1
      usage
      exit 0
      ;;

    "")
      # skip if the argument is empty
      shift 1
      ;;

    *)
      util::print::error "unknown argument \"${1}\""
      ;;
    esac
  done

  if [[ -z "${image_ref:-}" ]]; then
    usage
    util::print::error "--image-ref is required"
  fi

  repo::prepare

  tools::install "${token}"

  buildpack::publish "${image_ref}"
}

function usage() {
  cat <<-USAGE
Publishes a composite buildpack to a registry.

OPTIONS
  -h, --help                          Prints the command usage
  -i, --image-ref <ref>               List of image reference to publish to (required)
  -t, --token <token>                 Token used to download assets from GitHub (e.g. jam, pack, etc) (optional)

USAGE
}

function repo::prepare() {
  util::print::title "Preparing repo..."

  mkdir -p "${BIN_DIR}"

  export PATH="${BIN_DIR}:${PATH}"
}

function tools::install() {
  local token
  token="${1}"

  util::tools::pack::install \
    --directory "${BIN_DIR}" \
    --token "${token}"
}

function buildpack::publish() {

  local image_ref
  image_ref="${1}"

  util::print::title "Publishing composite buildpack..."

  util::print::info "Publishing buildpack to ${image_ref}"

  pack \
    buildpack package "${image_ref}" \
    --config "${ROOT_DIR}/package.toml" \
    --format image \
    --publish
}

main "${@:-}"
