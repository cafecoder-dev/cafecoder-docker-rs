# Ubuntu:20.04(amd64)
# m1 mac だとハッシュを指定しないと arm64 で build してしまうので・・。
FROM ubuntu@sha256:e3d7ff9efd8431d9ef39a144c45992df5502c995b9ba3c53ff70c5b52a848d9c

ENV TZ Asia/Tokyo
ENV DEBIAN_FRONTEND=noninteractive
ENV DOWNLOAD_ROOT=/download

SHELL ["/bin/bash", "-c"]

WORKDIR / 

RUN mkdir download
RUN mkdir box
RUN mkdir judge

# install common tools
RUN \
    apt update && apt install -y \
        software-properties-common \
        apt-transport-https \
        dirmngr \
        curl \
        wget \
        time \
        iproute2 \
        build-essential \
        sudo \
        unzip \
        git && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Raku install
RUN \
    apt update && apt-get install -y \
        rakudo && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
   
# C#(mono) install
RUN \
    apt update && apt install -y \
        gnupg ca-certificates && \
    yes | apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
    echo "deb https://download.mono-project.com/repo/ubuntu stable-focal main" | tee /etc/apt/sources.list.d/mono-official-stable.list && \
    apt update && apt install -y \
        mono-devel && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# C#(.NET) install
RUN \
    mkdir -p $HOME/dotnet &&\
    curl -fsSL https://download.visualstudio.microsoft.com/download/pr/820db713-c9a5-466e-b72a-16f2f5ed00e2/628aa2a75f6aa270e77f4a83b3742fb8/dotnet-sdk-5.0.100-linux-x64.tar.gz | \
    tar zxf -C $HOME/dotnet && \
    echo 'export DOTNET_ROOT=$HOME/dotnet' >> ~/.profile && \
    echo 'export PATH=$PATH:$HOME/dotnet' >> ~/.profile

# C/C++ install
RUN \
    apt update && apt-get install g++-10 gcc-10 -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Java11 install
RUN \
    apt update && apt install default-jdk -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Python3 install
RUN \
    apt update && apt install python3.9 -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Pypy3 install
RUN \
    cd /opt && \
    curl -fsSL https://downloads.python.org/pypy/pypy3.7-v7.3.3-linux64.tar.bz2 | \
    tar xf && \
    cd /bin && \
    ln -s /opt/pypy3.7-v7.3.3-linux64/bin/pypy3 pypy3

# go install
RUN \
    curl -fsSL https://golang.org/dl/go1.15.5.linux-amd64.tar.gz | \
    tar -C /usr/local -xzf && \
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile

ENV USER=$USER
    
# Rust install
RUN \
    curl https://sh.rustup.rs -sSf | sh -s -- -y && \
    source $HOME/.cargo/env && \
    cargo new rust_workspace && \
    cd rust_workspace &&\
    wget https://raw.githubusercontent.com/cafecoder-dev/language-update/20.10/Rust/Cargo.toml -O Cargo.toml && \
    cargo build --release && \
    cd /

# Nim install
RUN \
    curl https://nim-lang.org/choosenim/init.sh -sSf | sh -s -- -y && \
    echo 'export PATH=/root/.nimble/bin:$PATH' >> ~/.profile
    
# Ruby install
RUN \
    apt update apt install make libffi-dev openssl libssl-dev zlib1g-dev -y && \
    git clone https://github.com/sstephenson/rbenv.git ~/.rbenv && \
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.profile && \
    echo 'eval "$(rbenv init -)"' >> ~/.profile && \
    bash -c exec $SHELL -l && \
    git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build && \
    export PATH="$HOME/.rbenv/bin:$PATH" && rbenv install 2.7.2 && rbenv global 2.7.2 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Kotlin install
RUN \
    apt update && apt install zip unzip -y && \
    curl -s https://get.sdkman.io | bash && \
    bash && \
    echo 'source "/root/.sdkman/bin/sdkman-init.sh"' >> ~/.profile && \
    source ~/.profile && \
    sdk install kotlin && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Fortran install
RUN \
    apt update && apt install gfortran-10 -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
    
# crystal
RUN \
    curl -sSL https://dist.crystal-lang.org/apt/setup.sh | bash && \
    apt update && apt install crystal -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
    
# Perl install
RUN \
    curl -fsSL https://www.cpan.org/src/5.0/perl-5.32.0.tar.gz | \
    tar -xzf && \
    cd perl-5.32.0 && \
    ./Configure -Dprefix=$HOME/perl -Dscriptdir=$HOME/perl/bin -des -Dman1dir=none -Dman3dir=none -DDEBUGGING=-g && \
    make --jobs=8 install

# install external libraries
RUN \
    wget https://raw.githubusercontent.com/MikeMirzayanov/testlib/master/testlib.h && \
    wget https://github.com/atcoder/ac-library/releases/download/v1.0/ac-library.zip && unzip ac-library.zip

# install isolate
RUN \
    apt install libcap-dev && \
    git clone https://github.com/ioi/isolate.git /isolate && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
COPY ./default.cf /isolate/default.cf
RUN cd /isolate && make install

# build judge
COPY . /cafecoder-docker-rust
RUN cd cafecoder-docker-rust && \
    source $HOME/.cargo/env && \
    cargo build --release && \
    cp target/release/cafecoder-docker-rs / && \
    cp .env / && \
    cp service-account-cafecoder.json / && \
    cp default.cf / && \
    cargo clean

ENTRYPOINT ["./cafecoder-docker-rs"]