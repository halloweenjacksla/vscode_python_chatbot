#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------

# Pick any base image, but if you select node, skip installing node. 😊
FROM python:3.7-slim

# This Dockerfile adds a non-root user with sudo access. Use the "remoteUser"
# property in devcontainer.json to use it. On Linux, the container user's GID/UIDs
# will be updated to match your local UID/GID (when using the dockerFile property).
# See https://aka.ms/vscode-remote/containers/non-root-user for details.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Configure apt and install packages
RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends apt-utils dialog 2>&1 \
    #
    # Verify git, required tools installed
    && apt-get install -y \
        git \
        openssh-client \
        less \
        iproute2 \
        curl \
        procps \
        unzip \
        apt-transport-https \
        ca-certificates \
        gnupg-agent \
        software-properties-common \
        python3-ldap \
        lsb-release 2>&1 \
        vim \
    #
    # [Optional] Install Node.js for Azure Cloud Shell support 
    # Change the "lts/*" in the two lines below to pick a different version
    # && curl -so- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash 2>&1 \
    # && /bin/bash -c "source $HOME/.nvm/nvm.sh \
    #     && nvm install lts/* \
    #     && nvm alias default lts/*" 2>&1 \
    # #
    # # [Optional] For local testing instead of cloud shell
    # # Install Docker CE CLI. 
    # && curl -fsSL https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/gpg | apt-key add - 2>/dev/null \
    # && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]') $(lsb_release -cs) stable" \
    # && apt-get update \
    # && apt-get install -y docker-ce-cli \
    # #
    # # [Optional] For local testing instead of cloud shell
    # # Install the Azure CLI
    # && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/azure-cli.list \
    # && curl -sL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - 2>/dev/null \
    # && apt-get update \
    # && apt-get install -y azure-cli \
    #
    # Install Ansible
    && apt-get install -y libssl-dev libffi-dev \
    #
    # Create a non-root user to use if preferred - see https://aka.ms/vscode-remote/containers/non-root-user.
    && groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    # [Optional] Add sudo support for the non-root user
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME\
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    #
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

COPY .bashrc.tmp /tmp/.bashrc.tmp
COPY requirements.txt /tmp/requirements.txt

RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/home/${USERNAME}/.commandhistory/.bash_history" \
    && echo $SNIPPET >> "/tmp/.bashrc.tmp" \
    # [Optional] If you have a non-root user
    && echo "PATH=$PATH:/home/$USERNAME/.local/bin\n" >> /tmp/.bashrc.tmp \
    && mkdir /home/${USERNAME}/.commandhistory \
    && touch /home/${USERNAME}/.commandhistory/.bash_history \
    && mkdir -p /home/$USERNAME/.vscode-server/extensions \
        /home/$USERNAME/.vscode-server-insiders/extensions \
        /home/$USERNAME/.aws \
    && chown -R $USERNAME:${USER_GID} /home/${USERNAME} \
    && chown -R $USERNAME:${USER_GID} /home/${USERNAME}/.* \
    && pip3 install -r /tmp/requirements.txt

RUN cat /tmp/.bashrc.tmp >> "/home/${USERNAME}/.bashrc"

USER ${USERNAME}

# Setup git-bash-prompt
RUN git clone https://github.com/magicmonty/bash-git-prompt.git ~/.bash-git-prompt --depth=1