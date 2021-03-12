#!/bin/bash
set -eu

DOWNLOAD_LOCATION=$(/usr/share/google/get_metadata_value attributes/DOWNLOAD_LOCATION)
TERADATA_CONNECTOR_FILE=$(/usr/share/google/get_metadata_value attributes/TERADATA_CONNECTOR_FILE)
LIB_TO_BE_ADDED=$(/usr/share/google/get_metadata_value attributes/LIB_TO_BE_ADDED)


# ------------------------------------------------------------------------------
# Download Teradata connector on local machine
# ------------------------------------------------------------------------------
DOWNLOAD_STATUS=$(gsutil cp "${DOWNLOAD_LOCATION}/${TERADATA_CONNECTOR_FILE}" /tmp &>/dev/null && echo $? || echo $?)

if [ $DOWNLOAD_STATUS != 0 ]; then
  echo "could not download installable file ${TERADATA_CONNECTOR_FILE}"
  exit 1
fi

# ------------------------------------------------------------------------------
# Install the package
# ------------------------------------------------------------------------------
PKG_INSTALL_STATUS=$(sudo dpkg -i "/tmp/${TERADATA_CONNECTOR_FILE}" && echo $? || echo $?)

if [ $PKG_INSTALL_STATUS != 0 ]; then
  echo "Teradata Connector did not get installed"
  exit 1
fi

# ------------------------------------------------------------------------------
# Add Teradata library path in TEZ XML file
# ------------------------------------------------------------------------------
# Check if library has already added
if sudo grep -q "${LIB_TO_BE_ADDED}" "${TEZ_XML_FILE}" ; then
  echo "library already added"
  exit
fi

# add library in tez-site.xml
FILE_ARRAY=( "file:/usr/local/share/google/dataproc/lib"
        "file:/usr/lib/tez/lib"
        "file:/usr/lib/tez" )
for this_file in "${FILE_ARRAY[@]}" ; do
    if sudo grep -q "$this_file" "${TEZ_XML_FILE}"; then
      sudo sed -i "s@${this_file}@&,${LIB_TO_BE_ADDED}@" "${TEZ_XML_FILE}"
      exit
    fi
done

# if following line is executed that means library could not be added in the tez-site.xml
echo "Library could not be updated"
exit 1

