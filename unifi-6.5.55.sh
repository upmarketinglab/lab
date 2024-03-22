#!/bin/bash

# UniFi Network Application Easy Installation Script.

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                        List of supported Distributions/Operating Systems                                                                        #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

#                       | Ubuntu Precise Pangolin ( 12.04 )
#                       | Ubuntu Trusty Tahr ( 14.04 )
#                       | Ubuntu Xenial Xerus ( 16.04 )
#                       | Ubuntu Bionic Beaver ( 18.04 )
#                       | Ubuntu Cosmic Cuttlefish ( 18.10 )
#                       | Ubuntu Disco Dingo ( 19.04 )
#                       | Ubuntu Eoan Ermine ( 19.10 )
#                       | Ubuntu Focal Fossa ( 20.04 )
#                       | Ubuntu Groovy Gorilla ( 20.10 )
#                       | Ubuntu Hirsute Hippo ( 21.04 )
#                       | Ubuntu Impish Indri ( 21.10 )
#                       | Ubuntu Jammy Jellyfish ( 22.04 )
#                       | Ubuntu Kinetic Kudu ( 22.10 )
#                       | Ubuntu Lunar Lobster ( 23.04 )
#                       | Ubuntu Mantic Minotaur ( 23.10 )
#                       | Ubuntu Noble Numbat ( 24.04 )
#                       | Debian Jessie ( 8 )
#                       | Debian Stretch ( 9 )
#                       | Debian Buster ( 10 )
#                       | Debian Bullseye ( 11 )
#                       | Debian Bookworm ( 12 )
#                       | Debian Trixie ( 13 )
#                       | Debian Forky ( 14 )
#                       | Linux Mint 13 ( Maya )
#                       | Linux Mint 17 ( Qiana | Rebecca | Rafaela | Rosa )
#                       | Linux Mint 18 ( Sarah | Serena | Sonya | Sylvia )
#                       | Linux Mint 19 ( Tara | Tessa | Tina | Tricia )
#                       | Linux Mint 20 ( Ulyana | Ulyssa | Uma | Una )
#                       | Linux Mint 21 ( Vanessa | Vera | Victoria | Virginia )
#                       | Linux Mint 4 ( Debbie )
#                       | Linux Mint 5 ( Elsie )
#                       | Linux Mint 6 ( Faye )
#                       | MX Linux 18 ( Continuum )
#                       | Progress-Linux ( Engywuck )
#                       | Parrot OS ( Lory )
#                       | Elementary OS
#                       | Deepin Linux
#                       | Kali Linux ( rolling )

###################################################################################################################################################################################################

# Version               | 6.4.2
# Application version   | 6.5.55-1d0581c00d
# Debian Repo version   | 6.5.55-16678-1
# Author                | Bruno Mota
# Email                 | bmota@duck.com
# Website               | **************

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Color Codes                                                                                           #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

RESET='\033[0m'
YELLOW='\033[1;33m'
#GRAY='\033[0;37m'
#WHITE='\033[1;37m'
GRAY_R='\033[39m'
WHITE_R='\033[39m'
RED='\033[1;31m' # Light Red.
GREEN='\033[1;32m' # Light Green.
#BOLD='\e[1m'

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Start Checks                                                                                          #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

header() {
  clear
  clear
  echo -e "${GREEN}#########################################################################${RESET}\\n"
}

header_red() {
  clear
  clear
  echo -e "${RED}#########################################################################${RESET}\\n"
}

# Check for root (SUDO).
if [[ "$EUID" -ne 0 ]]; then
  header_red
  echo -e "${WHITE_R}#${RESET} The script need to be run as root...\\n\\n"
  echo -e "${WHITE_R}#${RESET} For Ubuntu based systems run the command below to login as root"
  echo -e "${GREEN}#${RESET} sudo -i\\n"
  echo -e "${WHITE_R}#${RESET} For Debian based systems run the command below to login as root"
  echo -e "${GREEN}#${RESET} su\\n\\n"
  exit 1
fi

if ! env | grep "LC_ALL\\|LANG" | grep -iq "en_US\\|C.UTF-8"; then
  header
  echo -e "${WHITE_R}#${RESET} Your language is not set to English ( en_US ), the script will temporarily set the language to English."
  echo -e "${WHITE_R}#${RESET} Information: This is done to prevent issues in the script.."
  export LC_ALL=C &> /dev/null
  set_lc_all="true"
  sleep 3
fi

cleanup_codename_mismatch_repos() {
  if [[ -f "/etc/apt/sources.list.d/glennr-install-script.list" ]]; then
    awk '{print $3}' /etc/apt/sources.list.d/glennr-install-script.list | awk '!a[$0]++' | sed "/${os_codename}/d" | sed 's/ //g' &> /tmp/EUS/sourcelist
    while read -r sourcelist_os_codename; do
      sed -i "/${sourcelist_os_codename}/d" /etc/apt/sources.list.d/glennr-install-script.list &> /dev/null
    done < /tmp/EUS/sourcelist
    rm --force /tmp/EUS/sourcelist &> /dev/null
    if ! [[ -s "/etc/apt/sources.list.d/glennr-install-script.list" ]]; then
      rm --force /etc/apt/sources.list.d/glennr-install-script.list &> /dev/null
    fi
  fi
}

support_file() {
  if [[ "${set_lc_all}" == 'true' ]]; then unset LC_ALL; fi
  if [[ "${script_option_support_file}" == 'true' ]]; then header; fi
  echo -e "${WHITE_R}#${RESET} Creating support file..."
  mkdir -p "/tmp/EUS/support" &> /dev/null
  if dpkg -l lsb-release 2> /dev/null | grep -iq "^ii\\|^hi"; then lsb_release -a &> "/tmp/EUS/support/lsb-release"; fi
  df -h &> "/tmp/EUS/support/df"
  free -hm &> "/tmp/EUS/support/memory"
  uname -a &> "/tmp/EUS/support/uname"
  lscpu &> "/tmp/EUS/support/lscpu"
  dpkg -l | grep "mongo\\|oracle\\|openjdk\\|unifi\\|temurin" &> "/tmp/EUS/support/unifi-packages"
  dpkg -l &> "/tmp/EUS/support/dpkg-list"
  dpkg --print-architecture &> "/tmp/EUS/support/architecture"
  # shellcheck disable=SC2129
  sed -n '3p' "${script_location}" &>> "/tmp/EUS/support/script"
  grep "# Version" "${script_location}" | head -n1 &>> "/tmp/EUS/support/script"
  find "${eus_dir}" "${unifi_db_eus_dir}" -type d,f &> "/tmp/EUS/support/dirs_and_files"
  support_file_time="$(date +%Y%m%d_%H%M_%S%N)"
  if dpkg -l tar 2> /dev/null | grep -iq "^ii\\|^hi"; then
    tar czvfh "/tmp/eus_support_${support_file_time}.tar.gz" --exclude="${eus_dir}/unifi_db" --exclude="/tmp/EUS/downloads" "/tmp/EUS" "${eus_dir}" "/usr/lib/unifi/logs" "/etc/apt/sources.list" "/etc/apt/sources.list.d/" &> /dev/null
    support_file="/tmp/eus_support_${support_file_time}.tar.gz"
  elif dpkg -l zip 2> /dev/null | grep -iq "^ii\\|^hi"; then
    zip -r "/tmp/eus_support_${support_file_time}.zip" "/tmp/EUS/" "${eus_dir}/" "/usr/lib/unifi/logs/" "/etc/apt/sources.list" "/etc/apt/sources.list.d/" -x "${eus_dir}/unifi_db/*" -x "/tmp/EUS/downloads" &> /dev/null
    support_file="/tmp/eus_support_${support_file_time}.zip"
  fi
  if [[ -n "${support_file}" ]]; then echo -e "${WHITE_R}#${RESET} Support file has been created here: ${support_file} \\n"; fi
  if [[ "${script_option_support_file}" == 'true' ]]; then exit 0; fi
}

abort() {
  if [[ "${set_lc_all}" == 'true' ]]; then unset LC_ALL; fi
  if [[ -f /tmp/EUS/services/stopped_list && -s /tmp/EUS/services/stopped_list ]]; then
    while read -r service; do
      echo -e "\\n${WHITE_R}#${RESET} Starting ${service}.."
      systemctl start "${service}" && echo -e "${GREEN}#${RESET} Successfully started ${service}!" || echo -e "${RED}#${RESET} Failed to start ${service}!"
    done < /tmp/EUS/services/stopped_list
  fi
  echo -e "\\n\\n${RED}#########################################################################${RESET}\\n"
  echo -e "${WHITE_R}#${RESET} An error occurred. Aborting script..."
  echo -e "${WHITE_R}#${RESET} Please contact Glenn R. (AmazedMender16) on the UI Community Forums!"
  echo -e "${WHITE_R}#${RESET} UI Community Thread: https://community.ui.com/questions/ccbc7530-dd61-40a7-82ec-22b17f027776 \\n"
  support_file
  cleanup_codename_mismatch_repos
  exit 1
}

if uname -a | tr '[:upper:]' '[:lower:]' | grep -iq "cloudkey\\|uck\\|ubnt-mtk"; then
  eus_dir='/srv/EUS'
  is_cloudkey="true"
elif grep -iq "UCKP\\|UCKG2\\|UCK" /usr/lib/version &> /dev/null; then
  eus_dir='/srv/EUS'
  is_cloudkey="true"
else
  eus_dir='/usr/lib/EUS'
  is_cloudkey="false"
fi
if [[ "${is_cloudkey}" == "true" ]]; then
  if grep -iq "UCK.mtk7623" /usr/lib/version &> /dev/null; then
    cloudkey_generation="1"
  fi
fi

script_logo() {
  cat << "EOF"

  _______________ ___  _________  .___                 __         .__  .__   
  \_   _____/    |   \/   _____/  |   | ____   _______/  |______  |  | |  |  
   |    __)_|    |   /\_____  \   |   |/    \ /  ___/\   __\__  \ |  | |  |  
   |        \    |  / /        \  |   |   |  \\___ \  |  |  / __ \|  |_|  |__
  /_______  /______/ /_______  /  |___|___|  /____  > |__| (____  /____/____/
          \/                 \/            \/     \/            \/           

EOF
}

start_script() {
  script_location="${BASH_SOURCE[0]}"
  script_name=$(basename "${BASH_SOURCE[0]}")
  mkdir -p "${eus_dir}/logs" 2> /dev/null
  if ! [[ -d "/etc/apt/keyrings" ]]; then if ! install -m "0755" -d "/etc/apt/keyrings" &>> "${eus_dir}/logs/keyrings-directory-creation.log"; then if ! mkdir -m "0755" -p "/etc/apt/keyrings" &>> "${eus_dir}/logs/keyrings-directory-creation.log"; then echo -e "${RED}#${RESET} Failed to create \"/etc/apt/keyrings\"..."; abort; fi; fi; if ! [[ -s "${eus_dir}/logs/keyrings-directory-creation.log" ]]; then rm --force "${eus_dir}/logs/keyrings-directory-creation.log"; fi; fi
  mkdir -p /tmp/EUS/ 2> /dev/null
  mkdir -p /tmp/EUS/upgrade/ 2> /dev/null
  mkdir -p /tmp/EUS/dpkg/ 2> /dev/null
  header
  script_logo
  echo -e "    Easy UniFi Network Application Install Script"
  echo -e "\\n${WHITE_R}#${RESET} Starting the Easy UniFi Install Script.."
  echo -e "${WHITE_R}#${RESET} Thank you for using my Easy UniFi Install Script :-)\\n\\n"
  sleep 4
}
start_script

help_script() {
  if [[ "${script_option_help}" == 'true' ]]; then header; script_logo; else echo -e "${WHITE_R}----${RESET}\\n"; fi
  echo -e "    Easy UniFi Network Application Install Script assistance\\n"
  echo -e "
  Script usage:
  bash ${script_name} [options]
  
  Script options:
    --skip                                  Skip any kind of manual input.
    --skip-swap                             Skip swap file check/creation.
    --add-repository                        Add UniFi Repository if --skip is used.
    --local-install                         Inform script that it's a local UniFi Network installation, to open port 10001/udp ( discovery ).
    --custom-url [argument]                 Manually provide a UniFi Network Application download URL.
                                            example:
                                            --custom-url https://dl.ui.com/unifi/7.4.162/unifi_sysvinit_all.deb
    --help                                  Shows this information :)\\n\\n
  Script options for UniFi Easy Encrypt:
    --v6                                    Run the script in IPv6 mode instead of IPv4.
    --email [argument]                      Specify what email address you want to use
                                            for renewal notifications.
                                            example:
                                            --email glenn@glennr.nl
    --fqdn [argument]                       Specify what domain name ( FQDN ) you want to use, you
                                            can specify multiple domain names with : as seperator, see
                                            the example below:
                                            --fqdn glennr.nl:www.glennr.nl
    --server-ip [argument]                  Specify the server IP address manually.
                                            example:
                                            --server-ip 1.1.1.1
    --retry [argument]                      Retry the unattended script if it aborts for X times.
                                            example:
                                            --retry 5
    --external-dns [argument]               Use external DNS server to resolve the FQDN.
                                            example:
                                            --external-dns 1.1.1.1
    --force-renew                           Force renew the certificates.
    --dns-challenge                         Run the script in DNS mode instead of HTTP.
    --dns-provider                          Specify your DNS server provider.
                                            example:
                                            --dns-provider ovh
                                            Supported providers: cloudflare, digitalocean, dnsimple, dnsmadeeasy, gehirn, google, linode, luadns, nsone, ovh, rfc2136, route53, sakuracloud
    --dns-provider-credentials              Specify where the API credentials of your DNS provider are located.
                                            example:
                                            --dns-provider-credentials ~/.secrets/EUS/ovh.ini
    --private-key [argument]                Specify path to your private key (paid certificate)
                                            example:
                                            --private-key /tmp/PRIVATE.key
    --signed-certificate [argument]         Specify path to your signed certificate (paid certificate)
                                            example:
                                            --signed-certificate /tmp/SSL_CERTIFICATE.cer
    --chain-certificate [argument]          Specify path to your chain certificate (paid certificate)
                                            example:
                                            --chain-certificate /tmp/CHAIN.cer
    --intermediate-certificate [argument]   Specify path to your intermediate certificate (paid certificate)
                                            example:
                                            --intermediate-certificate /tmp/INTERMEDIATE.cer
    --own-certificate                       Requirement if you want to import your own paid certificates
                                            with the use of --skip.\\n\\n"
  exit 0
}

rm --force /tmp/EUS/script_options &> /dev/null
rm --force /tmp/EUS/le_script_options &> /dev/null
script_option_list=(-skip --skip --skip-swap --add-repository --local --local-controller --local-install --custom-url --help --v6 --ipv6 --email --mail --fqdn --domain-name --server-ip --server-address --retry --external-dns --force-renew --renew --dns --dns-challenge --dns-provider --dns-provider-credentials)
dns_provider_list=(cloudflare digitalocean dnsimple dnsmadeeasy gehirn google linode luadns nsone ovh rfc2136 route53 sakuracloud)

while [ -n "$1" ]; do
  case "$1" in
  -skip | --skip)
       script_option_skip="true"
       echo "--skip" &>> /tmp/EUS/script_options
       echo "--skip" &>> /tmp/EUS/le_script_options;;
  --skip-swap)
       script_option_skip_swap="true"
       echo "--skip-swap" &>> /tmp/EUS/script_options;;
  --add-repository)
       script_option_add_repository="true"
       echo "--add-repository" &>> /tmp/EUS/script_options;;
  --local | --local-controller | --local-install)
       script_option_local_install="true"
       echo "--local-install" &>> /tmp/EUS/script_options;;
  --custom-url)
       if [[ -n "${2}" ]]; then if echo "${2}" | grep -ioq ".deb"; then custom_url_down_provided="true"; custom_download_url="${2}"; else header_red; echo -e "${RED}#${RESET} Provided URL does not have the 'deb' extension...\\n"; help_script; fi; fi
       script_option_custom_url="true"
       if [[ "${custom_url_down_provided}" == 'true' ]]; then echo "--custom-url ${2}" &>> /tmp/EUS/script_options; else echo "--custom-url" &>> /tmp/EUS/script_options; fi;;
  --help)
       script_option_help="true"
       help_script;;
  --v6 | --ipv6)
       echo "--v6" &>> /tmp/EUS/le_script_options;;
  --email | --mail)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo -e "--email ${2}" &>> /tmp/EUS/le_script_options
       shift;;
  --fqdn | --domain-name)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo -e "--fqdn ${2}" &>> /tmp/EUS/le_script_options
       fqdn_specified="true"
       shift;;
  --server-ip | --server-address)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo -e "--server-ip ${2}" &>> /tmp/EUS/le_script_options
       shift;;
  --retry)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo -e "--retry ${2}" &>> /tmp/EUS/le_script_options
       shift;;
  --external-dns)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then echo -e "--external-dns" &>> /tmp/EUS/le_script_options; else echo -e "--external-dns ${2}" &>> /tmp/EUS/le_script_options; fi
       done;;
  --force-renew | --renew)
       echo -e "--force-renew" &>> /tmp/EUS/le_script_options;;
  --dns | --dns-challenge)
       echo -e "--dns-challenge" &>> /tmp/EUS/le_script_options;;
  --dns-provider)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       if ! [[ "${dns_provider_list[@]}" =~ "${2}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} DNS Provider ${2} is not supported... \\n\\n"; help_script; fi
       echo "--dns-provider ${2}" &>> /tmp/EUS/le_script_options;;
  --dns-provider-credentials)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo "--dns-provider-credentials ${2}" &>> /tmp/EUS/le_script_options;;
  --priv-key | --private-key)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo "--private-key ${2}" &>> /tmp/EUS/le_script_options
       shift;;
  --signed-crt | --signed-certificate)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo "--signed-certificate ${2}" &>> /tmp/EUS/le_script_options
       shift;;
  --chain-crt | --chain-certificate)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo "--chain-certificate ${2}" &>> /tmp/EUS/le_script_options
       shift;;
  --intermediate-crt | --intermediate-certificate)
       for option in "${script_option_list[@]}"; do
         if [[ "${2}" == "${option}" ]]; then header_red; echo -e "${WHITE_R}#${RESET} Option ${1} requires a command argument... \\n\\n"; help_script; fi
       done
       echo "--intermediate-certificate ${2}" &>> /tmp/EUS/le_script_options
       shift;;
  --own-certificate)
       echo "--own-certificate" &>> /tmp/EUS/le_script_options;;
  esac
  shift
done

# Check script options.
if [[ -f /tmp/EUS/script_options && -s /tmp/EUS/script_options ]]; then IFS=" " read -r script_options <<< "$(tr '\r\n' ' ' < /tmp/EUS/script_options)"; fi

if [[ "$(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "downloads-distro.mongodb.org")" -gt 0 ]]; then
  grep -riIl "downloads-distro.mongodb.org" /etc/apt/ &>> /tmp/EUS/repository/dead_mongodb_repository
  while read -r glennr_mongo_repo; do
    sed -i '/downloads-distro.mongodb.org/d' "${glennr_mongo_repo}" 2> /dev/null
	if ! [[ -s "${glennr_mongo_repo}" ]]; then
      rm --force "${glennr_mongo_repo}" 2> /dev/null
    fi
  done < /tmp/EUS/repository/dead_mongodb_repository
  rm --force /tmp/EUS/repository/dead_mongodb_repository
fi

# Check if DST_ROOT certificate exists
if grep -siq "^mozilla/DST_Root" /etc/ca-certificates.conf; then
  echo -e "${WHITE_R}#${RESET} Detected DST_Root certificate..."
  if sed -i '/^mozilla\/DST_Root_CA_X3.crt$/ s/^/!/' /etc/ca-certificates.conf; then
    echo -e "${GREEN}#${RESET} Successfully commented out the DST_Root certificate! \\n"
    update-ca-certificates &> /dev/null
  else
    echo -e "${RED}#${RESET} Failed to comment out the DST_Root certificate... \\n"
  fi
fi

# Check if apt-key is deprecated
aptkey_depreciated() {
  apt-key list >/tmp/EUS/aptkeylist 2>&1
  if grep -ioq "apt-key is deprecated" /tmp/EUS/aptkeylist; then apt_key_deprecated="true"; fi
  rm --force /tmp/EUS/aptkeylist
}
aptkey_depreciated

find "${eus_dir}/logs/" -printf "%f\\n" | grep '.*.log' | awk '!a[$0]++' &> /tmp/EUS/log_files
while read -r log_file; do
  if [[ -f "${eus_dir}/logs/${log_file}" ]]; then
    log_file_size=$(stat -c%s "${eus_dir}/logs/${log_file}")
    if [[ "${log_file_size}" -gt "10485760" ]]; then
      tail -n1000 "${eus_dir}/logs/${log_file}" &> "${log_file}.tmp"
      mv "${eus_dir}/logs/${log_file}.tmp" "${eus_dir}/logs/${log_file}"
    fi
  fi
done < /tmp/EUS/log_files
rm --force /tmp/EUS/log_files

run_apt_get_update() {
  if ! [[ -d /tmp/EUS/keys ]]; then mkdir -p /tmp/EUS/keys; fi
  if ! [[ -s /tmp/EUS/keys/missing_keys ]]; then
    if [[ "${no_output_hide_apt_update}" == 'true' ]]; then
      apt-get update &> /tmp/EUS/keys/apt_update
      unset no_output_hide_apt_update
    elif [[ "${hide_apt_update}" == 'true' ]]; then
      echo -e "${WHITE_R}#${RESET} Running apt-get update..."
      if apt-get update &> /tmp/EUS/keys/apt_update; then echo -e "${GREEN}#${RESET} Successfully ran apt-get update! \\n"; else echo -e "${YELLOW}#${RESET} Something went wrong during running apt-get update! \\n"; fi
      unset hide_apt_update
    else
      apt-get update 2>&1 | tee /tmp/EUS/keys/apt_update
    fi
    grep -o 'NO_PUBKEY.*' /tmp/EUS/keys/apt_update | sed 's/NO_PUBKEY //g' | tr ' ' '\n' | awk '!a[$0]++' &> /tmp/EUS/keys/missing_keys
    if [[ -s "/tmp/EUS/keys/missing_keys_done" ]]; then
      while read -r key_done; do
        if grep -ioq "${key_done}" /tmp/EUS/keys/missing_keys; then sed -i "/${key_done}/d" /tmp/EUS/keys/missing_keys; fi
      done < /tmp/EUS/keys/missing_keys_done
    fi
  fi
  if [[ -s /tmp/EUS/keys/missing_keys ]]; then
    #header
    #echo -e "${WHITE_R}#${RESET} Some keys are missing.. The script will try to add the missing keys."
    #echo -e "\\n${WHITE_R}----${RESET}\\n"
    if dpkg -l dirmngr 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
      while read -r key; do
        echo -e "${WHITE_R}#${RESET} Key ${key} is missing.. adding!"
        http_proxy=$(env | grep -i "http.*Proxy" | cut -d'=' -f2 | sed 's/[";]//g')
        if [[ -n "$http_proxy" ]]; then
          apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="${http_proxy}" --recv-keys "$key" &> /dev/null && echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n" || fail_key="true"
        elif [[ -f /etc/apt/apt.conf ]]; then
          apt_http_proxy=$(grep "http.*Proxy" /etc/apt/apt.conf | awk '{print $2}' | sed 's/[";]//g')
          if [[ -n "${apt_http_proxy}" ]]; then
            apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="${apt_http_proxy}" --recv-keys "$key" &> /dev/null && echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n" || fail_key="true"
          fi
        else
          apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv "$key" &> /dev/null && echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n" && echo "${key}" /tmp/EUS/keys/missing_keys_done || fail_key="true"
        fi
        if [[ "${fail_key}" == 'true' ]]; then
          echo -e "${RED}#${RESET} Failed to add key ${key}... \\n"
          echo -e "${WHITE_R}#${RESET} Trying different method to get key: ${key}"
          gpg -vvv --debug-all --keyserver keyserver.ubuntu.com --recv-keys "${key}" &> /tmp/EUS/keys/failed_key
          debug_key=$(grep "KS_GET" /tmp/EUS/keys/failed_key | grep -io "0x.*")
          if wget -q "https://keyserver.ubuntu.com/pks/lookup?op=get&search=${debug_key}" -O- | gpg --dearmor > "/tmp/EUS/keys/EUS-${key}.gpg"; then
            mv "/tmp/EUS/keys/EUS-${key}.gpg" /etc/apt/trusted.gpg.d/ && echo -e "${GREEN}#${RESET} Successfully added key ${key}!\\n" && echo "${key}" /tmp/EUS/keys/missing_keys_done
          else
            echo -e "${RED}#${RESET} Failed to add key ${key}... \\n"
          fi
        fi
        sleep 1
      done < /tmp/EUS/keys/missing_keys
      rm --force /tmp/EUS/keys/missing_keys
      rm --force /tmp/EUS/keys/apt_update
    else
      echo -e "${WHITE_R}#${RESET} Keys appear to be missing..." && sleep 1
      echo -e "${YELLOW}#${RESET} Required package dirmngr is missing... cannot recover keys... \\n"
    fi
    #header
    #echo -e "${WHITE_R}#${RESET} Running apt-get update again.\\n\\n"
    #sleep 2
    apt-get update &> /tmp/EUS/keys/apt_update
    if dpkg -l dirmngr 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
      if grep -qo 'NO_PUBKEY.*' /tmp/EUS/keys/apt_update; then
        if [[ "${hide_apt_update}" != 'true' ]]; then hide_apt_update="true"; fi
        run_apt_get_update
      fi
    fi
  fi
}

add_glennr_mongod_repo() {
  repo_http_https="https"
  if [[ "${mongodb_upgrade_import_failure}" == 'true' ]]; then skip_mongod_armv8_v="true"; fi
  if [[ "${skip_mongod_armv8_v}" != 'true' ]]; then mongod_armv8_v="$(dpkg -l | grep "mongod-armv8" | grep -i "^ii\\|^hi" | awk '{print $3}' | sed 's/\.//g' | sed 's/.*://' | sed 's/-.*//g' | sed 's/+.*//g' | sort -V | tail -n 1)"; fi
  if [[ "${mongod_armv8_v::2}" == '70' ]] || [[ "${add_mongod_70_repo}" == 'true' ]]; then
    mongod_version_major_minor="7.0"
    mongod_repo_type="mongod/7.0"
    if [[ "${os_codename}" =~ (stretch|continuum) ]]; then
      mongod_codename="repo stretch"
    elif [[ "${os_codename}" =~ (buster|bullseye|bookworm|trixie|forky) ]]; then
      mongod_codename="repo ${os_codename}"
    elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|loki) ]]; then
      mongod_codename="repo xenial"
    elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia|hera|juno) ]]; then
      mongod_codename="repo bionic"
    elif [[ "${os_codename}" =~ (focal|groovy|hirsute|impish) ]]; then
      mongod_codename="repo focal"
    elif [[ "${os_codename}" =~ (jammy|kinetic|lunar|mantic) ]]; then
      mongod_codename="repo jammy"
    elif [[ "${os_codename}" =~ (noble) ]]; then
      mongod_codename="repo noble"
    else
      mongod_codename="repo xenial"
    fi
  fi
  if [[ -n "${mongod_version_major_minor}" ]]; then
    if ! [[ -s "/etc/apt/keyrings/apt-glennr.gpg" ]]; then
      echo -e "${WHITE_R}#${RESET} Adding key for the Glenn R. APT Repository..."
      aptkey_depreciated
      if [[ "${apt_key_deprecated}" == 'true' ]]; then
        if curl -fsSL "${repo_http_https}://get.glennr.nl/apt/keys/apt-glennr.asc" | gpg -o "/etc/apt/keyrings/apt-glennr.gpg" --dearmor &> /dev/null; then
          echo -e "${GREEN}#${RESET} Successfully added the key for the Glenn R. APT Repository! \\n"
          signed_by_value=" signed-by=/etc/apt/keyrings/apt-glennr.gpg"
        else
          echo -e "${RED}#${RESET} Failed to add the key for the Glenn R. APT Repository...\\n"
          abort
        fi
      else
        if wget -qO - "${repo_http_https}://get.glennr.nl/apt/keys/apt-glennr.asc" | apt-key add - &> /dev/null; then
          echo -e "${GREEN}#${RESET} Successfully added the key for the Glenn R. APT Repository! \\n"
        else
          echo -e "${RED}#${RESET} Failed to add the key for the Glenn R. APT Repository...\\n"
          abort
        fi
      fi
    else
      signed_by_value=" signed-by=/etc/apt/keyrings/apt-glennr.gpg"
    fi
    echo -e "${WHITE_R}#${RESET} Adding the Glenn R. APT reposity for mongod ${mongod_version_major_minor}..."
    if [[ "${architecture}" == 'arm64' ]]; then arch="arch=arm64"; elif [[ "${architecture}" == 'amd64' ]]; then arch="arch=amd64"; else arch="arch=amd64,arm64"; fi
    if echo "deb [ ${arch}${signed_by_value} ] ${repo_http_https}://apt.glennr.nl/${mongod_codename} ${mongod_repo_type}" &> "/etc/apt/sources.list.d/glennr-mongod-${mongod_version_major_minor}.list"; then
      echo -e "${GREEN}#${RESET} Successfully added the Glenn R. APT reposity for mongod ${mongod_version_major_minor}!\\n" && sleep 2
      if [[ "${mongodb_key_update}" != 'true' ]]; then
        hide_apt_update="true"
        run_apt_get_update
        mongod_upgrade_to_version_with_dot="$(apt-cache policy mongod-armv8 | grep -i "${mongo_version_max_with_dot}" | grep -i Candidate | sed 's/ //g' | cut -d':' -f2)"
        if [[ -z "${mongod_upgrade_to_version_with_dot}" ]]; then mongod_upgrade_to_version_with_dot="$(apt-cache policy mongod-armv8 | grep -i "${mongo_version_max_with_dot}" | sed -e 's/500//g' | sed 's/ //g' | cut -d':' -f2 | sed '/mongod/d' | sed 's/*//g' | sort -r -V | head -n 1)"; fi
        mongod_upgrade_to_version="${mongod_upgrade_to_version_with_dot//./}"
        if [[ "${mongod_upgrade_to_version::2}" == "${mongo_version_max}" ]]; then
          install_mongod_version="${mongod_upgrade_to_version_with_dot}"
          install_mongod_version_with_equality_sign="=${mongod_upgrade_to_version_with_dot}"
        fi
      fi
    else
      echo -e "${RED}#${RESET} Failed to add the Glenn R. APT reposity for mongod ${mongod_version_major_minor}..."
      abort
    fi
  fi
  unset mongod_armv8_v
}

