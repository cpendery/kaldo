#!/bin/sh
cat << EOF
===============================================================================
 _           _     _       
| |         | |   | |      
| |  _ _____| | __| | ___  
| |_/ |____ | |/ _  |/ _ \ 
|  _ (/ ___ | ( (_| | |_| |
|_| \_)_____|\_)____|\___/ 
                           
cross shell aliases

https://github.com/cpendery/kaldo

Please file an issue if you encounter any problems!
===============================================================================

EOF


PROJECT_NAME="kaldo"
OWNER="cpendery"
REPO="${PROJECT_NAME}"
GITHUB_DOWNLOAD_PREFIX=https://github.com/${OWNER}/${REPO}/releases/download

# ------------------------------------------------------------------------
# https://github.com/client9/shlib - portable posix shell functions
# ------------------------------------------------------------------------

is_command() (
  command -v "$1" >/dev/null
)

echo_stderr() (
  echo "$@" 1>&2
)

_logp=2
log_set_priority() {
  _logp="$1"
}

log_priority() (
  if test -z "$1"; then
    echo "$_logp"
    return
  fi
  [ "$1" -le "$_logp" ]
)

log_tag() (
  case $1 in
    0) echo "[error]" ;;
    1) echo "[warn]" ;;
    2) echo "" ;;
    3) echo "[debug]" ;;
    4) echo "[trace]" ;;
    *) echo "[$1]" ;;
  esac
)


log_trace_priority=4
log_trace() (
  priority=$log_trace_priority
  log_priority "$priority" || return 0
  echo_stderr "$(log_tag $priority)" "${@}"
)

log_debug_priority=3
log_debug() (
  priority=$log_debug_priority
  log_priority "$priority" || return 0
  echo_stderr "$(log_tag $priority)" "${@}"
)

log_info_priority=2
log_info() (
  priority=$log_info_priority
  log_priority "$priority" || return 0
  echo_stderr "$(log_tag $priority)" "${@}"
)

log_warn_priority=1
log_warn() (
  priority=$log_warn_priority
  log_priority "$priority" || return 0
  echo_stderr "$(log_tag $priority)" "${@}"
)

log_err_priority=0
log_err() (
  priority=$log_err_priority
  log_priority "$priority" || return 0
  echo_stderr "$(log_tag $priority)" "${@}"
)

uname_os_check() (
  os=$1
  case "$os" in
    darwin) return 0 ;;
    dragonfly) return 0 ;;
    freebsd) return 0 ;;
    linux) return 0 ;;
    android) return 0 ;;
    nacl) return 0 ;;
    netbsd) return 0 ;;
    openbsd) return 0 ;;
    plan9) return 0 ;;
    solaris) return 0 ;;
    windows) return 0 ;;
  esac
  log_err "uname_os_check '$(uname -s)' got converted to '$os' which is not a GOOS value. Please file bug at https://github.com/client9/shlib"
  return 1
)

uname_arch_check() (
  arch=$1
  case "$arch" in
    386) return 0 ;;
    amd64) return 0 ;;
    arm64) return 0 ;;
    armv5) return 0 ;;
    armv6) return 0 ;;
    armv7) return 0 ;;
    ppc64) return 0 ;;
    ppc64le) return 0 ;;
    mips) return 0 ;;
    mipsle) return 0 ;;
    mips64) return 0 ;;
    mips64le) return 0 ;;
    s390x) return 0 ;;
    amd64p32) return 0 ;;
  esac
  log_err "uname_arch_check '$(uname -m)' got converted to '$arch' which is not a GOARCH value.  Please file bug report at https://github.com/client9/shlib"
  return 1
)

http_download_curl() (
  local_file=$1
  source_url=$2
  header=$3

  log_trace "http_download_curl(local_file=$local_file, source_url=$source_url, header=$header)"

  if [ -z "$header" ]; then
    code=$(curl -w '%{http_code}' -sL -o "$local_file" "$source_url")
  else
    code=$(curl -w '%{http_code}' -sL -H "$header" -o "$local_file" "$source_url")
  fi

  if [ "$code" != "200" ]; then
    log_err "received HTTP status=$code for url='$source_url'"
    return 1
  fi
  return 0
)

http_download_wget() (
  local_file=$1
  source_url=$2
  header=$3

  log_trace "http_download_wget(local_file=$local_file, source_url=$source_url, header=$header)"

  if [ -z "$header" ]; then
    wget -q -O "$local_file" "$source_url"
  else
    wget -q --header "$header" -O "$local_file" "$source_url"
  fi
)

http_download() (
  log_debug "http_download(url=$2)"
  if is_command curl; then
    http_download_curl "$@"
    return
  elif is_command wget; then
    http_download_wget "$@"
    return
  fi
  log_err "http_download unable to find wget or curl"
  return 1
)

http_copy() (
  tmp=$(mktemp)
  http_download "${tmp}" "$1" "$2" || return 1
  body=$(cat "$tmp")
  rm -f "${tmp}"
  echo "$body"
)

# ------------------------------------------------------------------------
# end https://github.com/client9/shlib
# ------------------------------------------------------------------------

# github_release_json [owner] [repo] [version]
#
# outputs release json string
#
github_release_json() (
  owner=$1
  repo=$2
  version=$3
  test -z "$version" && version="latest"
  giturl="https://github.com/${owner}/${repo}/releases/${version}"
  json=$(http_copy "$giturl" "Accept:application/json")

  log_trace "github_release_json(owner=${owner}, repo=${repo}, version=${version}) returned '${json}'"

  test -z "$json" && return 1
  echo "${json}"
)

