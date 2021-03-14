# ephemeral-ssh
This is a silly solution to a silly problem.

Some _secure_ implementations involve a "gateway" in order to segment access to hosts on a remote network. Due to this implementation, one must specify the following options to connect to the remote host: `ssh -o "ForwardAgent=yes" gu=gatewayUsername@serverUsername@serverAddress@gatewayAddress`

The problem that I ran into was utilizing `scp` to transfer files between my host and the remote host due to the agent forwarding option not being present in my version of SSH (OpenSSH_8.1p1). The easy solution was to pull the source files for one of the newer versions of SSH. [OpenSSH_8.4p1](https://www.openssh.com/txt/release-8.4) implements the agent forwarding feature for SCP with the `-A` flag.

```shell
# Example scp command for OpenSSH_8.4p1 with the path to the newly compiled binaries
/path/to/scp -A -S /path/to/ssh fileToTransfer \
gu=gatewayUsername@serverUsername@serverAddress@gatewayAddress:/serverPath/to/destination
```

While the above example solves my problem, I don't like that I had to compile the binaries seeing as this meant I needed to either specify the path or replace the system binaries. The silly solution was to create a container-based implementation utilizing `OpenSSH_8.4p1`. Luckily, the `alpine:latest` image includes `OpenSSH_8.4p1` in it's APK repositories. Below are the instructions for building the image with `OpenSSH_8.4p1` installed and the `/root/.ssh/` directory created.


### Build the image from the Dockerfile
```shell
# Clone the repository
git clone https://github.com/avocadosec/ephemeral-ssh

# Change into the cloned repository
cd ephemeral-ssh

# Build the image
docker build -t ephemeral-ssh .

# List docker images and verify ephemeral-ssh exists
docker images
```

### Run the container to send your file to the host behind the gateway
```shell
docker run \
-v /hostPath/to/sshPrivateKey:/containerPath/to/sshPrivateKey \
-v /hostPath/to/file:/containerPath/to/file \
imageName /bin/sh -c 'eval $(ssh-agent) && \
ssh-add /containerPath/to/sshPrivateKey && \
scp -A -i /containerPath/to/sshPrivateKey \
-o "StrictHostKeyChecking=no" \
/containerPath/to/file gu=gatewayUsername@serverUsername@serverAddress@gatewayAddress:/serverPath/to/destination'
```

### TODO
- Add a shell function snippet to make this less cumbersome to run 
- Implement a solution that pulls and compiles a given version of Alpine seeing as I got lucky that `alpine:latest` had the version of OpenSSH necessary for this.
