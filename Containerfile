FROM ubuntu:20.04

RUN apt-get update && \
    apt-get install -y \
        build-essential \
        curl \
        git \
        gcc-9 \
        gcc-aarch64-linux-gnu \
        iasl \
        lzma-dev \
        mtools \
        perl \
        python3 \
        python3-pip \
        uuid-dev \
        zip && \
    ln -s /usr/bin/python3 /usr/bin/python

COPY ./edk2/pip-requirements.txt /opt/pip-requirements.txt
RUN pip3 install -r /opt/pip-requirements.txt

COPY . /opt
RUN make -C /opt clean
CMD make -C /opt