# extract_value [key-value-pair]
#
# outputs value from a colon delimited key-value pair
#
extract_value() (
  key_value="$1"
  IFS=':' read -r _ value << EOF
${key_value}
EOF
  echo "$value"
)

# extract_json_value [json] [key]
#
# outputs value of the key from the given json string
#
extract_json_value() (
  json="$1"
  key="$2"
  key_value=$(echo "${json}" | grep  -o "\"$key\":[^,]*[,}]" | tr -d '",}')

  extract_value "$key_value"
)

# github_release_tag [release-json]
#
# outputs release tag string
#
github_release_tag() (
  json="$1"
  tag=$(extract_json_value "${json}" "tag_name")
  test -z "$tag" && return 1
  echo "$tag"
)

# uname_os
#
# outputs an adjusted os value
#
uname_os() (
  os=$(uname -s | tr '[:upper:]' '[:lower:]')
  case "$os" in
    cygwin_nt*) os="windows" ;;
    mingw*) os="windows" ;;
    msys_nt*) os="windows" ;;
  esac

  uname_os_check "$os"

  log_trace "uname_os() returned '${os}'"

  echo "$os"
)

# uname_arch
#
# outputs an adjusted architecture value
#
uname_arch() (
  arch=$(uname -m)
  case $arch in
    x86_64) arch="amd64" ;;
    x86) arch="386" ;;
    i686) arch="386" ;;
    i386) arch="386" ;;
    aarch64) arch="arm64" ;;
    armv5*) arch="armv5" ;;
    armv6*) arch="armv6" ;;
    armv7*) arch="armv7" ;;
  esac

  uname_arch_check "${arch}"

  log_trace "uname_arch() returned '${arch}'"

  echo "${arch}"
)

# get_release_tag [owner] [repo] [tag]
#
# outputs tag string
#
get_release_tag() (
  owner="$1"
  repo="$2"
  tag="$3"

  log_trace "get_release_tag(owner=${owner}, repo=${repo}, tag=${tag})"

  json=$(github_release_json "${owner}" "${repo}" "${tag}")
  real_tag=$(github_release_tag "${json}")
  if test -z "${real_tag}"; then
    return 1
  fi

  log_trace "get_release_tag() returned '${real_tag}'"

  echo "${real_tag}"
)

download_release() (
  tag="$1"
  os="$2"
  arch="$3"
  
  path="$HOME/.$PROJECT_NAME/bin/"
  binary_path="$path/$PROJECT_NAME"
  mkdir -p $path
  http_download "$binary_path" "$GITHUB_DOWNLOAD_PREFIX/$tag/$PROJECT_NAME-$tag-$os-$arch" ""
  chmod u+x "$binary_path"
)

update_path() (
  case ":${PATH}:" in
    *:"$HOME/.$PROJECT_NAME/bin":*)
        return 0
        ;;
    *)
        ;;
  esac

  path_cmd="PATH=\"\$HOME/.$PROJECT_NAME/bin:\${PATH}\"" 
  echo "\n\n$path_cmd" >> "$HOME/.profile"
  echo "\n\n$path_cmd" >> "$HOME/.zprofile"
)

install_shellplugin() (
  if ! grep -q "$PROJECT_NAME -s zsh" "${ZDOTDIR:-$HOME}/.zshrc"; then
    $HOME/.$PROJECT_NAME/bin/$PROJECT_NAME init zsh >> "${ZDOTDIR:-$HOME}/.zshrc"
    log_info "installed zsh plugin!"
  fi

  if ! grep -q "$PROJECT_NAME -s bash" "$HOME/.bashrc"; then
    $HOME/.$PROJECT_NAME/bin/$PROJECT_NAME init bash >> "$HOME/.bashrc"
    log_info "installed bash plugin!"
  fi

  mkdir -p "$HOME/.config/fish"
  if [ -f "$HOME/.config/fish/config.fish" ]; then
    if ! grep -q "$PROJECT_NAME -s fish" "$HOME/.config/fish/config.fish"; then
      $HOME/.$PROJECT_NAME/bin/$PROJECT_NAME init fish >> "$HOME/.config/fish/config.fish"
      log_info "installed fish plugin!"
    fi
  fi
  
)

main() (
  os=$(uname_os)

  # check if installing on windows
  if [ $os = "windows" ]; then 
    log_err "installation on windows is only supported via the powershell install script"
    return 1
  fi

  # pull latest github release
  log_info "checking github for the current release tag"
  tag=""

  tag=$(get_release_tag "${OWNER}" "${REPO}" "${tag}")
  if [ "$?" != "0" ]; then
      log_err "unable to find tag='${tag}'"
      log_err "do not specify a version or select a valid version from https://github.com/${OWNER}/${REPO}/releases"
      return 1
  fi

  update_path

  # run the install
  arch=$(uname_arch)

  # download to temp directory
  log_info "using release tag='${tag}' os='${os}' arch='${arch}'"

  # install and move to current directory
  download_release "${tag}" "${os}" "${arch}"

  if [ "$?" != "0" ]; then
      log_err "failed to install ${PROJECT_NAME}"
      return 1
  fi

  install_shellplugin
)

# entrypoint
main "$@"

cat << EOF

===============================================================================

thanks for installing kaldo!
if you have any issues, please open an issue on GitHub!
if you love kaldo, please give us a star on GitHub! it really helps ⭐️ https://github.com/cpendery/kaldo

to have kaldo take effect, restart your shell!

EOF