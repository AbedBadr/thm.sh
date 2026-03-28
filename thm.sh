#!/bin/bash

vpn_dir="$HOME/.vpn"
username="your_username" # Change this to your TryHackMe username
log_file="${vpn_dir}/thm_session.log"
pid_file="${vpn_dir}/thm_session.pid"
profile_file="$HOME/.zshrc"

mode=""
vmip=""

#### Colors ####
RED="\e[31m"
YLW="\e[33m"
CYN="\e[36m"
RST="\e[0m"

#### Helpers ####
valid_ip="^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"

error() { echo -e "${RED}[ERROR] $1${RST}" >&2; exit "${2:-1}"; }
warn()  { echo -e "${YLW}[WARN] $1${RST}"; }
info()  { echo -e "${CYN}[INFO] $1${RST}"; }

confirm() {
    msg="${1:-Are you sure?}"
    read -r -p "${msg} [Y/n]: " response
    case "${response}" in
        [nN][oO]|[nN]) return 1 ;;
        *) return 0 ;;
    esac
}

#### Functions ####
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -x, --koth         Use KOTH VPN
  -b, --lab          Use Lab VPN
  -i, --ip IP        Set VM IP (updates profile file)
  -k, --kill         Kill active VPN session
  -l, --log          Show session log
  -h, --help         Show this help
EOF
}

getLog() {
    cat "${log_file}" || warn "No log file found"
    info "Log file is located at: ${log_file}"
}

updateProfile() {
    if [[ -n "${vmip}" ]]; then
        if [[ "${vmip}" =~ ${valid_ip} ]]; then
            if confirm "Update profile with VMIP=${vmip}?"; then
                sed -i'.bak' "s/^VMIP=.*/VMIP=${vmip}/" "${profile_file}"
                info "Editing ${profile_file}: ${vmip}"
                info "Run: 'source ${profile_file}' (to reload this session, new terminals will have \$VMIP set automatically)"
            else
                warn "Skipped updating VMIP in ${profile_file}"
            fi
        else
            error "Invalid IP address: ${vmip}"
        fi
    fi
}

connect() {
    vpn_file="${vpn_dir}/thm${mode:+_${mode}}_${username}.ovpn"
    [[ -f "${vpn_file}" ]] || error "VPN file not found: ${vpn_file}"

    if [[ -f "${pid_file}" ]]; then
        info "THM VPN connected"
        exit 0
    fi

    if confirm "Connect to VPN now? (requires sudo)"; then
        info "Connecting using: ${vpn_file}"
        sudo openvpn --config "${vpn_file}" --log "${log_file}" --daemon --writepid "${pid_file}" > /dev/null 2>&1
        info "Done!"
    fi
}

disconnect() {
    if [[ ! -f "${pid_file}" ]]; then
        warn "THM VPN not connected"
        exit 1
    fi

    if confirm "Kill active VPN session?"; then
        if sudo kill "$(cat "$pid_file")"; then
            rm -f "${pid_file}"
            info "THM VPN disconnected"
            exit 0
        else
            error "Failed to kill processes"
        fi
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
     -x|--koth) mode="koth"; connect; shift ;;
     -b|--lab) mode="lab"; connect; shift ;;
     -i|--ip) vmip="$2"; updateProfile; shift 2 ;;
     -k|--kill) disconnect ;;
     -l|--log) getLog; exit 0 ;;
     -h|--help) usage; exit 0 ;;
     *) usage; error "Unkown option: $1" ;;
    esac
done
