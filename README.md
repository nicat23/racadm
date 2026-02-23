# Docker iDRAC Tools (racadm)

This repository contains a Docker image that provides the Dell `racadm` utility for managing iDRAC interfaces. The image is based on Alpine Linux to keep it lightweight.

## Features

- Includes the `racadm` utility and its required libraries.
- Lightweight image based on Alpine Linux.
- Automatically handles privilege escalation using `sudo`.

## Usage

### Build the Image

To build the Docker image, run the following command in the same directory as the `Dockerfile`:

```sh
docker build -t racadm .
```

### Run the Container

To use the `racadm` utility, you can run the container and pass `racadm` commands to it.

For example, to get the system information from an iDRAC at a specific IP address, you can run:

```sh
docker run --rm racadm -r <iDRAC_IP> -u <username> -p <password> get System.Info
```

**Explanation of command-line options:**

- `docker run`: The command to run a Docker container.
- `--rm`: Automatically removes the container when it exits.
- `racadm`: The name of the image you built.
- `-r <iDRAC_IP>`: The IP address or hostname of the iDRAC.
- `-u <username>`: The username for the iDRAC.
- `-p <password>`: The password for the iDRAC.
- `get System.Info`: The `racadm` command to execute.

## Interactive Mode

You can also run the container in interactive mode to execute multiple `racadm` commands:

```sh
docker run --rm -it --entrypoint=/bin/sh racadm
```

This will give you a shell inside the container where you can run `racadm` commands directly.

## Disclaimer

This Docker image is provided as-is and is not officially supported by Dell.
