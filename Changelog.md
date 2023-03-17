# Changelog

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
