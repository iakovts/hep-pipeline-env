FROM ubuntu:22.04

ENV LC_ALL=C \
    DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/Athens

RUN apt-get update && apt-get install -y --no-install-recommends \
    gfortran g++ rsync make cmake \
    python3 python3-pip python-is-python3 cython3 python3-dev \
    wget ca-certificates vim git \
    gosu sudo \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /madgraph

ENTRYPOINT ["entrypoint.sh"]
CMD ["bash"]
