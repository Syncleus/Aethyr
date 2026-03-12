FROM borea/aethyr:1.0.0

LABEL maintainer="Jeffrey Phillips Freeman the@jeffreyfreeman.me"

RUN sudo pacman -Sy --noconfirm archlinux-keyring && \
    sudo pacman-key --init && \
    sudo pacman-key --populate archlinux && \
    sudo pacman -S --noconfirm \
        go && \
    sudo pacman -Scc --noconfirm

RUN git clone https://aur.archlinux.org/yay.git && \
    cd yay && \
    makepkg -si --noconfirm && \
    cd .. && \
    rm -rf yay

RUN yay -Sy --noconfirm \
        less \
        python313 && \
    yay -Scc --noconfirm


# Playwright browser settings
#ENV PLAYWRIGHT_BROWSERS_PATH=${USER_HOME}/pw-browsers
#ENV PLAYWRIGHT_SKIP_BROWSER_GC=1

# Create directories with proper permissions
# #sudo mkdir -p ${USER_HOME}/.aider ${USER_HOME}/.cache ${USER_HOME}/pw-browsers && \
RUN sudo chown -R ${AETHYR_UID}:${AETHYR_GID} ${USER_HOME}

# So git doesn't complain about unusual permissions
RUN sudo git config --system --add safe.directory ${APP_DIR}

#RUN sudo python3.12 -m ensurepip && \
#    sudo python3.12 -m pip install --no-cache-dir aider-chat[help,browser,playwright] boto3 --extra-index-url https://download.pytorch.org/whl/cpu

#RUN sudo playwright install --with-deps chromium

#RUN git config --global commit.gpgsign false && \
#    git config --global tag.gpgsign false

ENV FORGEJO_PAT=""

# Create directories for MCP server configurations and logs
RUN mkdir -p ~/.local/bin \
    && mkdir -p ~/.local/share/mcp-logs

# Install Go 1.22+ (for building Forgejo MCP if needed)
RUN curl -fsSL https://go.dev/dl/go1.22.10.linux-amd64.tar.gz | sudo tar -xzC /usr/local \
    && sudo ln -s /usr/local/go/bin/go /usr/local/bin/go \
    && sudo ln -s /usr/local/go/bin/gofmt /usr/local/bin/gofmt

# Install forgejo-mcp from source
RUN cd /tmp && \
    git clone https://github.com/goern/forgejo-mcp.git && \
    cd forgejo-mcp && \
    /usr/local/go/bin/go build -o forgejo-mcp . && \
    sudo mv forgejo-mcp /usr/local/bin/forgejo-mcp && \
    sudo chmod +x /usr/local/bin/forgejo-mcp && \
    cd / && rm -rf /tmp/forgejo-mcp

# Install test-runner-mcp from source
RUN cd /tmp && \
    git clone https://github.com/privsim/mcp-test-runner.git && \
    cd mcp-test-runner && \
    npm install && \
    npm run build && \
    sudo cp -r . /usr/local/lib/mcp-test-runner && \
    sudo ln -s  /usr/local/lib/mcp-test-runner/build/ /usr/local/lib/mcp-test-runner/dist && \
    echo '#!/bin/bash\ncd /usr/local/lib/mcp-test-runner && node dist/index.js "$@"' | sudo tee /usr/local/bin/mcp-test-runner && \
    sudo chmod +x /usr/local/bin/mcp-test-runner && \
    cd / && rm -rf /tmp/mcp-test-runner

# Configure OpenCode with MCP servers
RUN mkdir -p ${USER_HOME}/.config/opencode
COPY .devcontainer/opencode.json ${USER_HOME}/.config/opencode/opencode.json

# Install zsh and Oh My Zsh for better shell experience
RUN sudo pacman -Sy --noconfirm zsh && sudo pacman -Scc --noconfirm
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Set default shell to zsh
ENV SHELL=/bin/zsh

# Install marksman (Markdown LSP) binary
RUN curl -fsSL https://github.com/artempyanykh/marksman/releases/latest/download/marksman-linux-x64 \
    -o /tmp/marksman && \
    sudo mv /tmp/marksman /usr/local/bin/marksman && \
    sudo chmod +x /usr/local/bin/marksman

# Install LSPs
RUN sudo python3.13 -m ensurepip && \
    sudo python3.13 -m pip install python-lsp-server[all]

# Install additional LSP servers
RUN sudo npm install -g \
      yaml-language-server \
      vscode-json-languageserver \
      dockerfile-language-server-nodejs \
      bash-language-server

ENV FORGEJO_URL="https://git.cleverthis.com/"

RUN bash -c "$(curl -fsSL https://opencode.ai/install)" "" --unattended
COPY .devcontainer/opencode.json ${USER_HOME}/.config/opencode/opencode.json

COPY . $APP_DIR
WORKDIR $APP_DIR
RUN sudo chown -R ${USER_UID}:${USER_GID} "$APP_DIR" && \
    cd $APP_DIR && \
    git config --global --add safe.directory /app && \
    sudo git clean -xdf && \
    sudo rm -rf .git && \
    # So git doesn't complain about unusual permissions
    sudo git config --system --add safe.directory ${APP_DIR}

EXPOSE 8000/tcp
EXPOSE 8080/tcp
EXPOSE 3000/tcp

VOLUME ["${APP_DIR}"]
CMD ["bash"]
