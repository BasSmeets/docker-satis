#!/bin/bash
set -e

STEP="START"
echo "----------------------------------------------------------------"
echo "                STARTUP SCRIPT: START                           "
echo "----------------------------------------------------------------"
echo ""

function end_of_script() {
  result=$?

  if [ "0" != "${result}" ]; then
    echo ""
    echo "!!! ERROR !!!"
  fi
  echo ""
  echo "-----------------------------------------------------------"
  echo "     STARTUP SCRIPT: FINISHED AT STEP '${STEP}' WITH CODE: $result"
  echo "-----------------------------------------------------------"
  echo ""
  trap - INT TERM EXIT QUIT

  exit 0;
}

# Replace the frequency of a crontab entry
set_cron() {
  local cmd="sudo -u www -H sh -c '/satisfy/bin/satis build --working-dir=/satisfy/ --skip-errors --no-ansi'"
  local new_frequency=$1
  (echo "${new_frequency} ${cmd}")| crontab -
}

trap 'end_of_script' INT TERM EXIT QUIT

# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow

STEP="CRON"
set_cron "${CRONTAB_FREQUENCY}"

STEP="SSH"
touch ${USER_HOME}/.ssh/known_hosts

if [[ -f /var/tmp/sshconf ]]; then
    echo " >>> Copying host ssh config from /var/tmp/sshconf to ${USER_HOME}/.ssh/config"
    cp /var/tmp/sshconf "${USER_HOME}/.ssh/config"
fi

echo " >>> Creating the correct known_hosts file"
for _DOMAIN in ${PRIVATE_REPO_DOMAIN_LIST} ; do
    IFS=':' read -a arr <<< "${_DOMAIN}"
    if [[ "${#arr[@]}" == "2" ]]; then
        port="${arr[1]}"
        ssh-keyscan -t rsa,dsa, -p "${port}" ${arr[0]} >> ${USER_HOME}/.ssh/known_hosts
    else
        ssh-keyscan -t rsa,dsa ${_DOMAIN} >> ${USER_HOME}/.ssh/known_hosts
    fi
done

echo " >>> Copy ssh key to directory and assign permissions"
cp /tmp/id_rsa "${USER_HOME}/.ssh/id_rsa" && chmod 600 "${USER_HOME}/.ssh/id_rsa" && chown ${USER}:${USER} "${USER_HOME}/.ssh/id_rsa"

STEP="BUILD"
if [[ ! -f /satisfy/public/packages.json ]]; then
   sudo -u www -H sh -c "/satisfy/bin/satis build --working-dir=/satisfy/ --skip-errors --no-ansi"
fi

STEP="END"

exec "$@"