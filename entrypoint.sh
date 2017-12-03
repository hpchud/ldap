#!/bin/bash

# originally based on https://github.com/dinkel/docker-openldap

# When not limiting the open file descritors limit, the memory consumption of
# slapd is absurdly high. See https://github.com/docker/docker/issues/8231
ulimit -n 8192

set -e

LDAP_DIR=/etc/openldap
SLAPD_DIR=${LDAP_DIR}/slapd.d
SLAPD_USER=ldap
SLAPD_GROUP=ldap

# check for required vars
if [[ -z "$CONFIG_REPO" ]]; then
    echo -n >&2 "Error: no configuration repository is set "
    echo >&2 "Did you forget to add -e CONFIG_REPO=... ?"
    exit 1
fi
if [[ -z "$CONFIG_USER" ]]; then
    echo -n >&2 "Error: the user or team name is not set "
    echo >&2 "Did you forget to add -e CONFIG_USER=... ?"
    exit 1
fi
if [[ -z "$CONFIG_PASS" ]]; then
    echo -n >&2 "Error: the password or API key is not set "
    echo >&2 "Did you forget to add -e CONFIG_PASS=... ?"
    exit 1
fi

# reset db if it has already been configured
if [[ -f "/var/lib/ldap/DB_CONFIG" ]]; then 
    echo "database already configured, wiping it"
    rm -rf /var/lib/ldap/*
    rm -rf $LDAP_DIR
    rm -rf /root/ldap-config
fi

echo "database not configured, will populate now"
cp -r $LDAP_DIR.dist $LDAP_DIR

# clone the git repo
echo "cloning config repository..."
git clone https://${CONFIG_USER}:${CONFIG_PASS}@${CONFIG_REPO} /root/ldap-config

# copy in the cn=config ldifs
echo "copying cn=config ldifs..."
cp -r /root/ldap-config/cn=config/* ${SLAPD_DIR}/cn=config/

# add required schemas
echo "adding schemas..."
slapadd -n0 -F /etc/openldap/slapd.d -l /etc/openldap/schema/cosine.ldif 
slapadd -n0 -F /etc/openldap/slapd.d -l /etc/openldap/schema/nis.ldif 
slapadd -n0 -F /etc/openldap/slapd.d -l /etc/openldap/schema/inetorgperson.ldif

# convert any yml files to ldif format
yml2ldif /root/ldap-config/populate/*.yml > /root/ldap-config/populate/40_converted-from-yml.ldif
rm -rf /root/ldap-config/populate/*.yml

# use ldifs to populate directory
echo "populating directory..."
for file in `ls /root/ldap-config/populate/*.ldif`; do
    echo "adding $file"
    slapadd -F $SLAPD_DIR -l "$file"
done

# set permissions
echo "fixing permissions..."
chown -R ${SLAPD_USER}:${SLAPD_GROUP} $SLAPD_DIR
chown -R ${SLAPD_USER}:${SLAPD_GROUP} /var/lib/ldap

echo "starting the server"
exec "$@"