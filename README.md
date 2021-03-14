# ephemeral-ssh
This is a silly solution to a silly problem.

The problem that I ran into was utilizing `scp` to transfer files between my host and the remote host due to the agent forwarding option not being present in my version of SSH (OpenSSH_8.1p1). The easy solution was to pull the source files for one of the newer versions of SSH and compile it. [OpenSSH_8.4p1](https://www.openssh.com/txt/release-8.4) implements the agent forwarding feature for SCP with the `-A` flag.

```shell
# Example scp command for OpenSSH_8.4p1 with the path to the newly compiled binaries
/path/to/scp -A -S /path/to/ssh fileToTransfer serverUsername@serverAddress:/serverPath/to/destination
```

### Why this solution?
Some _secure_ infrastructure implementations involve a "gateway" in order to segment access to hosts on a remote network. Due to this implementation, one must specify the following options to connect to the remote host: 

```console
ssh -A gu=gatewayUsername@serverUsername@serverAddress@gatewayAddress
```

While the first example snippet solves my problem, I don't like that I had to compile the binaries seeing as this meant I needed to either specify the path or replace the system binaries. The silly solution was to create a container-based implementation utilizing `OpenSSH_8.4p1`. Luckily, the `alpine:latest` image includes `OpenSSH_8.4p1` in it's APK repositories. **You can also use this without the gatway user option in situations not requiring a gateway.**

Below are the instructions for building the image with `OpenSSH_8.4p1` installed and the `/root/.ssh/` directory created.

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
### Command Examples
These examples assume that your public key is added to the authorized_keys file on the remote host and that you don't have a passphrase for that key. Eventually, I'll add a solution for keys with a passphrase since passphrases should **always** be used for key pairs. :wink:

#### Command to run this for the gateway problem with forwarding
```shell
docker run --rm \
-v /hostPath/to/sshPrivateKey:/containerPath/to/sshPrivateKey \
-v /hostPath/to/file:/containerPath/to/file \
imageName /bin/sh -c 'eval $(ssh-agent) && \
ssh-add /containerPath/to/sshPrivateKey && \
scp -A -i /containerPath/to/sshPrivateKey \
-o "StrictHostKeyChecking=no" \
/containerPath/to/file gu=gatewayUsername@serverUsername@serverAddress@gatewayAddress:/serverPath/to/destination'
```

#### Command to run this without the gateway problem
```shell
docker run --rm \
-v /hostPath/to/sshPrivateKey:/containerPath/to/sshPrivateKey \
-v /hostPath/to/file:/containerPath/to/file \
imageName /bin/sh -c 'eval $(ssh-agent) && \
ssh-add /containerPath/to/sshPrivateKey && \
scp -A -i /containerPath/to/sshPrivateKey \
-o "StrictHostKeyChecking=no" \
/containerPath/to/file serverUsername@serverAddress:/serverPath/to/destination'
```

#### Command flag explanations
- `--rm` removes the container after running. This helps reduce the footprint of our keys being outside of their original location.
- `-v /hostPath/to/file:/containerPath/to/file` specifies a volume for the container with the host source.
- `-c` interprets the string of commands specified between the single quatotation marks.
- `-A` enables agent forwarding for scp.
- `-i /containerPath/to/sshPrivateKey` specifies the private key to use for authentication.
- `-o "StrictHostKeyChecking=no"` directs scp to bypass the host verification step that requires user input.

### TODO
- Implement a solution for keys with a passphrase.
- Implement a solution to pull files from the remote server.
- Implement a solution that pulls and compiles a given version of Alpine seeing as I got lucky that `alpine:latest` had the version of OpenSSH necessary for this.
- Add a shell function snippet to make this less cumbersome to run.
