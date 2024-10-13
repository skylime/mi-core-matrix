# Changelog

## 23.4.0

### New

* Switch to matrix-synapse version 1.114. [Thomas Merkel]
- Initial commit to handle app services like IRC. [Thomas Merkel]
- Switch to core-base 23.4.1. [Thomas Merkel]
- Enable registration with tokens. [Thomas Merkel]

## 22.4.1

### New

* Provide pgsql dump and upgrade handling. [Thomas Merkel]

  Lookup for dump.sql file to provide a easy way to upgrade postgreSQL in
  an re-provision environment. Additional service and motd handling for
  better operational tasks.

  Fixing nginx.conf for latest matrix-synapse service.

  Providing new reset_matrix_user script to easily handle password resets
  as admin user.

## 22.4.0

### New

* Switch to Matrix Synapse 1.73.0 (core-base 22Q4) [Thomas Merkel]

  Switching to latest stable Matrix Synapse version. This upgrade could
  not performed automatically because of PostgreSQL. Please create a
  database dump before upgrading to this version.

  Additional changes:

  * python version 3.10
  * postgresql version 14.x
  * latest riot webui aka element
  * restructure data location and config location
  * using of pkgsrc matrix-synapse package

### Other

* Add logadm rule for homeserver.log. [Thomas Merkel]

## 18.4.0

### New

* Install matrix-synapse and all python requirements. [Thomas Merkel]
* Allow enable, disable guest and registration. [Thomas Merkel]
* Add SMF for matrix-synapse. [Thomas Merkel]
* Add riot web interface. [Thomas Merkel]

### Fix

* Fix py-nacl. [Thomas Merkel]
* Fix config.json for riot client. [Thomas Merkel]

### Other

* Enable SSL via lets encrypt, enable synpase service. [Thomas Merkel]
* Add script for mdata-create-password which will move to base soon. [Thomas Merkel]
* Add riot config generation script. [Thomas Merkel]
* Switch to latest core-base. [Thomas Merkel]
* Configure matrix synapse. [Thomas Merkel]
