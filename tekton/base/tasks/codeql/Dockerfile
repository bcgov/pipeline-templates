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
RUN mkdir -p ${CODEQL_HOME} \
    ${CODEQL_HOME}/codeql-repo \
    ${CODEQL_HOME}/codeql-go-repo \
    /opt/codeql

# get the latest codeql queries and record the HEAD
RUN git clone --depth 1 https://github.com/github/codeql ${CODEQL_HOME}/codeql-repo && \
    git --git-dir ${CODEQL_HOME}/codeql-repo/.git log --pretty=reference -1 > /opt/codeql/codeql-repo-last-commit
RUN git clone --depth 1 https://github.com/github/codeql-go ${CODEQL_HOME}/codeql-go-repo && \
    git --git-dir ${CODEQL_HOME}/codeql-go-repo/.git log --pretty=reference -1 > /opt/codeql/codeql-go-repo-last-commit

RUN wget -O codeql-bundle.tar.gz https://github.com/github/codeql-action/releases/download/codeql-bundle-20211025/codeql-bundle.tar.gz &&\
    tar -xvzf codeql-bundle.tar.gz &&\
    cp -R ./codeql ${CODEQL_HOME}

ENV PATH="${CODEQL_HOME}/codeql:${PATH}"

# Pre-compile our queries to save time later
RUN codeql query compile --threads=0 ${CODEQL_HOME}/codeql-repo/*/ql/src/codeql-suites/*.qls
RUN codeql query compile --threads=0 ${CODEQL_HOME}/codeql-go-repo/ql/src/codeql-suites/*.qls

ENV PYTHONIOENCODING=utf-8
ENTRYPOINT ["/bin/bash"]