add_extra_repo_mongodb() {
  unset repo_arguments
  unset repo_url
  if [[ "${os_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
    if [[ "${architecture}" =~ (amd64|i386) ]]; then
      if [[ "${add_extra_repo_mongodb_security}" == 'true' ]]; then
        repo_url="http://security.ubuntu.com/ubuntu"
        repo_arguments="-security main"
      fi
    else
      repo_url="http://ports.ubuntu.com"
    fi
  fi
  if [[ -z "${repo_arguments}" ]]; then repo_arguments=" main"; fi
  if [[ -z "${repo_url}" ]]; then get_repo_url; fi
  repo_codename="${add_extra_repo_mongodb_codename}"
  os_codename="${add_extra_repo_mongodb_codename}"
  add_repositories
  get_distro
  get_repo_url
  unset add_extra_repo_mongodb_security
  unset add_extra_repo_mongodb_codename
}

add_mongodb_repo() {
  if [[ "${glennr_compiled_mongod}" == 'true' ]]; then add_glennr_mongod_repo; fi
  if [[ "${mongodb_key_update}" == 'true' ]]; then skip_mongodb_org_v="true"; elif [[ "${mongodb_upgrade_import_failure}" == 'true' ]]; then skip_mongodb_org_v="true"; fi
  if [[ "${skip_mongodb_org_v}" != 'true' ]]; then
    mongodb_org_v="$(dpkg -l | grep "mongodb-org-server" | grep -i "^ii\\|^hi" | awk '{print $3}' | sed 's/\.//g' | sed 's/.*://' | sed 's/-.*//g' | sed 's/+.*//g' | sort -V | tail -n 1)"
  fi
  repo_http_https="https"
  if [[ "${mongodb_org_v::2}" == '32' ]] || [[ "${add_mongodb_32_repo}" == 'true' ]]; then
    if [[ "${architecture}" == "arm64" ]]; then add_mongodb_34_repo="true"; unset add_mongodb_32_repo; fi
    mongodb_version_major_minor="3.2"
    if [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      mongodb_codename="ubuntu trusty"
      mongodb_repo_type="multiverse"
    elif [[ "${os_codename}" == "jessie" ]]; then
      mongodb_codename="debian jessie"
      mongodb_repo_type="main"
    else
      mongodb_codename="ubuntu xenial"
      mongodb_repo_type="multiverse"
    fi
  fi
  if [[ "${mongodb_org_v::2}" == '34' ]] || [[ "${add_mongodb_34_repo}" == 'true' ]]; then
    mongodb_version_major_minor="3.4"
    if [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      mongodb_codename="ubuntu trusty"
      mongodb_repo_type="multiverse"
    elif [[ "${os_codename}" == "jessie" ]]; then
      mongodb_codename="debian jessie"
      mongodb_repo_type="main"
    else
      mongodb_codename="ubuntu xenial"
      mongodb_repo_type="multiverse"
    fi
  fi
  if [[ "${mongodb_org_v::2}" == '36' ]] || [[ "${add_mongodb_36_repo}" == 'true' ]]; then
    mongodb_version_major_minor="3.6"
    if [[ "${try_different_mongodb_repo}" == 'true' ]] || [[ "${architecture}" != "amd64" ]]; then
      if [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
        mongodb_codename="ubuntu trusty"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|bullseye|bookworm|trixie|forky) ]]; then
        mongodb_codename="ubuntu bionic"
        mongodb_repo_type="multiverse"
      else
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      fi
    else
      if [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" == "jessie" ]]; then
        mongodb_codename="debian jessie"
        mongodb_repo_type="main"
      elif [[ "${os_codename}" =~ (stretch|continuum|buster|bullseye|bookworm|trixie|forky) ]]; then
        mongodb_codename="debian stretch"
        mongodb_repo_type="main"
      else
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      fi
    fi
  fi
  if [[ "${mongodb_org_v::2}" == '40' ]] || [[ "${add_mongodb_40_repo}" == 'true' ]]; then
    mongodb_version_major_minor="4.0"
    if [[ "${try_different_mongodb_repo}" == 'true' ]] || [[ "${architecture}" != "amd64" ]]; then
      if [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
        mongodb_codename="ubuntu trusty"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|bullseye|bookworm|trixie|forky) ]]; then
        mongodb_codename="ubuntu bionic"
        mongodb_repo_type="multiverse"
      else
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      fi
    else
      if [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" == "jessie" ]]; then
        mongodb_codename="debian jessie"
        mongodb_repo_type="main"
      elif [[ "${os_codename}" =~ (stretch|continuum|buster|bullseye|bookworm|trixie|forky) ]]; then
        mongodb_codename="debian stretch"
        mongodb_repo_type="main"
      else
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      fi
    fi
  fi
  if [[ "${mongodb_org_v::2}" == '42' ]] || [[ "${add_mongodb_42_repo}" == 'true' ]]; then
    mongodb_version_major_minor="4.2"
    if [[ "${try_different_mongodb_repo}" == 'true' ]] || [[ "${architecture}" != "amd64" ]]; then
      if [[ "${os_codename}" =~ (stretch|buster|bullseye|bookworm|trixie|forky|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
        mongodb_codename="ubuntu bionic"
        mongodb_repo_type="multiverse"
      else
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      fi
    else
      if [[ "${os_codename}" =~ (stretch|continuum) ]]; then
        mongodb_codename="debian stretch"
        mongodb_repo_type="main"
      elif [[ "${os_codename}" =~ (buster|bullseye|bookworm|trixie|forky) ]]; then
        mongodb_codename="debian buster"
        mongodb_repo_type="main"
      elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|loki) ]]; then
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia|hera|juno|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
        mongodb_codename="ubuntu bionic"
        mongodb_repo_type="multiverse"
      else
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      fi
    fi
  fi
  if [[ "${mongodb_org_v::2}" == '44' ]] || [[ "${add_mongodb_44_repo}" == 'true' ]]; then
    mongodb_version_major_minor="4.4"
    if [[ "${try_different_mongodb_repo}" == 'true' ]] || [[ "${architecture}" != "amd64" ]]; then
      if [[ "${os_codename}" =~ (stretch|bionic|tara|tessa|tina|tricia|hera|juno) ]]; then
        mongodb_codename="ubuntu bionic"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (buster|bullseye|bookworm|trixie|forky|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
        mongodb_codename="ubuntu focal"
        mongodb_repo_type="multiverse"
      else
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      fi
    else
      if [[ "${os_codename}" =~ (stretch|continuum) ]]; then
        mongodb_codename="debian stretch"
        mongodb_repo_type="main"
      elif [[ "${os_codename}" =~ (buster|bullseye|bookworm|trixie|forky) ]]; then
        mongodb_codename="debian buster"
        mongodb_repo_type="main"
      elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|loki) ]]; then
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia|hera|juno) ]]; then
        mongodb_codename="ubuntu bionic"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
        mongodb_codename="ubuntu focal"
        mongodb_repo_type="multiverse"
      else
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      fi
    fi
  fi
  if [[ "${mongodb_org_v::2}" == '50' ]] || [[ "${add_mongodb_50_repo}" == 'true' ]]; then
    mongodb_version_major_minor="5.0"
    if [[ "${try_different_mongodb_repo}" == 'true' ]] || [[ "${architecture}" != "amd64" ]]; then
      if [[ "${os_codename}" =~ (stretch|buster|bullseye|bookworm|trixie|forky|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
        mongodb_codename="ubuntu focal"
        mongodb_repo_type="multiverse"
      else
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      fi
    else
      if [[ "${os_codename}" =~ (stretch|continuum) ]]; then
        mongodb_codename="debian stretch"
        mongodb_repo_type="main"
      elif [[ "${os_codename}" =~ (buster) ]]; then
        mongodb_codename="debian buster"
        mongodb_repo_type="main"
      elif [[ "${os_codename}" =~ (bullseye|bookworm|trixie|forky) ]]; then
        mongodb_codename="debian bullseye"
        mongodb_repo_type="main"
      elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|loki) ]]; then
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia|hera|juno) ]]; then
        mongodb_codename="ubuntu bionic"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
        mongodb_codename="ubuntu focal"
        mongodb_repo_type="multiverse"
      else
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      fi
    fi
  fi
  if [[ "${mongodb_org_v::2}" == '60' ]] || [[ "${add_mongodb_60_repo}" == 'true' ]]; then
    mongodb_version_major_minor="6.0"
    if [[ "${try_different_mongodb_repo}" == 'true' ]] || [[ "${architecture}" != "amd64" ]]; then
      if [[ "${os_codename}" =~ (stretch|buster|bullseye|bookworm|trixie|forky|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
        mongodb_codename="ubuntu jammy"
        mongodb_repo_type="multiverse"
      else
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      fi
    else
      if [[ "${os_codename}" =~ (stretch|continuum|buster) ]]; then
        mongodb_codename="debian buster"
        mongodb_repo_type="main"
      elif [[ "${os_codename}" =~ (bullseye|bookworm|trixie|forky) ]]; then
        mongodb_codename="debian bullseye"
        mongodb_repo_type="main"
      elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|loki) ]]; then
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (bionic|tara|tessa|tina|tricia|hera|juno) ]]; then
        mongodb_codename="ubuntu bionic"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (focal|groovy|hirsute|impish) ]]; then
        mongodb_codename="ubuntu focal"
        mongodb_repo_type="multiverse"
      elif [[ "${os_codename}" =~ (jammy|kinetic|lunar|mantic|noble) ]]; then
        mongodb_codename="ubuntu jammy"
        mongodb_repo_type="multiverse"
      else
        mongodb_codename="ubuntu xenial"
        mongodb_repo_type="multiverse"
      fi
    fi
  fi
  if [[ "${mongodb_org_v::2}" == '70' ]] || [[ "${add_mongodb_70_repo}" == 'true' ]]; then
    mongodb_version_major_minor="7.0"
    if [[ "${try_different_mongodb_repo}" == 'true' ]] || [[ "${architecture}" != "amd64" ]]; then
      if [[ "${os_codename}" =~ (stretch|buster|bullseye|focal|groovy|hirsute|impish) ]]; then
        mongodb_codename="ubuntu focal"
        mongodb_repo_type="multiverse"
        if [[ "${os_codename}" =~ (stretch|buster) ]]; then
          add_extra_repo_mongodb_codename="bullseye"
          add_extra_repo_mongodb
        fi
      elif [[ "${os_codename}" =~ (bookworm|trixie|forky|jammy|kinetic|lunar|mantic|noble) ]]; then
        mongodb_codename="ubuntu jammy"
        mongodb_repo_type="multiverse"
      else
        mongodb_codename="ubuntu focal"
        mongodb_repo_type="multiverse"
        if [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|loki|bionic|tara|tessa|tina|tricia|hera|juno) ]]; then
          add_extra_repo_mongodb_security="true"
          add_extra_repo_mongodb_codename="focal"
          add_extra_repo_mongodb
          add_extra_repo_mongodb_codename="focal"
          add_extra_repo_mongodb
        fi
      fi
    else
      if [[ "${os_codename}" =~ (stretch|continuum|buster) ]]; then
        mongodb_codename="ubuntu focal"
        mongodb_repo_type="main"
        if [[ "${os_codename}" =~ (stretch|continuum|buster) ]]; then
          add_extra_repo_mongodb_codename="bullseye"
          add_extra_repo_mongodb
        fi
      elif [[ "${os_codename}" =~ (bullseye|bookworm|trixie|forky) ]]; then
        mongodb_codename="debian bullseye"
        mongodb_repo_type="main"
      elif [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|loki|bionic|tara|tessa|tina|tricia|hera|juno|focal|groovy|hirsute|impish) ]]; then
        mongodb_codename="ubuntu focal"
        mongodb_repo_type="multiverse"
        if [[ "${os_codename}" =~ (xenial|sarah|serena|sonya|sylvia|loki|bionic|tara|tessa|tina|tricia|hera|juno) ]]; then
          add_extra_repo_mongodb_security="true"
          add_extra_repo_mongodb_codename="focal"
          add_extra_repo_mongodb
          add_extra_repo_mongodb_codename="focal"
          add_extra_repo_mongodb
        fi
      elif [[ "${os_codename}" =~ (jammy|kinetic|lunar|mantic|noble) ]]; then
        mongodb_codename="ubuntu jammy"
        mongodb_repo_type="multiverse"
      else
        mongodb_codename="ubuntu focal"
        mongodb_repo_type="multiverse"
      fi
    fi
  fi
  if [[ "$(curl -s https://get.glennr.nl/unifi/releases/mongodb-versions.json | jq -r '.versions."'${mongodb_version_major_minor}'".expired')" == 'true' ]]; then trusted_mongodb_repo=" trusted=yes"; fi
  if ! [[ -d "${eus_dir}/data" ]]; then mkdir -p "${eus_dir}/data"; fi
  echo -e "$(date +%s)" &> "${eus_dir}/data/mongodb-key-check-time"
  if [[ "${try_different_mongodb_repo}" == 'true' ]]; then try_different_mongodb_repo_test="a different"; try_different_mongodb_repo_test_2="different "; else try_different_mongodb_repo_test="the"; try_different_mongodb_repo_test_2=""; fi
  if [[ "${try_http_mongodb_repo}" == 'true' ]]; then repo_http_https="http"; try_different_mongodb_repo_test="a HTTP instead of HTTPS"; try_different_mongodb_repo_test_2="HTTP "; else try_different_mongodb_repo_test="the"; try_different_mongodb_repo_test_2=""; fi
  if [[ -n "${mongodb_version_major_minor}" ]]; then
    if ! [[ -s "/etc/apt/keyrings/mongodb-server-${mongodb_version_major_minor}.gpg" ]] || [[ "${mongodb_key_update}" == 'true' ]]; then
      echo -e "${WHITE_R}#${RESET} Adding key for MongoDB ${mongodb_version_major_minor}..."
      aptkey_depreciated
      if [[ "${apt_key_deprecated}" == 'true' ]]; then
        if wget -qO - "${repo_http_https}://pgp.mongodb.com/server-${mongodb_version_major_minor}.asc" | gpg --dearmor | tee -a "/etc/apt/keyrings/mongodb-server-${mongodb_version_major_minor}.gpg" &> /dev/null; then
          echo -e "${GREEN}#${RESET} Successfully added the key for MongoDB ${mongodb_version_major_minor}! \\n"
          signed_by_value=" signed-by=/etc/apt/keyrings/mongodb-server-${mongodb_version_major_minor}.gpg"
        else
          if ! wget -qO - "${repo_http_https}://www.mongodb.org/static/pgp/server-${mongodb_version_major_minor}.asc" | gpg --dearmor | tee -a "/etc/apt/keyrings/mongodb-server-${mongodb_version_major_minor}.gpg" &> /dev/null; then
            echo -e "${RED}#${RESET} Failed to add the key for MongoDB ${mongodb_version_major_minor}...\\n"
            abort
          fi
        fi
      else
        if wget -qO - "${repo_http_https}://pgp.mongodb.com/server-${mongodb_version_major_minor}.asc" | apt-key add - &> /dev/null; then
          echo -e "${GREEN}#${RESET} Successfully added the key for MongoDB ${mongodb_version_major_minor}! \\n"
        else
          if ! wget -qO - "${repo_http_https}://www.mongodb.org/static/pgp/server-${mongodb_version_major_minor}.asc" | apt-key add - &> /dev/null; then
            echo -e "${RED}#${RESET} Failed to add the key for MongoDB ${mongodb_version_major_minor}...\\n"
            abort
          fi
        fi
      fi
    else
      signed_by_value=" signed-by=/etc/apt/keyrings/mongodb-server-${mongodb_version_major_minor}.gpg"
    fi
    echo -e "${WHITE_R}#${RESET} Adding ${try_different_mongodb_repo_test} MongoDB ${mongodb_version_major_minor} repository..."
    if [[ "${architecture}" == 'arm64' ]]; then arch="arch=arm64"; elif [[ "${architecture}" == 'amd64' ]]; then arch="arch=amd64"; else arch="arch=amd64,arm64"; fi
    if echo "deb [ ${arch}${signed_by_value}${trusted_mongodb_repo} ] ${repo_http_https}://repo.mongodb.org/apt/${mongodb_codename}/mongodb-org/${mongodb_version_major_minor} ${mongodb_repo_type}" &> "/etc/apt/sources.list.d/mongodb-org-${mongodb_version_major_minor}.list"; then
      echo -e "${GREEN}#${RESET} Successfully added the ${try_different_mongodb_repo_test_2}MongoDB ${mongodb_version_major_minor} repository!\\n" && sleep 2
      if [[ "${mongodb_key_update}" != 'true' ]]; then
        hide_apt_update="true"
        run_apt_get_update
        mongodb_org_upgrade_to_version_with_dot="$(apt-cache policy mongodb-org-server | grep -i "${mongo_version_max_with_dot}" | grep -i Candidate | sed 's/ //g' | cut -d':' -f2)"
        if [[ -z "${mongodb_org_upgrade_to_version_with_dot}" ]]; then mongodb_org_upgrade_to_version_with_dot="$(apt-cache policy mongodb-org-server | grep -i "${mongo_version_max_with_dot}" | sed -e 's/500//g' | sed 's/ //g' | cut -d':' -f2 | sed '/mongodb/d' | sort -r -V | head -n 1)"; fi
        mongodb_org_upgrade_to_version="${mongodb_org_upgrade_to_version_with_dot//./}"
        if [[ -n "${arm64_mongodb_version}" ]]; then install_mongodb_version="${arm64_mongodb_version}"; install_mongodb_version_with_equality_sign="=${arm64_mongodb_version}"; fi
        if [[ "${mongodb_org_upgrade_to_version::2}" == "${mongo_version_max}" ]]; then
          if [[ -z "${arm64_mongodb_version}" ]]; then
            install_mongodb_version="${mongodb_org_upgrade_to_version_with_dot}"
            install_mongodb_version_with_equality_sign="=${mongodb_org_upgrade_to_version_with_dot}"
          fi
        fi
      fi
    else
      echo -e "${RED}#${RESET} Failed to add the ${try_different_mongodb_repo_test_2}MongoDB ${mongodb_version_major_minor} repository..."
      abort
    fi
  fi
  unset skip_mongodb_org_v
}

# Check if system runs Unifi OS
if dpkg -l unifi-core 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  unifi_core_system="true"
  if [[ -f /proc/ubnthal/system.info ]]; then if grep -iq "shortname" /proc/ubnthal/system.info; then unifi_core_device=$(grep "shortname" /proc/ubnthal/system.info | sed 's/shortname=//g'); fi; fi
  if [[ -f /etc/motd && -s /etc/motd && -z "${unifi_core_device}" ]]; then unifi_core_device=$(grep -io "welcome.*" /etc/motd | sed -e 's/Welcome //g' -e 's/to //g' -e 's/the //g' -e 's/!//g'); fi
  if [[ -f /usr/lib/version && -s /usr/lib/version && -z "${unifi_core_device}" ]]; then unifi_core_device=$(cut -d'.' -f1 /usr/lib/version); fi
  if [[ -z "${unifi_core_device}" ]]; then unifi_core_device='Unknown device'; fi
fi

cancel_script() {
  if [[ "${set_lc_all}" == 'true' ]]; then unset LC_ALL &> /dev/null; fi
  if [[ "${script_option_skip}" == 'true' ]]; then
    echo -e "\\n${WHITE_R}#########################################################################${RESET}\\n"
  else
    header
  fi
  echo -e "${WHITE_R}#${RESET} Cancelling the script!\\n\\n"
  author
  remove_yourself
  exit 0
}

http_proxy_found() {
  header
  echo -e "${GREEN}#${RESET} HTTP Proxy found. | ${WHITE_R}${http_proxy}${RESET}\\n\\n"
}

remove_yourself() {
  if [[ "${set_lc_all}" == 'true' ]]; then unset LC_ALL &> /dev/null; fi
  if [[ "${delete_script}" == 'true' || "${script_option_skip}" == 'true' ]]; then if [[ -e "${script_location}" ]]; then rm --force "${script_location}" 2> /dev/null; fi; fi
}

