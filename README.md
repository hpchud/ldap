# ldap

This is the QGG stateless ldap server.

# Running it

```
docker run -d -p 389:389 \
    -e CONFIG_REPO=bitbucket.org/hpchud/ldap-config.git \
    -e CONFIG_USER=hpchud
    -e CONFIG_PASS=<api key> \
    hpchud/ldap
```

# Configuring

The data that is used to populate the ldap server must be in another repository and passed to the container through environment variable `CONFIG_REPO`. This repo must have the following layout:

```
./cn=config/
           olcDatabase\=\{2\}hdb.ldif
           olcDatabase\=\{1\}monitor.ldif
           <etc>
./populate/
           users.ldif
           groups.ldif
           <etc>
```

On startup, this repository will be cloned using `CONFIG_USER` and `CONFIG_PASS` as the credentials. Whilst this image can be public, you don't want the configuration to be.

The `cn=config/*.ldif` files will be applied to configure the server, against the first database (0).

The `populate/*.ldif` files will be applied to populate the server, against the next available database.

When the server is restarted, it is discarded completely - a brand new server is configured, populated again with the users and groups.

Thus, any changes performed against the server whilst it is running will be discarded. All changes should be made to the `ldif` file in the `prepopulate` folder.

The benefits are many; the most important one being that no complex replication policies are required for high availability - just start up more than 1 instance, configure the client appropriately, and remember to restart them one by one when updating.