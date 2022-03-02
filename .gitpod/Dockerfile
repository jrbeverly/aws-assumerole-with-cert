FROM gitpod/workspace-full
USER root

RUN npm install -g @bazel/bazelisk
RUN npm install -g @bazel/ibazel

RUN apt-get update
RUN apt-get install -y zsh && \
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

ENV GOPATH=$HOME/go-packages
RUN go get -u -v github.com/bazelbuild/buildtools/buildifier
RUN go get -u -v github.com/bazelbuild/buildtools/buildozer
ENV GOPATH=/workspace/go

RUN wget -O /usr/local/bin/gostarlark https://github.com/stackb/bzl/releases/download/0.9.4/bzl && \
  chmod +x /usr/local/bin/gostarlark

ARG AWS_CLI_V2_URL='https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip'
RUN curl "${AWS_CLI_V2_URL}" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install

ARG KUBECTL_URL='https://amazon-eks.s3.us-west-2.amazonaws.com/1.20.4/2021-04-12/bin/linux/amd64/kubectl'
RUN curl -o kubectl "${KUBECTL_URL}" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin

ARG YQ_URL='https://github.com/mikefarah/yq/releases/download/v4.18.1/yq_linux_amd64'
RUN curl -o yq "${KUBECTL_URL}" && \
    chmod +x yq && \
    mv yq /usr/local/bin

USER gitpod