christmass_new_year() {
  date_d=$(date '+%d' | sed "s/^0*//g; s/\.0*/./g")
  date_m=$(date '+%m' | sed "s/^0*//g; s/\.0*/./g")
  if [[ "${date_m}" == '12' && "${date_d}" -ge '18' && "${date_d}" -lt '26' ]]; then
    echo -e "\\n${WHITE_R}----${RESET}\\n"
    echo -e "${WHITE_R}#${RESET} GlennR wishes you a Merry Christmas! May you be blessed with health and happiness!"
    christmas_message="true"
  fi
  if [[ "${date_m}" == '12' && "${date_d}" -ge '24' && "${date_d}" -le '30' ]]; then
    if [[ "${christmas_message}" != 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; fi
    if [[ "${christmas_message}" == 'true' ]]; then echo -e ""; fi
    date_y=$(date -d "+1 year" +"%Y")
    echo -e "${WHITE_R}#${RESET} HAPPY NEW YEAR ${date_y}"
    echo -e "${WHITE_R}#${RESET} May the new year turn all your dreams into reality and all your efforts into great achievements!"
    new_year_message="true"
  elif [[ "${date_m}" == '12' && "${date_d}" == '31' ]]; then
    if [[ "${christmas_message}" != 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; fi
    if [[ "${christmas_message}" == 'true' ]]; then echo -e ""; fi
    date_y=$(date -d "+1 year" +"%Y")
    echo -e "${WHITE_R}#${RESET} HAPPY NEW YEAR ${date_y}"
    echo -e "${WHITE_R}#${RESET} Tomorrow, is the first blank page of a 365 page book. Write a good one!"
    new_year_message="true"
  fi
  if [[ "${date_m}" == '1' && "${date_d}" -le '5' ]]; then
    if [[ "${christmas_message}" != 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; fi
    if [[ "${christmas_message}" == 'true' ]]; then echo -e ""; fi
    date_y=$(date '+%Y')
    echo -e "${WHITE_R}#${RESET} HAPPY NEW YEAR ${date_y}"
    echo -e "${WHITE_R}#${RESET} May this new year all your dreams turn into reality and all your efforts into great achievements"
    new_year_message="true"
  fi
}

author() {
  cleanup_codename_mismatch_repos
  christmass_new_year
  if [[ "${new_year_message}" == 'true' || "${christmas_message}" == 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n"; fi
  if [[ "${archived_repo}" == 'true' && "${unifi_core_system}" != 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n\\n${RED}# ${RESET}Looks like you're using a ${RED}EOL/unsupported${RESET} OS Release (${os_codename})\\n${RED}# ${RESET}Please update to a supported release...\\n"; fi
  if [[ "${archived_repo}" == 'true' && "${unifi_core_system}" == 'true' ]]; then echo -e "\\n${WHITE_R}----${RESET}\\n\\n${RED}# ${RESET}Please update to the latest UniFi OS Release!\\n"; fi
  echo -e "${WHITE_R}#${RESET} ${GRAY_R}Author   |  ${WHITE_R}Glenn R.${RESET}"
  echo -e "${WHITE_R}#${RESET} ${GRAY_R}Email    |  ${WHITE_R}glennrietveld8@hotmail.nl${RESET}"
  echo -e "${WHITE_R}#${RESET} ${GRAY_R}Website  |  ${WHITE_R}https://GlennR.nl${RESET}"
  echo -e "\\n\\n"
}

# Set architecture
architecture=$(dpkg --print-architecture)
if [[ "${architecture}" == 'i686' ]]; then architecture="i386"; fi

# Get distro.
get_distro() {
  if [[ -z "$(command -v lsb_release)" ]] || [[ "${skip_use_lsb_release}" == 'true' ]]; then
    if [[ -f "/etc/os-release" ]]; then
      if grep -iq VERSION_CODENAME /etc/os-release; then
        os_codename=$(grep VERSION_CODENAME /etc/os-release | sed 's/VERSION_CODENAME//g' | tr -d '="' | tr '[:upper:]' '[:lower:]')
      elif ! grep -iq VERSION_CODENAME /etc/os-release; then
        os_codename=$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="' | awk '{print $4}' | sed 's/\((\|)\)//g' | sed 's/\/sid//g' | tr '[:upper:]' '[:lower:]')
        if [[ -z "${os_codename}" ]]; then
          os_codename=$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="' | awk '{print $3}' | sed 's/\((\|)\)//g' | sed 's/\/sid//g' | tr '[:upper:]' '[:lower:]')
        fi
      fi
    fi
  else
    os_codename=$(lsb_release -cs | tr '[:upper:]' '[:lower:]')
    if [[ "${os_codename}" == 'n/a' ]]; then
      skip_use_lsb_release="true"
      get_distro
      return
    fi
  fi
  if [[ "${os_codename}" =~ ^(precise|maya|luna)$ ]]; then repo_codename=precise; os_codename=precise
  elif [[ "${os_codename}" =~ ^(trusty|qiana|rebecca|rafaela|rosa|freya)$ ]]; then repo_codename=trusty; os_codename=trusty
  elif [[ "${os_codename}" =~ ^(xenial|sarah|serena|sonya|sylvia|loki)$ ]]; then repo_codename=xenial; os_codename=xenial
  elif [[ "${os_codename}" =~ ^(bionic|tara|tessa|tina|tricia|hera|juno)$ ]]; then repo_codename=bionic; os_codename=bionic
  elif [[ "${os_codename}" =~ ^(focal|ulyana|ulyssa|uma|una)$ ]]; then repo_codename=focal; os_codename=focal
  elif [[ "${os_codename}" =~ ^(jammy|vanessa|vera|victoria|virginia)$ ]]; then repo_codename=jammy; os_codename=jammy
  elif [[ "${os_codename}" =~ ^(stretch|continuum)$ ]]; then repo_codename=stretch; os_codename=stretch
  elif [[ "${os_codename}" =~ ^(buster|debbie|parrot|engywuck-backports|engywuck|deepin)$ ]]; then repo_codename=buster; os_codename=buster
  elif [[ "${os_codename}" =~ ^(bullseye|kali-rolling|elsie|ara)$ ]]; then repo_codename=bullseye; os_codename=bullseye
  elif [[ "${os_codename}" =~ ^(bookworm|lory|faye)$ ]]; then repo_codename=bookworm; os_codename=bookworm
  else
    repo_codename="${os_codename}"
  fi
}
get_distro

get_repo_url() {
  unset archived_repo
  if [[ "${os_codename}" != "${repo_codename}" ]]; then os_codename="${repo_codename}"; os_codename_changed="true"; fi
  if dpkg -l apt-transport-https 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
    http_or_https="https"
    add_repositories_http_or_https="http[s]*"
    if [[ "${copied_source_files}" == 'true' ]]; then
      while read -r revert_https_repo_needs_http_file; do
        if [[ "${revert_https_repo_needs_http_file}" == 'source.list' ]]; then
          mv "${revert_https_repo_needs_http_file}" "/etc/apt/source.list" &>> "${eus_dir}/logs/revert-https-repo-needs-http.log"
        else
          mv "${revert_https_repo_needs_http_file}" "/etc/apt/source.list.d/$(basename "${revert_https_repo_needs_http_file}")" &>> "${eus_dir}/logs/revert-https-repo-needs-http.log"
        fi
      done < <(find "${eus_dir}/repositories" -type f -name "*.list")
    fi
  else
    http_or_https="http"
    add_repositories_http_or_https="http"
  fi
  if dpkg -l curl 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
    if [[ "${os_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
      if curl -s "${http_or_https}://old-releases.ubuntu.com/ubuntu/dists/" | grep -iq "${os_codename}" 2> /dev/null; then archived_repo="true"; fi
      if [[ "${architecture}" =~ (amd64|i386) ]]; then
        if [[ "${archived_repo}" == "true" ]]; then repo_url="${http_or_https}://old-releases.ubuntu.com/ubuntu"; else repo_url="http://archive.ubuntu.com/ubuntu"; fi
      else
        if [[ "${archived_repo}" == "true" ]]; then repo_url="${http_or_https}://old-releases.ubuntu.com/ubuntu"; else repo_url="http://ports.ubuntu.com"; fi
      fi
    elif [[ "${os_codename}" =~ (jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      if curl -s "${http_or_https}://archive.debian.org/debian/dists/" | grep -iq "${os_codename}" 2> /dev/null; then archived_repo="true"; fi
      if [[ "${archived_repo}" == "true" ]]; then repo_url="${http_or_https}://archive.debian.org/debian"; else repo_url="${http_or_https}://ftp.debian.org/debian"; fi
      if [[ "${architecture}" == 'armhf' ]]; then
        if curl -s "${http_or_https}://legacy.raspbian.org/raspbian/dists/" | grep -iq "${os_codename}" 2> /dev/null; then archived_raspbian_repo="true"; fi
        if [[ "${archived_raspbian_repo}" == "true" ]]; then raspbian_repo_url="${http_or_https}://legacy.raspbian.org/raspbian"; else raspbian_repo_url="${http_or_https}://archive.raspbian.org/raspbian"; fi
      fi
    fi
  else
    if [[ "${os_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
      repo_url="http://archive.ubuntu.com/ubuntu"
    elif [[ "${os_codename}" =~ (jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      repo_url="${http_or_https}://archive.debian.org/debian"
      if [[ "${architecture}" == 'armhf' ]]; then
        raspbian_repo_url="${http_or_https}://archive.raspbian.org/raspbian"
      fi
    fi
  fi
}
get_repo_url

cleanup_archived_repos() {
  if [[ "${archived_repo}" == "true" ]]; then
    repo_file_patterns=( "deb.debian.org\\/debian ${os_codename}" "deb.debian.org\\/debian\\/ ${os_codename}" "ftp.*.debian.org\\/debian ${os_codename}" "ftp.*.debian.org\\/debian ${os_codename}" "ftp.*.debian.org\\/debian\\/ ${os_codename}" "security.debian.org ${os_codename}" "security.debian.org\\/ ${os_codename}" "security.debian.org\\/debian-security ${os_codename}" "security.debian.org\\/debian-security\\/ ${os_codename}" "ftp.debian.org\\/debian ${os_codename}" "ftp.debian.org\\/debian\\/ ${os_codename}" "http.debian.net\\/debian ${os_codename}" "http.debian.net\\/debian\\/ ${os_codename}" "*.archive.ubuntu.com\\/ubuntu ${os_codename}" "*.archive.ubuntu.com\\/ubuntu\\/ ${os_codename}" "archive.ubuntu.com\\/ubuntu ${os_codename}" "archive.ubuntu.com\\/ubuntu\\/ ${os_codename}" "security.ubuntu.com\\/ubuntu ${os_codename}" "security.ubuntu.com\\/ubuntu\\/ ${os_codename}" "archive.raspbian.org\\/raspbian ${os_codename}" "archive.raspbian.org\\/raspbian\\/ ${os_codename}" "httpredir.debian.org\\/debian ${os_codename}" "httpredir.debian.org\\/debian\\/ ${os_codename}" )
    #repo_file_patterns=( "debian.org\\/debian ${os_codename}" "debian.org\\/debian\\/ ${os_codename}" "debian.net\\/debian ${os_codename}" "debian.net\\/debian\\/ ${os_codename}" "ubuntu.com\\/ubuntu ${os_codename}" "ubuntu.com\\/ubuntu\\/ ${os_codename}" )
    while read -r repo_file; do
      for pattern in "${repo_file_patterns[@]}"; do
        sed -e "/${pattern}/ s/^#*/#/g" -i "${repo_file}"
      done
    #done < <(find /etc/apt/ -type f -name "*.list" -exec grep -ilE 'deb.debian.org/debian|security.debian.org|ftp.[a-Z]{1,2}.debian.org/debian|ftp.debian.org/debian|[a-Z]{1,2}.archive.ubuntu.com/ubuntu|archive.ubuntu.com/ubuntu|security.ubuntu.com/ubuntu' {} +)
    done < <(find /etc/apt/ -type f -name "*.list" -exec grep -ilE 'debian.org|debian.net|ubuntu.com|raspbian.org' {} +)
  fi
}
cleanup_archived_repos

add_repositories() {
  # shellcheck disable=SC2154
  if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -c "^deb ${add_repositories_http_or_https}://$(echo "${repo_url}" | sed -e 's/https\:\/\///g' -e 's/http\:\/\///g')${repo_url_arguments} ${repo_codename}${repo_arguments}") -eq 0 ]]; then
    if [[ "${apt_key_deprecated}" == 'true' ]]; then
      if [[ -n "${repo_key}" && -n "${repo_key_name}" ]]; then
        if gpg --no-default-keyring --keyring "/etc/apt/keyrings/${repo_key_name}.gpg" --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "${repo_key}" &> /dev/null; then
          signed_by_value_repo_key="[ /etc/apt/keyrings/${repo_key_name}.gpg ] "
        else
          echo -e "${RED}#{WHITE_R} Failed to add repository key ${repo_key}...\\n"
          abort
        fi
      fi
    else
      missing_key="${repo_key}"
      if [[ -n "${missing_key}" ]]; then
        if ! echo -e "${missing_key}" &>> /tmp/EUS/keys/missing_keys; then
          echo -e "${RED}#{WHITE_R} Failed to add missing key \"${missing_key}\" to \"/tmp/EUS/keys/missing_keys\"...\\n"
        fi
      fi
    fi
    if [[ "${os_codename}" =~ (jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      os_version_number="$(lsb_release -rs | tr '[:upper:]' '[:lower:]' | cut -d'.' -f1)"
      check_debian_version="${os_version_number}"
      if echo "${repo_url}" | grep -ioq "archive"; then check_debian_version="${os_version_number}-archive"; fi
      if echo "${repo_url_arguments}" | grep -ioq "security"; then check_debian_version="${os_version_number}-security"; fi
      if [[ "$(curl -s https://get.glennr.nl/unifi/releases/debian-versions.json | jq -r '.versions."'${check_debian_version}'".expired')" == 'true' ]]; then if [[ -n "${signed_by_value_repo_key}" ]]; then signed_by_value_repo_key="[ /etc/apt/keyrings/${repo_key_name}.gpg trusted=yes ] "; else signed_by_value_repo_key="[ trusted=yes ] "; fi; fi
    fi
    if ! echo -e "deb ${signed_by_value_repo_key}${repo_url}${repo_url_arguments} ${repo_codename}${repo_arguments}" &>> /etc/apt/sources.list.d/glennr-install-script.list; then
      echo -e "${RED}#{WHITE_R} Failed to add repository...\\n"
      abort
    fi
    unset missing_key
    unset repo_key
    unset repo_key_name
    unset repo_url_arguments
    unset signed_by_value_repo_key
  fi
  if [[ "${add_repositories_http_or_https}" == 'http' ]]; then
    if ! [[ -d "${eus_dir}/repositories" ]]; then if ! mkdir -p "${eus_dir}/repositories"; then echo -e "${RED}#${RESET} Failed to create required EUS Repositories directory..."; fi; fi
    while read -r https_repo_needs_http_file; do
      if [[ -d "${eus_dir}/repositories" ]]; then 
        cp "${https_repo_needs_http_file}" "${eus_dir}/repositories/$(basename "${https_repo_needs_http_file}")" &>> "${eus_dir}/logs/https-repo-needs-http.log"
        copied_source_files="true"
      fi
      sed -i '/https/{s/^/#/}' "${https_repo_needs_http_file}" &>> "${eus_dir}/logs/https-repo-needs-http.log"
      sed -i 's/##/#/g' "${https_repo_needs_http_file}" &>> "${eus_dir}/logs/https-repo-needs-http.log"
    done < <(grep -ril "^deb https*://$(echo "${repo_url}" | sed -e 's/https\:\/\///g' -e 's/http\:\/\///g') ${repo_codename}${repo_arguments}" /etc/apt/sources.list /etc/apt/sources.list.d/*)
  fi
  if [[ "${os_codename_changed}" == 'true' ]]; then unset os_codename_changed; get_distro; get_repo_url; fi
}

if ! [[ "${os_codename}" =~ (precise|maya|trusty|qiana|rebecca|rafaela|rosa|xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|jessie|stretch|continuum|buster|bullseye|bookworm|trixie|forky) ]]; then
  clear
  header_red
  echo -e "${WHITE_R}#${RESET} This script is not made for your OS.."
  echo -e "${WHITE_R}#${RESET} Feel free to contact Glenn R. (AmazedMender16) on the Community Forums if you need help with installing your UniFi Network Application."
  echo -e ""
  echo -e "OS_CODENAME = ${os_codename}"
  echo -e ""
  echo -e ""
  exit 1
fi

if ! grep -iq '^127.0.0.1.*localhost' /etc/hosts; then
  clear
  header_red
  echo -e "${WHITE_R}#${RESET} '127.0.0.1   localhost' does not exist in your /etc/hosts file."
  echo -e "${WHITE_R}#${RESET} You will most likely see application startup issues if it doesn't exist..\\n\\n"
  read -rp $'\033[39m#\033[0m Do you want to add "127.0.0.1   localhost" to your /etc/hosts file? (Y/n) ' yes_no
  case "$yes_no" in
      [Yy]*|"")
          echo -e "${WHITE_R}----${RESET}\\n"
          echo -e "${WHITE_R}#${RESET} Adding '127.0.0.1       localhost' to /etc/hosts"
          sed  -i '1i # ------------------------------' /etc/hosts
          sed  -i '1i 127.0.0.1       localhost' /etc/hosts
          sed  -i '1i # Added by GlennR EUS script' /etc/hosts && echo -e "${WHITE_R}#${RESET} Done..\\n\\n"
          sleep 3;;
      [Nn]*) ;;
  esac
fi

if [[ $(echo "${PATH}" | grep -c "/sbin") -eq 0 ]]; then
  #PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin
  #PATH=$PATH:/usr/sbin
  PATH="$PATH:/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin"
fi

if ! [[ -d /etc/apt/sources.list.d ]]; then mkdir -p /etc/apt/sources.list.d; fi
if ! [[ -d /tmp/EUS/keys ]]; then mkdir -p /tmp/EUS/keys; fi

unifi_package=$(dpkg -l | grep "unifi " | awk '{print $1}' | tr '[:upper:]' '[:lower:]')
if [[ -n "${unifi_package}" ]]; then
  if ! [[ "${unifi_package}" =~ (hi|ii) ]]; then
    header_red
    echo -e "${RED}#${RESET} You have a broken UniFi Network Application installation...\\n\\n${WHITE}#${RESET} Removing the broken UniFi Network Application installation..."
    if dpkg --remove --force-remove-reinstreq unifi &>> "${eus_dir}/logs/broken_unifi.log"; then
      echo -e "${GREEN}#${RESET} Successfully removed the broken UniFi Network Application installation! \\n"
    else
      echo -e "${RED}#${RESET} Failed to remove the broken UniFi Network Application installation...\\n"
    fi
    broken_unifi_install="true"
    broken_unifi_install_version="$(dpkg -l unifi | tail -n1 | awk '{print $3}' | cut -d"-" -f1)"
    if [[ -n "${broken_unifi_install_version}" ]]; then
      broken_unifi_install_version="$(grep -sEio "UniFi [0-9].[0-9].[0-9]{1,3}" /usr/lib/unifi/logs/server.log | sed 's/UniFi //g' | tail -n1)"
    fi
    if [[ -n "${broken_unifi_install_version}" ]]; then
      broken_unifi_install_version_first_digit="$(echo "${broken_unifi_install_version}" | cut -d"." -f1)"
      broken_unifi_install_version_second_digit="$(echo "${broken_unifi_install_version}" | cut -d"." -f2)"
      broken_unifi_install_version_third_digit="$(echo "${broken_unifi_install_version}" | cut -d"." -f3)"
      unifi_download_link="$(curl -s "https://fw-update.ui.com/api/firmware-latest?filter=eq~~version_major~~${broken_unifi_install_version_first_digit}&filter=eq~~version_minor~~${broken_unifi_install_version_second_digit}&filter=eq~~version_patch~~${broken_unifi_install_version_third_digit}&filter=eq~~platform~~debian" | jq -r "._embedded.firmware[]._links.data.href" | sed '/null/d')"
      if [[ -z "${unifi_download_link}" ]]; then
        unifi_download_link="$(curl -s https://get.glennr.nl/unifi/releases/unifi-network-application-versions.json | jq -r '.versions."'${broken_unifi_install_version}'"."download_link"' | sed '/null/d')"
      fi
      if [[ -n "${unifi_download_link}" ]]; then
        echo -e "${WHITE_R}#${RESET} Checking if we need to change the version that the script will install..."
        if ! [[ -d "/tmp/EUS/downloads" ]]; then mkdir -p /tmp/EUS/downloads &> /dev/null; fi
        unifi_temp="$(mktemp --tmpdir=/tmp/EUS/downloads "unifi_sysvinit_all_${broken_unifi_install_version}_XXXXX.deb")"
        if wget -O "$unifi_temp" "${unifi_download_link}" &>> "${eus_dir}/logs/unifi-broken-install-download.log"; then
          unifi_network_application_downloaded="true"
          echo -e "${GREEN}#${RESET} The script will install UniFi Network Application version ${broken_unifi_install_version}! \\n"
        else
          echo -e "${RED}#${RESET} Failed to change the version to UniFi Network Application ${broken_unifi_install_version}...\\n"
        fi
      fi
      sleep 3
    fi
  fi
fi

# Check if --show-progrss is supported in wget version
if wget --help | grep -q '\--show-progress'; then if ! grep -q "show-progress" /tmp/EUS/wget_option &> /dev/null; then echo "--show-progress" &>> /tmp/EUS/wget_option; fi; fi
if [[ -f /tmp/EUS/wget_option && -s /tmp/EUS/wget_option ]]; then IFS=" " read -r -a wget_progress <<< "$(tr '\r\n' ' ' < /tmp/EUS/wget_option)"; rm --force /tmp/EUS/wget_option &> /dev/null; fi

# Check if --allow-change-held-packages is supported in apt
get_apt_options() {
  if [[ "${remove_apt_options}" == "true" ]]; then get_apt_option_arguments="false"; unset apt_options; fi
  if [[ "${get_apt_option_arguments}" != "false" ]]; then
    if [[ "$(dpkg -l apt | grep ^"ii" | awk '{print $2,$3}' | awk '{print $2}' | cut -d'.' -f1)" -ge "1" ]] || [[ "$(dpkg -l apt | grep ^"ii" | awk '{print $2,$3}' | awk '{print $2}' | cut -d'.' -f1)" == "1" && "$(dpkg -l apt | grep ^"ii" | awk '{print $2,$3}' | awk '{print $2}' | cut -d'.' -f2)" -ge "1" ]]; then if ! grep -q "allow-change-held-packages" /tmp/EUS/apt_option &> /dev/null; then echo "--allow-change-held-packages" &>> /tmp/EUS/apt_option; fi; fi
    if [[ -f /tmp/EUS/apt_option && -s /tmp/EUS/apt_option ]]; then IFS=" " read -r -a apt_options <<< "$(tr '\r\n' ' ' < /tmp/EUS/apt_option)"; rm --force /tmp/EUS/apt_option &> /dev/null; fi
  fi
  unset get_apt_option_arguments
  unset remove_apt_options
}
get_apt_options

# Check if UniFi is already installed.
if dpkg -l | grep "unifi " | grep -q "^ii\\|^hi"; then
  header
  echo -e "${WHITE_R}#${RESET} UniFi is already installed on your system!${RESET}"
  echo -e "${WHITE_R}#${RESET} You can use my Easy Update Script to update your UniFi Network Application.${RESET}\\n\\n"
  read -rp $'\033[39m#\033[0m Would you like to download and run my Easy Update Script? (Y/n) ' yes_no
  case "$yes_no" in
      [Yy]*|"")
        rm --force "${script_location}" 2> /dev/null
        wget -q "${wget_progress[@]}" https://get.glennr.nl/unifi/update/unifi-update.sh && bash unifi-update.sh; exit 0;;
      [Nn]*) exit 0;;
  esac
fi

dpkg_locked_message() {
  header_red
  echo -e "${WHITE_R}#${RESET} dpkg is locked.. Waiting for other software managers to finish!"
  echo -e "${WHITE_R}#${RESET} If this is everlasting please contact Glenn R. (AmazedMender16) on the Community Forums!\\n\\n"
  sleep 5
  if [[ -z "$dpkg_wait" ]]; then
    echo "glennr_lock_active" >> /tmp/glennr_lock
  fi
}

dpkg_locked_60_message() {
  header
  echo -e "${WHITE_R}#${RESET} dpkg is already locked for 60 seconds..."
  echo -e "${WHITE_R}#${RESET} Would you like to force remove the lock?\\n\\n"
}

# Check if dpkg is locked
if dpkg -l psmisc 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  while fuser /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock >/dev/null 2>&1; do
    dpkg_locked_message
    if [[ $(grep -c "glennr_lock_active" /tmp/glennr_lock) -ge 12 ]]; then
      rm --force /tmp/glennr_lock 2> /dev/null
      dpkg_locked_60_message
      if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Do you want to proceed with removing the lock? (Y/n) ' yes_no; fi
      case "$yes_no" in
          [Yy]*|"")
            killall apt apt-get 2> /dev/null
            rm --force /var/lib/apt/lists/lock 2> /dev/null
            rm --force /var/cache/apt/archives/lock 2> /dev/null
            rm --force /var/lib/dpkg/lock* 2> /dev/null
            dpkg --configure -a 2> /dev/null
            DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install --fix-broken 2> /dev/null;;
          [Nn]*) dpkg_wait="true";;
      esac
    fi
  done;
else
  dpkg -i /dev/null 2> /tmp/glennr_dpkg_lock; if grep -q "locked.* another" /tmp/glennr_dpkg_lock; then dpkg_locked="true"; rm --force /tmp/glennr_dpkg_lock 2> /dev/null; fi
  while [[ "${dpkg_locked}" == 'true'  ]]; do
    unset dpkg_locked
    dpkg_locked_message
    if [[ $(grep -c "glennr_lock_active" /tmp/glennr_lock) -ge 12 ]]; then
      rm --force /tmp/glennr_lock 2> /dev/null
      dpkg_locked_60_message
      if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Do you want to proceed with force removing the lock? (Y/n) ' yes_no; fi
      case "$yes_no" in
          [Yy]*|"")
            pgrep "apt" >> /tmp/EUS/apt
            while read -r glennr_apt; do
              kill -9 "$glennr_apt" 2> /dev/null
            done < /tmp/EUS/apt
            rm --force /tmp/EUS/apt 2> /dev/null
            rm --force /var/lib/apt/lists/lock 2> /dev/null
            rm --force /var/cache/apt/archives/lock 2> /dev/null
            rm --force /var/lib/dpkg/lock* 2> /dev/null
            dpkg --configure -a 2> /dev/null
            DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install --fix-broken 2> /dev/null;;
          [Nn]*) dpkg_wait="true";;
      esac
    fi
    dpkg -i /dev/null 2> /tmp/glennr_dpkg_lock; if grep -q "locked.* another" /tmp/glennr_dpkg_lock; then dpkg_locked="true"; rm --force /tmp/glennr_dpkg_lock 2> /dev/null; fi
  done;
  rm --force /tmp/glennr_dpkg_lock 2> /dev/null
fi

script_version_check() {
  if dpkg -l curl 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
    version=$(grep -i "# Application version" "${script_location}" | head -n 1 | cut -d'|' -f2 | sed 's/ //g' | cut -d'-' -f1)
    script_online_version_dots=$(curl -s "https://get.glennr.nl/unifi/install/unifi-${version}.sh" | grep -i "# Version" | head -n 1 | cut -d'|' -f2 | sed 's/ //g')
    script_local_version_dots=$(grep -i "# Version" "${script_location}" | head -n 1 | cut -d'|' -f2 | sed 's/ //g' | cut -d'-' -f1)
    script_online_version="${script_online_version_dots//./}"
    script_local_version="${script_local_version_dots//./}"
    # Script version check.
    if [[ "${script_online_version::3}" -gt "${script_local_version::3}" ]]; then
      header_red
      echo -e "${WHITE_R}#${RESET} You're currently running script version ${script_local_version_dots} while ${script_online_version_dots} is the latest!"
      echo -e "${WHITE_R}#${RESET} Downloading and executing version ${script_online_version_dots} of the Easy Installation Script..\\n\\n"
      sleep 3
      rm --force "${script_location}" 2> /dev/null
      rm --force "unifi-${version}.sh" 2> /dev/null
      # shellcheck disable=SC2068
      wget -q "${wget_progress[@]}" "https://get.glennr.nl/unifi/install/unifi-${version}.sh" && bash "unifi-${version}.sh" ${script_options[@]}; exit 0
    fi
  fi
}
script_version_check

armhf_recommendation() {
  print_architecture=$(dpkg --print-architecture)
  if [[ "${print_architecture}" == 'armhf' && "${is_cloudkey}" == "false" ]]; then
    header_red
    echo -e "${WHITE_R}#${RESET} Your installation might fail, please consider getting a Cloud Key Gen2 or go with a VPS at OVH/DO/AWS."
    if [[ "${os_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
      echo -e "${WHITE_R}#${RESET} You could try using Debian Bullseye before going with a UCK G2 ( PLUS ) or VPS"
    fi
    echo -e "\\n${WHITE_R}#${RESET} UniFi Cloud Key Gen2       | https://store.ui.com/products/unifi-cloud-key-gen2"
    echo -e "${WHITE_R}#${RESET} UniFi Cloud Key Gen2 Plus  | https://store.ui.com/products/unifi-cloudkey-gen2-plus\\n\\n"
    sleep 20
  fi
}

armhf_recommendation

check_service_overrides() {
  if [[ -e "/etc/systemd/system/unifi.service" ]] || [[ -e "/etc/systemd/system/unifi.service.d/" ]]; then
    echo -e "${WHITE_R}#${RESET} UniFi Network Application service overrides detected... Removing them..."
    if ! [[ -d "${eus_dir}/unifi-service-overrides/${unifi_clean}/" ]]; then if ! mkdir -p "${eus_dir}/unifi-service-overrides/${unifi_clean}/"; then echo -e "${RED}#${RESET} Failed to create required EUS UniFi Service Overrides directory..."; fi; fi
    if [[ -d "${eus_dir}/unifi-service-overrides/${unifi_clean}/" ]]; then
      if [[ -e "/etc/systemd/system/unifi.service" ]]; then
        mv "/etc/systemd/system/unifi.service" "${eus_dir}/unifi-service-overrides/${unifi_clean}/unifi.service" &>> "${eus_dir}/logs/service-override.log"
      fi
      if [[ -e "/etc/systemd/system/unifi.service.d/" ]]; then
        find /etc/systemd/system/unifi.service.d/ -type f &> "${eus_dir}/unifi-service-overrides/override-files-tmp.list"
        while read -r override_file; do
          override_file_name="$(basename "${override_file}")"
          mv "${override_file}" "${eus_dir}/unifi-service-overrides/${unifi_clean}/${override_file_name}" &>> "${eus_dir}/logs/service-override.log"
        done < "${eus_dir}/unifi-service-overrides/override-files-tmp.list"
        rm --force "${eus_dir}/unifi-service-overrides/override-files-tmp.list" &> /dev/null
      fi
    fi
    if systemctl revert unifi &>> "${eus_dir}/logs/service-override.log"; then
      echo -e "${GREEN}#${RESET} Successfully reverted the UniFi Network Application service overrides! \\n"
    else
      echo -e "${RED}#${RESET} Failed to revert the UniFi Network Application service overrides...\\n"
    fi
    sleep 3
  fi
}

custom_url_question() {
  header
  echo -e "${WHITE_R}#${RESET} Please enter the application download URL below."
  read -rp $'\033[39m#\033[0m ' custom_download_url
  custom_url_download_check
}

custom_url_upgrade_check() {
  echo -e "\\n${WHITE_R}----${RESET}\\n"
  echo -e "${YELLOW}#${RESET} The script will now install application version: ${unifi_clean}!" && sleep 3
  unifi_network_application_downloaded="true"
}

custom_url_download_check() {
  mkdir -p /tmp/EUS/downloads &> /dev/null
  unifi_temp="$(mktemp --tmpdir=/tmp/EUS/downloads unifi_sysvinit_all_XXXXX.deb)"
  header
  echo -e "${WHITE_R}#${RESET} Downloading the application release..."
  echo -e "\\n------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/unifi_custom_url_download.log"
  if ! wget -O "$unifi_temp" "${custom_download_url}" &>> "${eus_dir}/logs/unifi_custom_url_download.log"; then
    header_red
    echo -e "${WHITE_R}#${RESET} The URL you provided cannot be downloaded.. Please provide a working URL."
    sleep 3
    custom_url_question
  else
    dpkg -I "${unifi_temp}" | awk '{print tolower($0)}' &> "${unifi_temp}.tmp"
    package_maintainer=$(awk '/maintainer/{print$2}' "${unifi_temp}.tmp")
    unifi_clean=$(awk '/version/{print$2}' "${unifi_temp}.tmp" | grep -io "5.*\\|6.*\\|7.*\\|8.*" | cut -d'-' -f1 | cut -d'/' -f1)
    rm --force "${unifi_temp}.tmp" &> /dev/null
    if [[ "${package_maintainer}" =~ (unifi|ubiquiti) ]]; then
      echo -e "${GREEN}#${RESET} Successfully downloaded the application release!"
      sleep 2
      custom_url_upgrade_check
    else
      header_red
      echo -e "${WHITE_R}#${RESET} You did not provide a UniFi Network Application that is maintained by Ubiquiti ( UniFi )..."
      read -rp $'\033[39m#\033[0m Do you want to provide the script with another URL? (Y/n) ' yes_no
      case "$yes_no" in
          [Yy]*|"") custom_url_question;;
          [Nn]*) ;;
      esac
    fi
  fi
}

if [[ "${script_option_custom_url}" == 'true' ]]; then if [[ "${custom_url_down_provided}" == 'true' ]]; then custom_url_download_check; else custom_url_question; fi; fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                        Required Packages                                                                                        #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

# Install needed packages if not installed
install_required_packages() {
  sleep 2
  installing_required_package=yes
  header
  echo -e "${WHITE_R}#${RESET} Installing required packages for the script..\\n"
  hide_apt_update="true"
  run_apt_get_update
  sleep 2
}
apt_get_install_package() {
  if [[ "${old_openjdk_version}" == 'true' ]]; then
    apt_get_install_package_variable="update"
    apt_get_install_package_variable_2="updated"
  else
    apt_get_install_package_variable="install"
    apt_get_install_package_variable_2="installed"
  fi
  hide_apt_update="true"
  run_apt_get_update
  echo -e "\\n------- ${required_package} installation ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/apt.log"
  echo -e "${WHITE_R}#${RESET} Trying to ${apt_get_install_package_variable} ${required_package}..."
  if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg6::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${required_package}" &>> "${eus_dir}/logs/apt.log"; then
    echo -e "${GREEN}#${RESET} Successfully ${apt_get_install_package_variable_2} ${required_package}! \\n"
    sleep 2
  else
    echo -e "${RED}#${RESET} Failed to ${apt_get_install_package_variable} ${required_package}...\\n"
    if [[ "${required_package}" == "openjdk-11-jre-headless" ]] && [[ "${repo_codename}" =~ (stretch|continuum) ]]; then
      if grep -Eiq "openjdk-11-jre-headless.*Depends.*libjpeg8" "${eus_dir}/logs/apt.log"; then
        repo_codename="stretch"
        repo_arguments="-backports main"
        add_repositories
        hide_apt_update="true"
        run_apt_get_update
        get_distro
        get_repo_url
        if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg6::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${required_package}" -t stretch-backports &>> "${eus_dir}/logs/apt.log"; then
          echo -e "${GREEN}#${RESET} Successfully ${apt_get_install_package_variable_2} ${required_package}! \\n"
          sleep 2
          unset required_package
          return
        fi
      fi
    fi
    if [[ "${required_package}" =~ (openjdk-11-jre-headless|openjdk-17-jre-headless) ]]; then
      if ! [[ -f "/etc/java-${required_java_version_short}-openjdk/security/java.security" ]]; then
        echo -e "\\n------- ${required_package} installation ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/java.security-fix-required.log"
        echo -e "$(date +%F-%R) | \"/etc/java-${required_java_version_short}-openjdk/security/java.security\" is missing..." &>> "${eus_dir}/logs/java.security-fix-required.log"
        if [[ -f "/etc/java-${required_java_version_short}-openjdk/security/java.security.dpkg-new" ]]; then
          echo -e "$(date +%F-%R) | \"/etc/java-${required_java_version_short}-openjdk/security/java.security.dpkg-new\" exists, copying it to \"/etc/java-${required_java_version_short}-openjdk/security/java.security\"..." &>> "${eus_dir}/logs/java.security-fix-required.log"
          if cp "/etc/java-${required_java_version_short}-openjdk/security/java.security.dpkg-new" "/etc/java-${required_java_version_short}-openjdk/security/java.security" &>> "${eus_dir}/logs/java.security-fix-required.log"; then
            echo -e "$(date +%F-%R) | Successfully copied \"/etc/java-${required_java_version_short}-openjdk/security/java.security.dpkg-new\" to \"/etc/java-${required_java_version_short}-openjdk/security/java.security\"!" &>> "${eus_dir}/logs/java.security-fix-required.log"
            if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg6::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${required_package}" &>> "${eus_dir}/logs/apt.log"; then
              echo -e "${GREEN}#${RESET} Successfully ${apt_get_install_package_variable_2} ${required_package}! \\n"
              sleep 2
              unset required_package
              return
            fi
          else
            echo -e "$(date +%F-%R) | Failed to copy \"/etc/java-${required_java_version_short}-openjdk/security/java.security.dpkg-new\" to \"/etc/java-${required_java_version_short}-openjdk/security/java.security\"..." &>> "${eus_dir}/logs/java.security-fix-required.log"
          fi
        fi
      fi
    fi
    if [[ "${required_package}" =~ (openjdk-8-jre-headless|openjdk-11-jre-headless|openjdk-17-jre-headless) ]]; then
      if apt-cache search --names-only "^temurin-17-jre" | grep -ioq "temurin-17-jre"; then
        adoptium_java_type="jre"
      else
        adoptium_java_type="jdk"
      fi
      adoptium_java
      if [[ "${added_adoptium}" == 'true' ]]; then
        echo -e "${WHITE_R}#${RESET} Trying to ${apt_get_install_package_variable} temurin-${required_java_version_short}-${adoptium_java_type}..."
        if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg6::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "temurin-${required_java_version_short}-${adoptium_java_type}" &>> "${eus_dir}/logs/apt.log"; then
          echo -e "${GREEN}#${RESET} Successfully ${apt_get_install_package_variable_2} temurin-${required_java_version_short}-${adoptium_java_type}! \\n"
          if dpkg -l | grep "^ii\\|^hi" | grep -iq "temurin-${required_java_version_short}-jre"; then
            if dpkg -l | grep "^ii\\|^hi" | grep -iq "temurin-${required_java_version_short}-jdk"; then
              echo -e "${WHITE_R}#${RESET} Removing temurin-${required_java_version_short}-jdk..."
              if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg6::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' remove "temurin-${required_java_version_short}-jdk" &>> "${eus_dir}/logs/temurin-jdk-remove.log"; then
                echo -e "${GREEN}#${RESET} Successfully removed temurin-${required_java_version_short}-jdk! \\n"
              else
                echo -e "${RED}#${RESET} Failed to remove temurin-${required_java_version_short}-jdk... \\n"
              fi
            fi
          fi
          unset temurin_jdk_to_jre
          sleep 2
          unset required_package
          return
        else
          required_package="${required_package} or temurin-${required_java_version_short}-${adoptium_java_type}"
          echo -e "${RED}#${RESET} Failed to ${apt_get_install_package_variable} temurin-${required_java_version_short}-${adoptium_java_type}...\\n"
        fi
      fi
    fi
    if [[ "${temurin_jdk_to_jre}" != 'true' ]]; then abort; fi
  fi
  unset required_package
}

if ! dpkg -l curl 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  echo -e "${WHITE_R}#${RESET} Installing curl..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install curl &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install curl in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
      if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic) ]]; then repo_arguments="-security main"; fi
      if [[ "${repo_codename}" =~ (disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then repo_arguments=" main"; fi
    elif [[ "${repo_codename}" == "jessie" ]]; then
      repo_arguments="/updates main"
    elif [[ "${repo_codename}" =~ (stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      repo_arguments=" main"
    fi
    add_repositories
    required_package="curl"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed curl! \\n" && sleep 2
  fi
  script_version_check
  get_repo_url
fi
if ! dpkg -l sudo 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  echo -e "${WHITE_R}#${RESET} Installing sudo..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install sudo &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install sudo in the first run...\\n"
    repo_arguments=" main"
    add_repositories
    required_package="sudo"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed sudo! \\n" && sleep 2
  fi
fi
if ! dpkg -l jq 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  echo -e "${WHITE_R}#${RESET} Installing jq..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install jq &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install jq in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
      if [[ "${repo_codename}" =~ (focal|groovy|hirsute|impish) ]]; then repo_arguments=" main universe"; add_repositories; fi
      if [[ "${repo_codename}" =~ (jammy|kinetic|lunar|mantic|noble) ]]; then repo_arguments=" main"; add_repositories; fi
      repo_arguments="-security main universe"
    elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      if [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then repo_url_arguments="-security/"; repo_arguments="/updates main"; add_repositories; fi
      repo_arguments=" main"
    fi
    add_repositories
    required_package="jq"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed jq! \\n" && sleep 2
  fi
fi
if ! dpkg -l lsb-release 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  echo -e "${WHITE_R}#${RESET} Installing lsb-release..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install lsb-release &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install lsb-release in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
      repo_arguments=" main universe"
    elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      repo_arguments=" main"
    fi
    add_repositories
    required_package="lsb-release"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed lsb-release! \\n" && sleep 2
  fi
fi
if ! dpkg -l net-tools 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  echo -e "${WHITE_R}#${RESET} Installing net-tools..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install net-tools &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install net-tools in the first run...\\n"
    repo_arguments=" main"
    add_repositories
    required_package="net-tools"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed net-tools! \\n" && sleep 2
  fi
fi
if dpkg -l apt 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  apt_version_1=$(dpkg -l apt | grep ^"ii" | awk '{print $3}' | cut -d'.' -f1)
  if [[ "${apt_version_1}" -le "1" ]]; then
    apt_version_2=$(dpkg -l apt | grep ^"ii" | awk '{print $3}' | cut -d'.' -f2)
    if [[ "${apt_version_1}" == "0" ]] || [[ "${apt_version_2}" -le "4" ]]; then
      if ! dpkg -l apt-transport-https 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
        if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
        echo -e "${WHITE_R}#${RESET} Installing apt-transport-https..."
        if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install apt-transport-https &>> "${eus_dir}/logs/required.log"; then
          echo -e "${RED}#${RESET} Failed to install apt-transport-https in the first run...\\n"
          if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
            if [[ "${repo_codename}" =~ (precise|trusty|xenial) ]]; then repo_arguments="-security main"; fi
            if [[ "${repo_codename}" =~ (bionic|cosmic) ]]; then repo_arguments="-security main universe"; fi
            if [[ "${repo_codename}" =~ (disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then repo_arguments=" main universe"; fi
          elif [[ "${repo_codename}" == "jessie" ]]; then
            repo_arguments="/updates main"
          elif [[ "${repo_codename}" =~ (stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
            repo_arguments=" main"
          fi
          add_repositories
          required_package="apt-transport-https"
          apt_get_install_package
        else
          echo -e "${GREEN}#${RESET} Successfully installed apt-transport-https! \\n" && sleep 2
        fi
        get_repo_url
      fi
    fi
  fi
fi
if ! dpkg -l software-properties-common 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  echo -e "${WHITE_R}#${RESET} Installing software-properties-common..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install software-properties-common &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install software-properties-common in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
      if [[ "${repo_codename}" =~ (precise) ]]; then repo_arguments="-security main"; fi
      if [[ "${repo_codename}" =~ (trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then repo_arguments=" main"; fi
    elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      if [[ "${repo_codename}" =~ (jessie) ]]; then repo_url_arguments="-security/"; repo_arguments="/updates main"; fi
      if [[ "${repo_codename}" =~ (stretch|buster|bullseye|bookworm|trixie|forky) ]]; then repo_arguments=" main"; fi
    fi
    add_repositories
    if [[ "${repo_codename}" =~ (stretch) ]]; then repo_url_arguments="-security/"; repo_arguments="/updates main"; add_repositories; fi
    required_package="software-properties-common"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed software-properties-common! \\n" && sleep 2
  fi
fi
if ! dpkg -l dirmngr 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  echo -e "${WHITE_R}#${RESET} Installing dirmngr..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install dirmngr &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install dirmngr in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
      repo_arguments=" universe"
      add_repositories
      repo_arguments=" main restricted"
    elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      repo_arguments=" main"
    fi
    add_repositories
    required_package="dirmngr"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed dirmngr! \\n" && sleep 2
  fi
fi
if ! dpkg -l wget 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  echo -e "${WHITE_R}#${RESET} Installing wget..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install wget &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install wget in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
      if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic) ]]; then repo_arguments="-security main"; fi
      if [[ "${repo_codename}" =~ (disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then repo_arguments=" main"; fi
    elif [[ "${repo_codename}" == "jessie" ]]; then
      repo_arguments="/updates main"
    elif [[ "${repo_codename}" =~ (stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      repo_arguments=" main"
    fi
    add_repositories
    required_package="wget"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed wget! \\n" && sleep 2
  fi
fi
if ! dpkg -l netcat netcat-traditional 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  if apt-cache search netcat | grep "^netcat\b" | awk '{print$1}' | grep -iq "traditional"; then
    required_package="netcat-traditional"
  else
    required_package="netcat"
  fi
  netcat_installed_package_name="${required_package}"
  echo -e "${WHITE_R}#${RESET} Installing ${required_package}..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${required_package}" &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install ${required_package} in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
      repo_arguments=" universe"
    elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      repo_arguments=" main"
    fi
    add_repositories
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed ${required_package}! \\n" && sleep 2
  fi
  netcat_installed="true"
fi
if ! dpkg -l psmisc 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  echo -e "${WHITE_R}#${RESET} Installing psmisc..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install psmisc &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install psmisc in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
      if [[ "${repo_codename}" =~ (precise) ]]; then repo_arguments="-updates main restricted"; fi
      if [[ "${repo_codename}" =~ (trusty|xenial|bionic|cosmicdisco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then repo_arguments=" universe"; fi
    elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      repo_arguments=" main"
    fi
    add_repositories
    required_package="psmisc"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed psmisc! \\n" && sleep 2
  fi
fi
if ! dpkg -l gnupg 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
  echo -e "${WHITE_R}#${RESET} Installing gnupg..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install gnupg &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install gnupg in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
      if [[ "${repo_codename}" =~ (precise|trusty|xenial) ]]; then repo_arguments="-security main"; fi
      if [[ "${repo_codename}" =~ (bionic|cosmic) ]]; then repo_arguments="-security main universe"; fi
      if [[ "${repo_codename}" =~ (disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then repo_arguments=" main universe"; fi
    elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      repo_arguments=" main"
    fi
    add_repositories
    required_package="gnupg"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed gnupg! \\n" && sleep 2
  fi
fi
if ! dpkg -l perl 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  echo -e "${WHITE_R}#${RESET} Installing perl..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install perl &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install perl in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
      if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic) ]]; then repo_arguments="-security main"; fi
      if [[ "${repo_codename}" =~ (disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then repo_arguments=" main"; fi
    elif [[ "${repo_codename}" == "jessie" ]]; then
      repo_arguments="/updates main"
    elif [[ "${repo_codename}" =~ (stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      repo_arguments=" main"
    fi
    add_repositories
    required_package="perl"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed perl! \\n" && sleep 2
  fi
fi
if [[ "${fqdn_specified}" == 'true' ]]; then
  if ! dpkg -l dnsutils 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
    if [[ "${installing_required_package}" != 'yes' ]]; then install_required_packages; fi
    echo -e "${WHITE_R}#${RESET} Installing dnsutils..."
    if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install dnsutils &>> "${eus_dir}/logs/required.log"; then
      echo -e "${RED}#${RESET} Failed to install dnsutils in the first run...\\n"
      if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
        if [[ "${repo_codename}" =~ (precise|trusty|xenial) ]]; then repo_arguments="-security main"; fi
        if [[ "${repo_codename}" =~ (bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then repo_arguments=" main"; fi
      elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
        if [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then repo_url_arguments="-security/"; repo_arguments="/updates main"; add_repositories; fi
        repo_arguments=" main"
      fi
      add_repositories
      required_package="dnsutils"
      apt_get_install_package
    else
      echo -e "${GREEN}#${RESET} Successfully installed dnsutils! \\n" && sleep 2
    fi
  fi
fi
if ! dpkg -l adduser 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  echo -e "${WHITE_R}#${RESET} Installing adduser..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install adduser &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install adduser in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
      repo_arguments=" universe"
    elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      repo_arguments=" main"
    fi
    add_repositories
    required_package="adduser"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed adduser! \\n" && sleep 2
  fi
fi
if ! dpkg -l logrotate 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
  if [[ "${installing_required_package}" != 'yes' ]]; then
    install_required_packages
  fi
  echo -e "${WHITE_R}#${RESET} Installing logrotate..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install logrotate &>> "${eus_dir}/logs/required.log"; then
    echo -e "${RED}#${RESET} Failed to install logrotate in the first run...\\n"
    if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
      repo_arguments=" universe"
    elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      repo_arguments=" main"
    fi
    add_repositories
    required_package="logrotate"
    apt_get_install_package
  else
    echo -e "${GREEN}#${RESET} Successfully installed logrotate! \\n" && sleep 2
  fi
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                            Variables                                                                                            #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

dpkg -l | grep "mongodb-server\\|mongodb-org-server\\|mongod-armv8" | grep "^ii\\|^hi" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g' &> /tmp/EUS/mongodb_versions
if ! [[ -s "/tmp/EUS/mongodb_versions" ]]; then
  if [[ -n "$(command -v mongod)" ]]; then
    compiled_mongodb="true"
    if "${mongocommand}" --port 27117 --eval "print(\"waited for connection\")" &> /dev/null; then
      "$(which mongod)" --quiet --eval "db.version()" | sed 's/\.//g' | sed 's/.*://' | sed 's/-.*//g' &> /tmp/EUS/mongodb_versions
    else
      "$(which mongod)" --version --quiet | tr '[:upper:]' '[:lower:]' | sed -e '/db version/d' -e '/mongodb shell/d' -e 's/build info: //g' | jq -r '.version' &> /tmp/EUS/mongodb_versions
    fi
  fi
fi
mongodb_version_installed="$(sort -V /tmp/EUS/mongodb_versions | tail -n 1)"
mongodb_version_installed_no_dots="${mongodb_version_installed//./}"
if [[ -n "${mongodb_version_installed}" ]]; then mongodb_installed="true"; fi
if dpkg -l | grep "^ii\\|^hi" | grep -iq "mongodb-server\\|mongodb-org-server"; then mongodb_installed="true"; fi
rm --force /tmp/EUS/mongodb_versions &> /dev/null
first_digit_mongodb_version_installed="$(echo "${mongodb_version_installed}" | cut -d'.' -f1)"
second_digit_mongodb_version_installed="$(echo "${mongodb_version_installed}" | cut -d'.' -f2)"
#
system_memory="$(awk '/MemTotal/ {printf( "%.0f\n", $2 / 1024 / 1024)}' /proc/meminfo)"
system_swap="$(awk '/SwapTotal/ {printf( "%.0f\n", $2 / 1024 / 1024)}' /proc/meminfo)"
system_free_disk_space="$(df -k / | awk '{print $4}' | tail -n1)"
#
SERVER_IP="$(ip addr | grep -A8 -m1 MULTICAST | grep -m1 inet | cut -d' ' -f6 | cut -d'/' -f1)"
if [[ -z "${SERVER_IP}" ]]; then SERVER_IP="$(hostname -I | head -n 1 | awk '{ print $NF; }')"; fi
PUBLIC_SERVER_IP="$(curl https://ip.glennr.nl/ -s)"
#
if [[ "${unifi_network_application_downloaded}" == 'true' ]]; then
  if [[ -n "${custom_download_url}" ]]; then
    if [[ -z "${unifi_clean}" ]]; then unifi_clean="$(echo "${custom_download_url}" | grep -io "5.*\\|6.*\\|7.*\\|8.*" | cut -d'-' -f1 | cut -d'/' -f1)"; fi
    unifi_secret="$(echo "${custom_download_url}" | grep -io "5.*\\|6.*\\|7.*\\|8.*" | cut -d'/' -f1)"
  elif [[ -n "${broken_unifi_install_version}" ]]; then
    unifi_clean="${broken_unifi_install_version}"
  fi
else
  unifi_clean="$(grep -i "# Application version" "${script_location}" | head -n 1 | cut -d'|' -f2 | sed 's/ //g' | cut -d'-' -f1)"
  unifi_secret="$(grep -i "# Application version" "${script_location}" | head -n 1 | cut -d'|' -f2 | sed 's/ //g')"
  unifi_repo_version="$(grep -i "# Debian repo version" "${script_location}" | head -n 1 | cut -d'|' -f2 | sed 's/ //g')"
fi
first_digit_unifi="$(echo "${unifi_clean}" | cut -d'.' -f1)"
second_digit_unifi="$(echo "${unifi_clean}" | cut -d'.' -f2)"
third_digit_unifi="$(echo "${unifi_clean}" | cut -d'.' -f3)"
#
if [[ "${cloudkey_generation}" == "1" ]]; then
  if [[ "${first_digit_unifi}" -gt '7' ]] || [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" -ge '3' ]]; then
    header_red
    unifi_latest_72=$(curl -s "https://get.glennr.nl/unifi/latest-versions/7.2/latest.version")
    echo -e "${WHITE_R}#${RESET} UniFi Network Application ${unifi_clean} is not supported on your Gen1 UniFi Cloudkey (UC-CK)."
    echo -e "${WHITE_R}#${RESET} The latest supported version on your Cloudkey is ${unifi_latest_72} and older.. \\n\\n"
    echo -e "${WHITE_R}#${RESET} Consider upgrading to a Gen2 Cloudkey:"
    echo -e "${WHITE_R}#${RESET} UniFi Cloud Key Gen2       | https://store.ui.com/products/unifi-cloud-key-gen2"
    echo -e "${WHITE_R}#${RESET} UniFi Cloud Key Gen2 Plus  | https://store.ui.com/products/unifi-cloudkey-gen2-plus\\n\\n"
    author
    exit 0
  fi
fi
#
if [[ "${first_digit_unifi}" -gt '7' ]] || [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" -ge '5' ]]; then
  if [[ "$(getconf LONG_BIT)" == '32' ]]; then
    header_red
    if [[ "${first_digit_mongodb_version_installed}" -le "2" && "${second_digit_mongodb_version_installed}" -le "5" ]]; then unifi_latest_supported_version="7.3"; else unifi_latest_supported_version="7.4"; fi
    unifi_latest_supported_version=$(curl -s "https://get.glennr.nl/unifi/latest-versions/${unifi_latest_supported_version}/latest.version")
    echo -e "${WHITE_R}#${RESET} Your 32-bit system/OS is no longer supported by UniFi Network Application ${unifi_clean}!"
    echo -e "${WHITE_R}#${RESET} The latest supported version on your system/OS is ${unifi_latest_supported_version} and older..."
    echo -e "${WHITE_R}#${RESET} Consider upgrading to a 64-bit system/OS!\\n\\n"
    author
    exit 0
  fi
fi
#
mongo_version_max="36"
mongo_version_max_with_dot="3.6"
add_mongodb_36_repo="true"
mongo_version_not_supported="4.0"
# MongoDB Version override
if [[ "${first_digit_unifi}" -le '5' && "${second_digit_unifi}" -le '13' ]]; then
  mongo_version_max="34"
  mongo_version_max_with_dot="3.4"
  add_mongodb_34_repo="true"
  unset add_mongodb_36_repo
  mongo_version_not_supported="3.6"
fi
if [[ "${first_digit_unifi}" == '5' && "${second_digit_unifi}" == '13' && "${third_digit_unifi}" -gt '10' ]]; then
  mongo_version_max="36"
  mongo_version_max_with_dot="3.6"
  add_mongodb_36_repo="true"
  mongo_version_not_supported="4.0"
fi
# JAVA/MongoDB Version override
if [[ "${first_digit_unifi}" -gt '8' ]] || [[ "${first_digit_unifi}" == '8' && "${second_digit_unifi}" -ge "1" ]]; then
  mongo_version_max="70"
  mongo_version_max_with_dot="7.0"
  add_mongodb_70_repo="true"
  unset add_mongodb_44_repo
  unset add_mongodb_36_repo
  unset add_mongodb_34_repo
  mongo_version_not_supported="7.1"
  required_java_version="openjdk-17"
  required_java_version_short="17"
elif [[ "${first_digit_unifi}" -gt '7' ]] || [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" -ge "5" ]]; then
  mongo_version_max="44"
  mongo_version_max_with_dot="4.4"
  add_mongodb_44_repo="true"
  unset add_mongodb_36_repo
  unset add_mongodb_34_repo
  mongo_version_not_supported="4.5"
  required_java_version="openjdk-17"
  required_java_version_short="17"
elif [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" =~ (3|4) ]]; then
  required_java_version="openjdk-11"
  required_java_version_short="11"
else
  required_java_version="openjdk-8"
  required_java_version_short="8"
fi

# Stick to 4.4 if cpu doesn't report avx support.
if [[ "${mongo_version_max}" =~ (44|70) ]]; then
  if [[ "${architecture}" == "arm64" ]]; then
    cpu_model_name="$(lscpu | tr '[:upper:]' '[:lower:]' | grep -i 'model name' | cut -f 2 -d ":" | awk '{$1=$1}1')"
    cpu_model_regex="^(cortex-a55|cortex-a65|cortex-a65ae|cortex-a75|cortex-a76|cortex-a77|cortex-a78|cortex-x1|cortex-x2|cortex-x3|cortex-x4|neoverse n1|neoverse n2|neoverse e1|neoverse e2|neoverse v1|neoverse v2|cortex-a510|cortex-a520|cortex-a715|cortex-a720)$"
    if ! [[ "${cpu_model_name}" =~ ${cpu_model_regex} ]]; then
      if [[ "${mongo_version_max}" =~ (70) ]]; then
        if dpkg -l | grep "^ii\\|^hi" | grep -iq "mongod-armv8" || [[ "${script_option_skip}" == 'true' ]]; then
          mongod_armv8_installed="true"
          yes_no="y"
        else
          echo -e "${WHITE_R}----${RESET}\\n"
          echo -e "${YELLOW}#${RESET} Your CPU is no longer officially supported by MongoDB themselves..."
          read -rp $'\033[39m#\033[0m Would you like to try mongod compiled from MongoDB source code specifically for your CPU by Glenn R.? (y/N) ' yes_no
        fi
        case "$yes_no" in
            [Yy]*)
               add_mongod_70_repo="true"
               glennr_compiled_mongod="true"
               cleanup_unifi_repos
               if [[ "${mongod_armv8_installed}" != 'true' ]]; then echo ""; fi;;
            [Nn]*|"")
               unset add_mongodb_70_repo
               add_mongodb_44_repo="true"
               mongo_version_max="44"
               mongo_version_max_with_dot="4.4"
               arm64_mongodb_version="4.4.18";;
        esac
        unset yes_no
      else
        unset add_mongodb_70_repo
        add_mongodb_44_repo="true"
        mongo_version_max="44"
        mongo_version_max_with_dot="4.4"
        arm64_mongodb_version="4.4.18"
      fi
    fi
  elif [[ "${mongo_version_max}" != "44" ]]; then
    if ! lscpu | grep -ioq "avx"; then
      unset add_mongodb_70_repo
      add_mongodb_44_repo="true"
      mongo_version_max="44"
      mongo_version_max_with_dot="4.4"
    elif ! grep -ioq "avx" /proc/cpuinfo; then
      unset add_mongodb_70_repo
      add_mongodb_44_repo="true"
      mongo_version_max="44"
      mongo_version_max_with_dot="4.4"
    fi
  fi
fi

mongo_command() {
  if dpkg -l mongodb-mongosh-shared-openssl3 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
    mongocommand="mongosh"
    mongoprefix="EJSON.stringify( "
    mongosuffix=".toArray() )"
  elif dpkg -l mongodb-mongosh-shared-openssl11 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
    mongocommand="mongosh"
    mongoprefix="EJSON.stringify( "
    mongosuffix=".toArray() )"
  else
    mongocommand="mongo"
    mongoprefix="JSON.stringify( "
    mongosuffix=".toArray() )"
  fi
}
mongo_command

prevent_mongodb_org_server_install() {
  if ! [[ -e "/etc/apt/preferences.d/eus_prevent_install_mongodb-org-server" ]]; then
    tee /etc/apt/preferences.d/eus_prevent_install_mongodb-org-server &>/dev/null << EOF
Package: mongodb-org-server
Pin: release *
Pin-Priority: -1
EOF
  fi
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                             libssl                                                                                              #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

libssl_installation() {
  echo -e "${WHITE_R}#${RESET} Downloading libssl..."
  while read -r libssl_package; do
    libssl_package_empty="false"
    libssl_temp="$(mktemp --tmpdir=/tmp libssl${libssl_version}_XXXXX.deb)" || abort
    if wget "${wget_progress[@]}" -O "$libssl_temp" "${libssl_repo_url}/pool/main/o/${libssl_url_arg}/${libssl_package}" &>> "${eus_dir}/logs/libssl.log"; then
      if [[ "${libssl_download_success_message}" != 'true' ]]; then echo -e "${GREEN}#${RESET} Successfully downloaded libssl! \\n"; libssl_download_success_message="true"; fi
      echo -e "${WHITE_R}#${RESET} Installing libssl..."
      if dpkg -i "$libssl_temp" &>> "${eus_dir}/logs/libssl.log"; then
        echo -e "${GREEN}#${RESET} Successfully installed libssl! \\n"
        libssl_install_success="true"
        break
      else
        if [[ "${libssl_install_failed_message}" != 'true' ]]; then echo -e "${RED}#${RESET} Failed to install libssl... trying some different versions... \\n"; echo -e "${WHITE_R}#${RESET} Attempting to install different versions... \\n"; libssl_install_failed_message="true"; fi
        rm --force "$libssl_temp" &> /dev/null
      fi
    else
      echo -e "${RED}#${RESET} Failed to download libssl..."
      abort
    fi
  done < <(curl -s "${libssl_repo_url}/pool/main/o/${libssl_url_arg}/?C=M;O=D" | grep -io "${libssl_grep_arg}" | cut -d'"' -f1)
  if [[ "${libssl_package_empty}" != 'false' ]]; then
    echo -e "${RED}#${RESET} Failed to locate any libssl packages for version ${libssl_version}...\\n"
    libssl_curl_results="$(curl -s "${libssl_repo_url}/pool/main/o/${libssl_url_arg}/?C=M;O=D")"
    if ! [[ -s "${eus_dir}/logs/libssl-failure-debug-info.json" ]] || ! jq empty "${eus_dir}/logs/libssl-failure-debug-info.json"; then
      jq -n \
        --argjson "libssl failures" "$( 
          jq -n \
            --argjson $(date +%F-%R) "{ \"version\" : \"$libssl_version\", \"URL Argument\" : \"$libssl_url_arg\", \"Grep Argument\" : \"$libssl_grep_arg\", \"Repository URL\" : \"$libssl_repo_url\", \"Curl Results\" : \"$libssl_curl_results\" }" \
             '$ARGS.named'
        )" \
        '$ARGS.named' &> "${eus_dir}/logs/libssl-failure-debug-info.json"
    else
      cat "${eus_dir}/logs/libssl-failure-debug-info.json" | jq --arg libssl_repo_url "${libssl_repo_url}" --arg libssl_grep_arg "${libssl_grep_arg}" --arg libssl_url_arg "${libssl_url_arg}" --arg libssl_version "${libssl_version}" --arg version "${version}" --arg libssl_curl_results "${libssl_curl_results}" '."libssl failures" += {"'$(date +%F-%R)'": {"version": $libssl_version, "URL Argument": $libssl_url_arg, "Grep Argument": $libssl_grep_arg, "Repository URL": $libssl_repo_url, "Curl Results": $libssl_curl_results}}' &> "${eus_dir}/logs/libssl-failure-debug-info-tmp.json"
      if jq empty "${eus_dir}/logs/libssl-failure-debug-info-tmp.json"; then mv "${eus_dir}/logs/libssl-failure-debug-info-tmp.json" "${eus_dir}/logs/libssl-failure-debug-info.json"; fi
    fi
    abort
  fi
  if [[ "${libssl_install_success}" != 'true' && "${libssl_package_empty}" != 'false' ]]; then echo -e "${RED}#${RESET} Failed to install libssl...\\n"; abort; fi
  rm --force "$libssl_temp" 2> /dev/null
}

libssl_installation_check() {
  if [[ -n "${mongodb_package_libssl}" ]]; then
    if apt-cache policy "^${mongodb_package_libssl}$" | grep -ioq "candidate"; then
      if [[ -n "${mongodb_package_version_libssl}" ]]; then
        required_libssl_version="$(apt-cache depends "${mongodb_package_libssl}=${mongodb_package_version_libssl}" | sed -e 's/>//g' -e 's/<//g' | grep -io "libssl1.0.0$\\|libssl1.1$\\|libssl3$")"
      else
        required_libssl_version="$(apt-cache depends "${mongodb_package_libssl}" | sed -e 's/>//g' -e 's/<//g' | grep -io "libssl1.0.0$\\|libssl1.1$\\|libssl3$")"
      fi
      if ! [[ "${required_libssl_version}" =~ (libssl1.0.0|libssl1.1|libssl3) ]]; then echo -e "$(date +%F-%R) | mongodb_package_libssl was \"${mongodb_package_libssl}\", mongodb_package_version_libssl was \"${mongodb_package_version_libssl}\", required_libssl_version was \"${required_libssl_version}\"..." &>> "${eus_dir}/logs/libssl-dynamic-failure.log"; unset required_libssl_version; fi
      unset mongodb_package_libssl
      unset mongodb_package_version_libssl
    fi
  fi
  if [[ -z "${required_libssl_version}" ]]; then
    if [[ "${mongodb_org_upgrade_from_version::2}" -ge "36" && "${mongodb_package_requirement_check}" == 'true' ]]; then
      required_libssl_version="libssl1.1"
      unset mongodb_package_requirement_check
    elif [[ "${mongo_version_max}" == '70' ]]; then
      if grep -sioq "jammy" "/etc/apt/sources.list.d/mongodb-org-7.0.list"; then
        required_libssl_version="libssl3"
      else
        required_libssl_version="libssl1.1"
      fi
    elif [[ "${mongo_version_max}" == '44' ]]; then
      required_libssl_version="libssl1.1"
    elif [[ "${mongo_version_max}" == '36' ]]; then
      required_libssl_version="libssl1.1"
    else
      required_libssl_version="libssl1.0.0"
    fi 
  fi
  unset libssl_install_required
  if [[ "${required_libssl_version}" == 'libssl3' ]]; then
    if ! dpkg -l libssl3 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then libssl_install_required="true"; fi
    libssl_version="3.0"
    libssl_url_arg="openssl"
    libssl_grep_arg="libssl3_3.0.*${architecture}.deb"
    if [[ "${os_codename}" =~ (jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      libssl_repo_url="${http_or_https}://ftp.debian.org/debian"
    else
      if [[ "${architecture}" =~ (amd64|i386) ]]; then
        libssl_repo_url="http://security.ubuntu.com/ubuntu"
      else
        libssl_repo_url="http://ports.ubuntu.com"
      fi
    fi
  elif [[ "${required_libssl_version}" == 'libssl1.1' ]]; then
    if ! dpkg -l libssl1.1 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then libssl_install_required="true"; fi
    libssl_version="1.1.1"
    libssl_url_arg="openssl"
    libssl_grep_arg="libssl1.1.1.*${architecture}.deb"
    if [[ "${os_codename}" =~ (jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
      libssl_repo_url="${http_or_https}://ftp.debian.org/debian"
    else
      if [[ "${architecture}" =~ (amd64|i386) ]]; then
        libssl_repo_url="http://security.ubuntu.com/ubuntu"
      else
        libssl_repo_url="http://ports.ubuntu.com"
      fi
    fi
  elif [[ "${required_libssl_version}" == 'libssl1.0.0' ]]; then
    if ! dpkg -l libssl1.0.0 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then libssl_install_required="true"; fi
    libssl_version="1.0.2"
    libssl_url_arg="openssl1.0"
    libssl_grep_arg="libssl1.0.0.*${architecture}.deb"
    if [[ "${architecture}" =~ (amd64|i386) ]]; then
      libssl_repo_url="http://security.ubuntu.com/ubuntu"
    else
      libssl_repo_url="http://ports.ubuntu.com"
    fi
  else
    echo -e "${RED}#${RESET} Failed to detect what libssl version is required..."
    echo -e "$(date +%F-%R) | Failed to detect what libssl version is required..." &>> "${eus_dir}/logs/libssl-dynamic-failure.log"
    sleep 3
  fi
  if [[ "${libssl_install_required}" == 'true' ]]; then
    if [[ "$(dpkg-query --showformat='${Version}' --show libc6 | sed 's/.*://' | sed 's/-.*//g' | cut -d'.' -f1)" -lt "2" ]] || [[ "$(dpkg-query --showformat='${Version}' --show libc6  | sed 's/.*://' | sed 's/-.*//g' | cut -d'.' -f1)" == "2" && "$(dpkg-query --showformat='${Version}' --show libc6  | sed 's/.*://' | sed 's/-.*//g' | cut -d'.' -f2)" -lt "34" ]]; then
      if [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish) ]] || [[ "${architecture}" != "arm64" ]]; then
        repo_url="http://security.ubuntu.com/ubuntu"
        repo_arguments="-security main"
        repo_codename="jammy"
        os_codename="jammy"
      elif [[ "${os_codename}" =~ (jessie|stretch|buster|bullseye) ]] || [[ "${architecture}" == "arm64" ]]; then
        repo_codename="bookworm"
        os_codename="bookworm"
        get_repo_url
        repo_arguments=" main"
      fi
      add_repositories
      hide_apt_update="true"
      run_apt_get_update
      get_distro
      get_repo_url
    fi
    libssl_installation
  fi
  unset required_libssl_version
}

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                             Checks                                                                                              #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

if [[ "${system_free_disk_space}" -lt "5000000" && "${unifi_core_system}" != 'true' && "${is_cloudkey}" != 'true' ]]; then
  header_red
  echo -e "${WHITE_R}#${RESET} Free disk space is below 5GB.. Please expand the disk size!"
  echo -e "${WHITE_R}#${RESET} I recommend expanding to atleast 10GB\\n\\n"
  if [[ "${script_option_skip}" != 'true' ]]; then
    read -rp "Do you want to proceed at your own risk? (Y/n)" yes_no
    case "$yes_no" in
        [Yy]*|"") ;;
        [Nn]*) cancel_script;;
    esac
  else
    cancel_script
  fi
fi

# MongoDB version check.
if [[ "${mongodb_version_installed_no_dots::2}" -gt "${mongo_version_max}" ]]; then
  if ! [[ -d "/tmp/EUS/mongodb/" ]]; then if ! mkdir -p "/tmp/EUS/mongodb/"; then echo -e "${RED}#${RESET} Failed to create required EUS MongoDB tmp directory..."; abort; fi; fi
  apt-cache rdepends mongodb-* | sed "/mongo/d" | sed "/Reverse Depends/d" | awk '!a[$0]++' | sed 's/|//g' | sed 's/ //g' | sed -e 's/unifi-video//g' -e 's/unifi//g' -e 's/libstdc++6//g' -e '/^$/d' &> /tmp/EUS/mongodb/reverse_depends
  if [[ -s "/tmp/EUS/mongodb/reverse_depends" ]]; then mongodb_has_dependencies="true"; fi
  header_red
  echo -e "${WHITE_R}#${RESET} UniFi Network Application ${unifi_clean} does not support MongoDB ${mongo_version_not_supported}..."
  if [[ "${mongodb_has_dependencies}" == 'true' ]]; then
    echo -e "${WHITE_R}#${RESET} The following services depend on MongoDB..."
    while read -r service; do echo -e "${RED}-${RESET} ${service}"; done < /tmp/EUS/mongodb/reverse_depends
    echo -e "\\n\\n"
    echo -e "${RED}#${RESET} Uninstalling MongoDB will also get rid of the applications/services listed above..."
  fi
  echo -e "\\n\\n"
  if [[ "${script_option_skip}" != 'true' && "${mongodb_has_dependencies}" != 'true' ]]; then
    read -rp "Do you want to proceed with uninstalling MongoDB? (Y/n)" yes_no
  else
    sleep 5
  fi
  case "$yes_no" in
      [Yy]*|"")
        mongodb_installed="false"
        header
        echo -e "${WHITE_R}#${RESET} Preparing unsupported mongodb uninstall... \\n"
        if dpkg -l | grep "unifi " | grep -q "^ii\\|^hi"; then
          echo -e "${WHITE_R}#${RESET} Removing the UniFi Network Application so that the files are kept on the system...\\n"
          if dpkg --remove --force-remove-reinstreq unifi &>> "${eus_dir}/logs/unsupported-mongodb-uninstall.log"; then
            echo -e "${GREEN}#${RESET} Successfully removed the UniFi Network Application! \\n"
          else
            echo -e "${RED}#${RESET} Failed to remove the UniFi Network Application...\\n"
            abort
          fi
        fi
        if dpkg -l | grep "unifi-video" | grep -q "^ii\\|^hi"; then
          echo -e "${WHITE_R}#${RESET} Removing UniFi Video so that the files are kept on the system...\\n"
          if dpkg --remove --force-remove-reinstreq unifi-video &>> "${eus_dir}/logs/unsupported-mongodb-uninstall.log"; then
            echo -e "${GREEN}#${RESET} Successfully removed UniFi Video! \\n"
          else
            echo -e "${RED}#${RESET} Failed to remove UniFi Video...\\n"
            abort
          fi
        fi
        sleep 2
        echo -e "${WHITE_R}#${RESET} Checking for MongoDB repository entries..."
        if grep -qriIl "mongo" /etc/apt/sources.list*; then
          echo -ne "${YELLOW}#${RESET} Removing repository entries for MongoDB..." && sleep 1
          sed -i '/mongodb/d' /etc/apt/sources.list
          if ls /etc/apt/sources.list.d/mongodb* > /dev/null 2>&1; then
            rm /etc/apt/sources.list.d/mongodb* 2> /dev/null
          fi
          echo -e "\\r${GREEN}#${RESET} Successfully removed all MongoDB repository entries! \\n"
        else
          echo -e "\\r${YELLOW}#${RESET} There were no MongoDB Repository entries! \\n"
        fi
        sleep 2
        while read -r mongodb_package_purge; do
          echo -e "${WHITE_R}#${RESET} Purging package ${mongodb_package_purge}..."
          if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' purge "${mongodb_package_purge}" &>> "${eus_dir}/logs/unsupported-mongodb-uninstall.log"; then
            echo -e "${GREEN}#${RESET} Successfully purged ${mongodb_package_purge}! \\n"
          else
            echo -e "${RED}#${RESET} Failed to purge ${mongodb_package_purge}... \\n"
            mongodb_package_purge_failed="true"
          fi
        done < <(dpkg -l | grep "^ii\\|^hi" | grep -i "mongo" | awk '{print $2}')
        if [[ "${mongodb_package_purge_failed}" == 'true' ]]; then
          echo -e "${YELLOW}#${RESET} There was a failure during the purge process...\\n"
          echo -e "${WHITE_R}#${RESET} Uninstalling MongoDB with different actions...\\n"
          while read -r mongodb_package_remove; do
            echo -e "${WHITE_R}#${RESET} Removing package ${mongodb_package_remove}..."
            if DEBIAN_FRONTEND='noninteractive' dpkg --remove --force-remove-reinstreq "${mongodb_package_remove}" &>> "${eus_dir}/logs/unsupported-mongodb-uninstall.log"; then
              echo -e "${GREEN}#${RESET} Successfully removed ${mongodb_package_remove}! \\n"
            else
              echo -e "${RED}#${RESET} Failed to remove ${mongodb_package_remove}... \\n"
            fi
          done < <(dpkg -l | grep "^ii\\|^hi" | grep -i "mongo" | awk '{print $2}')
        fi
        echo -e "${WHITE_R}#${RESET} Running apt-get autoremove..."
        if apt-get -y autoremove &>> "${eus_dir}/logs/apt-cleanup.log"; then echo -e "${GREEN}#${RESET} Successfully ran apt-get autoremove! \\n"; else echo -e "${RED}#${RESET} Failed to run apt-get autoremove"; fi
        echo -e "${WHITE_R}#${RESET} Running apt-get autoclean..."
        if apt-get -y autoclean &>> "${eus_dir}/logs/apt-cleanup.log"; then echo -e "${GREEN}#${RESET} Successfully ran apt-get autoclean! \\n"; else echo -e "${RED}#${RESET} Failed to run apt-get autoclean"; fi
        sleep 3;;
      [Nn]*) cancel_script;;
  esac
fi

# Memory and Swap file.
if [[ "${system_swap}" == "0" && "${script_option_skip_swap}" != 'true' && "${unifi_core_system}" != 'true' && "${is_cloudkey}" != 'true' ]]; then
  header_red
  if [[ "${system_memory}" -lt "2" ]]; then echo -e "${WHITE_R}#${RESET} System memory is lower than recommended!"; fi
  echo -e "${WHITE_R}#${RESET} Creating swap file.\\n"
  sleep 2
  if [[ "${system_free_disk_space}" -ge "10000000" ]]; then
    echo -e "${WHITE_R}---${RESET}\\n"
    echo -e "${WHITE_R}#${RESET} You have more than 10GB of free disk space!"
    echo -e "${WHITE_R}#${RESET} We are creating a 2GB swap file!\\n"
    dd if=/dev/zero of=/swapfile bs=2048 count=1048576 &>/dev/null
    chmod 600 /swapfile &>/dev/null
    mkswap /swapfile &>/dev/null
    swapon /swapfile &>/dev/null
    echo "/swapfile swap swap defaults 0 0" | tee -a /etc/fstab &>/dev/null
  elif [[ "${system_free_disk_space}" -ge "5000000" ]]; then
    echo -e "${WHITE_R}---${RESET}\\n"
    echo -e "${WHITE_R}#${RESET} You have more than 5GB of free disk space."
    echo -e "${WHITE_R}#${RESET} We are creating a 1GB swap file..\\n"
    dd if=/dev/zero of=/swapfile bs=1024 count=1048576 &>/dev/null
    chmod 600 /swapfile &>/dev/null
    mkswap /swapfile &>/dev/null
    swapon /swapfile &>/dev/null
    echo "/swapfile swap swap defaults 0 0" | tee -a /etc/fstab &>/dev/null
  elif [[ "${system_free_disk_space}" -ge "4000000" ]]; then
    echo -e "${WHITE_R}---${RESET}\\n"
    echo -e "${WHITE_R}#${RESET} You have more than 4GB of free disk space."
    echo -e "${WHITE_R}#${RESET} We are creating a 256MB swap file..\\n"
    dd if=/dev/zero of=/swapfile bs=256 count=1048576 &>/dev/null
    chmod 600 /swapfile &>/dev/null
    mkswap /swapfile &>/dev/null
    swapon /swapfile &>/dev/null
    echo "/swapfile swap swap defaults 0 0" | tee -a /etc/fstab &>/dev/null
  elif [[ "${system_free_disk_space}" -lt "4000000" ]]; then
    echo -e "${WHITE_R}---${RESET}\\n"
    echo -e "${WHITE_R}#${RESET} Your free disk space is extremely low!"
    echo -e "${WHITE_R}#${RESET} There is not enough free disk space to create a swap file..\\n"
    echo -e "${WHITE_R}#${RESET} I highly recommend upgrading the system memory to atleast 2GB and expanding the disk space!"
    echo -e "${WHITE_R}#${RESET} The script will continue the script at your own risk..\\n"
   sleep 10
  fi
else
  header
  echo -e "${WHITE_R}#${RESET} A swap file already exists!\\n\\n"
  sleep 2
fi

if [[ -d /tmp/EUS/services ]]; then
  if [[ -f /tmp/EUS/services/stopped_list ]]; then cat /tmp/EUS/services/stopped_list &>> /tmp/EUS/services/stopped_services; fi
  find /tmp/EUS/services/ -type f -printf "%f\\n" | sed 's/ //g' | sed '/file_list/d' | sed '/stopped_services/d' &> /tmp/EUS/services/file_list
  while read -r file; do
    rm --force "/tmp/EUS/services/${file}" &> /dev/null
  done < /tmp/EUS/services/file_list
  rm --force /tmp/EUS/services/file_list &> /dev/null
fi

if netstat -tulpn | grep -q ":8080\\b"; then
  port_8080_pid=$(netstat -tulpn | grep ":8080\\b" | awk '{print $7}' | sed 's/[/].*//g' | head -n1)
  port_8080_service=$(head -n1 "/proc/${port_8080_pid}/comm")
  # shellcheck disable=SC2012
  if [[ "$(ls -l "/proc/${port_8080_pid}/exe" 2> /dev/null | awk '{print $3}')" != "unifi" ]]; then
    port_8080_in_use="true"
    if ! [[ -d /tmp/EUS/services ]]; then mkdir -p /tmp/EUS/services; fi
    echo -e "${port_8080_service}" &>> /tmp/EUS/services/list
    echo -e "${port_8080_pid}" &>> /tmp/EUS/services/pid_list
  fi
fi
if netstat -tulpn | grep -q ":8443\\b"; then
  port_8443_pid=$(netstat -tulpn | grep ":8443\\b" | awk '{print $7}' | sed 's/[/].*//g' | head -n1)
  port_8443_service=$(head -n1 "/proc/${port_8443_pid}/comm")
  # shellcheck disable=SC2012
  if [[ "$(ls -l "/proc/${port_8443_pid}/exe" 2> /dev/null | awk '{print $3}')" != "unifi" ]]; then
    port_8443_in_use="true"
    if ! [[ -d /tmp/EUS/services ]]; then mkdir -p /tmp/EUS/services; fi
    echo -e "${port_8443_service}" &>> /tmp/EUS/services/list
    echo -e "${port_8443_pid}" &>> /tmp/EUS/services/pid_list
  fi
fi

check_port() {
  if ! [[ "${port}" =~ ${reg} ]]; then
    header_red
    echo -e "${WHITE_R}#${RESET} '${port}' is not a valid format, please only use numbers ( 0-9 )" && sleep 3
    change_default_ports
  elif [[ "${port}" -le "1024" || "${port}" -gt "65535" ]]; then
    header_red
    echo -e "${WHITE_R}#${RESET} '${port}' needs to be between 1025 and 65535.." && sleep 3
    change_default_ports
  else
    if netstat -tulpn | grep -q ":${port}\\b"; then
      header_red
      echo -e "${WHITE_R}#${RESET} '${port}' Is already in use by another process.." && sleep 3
      change_default_ports
    elif grep "${port}" /tmp/EUS/services/new_ports 2> /dev/null; then
      header_red
      echo -e "${WHITE_R}#${RESET} '${port}' will already be used for the UniFi Network Application.." && sleep 3
      change_default_ports
    elif [[ "${change_unifi_ports}" == 'true' && "${port}" == "${port_number}" ]]; then
      header_red
      echo -e "${WHITE_R}#${RESET} '${port}' Is already used by the service we stopped.." && sleep 3
      change_default_ports
    else
      echo -e "${WHITE_R}#${RESET} '${port}' Is available, we will use this for the ${port_usage}.."
      echo -e "${port_number}" &>> /tmp/EUS/services/success_port_change
      echo -e "${port}" &>> /tmp/EUS/services/new_ports
    fi
  fi
}

change_default_ports() {
  if [[ "${port_8080_in_use}" == 'true' ]] && ! grep "8080" /tmp/EUS/services/success_port_change 2> /dev/null; then
    port_usage="Device Inform"
    port_number="8080"
    reg='^[0-9]'
    echo -e "\\n${WHITE_R}----${RESET}\\n\\n${WHITE_R}#${RESET} Changing the default Device Inform port..\\n${WHITE_R}#${RESET} Please enter an alternate port below!"
	if [[ "${script_option_skip}" != 'true' ]]; then
      read -n 5 -rp $'\033[39m#\033[0m Device Inform Port | \033[39m' port
    else
      netstat -tulpn  &> /tmp/EUS/services/netstat
      if ! grep -q ":8081\\b" /tmp/EUS/services/netstat; then
        port="8081"
      elif ! grep -q ":8082\\b" /tmp/EUS/services/netstat; then
        port="8082"
      elif ! grep -q ":8083\\b" /tmp/EUS/services/netstat; then
        port="8083"
      elif ! grep -q ":8084\\b" /tmp/EUS/services/netstat; then
        port="8084"
      fi
    fi
    check_port
    if ! grep "^unifi.http.port=" /usr/lib/unifi/data/system.properties; then echo -e "unifi.http.port=${port}" &>> /usr/lib/unifi/data/system.properties && echo -e "${GREEN}#${RESET} Successfully changed the Device Inform port to '${port}'!"; else echo -e "${RED}#${RESET} Failed to change the Device Inform port."; fi
  fi
  if [[ "${port_8443_in_use}" == 'true' ]] && ! grep "8443" /tmp/EUS/services/success_port_change 2> /dev/null; then
    port_usage="Management Dashboard"
    port_number="8443"
    reg='^[0-9]'
    echo -e "\\n${WHITE_R}----${RESET}\\n\\n${WHITE_R}#${RESET} Changing the default UniFi Network Application Dashboard port..\\n${WHITE_R}#${RESET} Please enter an alternate port below!"
	if [[ "${script_option_skip}" != 'true' ]]; then
      read -n 5 -rp $'\033[39m#\033[0m UniFi Network Application Dashboard Port | \033[39m' port
    else
      netstat -tulpn  &> /tmp/EUS/services/netstat
      if ! grep -q ":1443\\b" /tmp/EUS/services/netstat; then
        port="1443"
      elif ! grep -q ":2443\\b" /tmp/EUS/services/netstat; then
        port="2443"
      elif ! grep -q ":3443\\b" /tmp/EUS/services/netstat; then
        port="3443"
      elif ! grep -q ":4443\\b" /tmp/EUS/services/netstat; then
        port="4443"
      fi
    fi
    check_port
    if ! grep "^unifi.https.port=" /usr/lib/unifi/data/system.properties; then echo -e "unifi.https.port=${port}" &>> /usr/lib/unifi/data/system.properties && echo -e "${GREEN}#${RESET} Successfully changed the Management Dashboard port to '${port}'!"; else echo -e "${RED}#${RESET} Failed to change the Management Dashboard port."; fi
  fi
  sleep 3
  if [[ -f /tmp/EUS/services/success_port_change && -s /tmp/EUS/services/success_port_change ]]; then
    header
    echo -e "${WHITE_R}#${RESET} Starting the UniFi Network Application.."
    systemctl start unifi
    if systemctl status unifi | grep -iq "Active: active (running)"; then
      echo -e "${GREEN}#${RESET} Successfully started the UniFi Network Application!"
    else
      echo -e "${RED}#${RESET} Failed to start the UniFi Network Application." && abort
    fi
    sleep 3
  fi
  if [[ "${change_unifi_ports}" != 'false' ]]; then
    if [[ -f /tmp/EUS/services/stopped_list && -s /tmp/EUS/services/stopped_list ]]; then
      while read -r service; do
        echo -e "\\n${WHITE_R}#${RESET} Starting ${service}.."
        systemctl start "${service}" && echo -e "${GREEN}#${RESET} Successfully started ${service}!" || echo -e "${RED}#${RESET} Failed to start ${service}!"
      done < /tmp/EUS/services/stopped_list
      sleep 3
    fi
  fi
}

if [[ "${port_8080_in_use}" == 'true' || "${port_8443_in_use}" == 'true' ]]; then
  cp /tmp/EUS/services/pid_list /tmp/EUS/services/pid_list_tmp && awk '!a[$0]++' < /tmp/EUS/services/pid_list_tmp &> /tmp/EUS/services/pid_list && rm --force /tmp/EUS/services/pid_list_tmp
  cp /tmp/EUS/services/list /tmp/EUS/services/list_tmp && awk '!a[$0]++' < /tmp/EUS/services/list_tmp &> /tmp/EUS/services/list && rm --force /tmp/EUS/services/list_tmp
  header_red
  echo -e "${RED}#${RESET} The following service(s) is/are running on a port that the UniFi Network Application wants to use as well.."
  # shellcheck disable=SC2009
  while read -r service_pid; do service_on_pid=$(head -n1 "/proc/${service_pid}/comm" 2> /dev/null); ps_service_on_pid=$(ps aux | grep -e "${service_pid}" | grep -v " grep -e ${service_pid}" | awk '{print $1}' | head -n1 2> /dev/null); echo -e "${RED}-${RESET} ${service_on_pid} ( ${ps_service_on_pid} ) | PID: ${service_pid}"; done < /tmp/EUS/services/pid_list
  echo ""
  if [[ "${script_option_skip}" != 'true' ]]; then
    read -rp $'\033[39m#\033[0m Do you want the script to find other port(s) for the UniFi Network Application? (Y/n) ' yes_no
  else
    echo -e "${WHITE_R}#${RESET} Script will change the default UniFi Network Application Ports.."
    sleep 2
  fi
  case "$yes_no" in
      [Yy]*|"") change_unifi_ports="true";;
      [Nn]*) change_unifi_ports="false" && echo -e "\\n${WHITE_R}----${RESET}\\n\\n${RED}#${RESET} The script will keep the services stopped, you need to manually change the conflicting ports of these services and then start them again..";;
  esac
  if [[ "${script_option_skip}" != 'true' ]]; then
    read -rp $'\033[39m#\033[0m Can we temporarily stop the service(s)? (Y/n) ' yes_no
  else
    echo -e "${WHITE_R}#${RESET} Temporarily stopping the services.."
    sleep 2
  fi
  case "$yes_no" in
      [Yy]*|"")
        echo -e "\\n${WHITE_R}----${RESET}\\n"
        while read -r service; do
          echo -e "${WHITE_R}#${RESET} Trying to stop ${service}..."
          systemctl stop "${service}" 2> /dev/null && echo -e "${service}" &>> /tmp/EUS/services/stopped_list
          if grep -iq "${service}" /tmp/EUS/services/stopped_list; then
            echo -e "${GREEN}#${RESET} Successfully stopped ${service}!"
          else
            echo -e "${RED}#${RESET} Failed to stop ${service}... Giving it one more try..."
            service="$(dpkg -l | grep -i "$(echo "${service}" | cut -d"-" -f1)" | awk '{print $2}')"
            echo -e "${WHITE_R}#${RESET} Trying to stop ${service}..."
            systemctl stop "${service}" 2> /dev/null && echo -e "${service}" &>> /tmp/EUS/services/stopped_list
            if grep -iq "${service}" /tmp/EUS/services/stopped_list; then
              echo -e "${GREEN}#${RESET} Successfully stopped ${service}!"
            else
              echo -e "${RED}#${RESET} Failed to stop ${service}.." && echo -e "${service}" &>> /tmp/EUS/services/stopped_failed_list
            fi
          fi
        done < /tmp/EUS/services/list
        sleep 2
        if [[ -f /tmp/EUS/services/stopped_failed_list && -s /tmp/EUS/services/stopped_failed_list ]]; then
          echo -e "\\n${WHITE_R}----${RESET}\\n"
          echo -e "${RED}#${RESET} The script failed to stop the following service(s).."
          while read -r service; do echo -e "${RED}-${RESET} ${service}"; done < /tmp/EUS/services/stopped_failed_list
          echo -e "${RED}#${RESET} We can try to kill the PID(s) of these services(s) but the script won't be able to start the service(s) again after completion.."
          if [[ "${script_option_skip}" != 'true' ]]; then
            read -rp $'\033[39m#\033[0m Can we proceed with killing the PID? (y/N) ' yes_no
          else
            echo -e "${WHITE_R}#${RESET} Killing the PID(s).."
            sleep 2
          fi
          case "$yes_no" in
              [Yy]*)
                echo -e "\\n${WHITE_R}----${RESET}\\n"
                while read -r pid; do
                  echo -e "${WHITE_R}#${RESET} Trying to kill ${pid}..."
                  kill -9 "${pid}" 2> /dev/null && echo -e "${pid}" &>> /tmp/EUS/services/killed_pid_list
                  if grep -iq "${pid}" /tmp/EUS/services/killed_pid_list; then echo -e "${GREEN}#${RESET} Successfully killed PID ${pid}!"; else echo -e "${RED}#${RESET} Failed to kill PID ${pid}.." && echo -e "${pid}" &>> /tmp/EUS/services/failed_killed_pid_list; fi
                done < /tmp/EUS/services/pid_list
                sleep 2
                if [[ -f /tmp/EUS/services/failed_killed_pid_list && -s /tmp/EUS/services/failed_killed_pid_list ]]; then
                  while read -r failed_pid; do
                    echo -e "${RED}-${RESET} PID ${failed_pid}..."
                  done < /tmp/EUS/services/failed_killed_pid_list
                  echo -e "${RED}#${RESET} You will have to change the following default post(s) yourself after the installation completed.."
                  if [[ "${port_8080_in_use}" == 'true' ]]; then
                    echo -e "${RED}-${RESET} 8080 ( Device Inform )"
                  fi
                  if [[ "${port_8443_in_use}" == 'true' ]]; then
                    echo -e "${RED}-${RESET} 8443 ( Management Dashboard )"
                  fi
                  sleep 5
                fi;;
              [Nn]*|"") ;;
          esac
        fi
        sleep 2;;
      [Nn]*)
        header_red
        echo -e "${RED}#${RESET} Continuing your UniFi Network Application install."
        echo -e "${RED}#${RESET} Please be aware that your application won't be able to start.."
        sleep 5;;
  esac
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                  Ask to keep script or delete                                                                                   #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

script_removal() {
  header
  read -rp $'\033[39m#\033[0m Do you want to keep the script on your system after completion? (Y/n) ' yes_no
  case "$yes_no" in
      [Yy]*|"") ;;
      [Nn]*) delete_script="true";;
  esac
}

if [[ "${script_option_skip}" != 'true' ]]; then
  script_removal
fi

# Expired MongoDB key check
if ! [[ -e "${eus_dir}/data/mongodb-key-check-time" ]]; then
  if ! [[ -d "${eus_dir}/data" ]]; then mkdir -p "${eus_dir}/data"; fi
  echo -e "$(date +%s)" &> "${eus_dir}/data/mongodb-key-check-time"
fi
while read -r mongodb_repo_version; do
  if [[ "$(curl -s https://get.glennr.nl/unifi/releases/mongodb-versions.json | jq -r '.versions."'${mongodb_repo_version}'".updated')" -ge "$(cat "${eus_dir}/data/mongodb-key-check-time")" ]]; then
    if [[ "${expired_header}" != 'true' ]]; then if header; then expired_header="true"; fi; fi
    if [[ "${expired_mongodb_check_message}" != 'true' ]]; then if echo -e "${WHITE_R}#${RESET} Checking for expired MongoDB repository keys..."; then expired_mongodb_check_message="true"; fi; fi
    if [[ "${expired_mongodb_check_message}" == 'true' ]]; then echo -e "${YELLOW}#${RESET} The script detected that the repository key for MongoDB version ${mongodb_repo_version} has been updated by MongoDB... \\n"; fi
    if [[ "${mongodb_repo_version//./}" =~ (32|34|36|40|42|44) ]]; then
      mongodb_key_update="true"
      mongodb_version_major_minor="${mongodb_repo_version}"
      mongodb_org_v="${mongodb_repo_version//./}"
      add_mongodb_repo
      continue
    fi
  fi
  while read -r repo_file; do
    if ! grep -ioq "trusted=yes" "${repo_file}" && [[ "$(curl -s https://get.glennr.nl/unifi/releases/mongodb-versions.json | jq -r '.versions."'${mongodb_repo_version}'".expired')" == 'true' ]]; then
      if [[ "${expired_header}" != 'true' ]]; then if header; then expired_header="true"; fi; fi
      if [[ "${expired_mongodb_check_message}" != 'true' ]]; then if echo -e "${WHITE_R}#${RESET} Checking for expired MongoDB repository keys..."; then expired_mongodb_check_message="true"; fi; fi
      if [[ "${mongodb_repo_version//./}" =~ (32|34|36|40|42|44) ]]; then
        if [[ "${expired_mongodb_check_message}" == 'true' ]]; then echo -e "${YELLOW}#${RESET} The script will add a new repository entry for MongoDB version ${mongodb_repo_version}... \\n"; fi
        mongodb_key_update="true"
        mongodb_version_major_minor="${mongodb_repo_version}"
        mongodb_org_v="${mongodb_repo_version//./}"
        add_mongodb_repo
      else
        if ! [[ -d "${eus_dir}/repository/archived/" ]]; then mkdir -p "${eus_dir}/repository/archived/"; fi
        if [[ "${expired_mongodb_check_message}" == 'true' ]]; then echo -e "${WHITE_R}#${RESET} The repository for version ${mongodb_repo_version} will be moved to \"${eus_dir}/repository/archived/$(basename -- "${repo_file}")\"..."; fi
        if mv "${repo_file}" "${eus_dir}/repository/archived/$(basename -- "${repo_file}")" &>> "${eus_dir}/logs/repository-archiving.log"; then echo -e "${GREEN}#${RESET} Successfully moved the repository list to \"${eus_dir}/repository/archived/$(basename -- "${repo_file}")\"! \\n"; else echo -e "${RED}#${RESET} Failed to move the repository list to \"${eus_dir}/repository/archived/$(basename -- "${repo_file}")\"... \\n"; fi
        mongodb_expired_archived="true"
      fi
    fi
  done < <(grep -riIl "${mongodb_repo_version} main\\|${mongodb_repo_version} multiverse" /etc/apt/sources.list /etc/apt/sources.list.d/)
  if [[ "${expired_mongodb_check_message_3}" != 'true' ]]; then if [[ "${expired_mongodb_check_message}" == 'true' && "${mongodb_key_update}" != 'true' && "${mongodb_expired_archived}" != 'true' ]]; then echo -e "${GREEN}#${RESET} The script didn't detect any expired MongoDB repository keys! \\n"; expired_mongodb_check_message_3="true"; sleep 3; fi; fi
done < <(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep mongodb | grep -io "[0-9].[0-9]" | awk '!NF || !seen[$0]++')
if [[ "${mongodb_key_update}" == 'true' ]]; then hide_apt_update="true"; run_apt_get_update; unset mongodb_key_update; sleep 3; fi

if ! systemctl daemon-reexec &>> "${eus_dir}/logs/daemon-reexec.log"; then
  echo -e "${RED}#${RESET} Failed to re-execute the systemctl daemon... \\n"
  sleep 3
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                 Installation Script starts here                                                                                 #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

remove_older_mongodb_repositories() {
  echo -e "${WHITE_R}#${RESET} Checking for older MongoDB repository entries..."
  if grep -qriIl "mongo" /etc/apt/sources.list*; then
    echo -ne "${WHITE_R}#${RESET} Removing old repository entries for MongoDB..." && sleep 1
    sed -i '/mongodb/d' /etc/apt/sources.list
    if ls /etc/apt/sources.list.d/mongodb* > /dev/null 2>&1; then
      rm /etc/apt/sources.list.d/mongodb*  2> /dev/null
    fi
    echo -e "\\r${GREEN}#${RESET} Successfully removed all older MongoDB repository entries! \\n"
  else
    echo -e "\\r${YELLOW}#${RESET} There were no older MongoDB Repository entries! \\n"
  fi
  sleep 2
}

mongodb_upgrade_check() {
  while read -r mongodb_upgrade_check_package; do
    mongodb_upgrade_check_from_version="$(dpkg-query --showformat='${Version}' --show "${mongodb_upgrade_check_package}" | sed 's/.*://' | sed 's/-.*//g' | sed 's/\.//g')"
    mongodb_upgrade_check_to_version="$(apt-cache madison "${mongodb_upgrade_check_package}" | awk '{print $3}' | sort -V | tail -n 1 | sed 's/\.//g')"
    if [[ "${mongodb_upgrade_check_to_version::2}" -gt "${mongodb_upgrade_check_from_version::2}" ]]; then
      echo -e "${WHITE_R}#${RESET} Preventing ${mongodb_upgrade_check_package} from upgrading..."
      if echo "${mongodb_upgrade_check_package} hold" | dpkg --set-selections; then
        echo -e "${GREEN}#${RESET} Successfully prevented ${mongodb_upgrade_check_package} from upgrading! \\n"
      else
        echo -e "${RED}#${RESET} Failed to prevent ${mongodb_upgrade_check_package} from upgrading...\\n"
        if [[ "${mongodb_upgrade_check_remove_old_mongo_repo}" != 'true' ]]; then remove_older_mongodb_repositories; mongodb_upgrade_check_remove_old_mongo_repo="true"; hide_apt_update="true"; run_apt_get_update; fi
      fi
    fi
  done < <(dpkg -l | awk '/ii.*mongo/ {print $2}')
}

system_upgrade() {
  if [[ -f /tmp/EUS/upgrade/upgrade_list && -s /tmp/EUS/upgrade/upgrade_list ]]; then
    while read -r package; do
      echo -e "\\n------- updating ${package} ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/upgrade.log"
      echo -ne "\\r${WHITE_R}#${RESET} Updating package ${package}..."
      if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' --only-upgrade install "${package}" &>> "${eus_dir}/logs/upgrade.log"; then
        echo -e "\\r${GREEN}#${RESET} Successfully updated package ${package}!"
      elif tail -n1 /usr/lib/EUS/logs/upgrade.log | grep -ioq "Packages were downgraded and -y was used without --allow-downgrades" "${eus_dir}/logs/upgrade.log"; then
        if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' --only-upgrade --allow-downgrades install "${package}" &>> "${eus_dir}/logs/upgrade.log"; then
          echo -e "\\r${GREEN}#${RESET} Successfully updated package ${package}!"
          continue
        else
          echo -e "\\r${RED}#${RESET} Something went wrong during the update of package ${package}... \\n${RED}#${RESET} The script will continue with an apt-get upgrade...\\n"
          break
        fi
        echo -e "\\r${RED}#${RESET} Something went wrong during the update of package ${package}... \\n${RED}#${RESET} The script will continue with an apt-get upgrade...\\n"
        break
      fi
    done < /tmp/EUS/upgrade/upgrade_list
    echo ""
  fi
  echo -e "\\n------- apt-get upgrade ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/upgrade.log"
  echo -e "${WHITE_R}#${RESET} Running apt-get upgrade..."
  if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade &>> "${eus_dir}/logs/upgrade.log"; then echo -e "${GREEN}#${RESET} Successfully ran apt-get upgrade! \\n"; else echo -e "${RED}#${RESET} Failed to run apt-get upgrade"; abort; fi
  echo -e "\\n------- apt-get dist-upgrade ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/upgrade.log"
  echo -e "${WHITE_R}#${RESET} Running apt-get dist-upgrade..."
  if DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' dist-upgrade &>> "${eus_dir}/logs/upgrade.log"; then echo -e "${GREEN}#${RESET} Successfully ran apt-get dist-upgrade! \\n"; else echo -e "${RED}#${RESET} Failed to run apt-get dist-upgrade"; abort; fi
  echo -e "${WHITE_R}#${RESET} Running apt-get autoremove..."
  if apt-get -y autoremove &>> "${eus_dir}/logs/apt-cleanup.log"; then echo -e "${GREEN}#${RESET} Successfully ran apt-get autoremove! \\n"; else echo -e "${RED}#${RESET} Failed to run apt-get autoremove"; fi
  echo -e "${WHITE_R}#${RESET} Running apt-get autoclean..."
  if apt-get -y autoclean &>> "${eus_dir}/logs/apt-cleanup.log"; then echo -e "${GREEN}#${RESET} Successfully ran apt-get autoclean! \\n"; else echo -e "${RED}#${RESET} Failed to run apt-get autoclean"; fi
  sleep 3
}

cleanup_codename_mismatch_repos
header
echo -e "${WHITE_R}#${RESET} Checking if your system is up-to-date...\\n" && sleep 1
hide_apt_update="true"
run_apt_get_update
mongodb_upgrade_check
echo -e "${WHITE_R}#${RESET} The package(s) below can be upgraded!"
echo -e "\\n${WHITE_R}----${RESET}\\n"
rm --force /tmp/EUS/upgrade/upgrade_list &> /dev/null
{ apt-get --just-print upgrade 2>&1 | perl -ne 'if (/Inst\s([\w,\-,\d,\.,~,:,\+]+)\s\[([\w,\-,\d,\.,~,:,\+]+)\]\s\(([\w,\-,\d,\.,~,:,\+]+)\)? /i) {print "$1 ( \e[1;34m$2\e[0m -> \e[1;32m$3\e[0m )\n"}';} | while read -r line; do echo -en "${WHITE_R}-${RESET} $line\\n"; echo -en "$line\\n" | awk '{print $1}' &>> /tmp/EUS/upgrade/upgrade_list; done;
if [[ -f /tmp/EUS/upgrade/upgrade_list ]]; then number_of_updates=$(wc -l < /tmp/EUS/upgrade/upgrade_list); else number_of_updates='0'; fi
if [[ "${number_of_updates}" == '0' ]]; then echo -e "${WHITE_R}#${RESET} There are no packages that need an upgrade..."; fi
echo -e "\\n${WHITE_R}----${RESET}\\n"
if [[ "${script_option_skip}" != 'true' ]]; then
  read -rp $'\033[39m#\033[0m Do you want to proceed with updating your system? (Y/n) ' yes_no
else
  echo -e "${WHITE_R}#${RESET} Performing the updates!"
fi
case "$yes_no" in
    [Yy]*|"") echo -e "\\n${WHITE_R}----${RESET}\\n"; system_upgrade;;
    [Nn]*) ;;
esac
while read -r mongo_package; do
  echo "${mongo_package} install" | dpkg --set-selections &> /dev/null
done < <(dpkg -l | awk '/ii.*mongo/ {print $2}')
rm --force /tmp/EUS/upgrade/upgrade_list &> /dev/null

mongodb_installation() {
  if [[ "${glennr_compiled_mongod}" == 'true' ]]; then
    list_of_mongod_armv8_dependencies="$(apt-cache depends mongod-armv8 | tr '[:upper:]' '[:lower:]' | grep -i depends | awk '!a[$0]++' | sed -e 's/|//g' -e 's/ //g' -e 's/<//g' -e 's/>//g' -e 's/depends://g' | sort -V | awk '!/^gcc/ || !f++')"
    mongod_armv8_dependency_version="$(echo "${list_of_mongod_armv8_dependencies}" | grep -Eio "gcc-[0-9]{1,2}-base" | sed -e 's/gcc-//g' -e 's/-base//g')"
    while read -r mongod_armv8_dependency; do
      if [[ "${mongod_armv8_dependency}" =~ (libssl1.0.0|libssl1.1|libssl3) ]]; then
        mongodb_package_libssl="mongod-armv8"
        mongodb_package_version_libssl="${install_mongod_version}"
        libssl_installation_check
        continue
      fi
      if dpkg -l mongodb-mongosh-shared-openssl11 "${mongod_armv8_dependency}" 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
        mongod_armv8_dependency_version_current="$(dpkg-query --showformat='${Version}' --show "${mongod_armv8_dependency}" | cut -d'.' -f1)"
      else
        mongod_armv8_dependency_version_current="0"
      fi
      if [[ "${mongod_armv8_dependency_version_current}" -le "${mongod_armv8_dependency_version}" ]]; then
        if ! apt-cache policy "${mongod_armv8_dependency}" | tr '[:upper:]' '[:lower:]' | sed '1,/version table/d' | sed -e 's/500//g' -e '/http/d' -e '/var/d' -e 's/*//g' -e 's/ //g' | grep -iq "^${mongod_armv8_dependency_version}"; then
          if [[ "${os_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish) ]]; then
            repo_codename="jammy"
            os_codename="jammy"
            get_repo_url
          elif [[ "${os_codename}" =~ (jessie|stretch|continuum|buster|bullseye) ]]; then
            repo_codename="bookworm"
            os_codename="bookworm"
            get_repo_url
          fi
          repo_arguments=" main"
          add_repositories
          hide_apt_update="true"
          run_apt_get_update
          get_distro
          get_repo_url
        fi
        mongod_armv8_dependency_install_version="$(apt-cache policy "${mongod_armv8_dependency}" | tr '[:upper:]' '[:lower:]' | sed '1,/version table/d' | sed -e 's/500//g' -e '/http/d' -e '/var/d' -e 's/*//g' -e 's/ //g' | grep -i "^${mongod_armv8_dependency_version}")"
        if [[ -z "${mongod_armv8_dependency_install_version}" ]]; then
          echo -e "${RED}#${RESET} Failed to locate required version for ${mongod_armv8_dependency}...\\n"
        fi
        echo -e "${WHITE_R}#${RESET} Installing ${mongod_armv8_dependency}..."
        if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongod_armv8_dependency}"="${mongod_armv8_dependency_install_version}" &>> "${eus_dir}/logs/mongod-armv8-dependencies.log"; then
          echo -e "${RED}#${RESET} Failed to install ${mongod_armv8_dependency}...\\n"
        else
          echo -e "${GREEN}#${RESET} Successfully installed ${mongod_armv8_dependency}! \\n" && sleep 2
        fi
      fi
    done < <(echo "${list_of_mongod_armv8_dependencies}")
    mongodb_installation_server_package="mongod-armv8${install_mongodd_version_with_equality_sign}"
  else
    mongodb_package_libssl="mongodb-org-server"
    mongodb_package_version_libssl="${install_mongodb_version}"
    libssl_installation_check
    mongodb_installation_server_package="mongodb-org-server${install_mongodb_version_with_equality_sign}"
  fi
  echo -e "${WHITE_R}#${RESET} Installing mongodb-org version ${mongo_version_max_with_dot::3}..."
  if DEBIAN_FRONTEND='noninteractive' apt-get -y --allow-downgrades "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongodb_installation_server_package}" "mongodb-org-shell${install_mongodb_version_with_equality_sign}" "mongodb-org-tools${install_mongodb_version_with_equality_sign}" &>> "${eus_dir}/logs/mongodb-org-install.log"; then
    echo -e "${GREEN}#${RESET} Successfully installed mongodb-org version ${mongo_version_max_with_dot::3}! \\n"
    mongodb_installed="true"
  else
    echo -e "${RED}#${RESET} Failed to install mongodb-org version ${mongo_version_max_with_dot::3}...\\n"
    try_different_mongodb_repo="true"
    add_mongodb_repo
    mongodb_package_libssl="mongodb-org-server"
    mongodb_package_version_libssl="${install_mongodb_version}"
    libssl_installation_check
    echo -e "${WHITE_R}#${RESET} Trying to install mongodb-org version ${mongo_version_max_with_dot::3} in the second run..."
    if DEBIAN_FRONTEND='noninteractive' apt-get -y --allow-downgrades "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongodb_installation_server_package}" "mongodb-org-shell${install_mongodb_version_with_equality_sign}" "mongodb-org-tools${install_mongodb_version_with_equality_sign}" &>> "${eus_dir}/logs/mongodb-org-install.log"; then
      echo -e "${GREEN}#${RESET} Successfully installed mongodb-org version ${mongo_version_max_with_dot::3} in the second run! \\n"
      mongodb_installed="true"
    else
      echo -e "${RED}#${RESET} Failed to install mongodb-org version ${mongo_version_max_with_dot::3} in the second run...\\n"
      try_different_mongodb_repo="true"
      try_http_mongodb_repo="true"
      add_mongodb_repo
      mongodb_package_libssl="mongodb-org-server"
      mongodb_package_version_libssl="${install_mongodb_version}"
      libssl_installation_check
      echo -e "${WHITE_R}#${RESET} Trying to install mongodb-org version ${mongo_version_max_with_dot::3} in the third run..."
      if DEBIAN_FRONTEND='noninteractive' apt-get -y --allow-downgrades "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongodb_installation_server_package}" "mongodb-org-shell${install_mongodb_version_with_equality_sign}" "mongodb-org-tools${install_mongodb_version_with_equality_sign}" &>> "${eus_dir}/logs/mongodb-org-install.log"; then
        echo -e "${GREEN}#${RESET} Successfully installed mongodb-org version ${mongo_version_max_with_dot::3} in the third run! \\n"
        mongodb_installed="true"
      else
        echo -e "${RED}#${RESET} Failed to install mongodb-org version ${mongo_version_max_with_dot::3} in the third run...\\n"
        abort
      fi
    fi
  fi
  if [[ "${architecture}" == "arm64" && "${mongodb_version_major_minor}" == "4.4" ]]; then
    if ! [[ -d "/tmp/EUS/mongodb" ]]; then if ! mkdir -p /tmp/EUS/mongodb; then echo -e "${RED}#${RESET} Failed to create required EUS tmp directory..."; abort; fi; fi
    dpkg -l | grep mongodb-org | grep "^ii\\|^hi" | awk '{print $2}' &> /tmp/EUS/mongodb/packages_list
    while read -r mongodb_package; do
      echo -e "${WHITE_R}#${RESET} Preventing ${mongodb_package} from upgrading..."
      if echo "${mongodb_package} hold" | dpkg --set-selections; then
        echo -e "${GREEN}#${RESET} Successfully prevented ${mongodb_package} from upgrading! \\n"
      else
        echo -e "${RED}#${RESET} Failed to prevent ${mongodb_package} from upgrading...\\n"
        abort
      fi
    done < /tmp/EUS/mongodb/packages_list
    rm /tmp/EUS/mongodb/packages_list
  fi
}

mongodb_server_clients_installation() {
  if [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|sarah|serena|sonya|sylvia|tara|tessa|tina|tricia) ]]; then
    repo_arguments=" main universe"
    repo_codename="xenial"
    os_codename="xenial"
    get_repo_url
  elif [[ "${os_codename}" =~ (jessie|stretch|continuum|buster|bullseye|bookworm|trixie|forky) ]]; then
    repo_arguments=" main"
    repo_codename="stretch"
    os_codename="stretch"
    get_repo_url
  fi
  echo -e "${WHITE_R}#${RESET} Installing mongodb-server and mongodb-clients..."
  if ! DEBIAN_FRONTEND='noninteractive' apt-get -y --allow-downgrades "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install mongodb-server mongodb-clients &>> "${eus_dir}/logs/mongodb-server-client-install.log"; then
    echo -e "${RED}#${RESET} Failed to install mongodb-server and mongodb-clients in the first run...\\n"
    add_repositories
    hide_apt_update="true"
    run_apt_get_update
    echo -e "${WHITE_R}#${RESET} Trying to install mongodb-server and mongodb-clients for the second time..."
    if ! DEBIAN_FRONTEND='noninteractive' apt-get -y --allow-downgrades "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install mongodb-server mongodb-clients &>> "${eus_dir}/logs/mongodb-server-client-install.log"; then
      echo -e "${RED}#${RESET} Failed to install mongodb-server and mongodb-clients in the second run... \\n${WHITE_R}#${RESET} Trying to save the installation...\\n"
      echo -e "${WHITE_R}#${RESET} Running apt-get install -f..."
      if ! apt-get install -f &>> "${eus_dir}/logs/mongodb-server-client-install.log"; then
        echo -e "${RED}#${RESET} Failed to run \"apt-get install -f\"! \\n"
        abort
      else
        echo -e "${GREEN}#${RESET} Successfully ran \"apt-get install -f\"! \\n"
        echo -e "${WHITE_R}#${RESET} Trying to install mongodb-server and mongodb-clients again..."
        if ! DEBIAN_FRONTEND='noninteractive' apt-get -y --allow-downgrades "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install mongodb-server mongodb-clients &>> "${eus_dir}/logs/mongodb-server-client-install.log"; then
          if [[ "${architecture}" == "armhf" ]]; then
            mongodb_installation_armhf
          else
            echo -e "${RED}#${RESET} Failed to install mongodb-server and mongodb-clients... Consider switching to a 64-bit platform and re-run the scripts...\\n"
            abort
          fi
        else
          echo -e "${GREEN}#${RESET} Successfully installed mongodb-server and mongodb-clients! \\n"
        fi
      fi
    else
      echo -e "${GREEN}#${RESET} Successfully installed mongodb-server and mongodb-clients! \\n"
    fi
  fi
  get_distro
  get_repo_url
}

mongodb_installation_armhf() {
  aptkey_depreciated
  if [[ "${apt_key_deprecated}" == 'true' ]]; then
    if wget -qO - "${raspbian_repo_url}.public.key" | gpg --dearmor | tee -a "/etc/apt/keyrings/raspbian.gpg" &> /dev/null; then echo -e "${GREEN}#${RESET} Successfully added key for the raspbian repository! \\n"; signed_by_value_raspbian="[ signed-by=/etc/apt/keyrings/raspbian.gpg ] "; else echo -e "${RED}#${RESET} Failed to add the key for the raspbian repository...\\n"; abort; fi
  else
    if wget -qO - "${raspbian_repo_url}.public.key" | apt-key add - &> /dev/null; then echo -e "${GREEN}#${RESET} Successfully added key for the raspbian repository! \\n"; else echo -e "${RED}#${RESET} Failed to add the key for the raspbian repository...\\n"; abort; fi
  fi
  if [[ -f "/etc/apt/sources.list.d/glennr_armhf.list" ]]; then rm --force "/etc/apt/sources.list.d/glennr_armhf.list"; fi
  echo "deb ${signed_by_value_raspbian}${raspbian_repo_url} ${os_codename} main contrib non-free rpi" &> /etc/apt/sources.list.d/glennr-install-script.list
  hide_apt_update="true"
  run_apt_get_update
  if DEBIAN_FRONTEND='noninteractive' apt-get -y --allow-downgrades "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install mongodb-server mongodb-clients &>> "${eus_dir}/logs/mongodb-armhf-install.log"; then
    echo -e "${GREEN}#${RESET} Successfully installed mongodb-server and mongodb-clients! \\n"
  else
    echo -e "${RED}#${RESET} Failed to install mongodb-server and mongodb-clients in the first run... \\n${RED}#${RESET} Trying to save the installation...\\n"
    echo -e "${WHITE_R}#${RESET} Running \"apt-get install -f\"..."
    if apt-get install -f &>> "${eus_dir}/logs/mongodb-armhf-install.log"; then
      echo -e "${GREEN}#${RESET} Successfully ran \"apt-get install -f\"! \\n"
      echo -e "${WHITE_R}#${RESET} Trying to install mongodb-server and mongodb-clients again..."
      if DEBIAN_FRONTEND='noninteractive' apt-get -y --allow-downgrades "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install mongodb-server mongodb-clients &>> "${eus_dir}/logs/mongodb-armhf-install.log"; then
        echo -e "${GREEN}#${RESET} Successfully installed mongodb-server and mongodb-clients! \\n"
      else
        echo -e "${RED}#${RESET} Failed to install mongodb-server and mongodb-clients... Consider switching to a 64-bit platform and re-run the scripts...\\n"
        abort
      fi
    else
      echo -e "${RED}#${RESET} Failed to run \"apt-get install -f\"! \\n"; abort
    fi
  fi
  sleep 3
}

header
echo -e "${WHITE_R}#${RESET} Preparing for MongoDB installation..."
sleep 2
if [[ "${mongodb_installed}" != 'true' ]]; then
  # Remove all current MongoDB Repository Entries
  echo -e "\\n${WHITE_R}#${RESET} Checking for MongoDB repository entries..."
  if grep -qriIl "mongo" /etc/apt/sources.list*; then
    echo -ne "${YELLOW}#${RESET} Removing repository entries for MongoDB..." && sleep 1
    sed -i '/mongodb/d' /etc/apt/sources.list
    if ls /etc/apt/sources.list.d/mongodb* > /dev/null 2>&1; then
      rm /etc/apt/sources.list.d/mongodb*  2> /dev/null
    fi
    echo -e "\\r${GREEN}#${RESET} Successfully removed all MongoDB repository entries! \\n"
  else
    echo -e "\\r${YELLOW}#${RESET} There were no MongoDB Repository entries! \\n"
  fi
  if [[ "${broken_unifi_install}" == 'true' ]]; then
    previous_mongodb_version="$(grep -sEio "db version v[0-9].[0-9].[0-9]{1,2}" /usr/lib/unifi/logs/mongod.log | tail -n1 | sed 's/db version v//g' | sed 's/\.//g')"
    if [[ -n "${previous_mongodb_version}" ]]; then
      unset add_mongodb_32_repo
      unset add_mongodb_34_repo
      unset add_mongodb_36_repo
      unset add_mongodb_40_repo
      unset add_mongodb_42_repo
      unset add_mongodb_44_repo
      unset add_mongodb_50_repo
      unset add_mongodb_60_repo
      unset add_mongodb_70_repo
      unset install_mongodb_version
      unset install_mongodb_version_with_equality_sign
      unset arm64_mongodb_version
      if [[ "${previous_mongodb_version::2}" == '26' ]]; then
        broken_unifi_install_mongodb_server_clients="true"
        mongodb_server_clients_installation
      elif [[ "${previous_mongodb_version::2}" =~ (30|32) ]]; then
        add_mongodb_32_repo="true"
        mongo_version_not_supported="4.0"
        mongo_version_max="32"
        mongo_version_max_with_dot="3.2"
      elif [[ "${previous_mongodb_version::2}" == '34' ]]; then
        add_mongodb_34_repo="true"
        mongo_version_not_supported="4.0"
        mongo_version_max="34"
        mongo_version_max_with_dot="3.4"
      elif [[ "${previous_mongodb_version::2}" == '36' ]]; then
        add_mongodb_36_repo="true"
        mongo_version_not_supported="4.0"
        mongo_version_max="36"
        mongo_version_max_with_dot="3.6"
      elif [[ "${previous_mongodb_version::2}" == '40' ]]; then
        add_mongodb_40_repo="true"
        mongo_version_not_supported="4.5"
        mongo_version_max="40"
        mongo_version_max_with_dot="4.0"
      elif [[ "${previous_mongodb_version::2}" == '42' ]]; then
        add_mongodb_42_repo="true"
        mongo_version_not_supported="4.5"
        mongo_version_max="42"
        mongo_version_max_with_dot="4.2"
      elif [[ "${previous_mongodb_version::2}" == '44' ]]; then
        add_mongodb_44_repo="true"
        mongo_version_not_supported="4.5"
        mongo_version_max="44"
        mongo_version_max_with_dot="4.4"
      elif [[ "${previous_mongodb_version::2}" == '50' ]]; then
        add_mongodb_50_repo="true"
        mongo_version_not_supported="5.1"
        mongo_version_max="50"
        mongo_version_max_with_dot="5.0"
      elif [[ "${previous_mongodb_version::2}" == '60' ]]; then
        add_mongodb_60_repo="true"
        mongo_version_not_supported="6.1"
        mongo_version_max="60"
        mongo_version_max_with_dot="6.0"
      elif [[ "${previous_mongodb_version::2}" == '70' ]]; then
        add_mongodb_70_repo="true"
        mongo_version_not_supported="7.1"
        mongo_version_max="70"
        mongo_version_max_with_dot="7.0"
      fi
    fi
  fi
  #
  if [[ "${broken_unifi_install_mongodb_server_clients}" != 'true' ]]; then
    if [[ "${os_codename}" =~ (trusty|qiana|rebecca|rafaela|rosa|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|sarah|serena|sonya|sylvia|tara|tessa|tina|tricia) ]]; then
      if [[ "${architecture}" =~ (amd64|arm64) ]]; then
	    if [[ "${os_codename}" =~ (precise|maya) && "${broken_unifi_install}" != 'true' ]]; then add_mongodb_34_repo="true"; fi
        add_mongodb_repo
        mongodb_installation
      elif [[ ! "${architecture}" =~ (amd64|arm64) ]]; then
        mongodb_server_clients_installation
      fi
    elif [[ "${os_codename}" =~ (jessie|stretch|continuum|buster|bullseye|bookworm|trixie|forky) ]]; then
      if [[ "${architecture}" =~ (amd64|arm64) ]]; then
        add_mongodb_repo
        mongodb_installation
      elif [[ ! "${architecture}" =~ (amd64|arm64) ]]; then
        mongodb_server_clients_installation
      fi
    else
      header_red
      echo -e "${RED}#${RESET} The script is unable to grab your OS ( or does not support it )"
      echo "${architecture}"
      echo "${os_codename}"
    fi
  else
    echo -e "${GREEN}#${RESET} MongoDB is already installed! \\n"
  fi
fi
sleep 3

if [[ "${arm64_mongodb_version}" == '4.4.18' ]]; then
  if dpkg -l mongodb-org-server 2> /dev/null | awk '{print $1}' | grep -iq "^ii\\|^hi"; then
    mongodb_org_version="$(dpkg-query --showformat='${Version}' --show mongodb-org-server | sed 's/.*://' | sed 's/-.*//g')"
    mongodb_org_version_no_dots="${mongodb_org_version//./}"
    if [[ "${mongodb_org_version_no_dots::2}" == '44' && "$(echo "${mongodb_org_version}" | cut -d'.' -f3)" -gt "18" ]]; then
      header
      echo -e "${WHITE_R}#${RESET} Downgrading MongoDB version ${mongodb_org_version} to ${arm64_mongodb_version}..."
      dpkg -l | grep "mongodb-org" | grep "^ii\\|^hi" | awk '{print $2}' &> /tmp/EUS/mongodb/packages_list
      add_mongodb_44_repo="true"
      unset mongodb_expire_attempt
      unset trusted_mongodb_repo
      add_mongodb_repo
      while read -r mongodb_package; do
        echo -e "${WHITE_R}#${RESET} Downgrading ${mongodb_package}..."
        if DEBIAN_FRONTEND='noninteractive' apt-get -y --allow-downgrades "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${mongodb_package}${install_mongodb_version_with_equality_sign}" &>> "${eus_dir}/logs/arm64-mongodb-downgrade.log"; then
          echo -e "${GREEN}#${RESET} Successfully downgraded ${mongodb_package} to version ${install_mongodb_version}! \\n"
        else
          echo -e "${RED}#${RESET} Failed to downgrade ${mongodb_package} to version ${install_mongodb_version}...\\n"
          abort
        fi
        echo -e "${WHITE_R}#${RESET} Preventing ${mongodb_package} from upgrading..."
        if echo "${mongodb_package} hold" | dpkg --set-selections; then
          echo -e "${GREEN}#${RESET} Successfully prevented ${mongodb_package} from upgrading! \\n"
        else
          echo -e "${RED}#${RESET} Failed to prevent ${mongodb_package} from upgrading...\\n"
        fi
      done < /tmp/EUS/mongodb/packages_list
      rm --force /tmp/EUS/mongodb/packages_list &> /dev/null
      unset add_mongodb_44_repo
    fi
  fi
fi

# Check if MongoDB is newer than 2.6 (3.6 for 7.5.x) for UniFi Network application 7.4.x
if [[ "${first_digit_unifi}" -gt '7' ]] || [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" -ge '4' ]] || [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" -ge '5' ]]; then
  if [[ "${first_digit_unifi}" -gt '7' ]] || [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" -ge '5' ]]; then minimum_required_mongodb_version_dot="3.6"; minimum_required_mongodb_version="36"; unifi_latest_supported_version_number="7.4"; fi
  if [[ "${first_digit_unifi}" == '7' && "${second_digit_unifi}" == '4' ]]; then minimum_required_mongodb_version_dot="2.6"; minimum_required_mongodb_version="26"; unifi_latest_supported_version_number="7.3"; fi
  mongodb_server_version="$(dpkg -l | grep "^ii\\|^hi" | grep "mongodb-server \\|mongodb-org-server " | awk '{print $3}' | sed 's/\.//g' | sed 's/.*://' | sed 's/-.*//g')"
  if [[ -z "${mongodb_server_version}" ]]; then
    if [[ -n "$(command -v mongod)" ]]; then
      if "${mongocommand}" --port 27117 --eval "print(\"waited for connection\")" &> /dev/null; then
        mongodb_server_version="$("$(which mongod)" --quiet --eval "db.version()" | sed 's/\.//g' | sed 's/.*://' | sed 's/-.*//g')"
      else
        mongodb_server_version="$("$(which mongod)" --version --quiet | tr '[:upper:]' '[:lower:]' | sed -e '/db version/d' -e '/mongodb shell/d' -e 's/build info: //g' | jq -r '.version' | sed 's/\.//g')"
      fi
    fi
  fi
  if [[ "${mongodb_server_version::2}" -lt "${minimum_required_mongodb_version}" ]]; then
    header_red
    unifi_latest_supported_version=$(curl -s "https://get.glennr.nl/unifi/latest-versions/${unifi_latest_supported_version_number}/latest.version")
    echo -e "${WHITE_R}#${RESET} UniFi Network Application ${first_digit_unifi}.${second_digit_unifi}.${third_digit_unifi} requires MongoDB ${minimum_required_mongodb_version_dot} or newer."
    echo -e "${WHITE_R}#${RESET} The latest version that you can run with MongoDB version $(dpkg -l | grep "^ii\\|^hi" | grep "mongodb-server\\|mongodb-org-server\\|mongod-armv8" | awk '{print $3}' | sed 's/.*://') is ${unifi_latest_supported_version} and older.. \\n\\n"
    echo -e "${WHITE_R}#${RESET} Upgrade to MongoDB ${minimum_required_mongodb_version_dot} or newer, or perform a fresh install with the latest OS."
    echo -e "${WHITE_R}#${RESET} Installation Script   | https://community.ui.com/questions/ccbc7530-dd61-40a7-82ec-22b17f027776\\n\\n"
    if [[ "$(getconf LONG_BIT)" == '32' ]]; then
      echo -e "${WHITE_R}#${RESET} You're using a 32-bit OS.. please switch over to a 64-bit OS.\\n\\n"
    fi
    author
    exit 0
  fi
fi

adoptium_java() {
  if [[ "${os_codename}" =~ (trixie|forky) ]]; then
    if ! curl -s "https://packages.adoptium.net/artifactory/deb/dists/" | sed -e 's/<[^>]*>//g' -e '/^$/d' -e '/\/\//d' -e '/function/d' -e '/location/d' -e '/}/d' -e 's/\///g' -e '/Name/d' -e '/Index/d' -e '/\.\./d' -e '/Artifactory/d' | awk '{print $1}' | grep -iq "${os_codename}"; then
      os_codename="bookworm"
      adoptium_adjusted_os_codename="true"
    fi
  fi
  if curl -s "https://packages.adoptium.net/artifactory/deb/dists/" | sed -e 's/<[^>]*>//g' -e '/^$/d' -e '/\/\//d' -e '/function/d' -e '/location/d' -e '/}/d' -e 's/\///g' -e '/Name/d' -e '/Index/d' -e '/\.\./d' -e '/Artifactory/d' | awk '{print $1}' | grep -iq "${os_codename}"; then
    echo -e "${WHITE_R}#${RESET} Adding the key for adoptium packages..."
    aptkey_depreciated
    if [[ "${apt_key_deprecated}" == 'true' ]]; then
      if wget -qO - "https://packages.adoptium.net/artifactory/api/gpg/key/public" | gpg --dearmor | tee -a "/etc/apt/keyrings/packages-adoptium.gpg" &> /dev/null; then echo -e "${GREEN}#${RESET} Successfully added the key for adoptium packages! \\n"; signed_by_value_adoptium="[ signed-by=/etc/apt/keyrings/packages-adoptium.gpg ] "; else echo -e "${RED}#${RESET} Failed to add the key for adoptium packages...\\n"; abort; fi
    else
      if wget -qO - "https://packages.adoptium.net/artifactory/api/gpg/key/public" | apt-key add - &> /dev/null; then echo -e "${GREEN}#${RESET} Successfully added the key for adoptium packages! \\n"; else echo -e "${RED}#${RESET} Failed to add the key for adoptium packages...\\n"; abort; fi
    fi
    echo -e "${WHITE_R}#${RESET} Adding the adoptium packages repository..."
    if echo "deb ${signed_by_value_adoptium}https://packages.adoptium.net/artifactory/deb ${os_codename} main" &> /etc/apt/sources.list.d/glennr-packages-adoptium.list; then
      echo -e "${GREEN}#${RESET} Successfully added the adoptium packages repository!\\n" && sleep 2
      added_adoptium="true"
    else
      echo -e "${RED}#${RESET} Failed to add the adoptium packages repository..."
      abort
    fi
    if [[ "${os_codename}" =~ (jessie|stretch) ]]; then
      repo_codename="buster"
      repo_arguments=" main"
      get_repo_url
      add_repositories
      get_distro
    fi
    repo_arguments=" main"
    get_repo_url
    add_repositories
    hide_apt_update="true"
    run_apt_get_update
  else
    echo -e "${RED}#${RESET} \"${os_codename}\" could not be found on adoptium packages Artifactory..."
    {
    echo -e "# Could not find \"${os_codename}\" on https://packages.adoptium.net/artifactory/deb/dists/"
    echo -e "# List of what was found:"
    curl -s "https://packages.adoptium.net/artifactory/deb/dists/" | sed -e 's/<[^>]*>//g' -e '/^$/d' -e '/\/\//d' -e '/function/d' -e '/location/d' -e '/}/d' -e 's/\///g' -e '/Name/d' -e '/Index/d' -e '/\.\./d' -e '/Artifactory/d' | awk '{print $1}'
    } &>> "${eus_dir}/logs/adoptium.log"
  fi
  if [[ "${adoptium_adjusted_os_codename}" == 'true' ]]; then get_distro; fi
}

openjdk_version=$(dpkg -l | grep "^ii\\|^hi" | grep "openjdk-8" | awk '{print $3}' | grep "^8u" | sed 's/-.*//g' | sed 's/8u//g' | grep -o '[[:digit:]]*' | sort -V | tail -n 1)
if dpkg -l | grep "^ii\\|^hi" | grep -iq "openjdk-8"; then
  if [[ "${openjdk_version}" -lt '131' && "${required_java_version}" == "openjdk-8" ]]; then
    old_openjdk_version="true"
  fi
fi
if dpkg -l | grep "^ii\\|^hi" | grep -iq "temurin-${required_java_version_short}-jdk"; then
  if ! dpkg -l | grep "^ii\\|^hi" | grep -iq "temurin-${required_java_version_short}-jre"; then
    if apt-cache search --names-only "^temurin-17-jre" | grep -ioq "temurin-17-jre"; then
      temurin_jdk_to_jre="true"
    fi
  fi
fi
if ! dpkg -l | grep "^ii\\|^hi" | grep -iq "${required_java_version}\\|temurin-${required_java_version_short}" || [[ "${old_openjdk_version}" == 'true' ]] || [[ "${temurin_jdk_to_jre}" == 'true' ]]; then
  if [[ "${old_openjdk_version}" == 'true' ]]; then
    header_red
    echo -e "${RED}#${RESET} OpenJDK ${required_java_version_short} is to old...\\n" && sleep 2
    openjdk_variable="Updating"
    openjdk_variable_2="Updated"
    openjdk_variable_3="Update"
  else
    header
    echo -e "${GREEN}#${RESET} Preparing OpenJDK ${required_java_version_short} installation...\\n" && sleep 2
    openjdk_variable="Installing"
    openjdk_variable_2="Installed"
    openjdk_variable_3="Install"
  fi
  sleep 2
  if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic) ]]; then
    echo -e "${WHITE_R}#${RESET} ${openjdk_variable} ${required_java_version}-jre-headless..."
    if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${required_java_version}-jre-headless" &>> "${eus_dir}/logs/apt.log" || [[ "${old_openjdk_version}" == 'true' ]]; then
      echo -e "${RED}#${RESET} Failed to ${openjdk_variable_3} ${required_java_version}-jre-headless in the first run...\\n"
      repo_url="http://ppa.launchpad.net/openjdk-r/ppa/ubuntu"
      repo_arguments=" main"
      repo_key="EB9B1D8886F44E2A"
      repo_key_name="openjdk-ppa"
      add_repositories
      get_distro
      get_repo_url
      required_package="${required_java_version}-jre-headless"
      apt_get_install_package
    else
      echo -e "${GREEN}#${RESET} Successfully ${openjdk_variable_2} ${required_java_version}-jre-headless! \\n" && sleep 2
    fi
  elif [[ "${repo_codename}" =~ (disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
    echo -e "${WHITE_R}#${RESET} ${openjdk_variable} ${required_java_version}-jre-headless..."
    if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${required_java_version}-jre-headless" &>> "${eus_dir}/logs/apt.log" || [[ "${old_openjdk_version}" == 'true' ]]; then
      echo -e "${RED}#${RESET} Failed to ${openjdk_variable_3} ${required_java_version}-jre-headless in the first run...\\n"
      repo_url="http://security.ubuntu.com/ubuntu"
      repo_arguments="-security main universe"
      add_repositories
      get_distro
      get_repo_url
      required_package="${required_java_version}-jre-headless"
      apt_get_install_package
    else
      echo -e "${GREEN}#${RESET} Successfully ${openjdk_variable_2} ${required_java_version}-jre-headless! \\n" && sleep 2
    fi
  elif [[ "${os_codename}" == "jessie" ]]; then
    echo -e "${WHITE_R}#${RESET} ${openjdk_variable} ${required_java_version}-jre-headless..."
    if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install -t jessie-backports "${required_java_version}-jre-headless" &>> "${eus_dir}/logs/apt.log" || [[ "${old_openjdk_version}" == 'true' ]]; then
      echo -e "${RED}#${RESET} Failed to ${openjdk_variable_3} ${required_java_version}-jre-headless in the first run...\\n"
      if [[ $(find /etc/apt/ -name "*.list" -type f -print0 | xargs -0 cat | grep -P -c "^deb http[s]*://archive.debian.org/debian jessie-backports main") -eq 0 ]]; then
        echo "deb http://archive.debian.org/debian jessie-backports main" >>/etc/apt/sources.list.d/glennr-install-script.list || abort
        http_proxy=$(env | grep -i "http.*Proxy" | cut -d'=' -f2 | sed 's/[";]//g')
        if [[ -n "$http_proxy" ]]; then
          apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="${http_proxy}" --recv-keys 8B48AD6246925553 7638D0442B90D010 || abort
        elif [[ -f /etc/apt/apt.conf ]]; then
          apt_http_proxy=$(grep "http.*Proxy" /etc/apt/apt.conf | awk '{print $2}' | sed 's/[";]//g')
          if [[ -n "${apt_http_proxy}" ]]; then
            apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy="${apt_http_proxy}" --recv-keys 8B48AD6246925553 7638D0442B90D010 || abort
          fi
        else
          apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 8B48AD6246925553 7638D0442B90D010 || abort
        fi
        echo -e "${WHITE_R}#${RESET} Running apt-get update..."
        required_package="${required_java_version}-jre-headless"
        if apt-get update -o Acquire::Check-Valid-Until="false" &> /dev/null; then echo -e "${GREEN}#${RESET} Successfully ran apt-get update! \\n"; else echo -e "${RED}#${RESET} Failed to ran apt-get update! \\n"; abort; fi
        echo -e "\\n------- ${required_package} installation ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/apt.log"
        if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install -t jessie-backports "${required_java_version}-jre-headless" &>> "${eus_dir}/logs/apt.log"; then echo -e "${GREEN}#${RESET} Successfully installed ${required_package}! \\n" && sleep 2; else echo -e "${RED}#${RESET} Failed to install ${required_package}! \\n"; abort; fi
        sed -i '/jessie-backports/d' /etc/apt/sources.list.d/glennr-install-script.list
        unset required_package
      fi
    fi
  elif [[ "${os_codename}" =~ (stretch|continuum) ]]; then
    echo -e "${WHITE_R}#${RESET} ${openjdk_variable} ${required_java_version}-jre-headless..."
    if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${required_java_version}-jre-headless" &>> "${eus_dir}/logs/apt.log" || [[ "${old_openjdk_version}" == 'true' ]]; then
      echo -e "${RED}#${RESET} Failed to ${openjdk_variable_3} ${required_java_version}-jre-headless in the first run...\\n"
      repo_url="http://ppa.launchpad.net/openjdk-r/ppa/ubuntu"
      repo_codename="xenial"
      repo_arguments=" main"
      repo_key="EB9B1D8886F44E2A"
      repo_key_name="openjdk-ppa"
      add_repositories
      get_distro
      get_repo_url
      required_package="${required_java_version}-jre-headless"
      apt_get_install_package
    else
      echo -e "${GREEN}#${RESET} Successfully ${openjdk_variable_2} ${required_java_version}-jre-headless! \\n" && sleep 2
    fi
  elif [[ "${repo_codename}" =~ (buster|bullseye|bookworm|trixie|forky) ]]; then
    echo -e "${WHITE_R}#${RESET} ${openjdk_variable} ${required_java_version}-jre-headless..."
    if ! DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install "${required_java_version}-jre-headless" &>> "${eus_dir}/logs/apt.log" || [[ "${old_openjdk_version}" == 'true' ]]; then
      echo -e "${RED}#${RESET} Failed to ${openjdk_variable_3} ${required_java_version}-jre-headless in the first run...\\n"
      if [[ "${required_java_version}" == "openjdk-8" ]]; then
        repo_codename="stretch"
        repo_arguments=" main"
        get_repo_url
        add_repositories
        get_distro
      elif [[ "${required_java_version}" =~ (openjdk-11|openjdk-17) ]]; then
        if [[ "${repo_codename}" =~ (bookworm|trixie|forky) ]] && [[ "${required_java_version}" =~ (openjdk-11) ]]; then repo_codename="unstable"; fi
        if [[ "${repo_codename}" =~ (trixie|forky) ]] && [[ "${required_java_version}" =~ (openjdk-17) ]]; then repo_codename="bookworm"; fi
        repo_arguments=" main"
        get_repo_url
        add_repositories
        get_distro
      fi
      required_package="${required_java_version}-jre-headless"
      apt_get_install_package
    else
      echo -e "${GREEN}#${RESET} Successfully ${openjdk_variable_2} ${required_java_version}-jre-headless! \\n" && sleep 2
    fi
  else
    header_red
    echo -e "${RED}Please manually install JAVA ${required_java_version_short} on your system!${RESET}\\n"
    echo -e "${RED}OS Details:${RESET}\\n"
    echo -e "${RED}$(lsb_release -a)${RESET}\\n"
    exit 0
  fi
else
  header
  echo -e "${GREEN}#${RESET} Preparing OpenJDK ${required_java_version_short} installation..."
  echo -e "${WHITE_R}#${RESET} OpenJDK ${required_java_version_short} is already installed! \\n"
fi
sleep 3

if dpkg -l | grep "^ii\\|^hi" | grep -iq "openjdk-${required_java_version_short}"; then
  required_java_version_installed="true"
fi
if dpkg -l | grep "^ii\\|^hi" | grep -i "openjdk-.*-\\|oracle-java.*" | grep -vq "openjdk-8\\|oracle-java8\\|openjdk-11\\|openjdk-17"; then
  unsupported_java_version_installed="true"
fi

if [[ "${required_java_version_installed}" == 'true' && "${unsupported_java_version_installed}" == 'true' && "${script_option_skip}" != 'true' && "${unifi_core_system}" != 'true' ]]; then
  header_red
  echo -e "${WHITE_R}#${RESET} Unsupported JAVA version(s) are detected, do you want to uninstall them?"
  echo -e "${WHITE_R}#${RESET} This may remove packages that depend on these java versions."
  read -rp $'\033[39m#\033[0m Do you want to proceed with uninstalling the unsupported JAVA version(s)? (y/N) ' yes_no
  case "$yes_no" in
       [Yy]*)
          rm --force /tmp/EUS/java/* &> /dev/null
          mkdir -p /tmp/EUS/java/ &> /dev/null
          mkdir -p "${eus_dir}/logs/" &> /dev/null
          header
          echo -e "${WHITE_R}#${RESET} Uninstalling unsupported JAVA versions..."
          echo -e "\\n${WHITE_R}----${RESET}\\n"
          sleep 3
          dpkg -l | grep "^ii\\|^hi" | awk '/openjdk-.*/{print $2}' | cut -d':' -f1 | grep -v "openjdk-8\\|openjdk-11" &>> /tmp/EUS/java/unsupported_java_list_tmp
          dpkg -l | grep "^ii\\|^hi" | awk '/oracle-java.*/{print $2}' | cut -d':' -f1 | grep -v "oracle-java8" &>> /tmp/EUS/java/unsupported_java_list_tmp
          awk '!a[$0]++' /tmp/EUS/java/unsupported_java_list_tmp >> /tmp/EUS/java/unsupported_java_list; rm --force /tmp/EUS/java/unsupported_java_list_tmp 2> /dev/null
          echo -e "\\n------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/java_uninstall.log"
          while read -r package; do
            apt-get remove "${package}" -y &>> "${eus_dir}/logs/java_uninstall.log" && echo -e "${WHITE_R}#${RESET} Successfully removed ${package}." || echo -e "${WHITE_R}#${RESET} Failed to remove ${package}."
          done < /tmp/EUS/java/unsupported_java_list
          rm --force /tmp/EUS/java/unsupported_java_list &> /dev/null
          echo -e "\\n" && sleep 3;;
       [Nn]*|"") ;;
  esac
fi

update_ca_certificates() {
  if [[ "${update_ca_certificates_ran}" != 'true' ]]; then
    echo -e "${WHITE_R}#${RESET} Updating the ca-certificates..."
    rm /etc/ssl/certs/java/cacerts 2> /dev/null
    if update-ca-certificates -f &> /dev/null; then
      echo -e "${GREEN}#${RESET} Successfully updated the ca-certificates\\n" && sleep 3
      /usr/bin/printf '\xfe\xed\xfe\xed\x00\x00\x00\x02\x00\x00\x00\x00\xe2\x68\x6e\x45\xfb\x43\xdf\xa4\xd9\x92\xdd\x41\xce\xb6\xb2\x1c\x63\x30\xd7\x92' > /etc/ssl/certs/java/cacerts
      /var/lib/dpkg/info/ca-certificates-java.postinst configure &> /dev/null
      update_ca_certificates_ran="true"
    else
      echo -e "${RED}#${RESET} Failed to update the ca-certificates...\\n" && sleep 3
    fi
  fi
}

if dpkg -l | grep "^ii\\|^hi" | grep -iq "openjdk-${required_java_version_short}\\|temurin-${required_java_version_short}"; then
  update_java_alternatives=$(update-java-alternatives --list | grep "^java-1.${required_java_version_short}.*openjdk\\|temurin-${required_java_version_short}" | awk '{print $1}' | head -n1)
  if [[ -n "${update_java_alternatives}" ]]; then
    update-java-alternatives --set "${update_java_alternatives}" &> /dev/null
  fi
  update_alternatives=$(update-alternatives --list java | grep "java-${required_java_version_short}-openjdk\\|temurin-${required_java_version_short}" | awk '{print $1}' | head -n1)
  if [[ -n "${update_alternatives}" ]]; then
    update-alternatives --set java "${update_alternatives}" &> /dev/null
  fi
  header
  update_ca_certificates
fi

if dpkg -l | grep "^ii\\|^hi" | grep -iq "openjdk-${required_java_version_short}\\|temurin-${required_java_version_short}"; then
  java_home_readlink="JAVA_HOME=$( readlink -f "$( command -v java )" | sed "s:bin/.*$::" )"
  current_java_home=$(grep -si "^JAVA_HOME" /etc/default/unifi)
  if [[ -n "${java_home_readlink}" ]]; then
    if [[ "${current_java_home}" != "${java_home_readlink}" ]]; then
      if [[ -e "/etc/default/unifi" ]]; then sed -i '/JAVA_HOME/d' /etc/default/unifi; fi
      echo "${java_home_readlink}" >> /etc/default/unifi
    fi
  fi
  current_java_home=$(grep -si "^JAVA_HOME" /etc/environment)
  if [[ -n "${java_home_readlink}" ]]; then
    if [[ "${current_java_home}" != "${java_home_readlink}" ]]; then
      if [[ -e "/etc/default/unifi" ]]; then sed -i 's/^JAVA_HOME/#JAVA_HOME/' /etc/environment; fi
      echo "${java_home_readlink}" >> /etc/environment
      # shellcheck disable=SC1091
      source /etc/environment
    fi
  fi
fi

header
echo -e "${WHITE_R}#${RESET} Preparing installation of the UniFi Network Application dependencies...\\n"
sleep 2
echo -e "\\n------- dependency installation ------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/apt.log"
if [[ "${os_codename}" =~ (precise|maya|trusty|qiana|rebecca|rafaela|rosa|xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|stretch|continuum|buster|bullseye|bookworm|trixie|forky) ]]; then
  echo -e "${WHITE_R}#${RESET} Installing binutils, ca-certificates-java and java-common..."
  if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install binutils ca-certificates-java java-common &>> "${eus_dir}/logs/apt.log"; then echo -e "${GREEN}#${RESET} Successfully installed binutils, ca-certificates-java and java-common! \\n"; else echo -e "${RED}#${RESET} Failed to install binutils, ca-certificates-java and java-common in the first run...\\n"; unifi_dependencies=fail; fi
  if [[ "${required_java_version}" == "openjdk-8" ]]; then
    echo -e "${WHITE_R}#${RESET} Installing jsvc and libcommons-daemon-java..."
    if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install jsvc libcommons-daemon-java &>> "${eus_dir}/logs/apt.log"; then echo -e "${GREEN}#${RESET} Successfully installed jsvc and libcommons-daemon-java! \\n"; else echo -e "${RED}#${RESET} Failed to install jsvc and libcommons-daemon-java in the first run...\\n"; unifi_dependencies=fail; fi
  fi
elif [[ "${os_codename}" == 'jessie' ]]; then
  echo -e "${WHITE_R}#${RESET} Installing binutils, ca-certificates-java and java-common..."
  if DEBIAN_FRONTEND='noninteractive' apt-get -y --force-yes -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install binutils ca-certificates-java java-common &>> "${eus_dir}/logs/apt.log"; then echo -e "${GREEN}#${RESET} Successfully installed binutils, ca-certificates-java and java-common! \\n"; else echo -e "${RED}#${RESET} Failed to install binutils, ca-certificates-java and java-common in the first run...\\n"; unifi_dependencies=fail; fi
  if [[ "${required_java_version}" == "openjdk-8" ]]; then
    echo -e "${WHITE_R}#${RESET} Installing jsvc and libcommons-daemon-java..."
    if DEBIAN_FRONTEND='noninteractive' apt-get -y --force-yes -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install jsvc libcommons-daemon-java &>> "${eus_dir}/logs/apt.log"; then echo -e "${GREEN}#${RESET} Successfully installed jsvc and libcommons-daemon-java! \\n"; else echo -e "${RED}#${RESET} Failed to install jsvc and libcommons-daemon-java in the first run...\\n"; unifi_dependencies=fail; fi
  fi
fi
if [[ "${unifi_dependencies}" == 'fail' ]]; then
  if [[ "${repo_codename}" =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble) ]]; then
    repo_arguments=" main universe"
  elif [[ "${repo_codename}" =~ (jessie|stretch|buster|bullseye|bookworm|trixie|forky) ]]; then
    repo_arguments=" main"
  fi
  add_repositories
  hide_apt_update="true"
  run_apt_get_update
  if [[ "${os_codename}" =~ (precise|maya|trusty|qiana|rebecca|rafaela|rosa|xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|tricia|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar|mantic|noble|stretch|continuum|buster|bullseye|bookworm|trixie|forky) ]]; then
    echo -e "${WHITE_R}#${RESET} Installing binutils, ca-certificates-java and java-common..."
    if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install binutils ca-certificates-java java-common &>> "${eus_dir}/logs/apt.log"; then echo -e "${GREEN}#${RESET} Successfully installed binutils, ca-certificates-java and java-common! \\n"; else echo -e "${RED}#${RESET} Failed to install binutils, ca-certificates-java and java-common in the first run...\\n"; abort; fi
    if [[ "${required_java_version}" == "openjdk-8" ]]; then
      echo -e "${WHITE_R}#${RESET} Installing jsvc and libcommons-daemon-java..."
      if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install jsvc libcommons-daemon-java &>> "${eus_dir}/logs/apt.log"; then echo -e "${GREEN}#${RESET} Successfully installed jsvc and libcommons-daemon-java! \\n"; else echo -e "${RED}#${RESET} Failed to install jsvc and libcommons-daemon-java in the first run...\\n"; abort; fi
    fi
  elif [[ "${os_codename}" == 'jessie' ]]; then
    echo -e "${WHITE_R}#${RESET} Installing binutils, ca-certificates-java and java-common..."
    if DEBIAN_FRONTEND='noninteractive' apt-get -y --force-yes -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install binutils ca-certificates-java java-common &>> "${eus_dir}/logs/apt.log"; then echo -e "${GREEN}#${RESET} Successfully installed binutils, ca-certificates-java and java-common! \\n"; else echo -e "${RED}#${RESET} Failed to install binutils, ca-certificates-java and java-common in the first run...\\n"; abort; fi
    if [[ "${required_java_version}" == "openjdk-8" ]]; then
      echo -e "${WHITE_R}#${RESET} Installing jsvc and libcommons-daemon-java..."
      if DEBIAN_FRONTEND='noninteractive' apt-get -y --force-yes -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install jsvc libcommons-daemon-java &>> "${eus_dir}/logs/apt.log"; then echo -e "${GREEN}#${RESET} Successfully installed jsvc and libcommons-daemon-java! \\n"; else echo -e "${RED}#${RESET} Failed to install jsvc and libcommons-daemon-java in the first run...\\n"; abort; fi
    fi
  fi
fi
sleep 3

# Quick workaround for 7.2.91 and older 7.2 versions.
if [[ "${first_digit_unifi}" == "7" && "${second_digit_unifi}" == "2" && "${third_digit_unifi}" -le "91" ]]; then
  NAME="unifi"
  UNIFI_USER="${UNIFI_USER:-unifi}"
  DATADIR="${UNIFI_DATA_DIR:-/var/lib/$NAME}"
  if ! id "${UNIFI_USER}" >/dev/null 2>&1; then
    adduser --system --home "${DATADIR}" --no-create-home --group --disabled-password --quiet "${UNIFI_USER}"
  fi
  if ! [[ -d "/usr/lib/unifi/" ]]; then mkdir -p /usr/lib/unifi/ && chown -R unifi:unifi /usr/lib/unifi/; fi
  if ! [[ -d "/var/lib/unifi/" ]]; then mkdir -p /var/lib/unifi/ && chown -R unifi:unifi /var/lib/unifi/; fi
fi

header
echo -e "${WHITE_R}#${RESET} Installing your UniFi Network Application ( ${WHITE_R}${unifi_clean}${RESET} )...\\n"
sleep 2
if [[ "${unifi_network_application_downloaded}" != 'true' ]]; then
  unifi_temp="$(mktemp --tmpdir=/tmp unifi_sysvinit_all_"${unifi_clean}"_XXX.deb)"
  unifi_fwupdate="$(curl -s "https://fw-update.ui.com/api/firmware-latest?filter=eq~~version_major~~${first_digit_unifi}&filter=eq~~version_minor~~${second_digit_unifi}&filter=eq~~version_patch~~${third_digit_unifi}&filter=eq~~platform~~debian" | jq -r "._embedded.firmware[]._links.data.href" | sed '/null/d')"
  echo -e "${WHITE_R}#${RESET} Downloading the UniFi Network Application..."
  echo -e "\\n------- $(date +%F-%R) -------\\n" &>> "${eus_dir}/logs/unifi_download.log"
  if wget "${wget_progress[@]}" -O "${unifi_temp}" "https://dl.ui.com/unifi/${unifi_secret}/unifi_sysvinit_all.deb" &>> "${eus_dir}/logs/unifi_download.log"; then
    echo -e "${GREEN}#${RESET} Successfully downloaded application version ${unifi_clean}! \\n"
  elif wget "${wget_progress[@]}" -O "${unifi_temp}" "https://dl.ui.com/unifi/${unifi_clean}/unifi_sysvinit_all.deb" &>> "${eus_dir}/logs/unifi_download.log"; then
    echo -e "${GREEN}#${RESET} Successfully downloaded application version ${unifi_clean}! \\n"
  elif wget "${wget_progress[@]}" -O "${unifi_temp}" "https://dl.ui.com/unifi/debian/pool/ubiquiti/u/unifi/unifi_${unifi_repo_version}_all.deb" &>> "${eus_dir}/logs/unifi_download.log"; then
    echo -e "${GREEN}#${RESET} Successfully downloaded application version ${unifi_clean}! \\n"
  elif wget "${wget_progress[@]}" -O "${unifi_temp}" "${unifi_fwupdate}" &>> "${eus_dir}/logs/unifi_download.log"; then
    echo -e "${GREEN}#${RESET} Successfully downloaded application version ${unifi_clean}! \\n"
  else
    echo -e "${RED}#${RESET} Failed to download application version ${unifi_clean}...\\n"
    abort
  fi
else
  echo -e "${WHITE_R}#${RESET} Downloading the UniFi Network Application..."
  echo -e "${GREEN}#${RESET} UniFi Network Application version ${unifi_clean} has already been downloaded! \n"
fi
if dpkg -l | grep "^ii\\|^hi" | grep -iq "temurin-${required_java_version_short}-jdk"; then
  temurin_type="jdk"
  custom_unifi_deb_file_required="true"
elif dpkg -l | grep "^ii\\|^hi" | grep -iq "temurin-${required_java_version_short}-jre"; then
  temurin_type="jre"
  if [[ "${first_digit_unifi}" -lt '8' ]]; then
    custom_unifi_deb_file_required="true"
  elif [[ "${first_digit_unifi}" -ge '8' ]]; then
    custom_unifi_deb_file_required="false"
  fi
fi
if dpkg -l | grep "^ii\\|^hi" | grep -iq "mongod-armv8"; then
  unifi_deb_package_modification_mongodb_package="mongod-armv8"
  custom_unifi_deb_file_required="true"
  prevent_mongodb_org_server_install
fi
if [[ "${custom_unifi_deb_file_required}" == 'true' ]]; then
  if [[ -n "${unifi_deb_package_modification_mongodb_package}" && -n "${temurin_type}" ]]; then
    unifi_deb_package_modification_message_1="temurin-${required_java_version_short}-${temurin_type} and ${unifi_deb_package_modification_mongodb_package}"
  elif [[ -n "${temurin_type}" ]]; then
    unifi_deb_package_modification_message_1="temurin-${required_java_version_short}-${temurin_type}"
  elif [[ -n "${unifi_deb_package_modification_mongodb_package}" ]]; then
    unifi_deb_package_modification_message_1="${unifi_deb_package_modification_mongodb_package}"
  fi
  eus_temp_dir="$(mktemp -d --tmpdir=${eus_dir} unifi.deb.XXX)"
  echo -e "${WHITE_R}#${RESET} This setup is using ${unifi_deb_package_modification_message_1}... Editing the UniFi Network Application dependencies..."
  if dpkg-deb -x "${unifi_temp}" "${eus_temp_dir}" &>> "${eus_dir}/logs/unifi-custom-deb-file.log"; then
    if dpkg-deb --control "${unifi_temp}" "${eus_temp_dir}/DEBIAN" &>> "${eus_dir}/logs/unifi-custom-deb-file.log"; then
      if [[ -e "${eus_temp_dir}/DEBIAN/control" ]]; then
        current_state_unifi_deb="$(stat -c "%y" "${eus_temp_dir}/DEBIAN/control")"
        if [[ -n "${temurin_type}" ]]; then if sed -i "s/openjdk-${required_java_version_short}-jre-headless/temurin-${required_java_version_short}-${temurin_type}/g" "${eus_temp_dir}/DEBIAN/control" &>> "${eus_dir}/logs/unifi-custom-deb-file.log"; then unifi_deb_package_modification_control_modified_success="true"; fi; fi
        if [[ -n "${unifi_deb_package_modification_mongodb_package}" ]]; then if sed -i "s/mongodb-org-server/${unifi_deb_package_modification_mongodb_package}/g" "${eus_temp_dir}/DEBIAN/control" &>> "${eus_dir}/logs/unifi-custom-deb-file.log"; then unifi_deb_package_modification_control_modified_success="true"; fi; fi
        if [[ "${unifi_deb_package_modification_control_modified_success}" == 'true' ]]; then
          echo -e "${GREEN}#${RESET} Successfully edited the dependencies of the UniFi Network Application deb file! \\n"
          if [[ "${current_state_unifi_deb}" != "$(stat -c "%y" "${eus_temp_dir}/DEBIAN/control")" ]]; then
            unifi_new_deb="$(basename "${unifi_temp}" .deb).new.deb"
            echo -e "${WHITE_R}#${RESET} Building a new UniFi Network Application deb file... This may take a while..."
            if dpkg -b "${eus_temp_dir}" "${unifi_new_deb}" &>> "${eus_dir}/logs/unifi-custom-deb-file.log"; then
              unifi_temp="${unifi_new_deb}"
              echo -e "${GREEN}#${RESET} Successfully built a new UniFi Network Application deb file! \\n"
            else
              echo -e "${RED}#${RESET} Failed to build a new UniFi Network Application deb file...\\n"
            fi
          else
            echo -e "${RED}#${RESET} Failed to edit the dependencies of the UniFi Network Application deb file...\\n"
          fi
        else
          echo -e "${RED}#${RESET} Failed to edit the dependencies of the UniFi Network Application deb file...\\n"
        fi
      else
        echo -e "${RED}#${RESET} Failed to detect the required files to edit the dependencies of the UniFi Network Application...\\n"
      fi
    else
      echo -e "${RED}#${RESET} Failed to unpack the current UniFi Network Application deb file...\\n"
    fi
  else
    echo -e "${RED}#${RESET} Failed to edit the dependencies of the UniFi Network Application deb file...\\n"
  fi
  rm -rf "${eus_temp_dir}" &> /dev/null
fi
if [[ -f "/tmp/EUS/ignore-depends" ]]; then rm --force /tmp/EUS/ignore-depends &> /dev/null; fi
if ! dpkg -l | grep "^ii\\|^hi" | grep -iq "mongodb-server\\|mongodb-org-server\\|mongod-armv8"; then echo -e "mongodb-server" &>> /tmp/EUS/ignore-depends; fi
if [[ "${first_digit_unifi}" -lt '8' ]]; then
  if ! dpkg -l | grep "^ii\\|^hi" | grep -iq "${required_java_version}-jre-headless"; then echo -e "${required_java_version}-jre-headless" &>> /tmp/EUS/ignore-depends; fi
fi
if [[ -f /tmp/EUS/ignore-depends && -s /tmp/EUS/ignore-depends ]]; then IFS=" " read -r -a ignored_depends <<< "$(tr '\r\n' ',' < /tmp/EUS/ignore-depends | sed 's/.$//')"; rm --force /tmp/EUS/ignore-depends &> /dev/null; dpkg_ignore_depends_flag="--ignore-depends=${ignored_depends[*]}"; fi

check_service_overrides
echo -e "${WHITE_R}#${RESET} Installing the UniFi Network Application..."
echo "unifi unifi/has_backup boolean true" 2> /dev/null | debconf-set-selections
# shellcheck disable=SC2086
if DEBIAN_FRONTEND=noninteractive dpkg -i ${dpkg_ignore_depends_flag} "${unifi_temp}" &>> "${eus_dir}/logs/unifi_install.log"; then
  echo -e "${GREEN}#${RESET} Successfully installed the UniFi Network Application! \\n"
else
  echo -e "${RED}#${RESET} Failed to install the UniFi Network Application...\\n"
  abort
fi
rm --force "${unifi_temp}" 2> /dev/null
systemctl start unifi || abort
sleep 3

dash_port=$(grep -si "unifi.https.port" /usr/lib/unifi/data/system.properties 2> /dev/null | cut -d'=' -f2 | tail -n1)
info_port=$(grep -si "unifi.http.port" /usr/lib/unifi/data/system.properties 2> /dev/null | cut -d'=' -f2 | tail -n1)
if [[ -z "${dash_port}" ]]; then dash_port="8443"; fi
if [[ -z "${info_port}" ]]; then info_port="8080"; fi

if [[ "${change_unifi_ports}" == 'true' ]]; then
  if [[ -f /usr/lib/unifi/data/system.properties && -s /usr/lib/unifi/data/system.properties ]]; then
    header
    echo -e "${WHITE_R}#${RESET} system.properties file got created!"
    echo -e "${WHITE_R}#${RESET} Stopping the UniFi Network Application.."
    systemctl stop unifi && echo -e "${GREEN}#${RESET} Successfully stopped the UniFi Network Application!" || echo -e "${RED}#${RESET} Failed to stop the UniFi Network Application."
    sleep 2
    change_default_ports
  else
    while sleep 3; do
      if [[ -f /usr/lib/unifi/data/system.properties && -s /usr/lib/unifi/data/system.properties ]]; then
        echo -e "${WHITE_R}#${RESET} system.properties got created!"
        echo -e "${WHITE_R}#${RESET} Stopping the UniFi Network Application.."
        systemctl stop unifi && echo -e "${GREEN}#${RESET} Successfully stopped the UniFi Network Application!" || echo -e "${RED}#${RESET} Failed to stop the UniFi Network Application."
        sleep 2
        change_default_ports
        break
      else
        header_red
        echo -e "${WHITE_R}#${RESET} system.properties file is not there yet.." && sleep 2
      fi
    done
  fi
fi

# Check if service is enabled
if ! [[ "${os_codename}" =~ (precise|maya|trusty|qiana|rebecca|rafaela|rosa) ]]; then
  if systemctl list-units --full -all | grep -Fioq "unifi.service"; then
    SERVICE_UNIFI=$(systemctl is-enabled unifi)
    if [[ "$SERVICE_UNIFI" = 'disabled' ]]; then
      if ! systemctl enable unifi 2>/dev/null; then
        echo -e "${RED}#${RESET} Failed to enable service | UniFi"
        sleep 3
      fi
    fi
  fi
fi

# Check if UniFi Repo is supported.
if [[ "${architecture}" == "arm64" && "${first_digit_unifi}" -ge "8" && "${glennr_compiled_mongod}" != 'true' ]]; then
  unifi_repo_supported="true"
elif [[ "${architecture}" == "amd64" ]]; then
  unifi_repo_supported="true"
else
  unifi_repo_supported="false"
fi

if [[ "${script_option_skip}" != 'true' || "${script_option_add_repository}" == 'true' ]] && [[ "${unifi_repo_supported}" == "true" ]]; then
  header
  echo -e "${WHITE_R}#${RESET} Would you like to update the UniFi Network Application via APT?"
  if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Do you want the script to add the source list file? (Y/n) ' yes_no; fi
  case "$yes_no" in
      [Yy]*|"")
        header
        echo -e "${WHITE_R}#${RESET} Adding the UniFi Network Application repository for branch ${first_digit_unifi}.${second_digit_unifi}... \\n"
        sleep 3
        sed -i '/unifi/d' /etc/apt/sources.list
        rm --force /etc/apt/sources.list.d/100-ubnt-unifi.list 2> /dev/null
        echo -e "${WHITE_R}#${RESET} Downloading the UniFi Network Application repository key..."
        if wget -qO - "https://dl.ui.com/unifi/unifi-repo.gpg" | gpg --dearmor | tee -a "/etc/apt/keyrings/unifi-repo.gpg" &> /dev/null; then
          echo -e "${GREEN}#${RESET} Successfully downloaded the key for the UniFi Network Application repository! \\n"
          echo -e "${WHITE_R}#${RESET} Adding the UniFi Network Application repository..."
          if [[ "${architecture}" == 'arm64' ]]; then arch="arch=arm64"; elif [[ "${architecture}" == 'amd64' ]]; then arch="arch=amd64"; else arch="arch=amd64,arm64"; fi
          if echo "deb [ ${arch} signed-by=/etc/apt/keyrings/unifi-repo.gpg ] https://www.ui.com/downloads/unifi/debian unifi-${first_digit_unifi}.${second_digit_unifi} ubiquiti" &> /etc/apt/sources.list.d/100-ubnt-unifi.list; then
            echo -e "${GREEN}#${RESET} Successfully added UniFi Network Application source list! \\n"
            hide_apt_update="true"
            run_apt_get_update
            echo -ne "\\r${WHITE_R}#${RESET} Checking if the added UniFi Network Application repository is valid..." && sleep 1
            if grep -ioq "unifi-${first_digit_unifi}.${second_digit_unifi} Release' does not" /tmp/EUS/keys/apt_update; then
              echo -ne "\\r${RED}#${RESET} The added UniFi Repository is not valid/used, the repository list will be removed! \\n"
              rm -f /etc/apt/sources.list.d/100-ubnt-unifi.list &> /dev/null
            else
              echo -ne "\\r${GREEN}#${RESET} The added UniFi Network Application Repository is valid! \\n"
            fi
            sleep 3
          else
            echo -e "${RED}#${RESET} Failed to add the UniFi Network Application source list...\\n"
          fi
        else
          echo -e "${RED}#${RESET} Failed to download the key for the UniFi Network Application repository...\\n"
        fi;;
      [Nn]*) ;;
  esac
fi

if dpkg -l ufw | grep -q "^ii\\|^hi"; then
  if ufw status verbose | awk '/^Status:/{print $2}' | grep -xq "active"; then
    if [[ "${script_option_skip}" != 'true' && "${script_option_local_install}" != 'true' ]]; then
      header
      read -rp $'\033[39m#\033[0m Is/will your application only be used locally ( regarding device discovery )? (Y/n) ' yes_no
      case "${yes_no}" in
          [Yy]*|"")
              echo -e "${WHITE_R}#${RESET} Script will ensure that 10001/udp for device discovery will be added to UFW."
              script_option_local_install="true"
              sleep 3;;
          [Nn]*|*) ;;
      esac
    fi
    header
    echo -e "${WHITE_R}#${RESET} Uncomplicated Firewall ( UFW ) seems to be active."
    echo -e "${WHITE_R}#${RESET} Checking if all required ports are added!"
    rm -rf /tmp/EUS/ports/* &> /dev/null
    mkdir -p /tmp/EUS/ports/ &> /dev/null
    ssh_port=$(awk '/Port/{print $2}' /etc/ssh/sshd_config | head -n1)
    if [[ "${script_option_local_install}" == 'true' ]]; then
      unifi_ports=(3478/udp "${info_port}"/tcp "${dash_port}"/tcp 8880/tcp 8843/tcp 6789/tcp 10001/udp)
      echo -e "3478/udp\\n${info_port}/tcp\\n${dash_port}/tcp\\n8880/tcp\\n8843/tcp\\n6789/tcp\\n10001/udp" &>> /tmp/EUS/ports/all_ports
    else
      unifi_ports=(3478/udp "${info_port}"/tcp "${dash_port}"/tcp 8880/tcp 8843/tcp 6789/tcp)
      echo -e "3478/udp\\n${info_port}/tcp\\n${dash_port}/tcp\\n8880/tcp\\n8843/tcp\\n6789/tcp" &>> /tmp/EUS/ports/all_ports
    fi
    echo -e "${ssh_port}" &>> /tmp/EUS/ports/all_ports
    ufw status verbose &>> /tmp/EUS/ports/ufw_list
    while read -r port; do
      port_number_only=$(echo "${port}" | cut -d'/' -f1)
      # shellcheck disable=SC1117
      if ! grep "^${port_number_only}\b\\|^${port}\b" /tmp/EUS/ports/ufw_list | grep -iq "ALLOW IN"; then
        required_port_missing="true"
      fi
      # shellcheck disable=SC1117
      if ! grep -v "(v6)" /tmp/EUS/ports/ufw_list | grep "^${port_number_only}\b\\|^${port}\b" | grep -iq "ALLOW IN"; then
        required_port_missing="true"
      fi
    done < /tmp/EUS/ports/all_ports
    if [[ "${required_port_missing}" == 'true' ]]; then
      echo -e "\\n${WHITE_R}----${RESET}\\n\\n"
      echo -e "${WHITE_R}#${RESET} We are missing required ports.."
      if [[ "${script_option_skip}" != 'true' ]]; then
        read -rp $'\033[39m#\033[0m Do you want to add the required ports for your UniFi Network Application? (Y/n) ' yes_no
      else
        echo -e "${WHITE_R}#${RESET} Adding required UniFi ports.."
        sleep 2
      fi
      case "${yes_no}" in
         [Yy]*|"")
            echo -e "\\n${WHITE_R}----${RESET}\\n\\n"
            for port in "${unifi_ports[@]}"; do
              port_number=$(echo "${port}" | cut -d'/' -f1)
              ufw allow "${port}" &> "/tmp/EUS/ports/${port_number}"
              if [[ -f "/tmp/EUS/ports/${port_number}" && -s "/tmp/EUS/ports/${port_number}" ]]; then
                if grep -iq "added" "/tmp/EUS/ports/${port_number}"; then
                  echo -e "${GREEN}#${RESET} Successfully added port ${port} to UFW."
                fi
                if grep -iq "skipping" "/tmp/EUS/ports/${port_number}"; then
                  echo -e "${YELLOW}#${RESET} Port ${port} was already added to UFW."
                fi
              fi
            done
            if [[ -f /etc/ssh/sshd_config && -s /etc/ssh/sshd_config ]]; then
              if ! ufw status verbose | grep -v "(v6)" | grep "${ssh_port}" | grep -iq "ALLOW IN"; then
                echo -e "\\n${WHITE_R}----${RESET}\\n\\n${WHITE_R}#${RESET} Your SSH port ( ${ssh_port} ) doesn't seem to be in your UFW list.."
                if [[ "${script_option_skip}" != 'true' ]]; then
                  read -rp $'\033[39m#\033[0m Do you want to add your SSH port to the UFW list? (Y/n) ' yes_no
                else
                  echo -e "${WHITE_R}#${RESET} Adding port ${ssh_port}.."
                  sleep 2
                fi
                case "${yes_no}" in
                   [Yy]*|"")
                      echo -e "\\n${WHITE_R}----${RESET}\\n"
                      ufw allow "${ssh_port}" &> "/tmp/EUS/ports/${ssh_port}"
                      if [[ -f "/tmp/EUS/ports/${ssh_port}" && -s "/tmp/EUS/ports/${ssh_port}" ]]; then
                        if grep -iq "added" "/tmp/EUS/ports/${ssh_port}"; then
                          echo -e "${GREEN}#${RESET} Successfully added port ${ssh_port} to UFW."
                        fi
                        if grep -iq "skipping" "/tmp/EUS/ports/${ssh_port}"; then
                          echo -e "${YELLOW}#${RESET} Port ${ssh_port} was already added to UFW."
                        fi
                      fi;;
                   [Nn]*|*) ;;
                esac
              fi
            fi;;
         [Nn]*|*) ;;
      esac
    else
      echo -e "\\n${WHITE_R}----${RESET}\\n\\n${WHITE_R}#${RESET} All required ports already exist!"
    fi
    echo -e "\\n\\n" && sleep 2
  fi
fi

if [[ -z "${SERVER_IP}" ]]; then
  SERVER_IP=$(ip addr | grep -A8 -m1 MULTICAST | grep -m1 inet | cut -d' ' -f6 | cut -d'/' -f1)
fi

# Check if application is reachable via public IP.
timeout 1 nc -zv "${PUBLIC_SERVER_IP}" "${dash_port}" &> /dev/null && public_reachable="true"

# Check if application is up and running + if it respond on public IP
if [[ "${public_reachable}" == 'true' ]]; then
  check_count=0
  while [[ "${check_count}" -lt '60' ]]; do
    if [[ "${check_count}" == '3' ]]; then
      header
      echo -e "${WHITE_R}#${RESET} Checking if the UniFi Network application is responding... (this can take up to 60 seconds)"
      unifi_api_message="true"
    fi
    if [[ "$(curl -sk "https://localhost:${dash_port}/status" | jq -r '.meta.up' 2> /dev/null)" == 'true' ]]; then
      if [[ "${unifi_api_message}" == 'true' ]]; then echo -e "${GREEN}#${RESET} The application is up and running! \\n"; sleep 2; fi
      if [[ "${unifi_api_message}" == 'true' ]]; then echo -e "${WHITE_R}#${RESET} Checking if the application is also responding on it's public IP address..."; fi
      if [[ "$(curl -sk "https://${PUBLIC_SERVER_IP}:${dash_port}/status" | jq -r '.meta.up' 2> /dev/null)" == 'true' ]]; then
        if [[ "${unifi_api_message}" == 'true' ]]; then echo -e "${GREEN}#${RESET} The application is responding on it's public IP address! The script will continue with the SSL setup!"; sleep 4; fi
        public_reachable="true"
      else
        if [[ "${unifi_api_message}" == 'true' ]]; then echo -e "${GREEN}#${RESET} The application does not respond on it's public IP address... \\n"; sleep 4; fi
        public_reachable="false"
      fi
      break
    fi
    ((check_count=check_count+1))
    sleep 1
  done
fi

if [[ "${public_reachable}" == 'true' ]] && [[ "${script_option_skip}" != 'true' || "${fqdn_specified}" == 'true' ]]; then
  echo -e "--install-script" &>> /tmp/EUS/le_script_options
  if [[ -f /tmp/EUS/le_script_options && -s /tmp/EUS/le_script_options ]]; then IFS=" " read -r le_script_options <<< "$(tr '\r\n' ' ' < /tmp/EUS/le_script_options)"; fi
  header
  le_script="true"
  echo -e "${WHITE_R}#${RESET} Your application seems to be exposed to the internet. ( port 8443 is open )"
  echo -e "${WHITE_R}#${RESET} It's recommend to secure your application with a SSL certficate.\\n"
  echo -e "${WHITE_R}#${RESET} Requirements:"
  echo -e "${WHITE_R}-${RESET} A domain name and A record pointing to the server that runs the UniFi Network Application."
  echo -e "${WHITE_R}-${RESET} Port 80 needs to be open ( port forwarded )\\n\\n"
  if [[ "${script_option_skip}" != 'true' ]]; then read -rp $'\033[39m#\033[0m Do you want to download and execute my UniFi Easy Encrypt Script? (Y/n) ' yes_no; fi
  case "$yes_no" in
      [Yy]*|"")
          rm --force unifi-easy-encrypt.sh &> /dev/null
          # shellcheck disable=SC2068
          wget "${wget_progress[@]}" -q https://get.glennr.nl/unifi/extra/unifi-easy-encrypt.sh && bash unifi-easy-encrypt.sh ${le_script_options[@]};;
      [Nn]*) ;;
  esac
fi

if [[ "${netcat_installed}" == 'true' ]]; then
  header
  echo -e "${WHITE_R}#${RESET} The script installed ${netcat_installed_package_name}, we do not need this anymore.\\n"
  echo -e "${WHITE_R}#${RESET} Purging package ${netcat_installed_package_name}..."
  if DEBIAN_FRONTEND='noninteractive' apt-get -y "${apt_options[@]}" -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' purge "${netcat_installed_package_name}" &>> "${eus_dir}/logs/uninstall-${netcat_installed_package_name}.log"; then
    echo -e "${GREEN}#${RESET} Successfully purged ${netcat_installed_package_name}! \\n"
  else
    echo -e "${RED}#${RESET} Failed to purge ${netcat_installed_package_name}... \\n"
  fi
  sleep 2
fi

if dpkg -l | grep "unifi " | grep -q "^ii\\|^hi"; then
  inform_port=$(grep "^unifi.http.port" /usr/lib/unifi/data/system.properties | cut -d'=' -f2 | tail -n1)
  dashboard_port=$(grep "^unifi.https.port" /usr/lib/unifi/data/system.properties | cut -d'=' -f2 | tail -n1)
  header
  echo -e "${GREEN}#${RESET} UniFi Network Application ${unifi_clean} has been installed successfully"
  if [[ "${public_reachable}" = 'true' ]]; then
    echo -e "${GREEN}#${RESET} Your application address: ${WHITE_R}https://$PUBLIC_SERVER_IP:${dash_port}${RESET}"
    if [[ "${le_script}" == 'true' ]]; then
      if [[ -d /usr/lib/EUS/ ]]; then
        if [[ -f /usr/lib/EUS/server_fqdn_install && -s /usr/lib/EUS/server_fqdn_install ]]; then
          application_fqdn_le=$(tail -n1 /usr/lib/EUS/server_fqdn_install)
          rm --force /usr/lib/EUS/server_fqdn_install &> /dev/null
        fi
      elif [[ -d /srv/EUS/ ]]; then
        if [[ -f /srv/EUS/server_fqdn_install && -s /srv/EUS/server_fqdn_install ]]; then
          application_fqdn_le=$(tail -n1 /srv/EUS/server_fqdn_install)
          rm --force /srv/EUS/server_fqdn_install &> /dev/null
        fi
      fi
      if [[ -n "${application_fqdn_le}" ]]; then
        echo -e "${GREEN}#${RESET} Your application FQDN: ${WHITE_R}https://$application_fqdn_le:${dash_port}${RESET}"
      fi
    fi
  else
    echo -e "${GREEN}#${RESET} Your application address: ${WHITE_R}https://$SERVER_IP:${dash_port}${RESET}"
  fi
  echo -e "\\n"
  if [[ "${os_codename}" =~ (precise|maya|trusty|qiana|rebecca|rafaela|rosa) ]]; then
    if systemctl status unifi | grep -iq running; then echo -e "${GREEN}#${RESET} UniFi is active ( running )"; else echo -e "${RED}#${RESET} UniFi failed to start... Please contact Glenn R. (AmazedMender16) on the Community Forums!"; fi
  else
    if systemctl is-active -q unifi; then echo -e "${GREEN}#${RESET} UniFi is active ( running )"; else echo -e "${RED}#${RESET} UniFi failed to start... Please contact Glenn R. (AmazedMender16) on the Community Forums!"; fi
  fi
  if [[ "${change_unifi_ports}" == 'true' ]]; then
    echo -e "\\n${WHITE_R}---- ${RED}NOTE${WHITE_R} ----${RESET}\\n\\n${WHITE_R}#${RESET} Your default application port(s) have changed!\\n"
    if [[ -n "${inform_port}" ]]; then
      echo -e "${WHITE_R}#${RESET} Device Inform port: ${inform_port}"
    fi
    if [[ -n "${dashboard_port}" ]]; then
      echo -e "${WHITE_R}#${RESET} Management Dashboard port: ${dashboard_port}"
    fi
    echo -e "\\n${WHITE_R}--------------${RESET}\\n"
  else
    if [[ "${port_8080_in_use}" == 'true' && "${port_8443_in_use}" == 'true' && "${port_8080_pid}" == "${port_8443_pid}" ]]; then
      echo -e "\\n${RED}#${RESET} Port ${info_port} and ${dash_port} is already in use by another process ( PID ${port_8080_pid} ), your UniFi Network Controll will most likely not start.."
      echo -e "${RED}#${RESET} Disable the service that is using port ${info_port} and ${dash_port} ( ${port_8080_service} ) or kill the process with the command below"
      echo -e "${RED}#${RESET} sudo kill -9 ${port_8080_pid}\\n"
    else
      if [[ "${port_8080_in_use}" == 'true' ]]; then
        echo -e "\\n${RED}#${RESET} Port ${info_port} is already in use by another process ( PID ${port_8080_pid} ), your UniFi Network Controll will most likely not start.."
        echo -e "${RED}#${RESET} Disable the service that is using port ${info_port} ( ${port_8080_service} ) or kill the process with the command below"
        echo -e "${RED}#${RESET} sudo kill -9 ${port_8080_pid}\\n"
      fi
      if [[ "${port_8443_in_use}" == 'true' ]]; then
        echo -e "\\n${RED}#${RESET} Port ${dash_port} is already in use by another process ( PID ${port_8443_pid} ), your UniFi Network Controll will most likely not start.."
        echo -e "${RED}#${RESET} Disable the service that is using port ${dash_port} ( ${port_8443_service} ) or kill the process with the command below"
        echo -e "${RED}#${RESET} sudo kill -9 ${port_8443_pid}\\n"
      fi
    fi
  fi
  echo -e "\\n"
  author
  remove_yourself
else
  header_red
  echo -e "\\n${RED}#${RESET} Failed to successfully install UniFi Network Application ${unifi_clean}"
  echo -e "${RED}#${RESET} Please contact Glenn R. (AmazedMender16) on the Community Forums!${RESET}\\n\\n"
  remove_yourself
fi
