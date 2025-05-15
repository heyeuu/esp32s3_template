FROM homebrew/ubuntu22.04

USER root

# 优化 apt 安装，确保安装 wget 和 curl
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    git \
    python3 \
    vim \
    wget \
    curl \
    unzip \
    usbutils \
    net-tools \
    iputils-ping \
    zsh \
    screen \
    cmake \
    build-essential \
    libudev-dev \
    pkg-config \
    python3-pip \
    python3-venv && \
    rm -rf /var/lib/apt/lists/*

# Install unison to allow file synchronization
RUN cd /tmp && \
    wget -O unison.tar.gz https://github.com/bcpierce00/unison/releases/download/v2.53.7/unison-2.53.7-ubuntu-x86_64.tar.gz && \
    mkdir -p unison && tar -zxf unison.tar.gz -C unison && \
    cp unison/bin/* /usr/local/bin && \
    rm -rf unison unison.tar.gz

# 添加开发用户并配置环境
RUN useradd -m developer --shell /bin/zsh && \
    echo "developer:developer" | chpasswd && \
    adduser developer sudo && \
    echo "developer ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    gpasswd --add developer dialout

# 设置 Rust 环境变量
ENV CARGO_HOME=/home/developer/.cargo
ENV RUSTUP_HOME=/home/developer/.rustup
ENV PATH=/home/developer/.cargo/bin:$PATH

USER developer
WORKDIR /home/developer

# 安装 rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    rustup toolchain install nightly && \
    rustup default nightly && \
    cargo install cargo-generate && \
    cargo install ldproxy && \
    cargo install espup && \
    cargo install espflash

# 安装 espup
RUN curl -L https://github.com/esp-rs/espup/releases/latest/download/espup-x86_64-unknown-linux-gnu -o espup && \
    chmod +x espup && \
    ./espup install --export-file ~/export-esp.sh && \
    rm -f espup

# 安装 Oh My Zsh 并配置主题
RUN wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O install.sh && \
    sh install.sh --unattended && \
    sed -i 's/ZSH_THEME="[^"]*"/ZSH_THEME="af-magic"/g' ~/.zshrc && \
    rm install.sh

# 设置默认启动命令
CMD ["zsh"]