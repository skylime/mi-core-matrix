# mi-core-matrix

This repository is based on [Joyent mibe](https://github.com/joyent/mibe). Please note this repository should be build with the [mi-core-base](https://github.com/skylime/mi-core-base) mibe image.

## description

Image for [Matrix Synapse](https://github.com/matrix-org/synapse) homeserver. Matrix is an open network for secure, decentralized communication.

## mdata variables

- `nginx_ssl`: ssl cert, key and CA for nginx in pem format (if not provided Let's Encrypt will be used)
- `matrix_server_name`: matrix synapse server name, if not provided the fqdn is used
- `matrix_allow_guest_access`: set to true if guest access to matrix synapse should be allowed
- `matrix_enable_registration`: set to true if user registration to matrix synapse should be allowed

## services

- `80/tcp`: http via nginx
- `443/tcp`: https via nginx for riot client and matrix client connection
- `8448/tcp`: ssl via nginx for matrix server connection
