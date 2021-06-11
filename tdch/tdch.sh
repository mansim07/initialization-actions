#!/bin/bash


#    Copyright 2019 Google LLC.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

#   This will install TDCH library on Dataproc cluster

#   As a pre-requisite, the .deb or .rpm file should be available in GCS

set -euxo pipefail

  role="$(/usr/share/google/get_metadata_value attributes/dataproc-role)"
  readonly role

  download_location=$(/usr/share/google/get_metadata_value attributes/DOWNLOAD_LOCATION)
  readonly download_location

  td_connector_file=$(/usr/share/google/get_metadata_value attributes/TERADATA_CONNECTOR_FILE)
  readonly td_connector_file

  lib_to_be_added=$(/usr/share/google/get_metadata_value attributes/LIB_TO_BE_ADDED)
  readonly lib_to_be_added

  tez_xml_file=$(/usr/share/google/get_metadata_value attributes/TEZ_XML_FILE)
  readonly tez_xml_file

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

function execute_with_retries() {
  local -r cmd=$1
  for ((i = 0; i < 10; i++)); do
    if eval "$cmd"; then
      return 0
    fi
    sleep 5
  done
  return 1
}

function download_deb_or_rpm() {
  #Download the teradata rpm or deb file from GCS to local
  download_status=$(gsutil cp "${download_location}/${td_connector_file}" /tmp &>/dev/null && echo $? || echo $?)

  if [ "${download_status}" != 0 ]; then
    err "Failed to download the ${td_connector_file}"
    exit 1
  fi

}

function validate_pkg(){

 if sudo grep -q "${lib_to_be_added}" "${tez_xml_file}" ; then
  err "Library is already present in tez.xml file"
  exit
 fi

declare -a file_array
file_array=( "file:/usr/local/share/google/dataproc/lib"
        "file:/usr/lib/tez/lib"
        "file:/usr/lib/tez" )
for this_file in "${file_array[@]}" ; do
    if sudo grep -q "$this_file" "${tez_xml_file}"; then
      sudo sed -i "s@${this_file}@&,${lib_to_be_added}@" "${tez_xml_file}"
      exit
    fi
done

err "Library update failed!" 
exit 1
}

function install_tdch(){
  download_deb_or_rpm

  if [[ "${DATAPROC_IMAGE_VERSION}" =~ .*"deb".* ]]; then
    pkg_install_status=$(sudo dpkg -i "/tmp/${td_connector_file}" && echo $? || echo $?)
  else
    pkg_install_status=$(sudo rpm -ivh "/tmp/${td_connector_file}" && echo $? || echo $?)
  fi
  

  if [ "${pkg_install_status}" != 0 ]; then
    err "Teradata Connector did not get installed"
    exit 1
  fi

validate_pkg

}

function main(){
  # Only run the installation on master nodes for Dataproc >= 2.0 
  if [[ ${DATAPROC_VERSION} == 1.* ]]; then
      install_tdch
  else 
      if [[ "${role}" == 'Master' ]]; then
      install_tdch
    fi

  fi
}

main