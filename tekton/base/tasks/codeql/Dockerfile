FROM ubuntu:20.04

# tzdata install needs to be non-interactive
ENV DEBIAN_FRONTEND=noninteractive

# install/update basics and python
RUN apt update

RUN apt-get install -y \
    software-properties-common \
    vim \
    curl \
    wget \
    git \
    build-essential \
    unzip \
    apt-transport-https \
    python3.8 \
    python3-venv \
    python3-pip \
    python3-setuptools \
    python3-dev \
    gnupg \
    g++ \
    make \
    gcc \
    apt-utils \
    rsync \
    file \
    dos2unix \
    gettext && \
    apt-get clean && \
    rm -f /usr/bin/python /usr/bin/pip && \
    ln -s /usr/bin/python3.8 /usr/bin/python && \
    ln -s /usr/bin/pip3 /usr/bin/pip

# Install latest codeQL
ENV CODEQL_HOME /usr/local/codeql-home
RUN mkdir -p ${CODEQL_HOME}

RUN wget -O codeql-bundle.tar.gz https://github.com/github/codeql-action/releases/download/codeql-bundle-20211025/codeql-bundle.tar.gz &&\
    tar -xvzf codeql-bundle.tar.gz &&\
    cp -R ./codeql ${CODEQL_HOME}

ENV PATH="${CODEQL_HOME}/codeql:${PATH}"

ENV PYTHONIOENCODING=utf-8
ENTRYPOINT ["codeql"]