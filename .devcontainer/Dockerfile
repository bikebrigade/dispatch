# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.222.0/containers/debian/.devcontainer/base.Dockerfile

# [Choice] Debian version (use bullseye on local arm64/Apple Silicon): bullseye, buster
ARG VARIANT="buster"
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}


ARG NIX_INSTALLER="https://releases.nixos.org/nix/nix-2.7.0/install"

# Install Nix
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
   && apt-get -y install --no-install-recommends wget xz-utils 
   
USER vscode   
RUN curl -sSL ${NIX_INSTALLER} -o /tmp/nix_installer.sh \
   && sh /tmp/nix_installer.sh --no-daemon

VOLUME ["/nix"]

# Set up a login shell
RUN  . /home/vscode/.nix-profile/etc/profile.d/nix.sh

# Initiate the nix-shell
#RUN nix-shell



