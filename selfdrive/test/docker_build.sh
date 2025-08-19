#!/bin/bash

# create a snapshot

PYTHONUNBUFFERED=1

echo whoami
whoami

DEBIAN_FRONTEND=noninteractive
apt-get update && \
    apt-get install -y --no-install-recommends sudo tzdata locales ssh pulseaudio xvfb x11-xserver-utils gnome-screenshot python3-tk python3-dev && \
    rm -rf /var/lib/apt/lists/* && apt-get clean

sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
LANG=en_US.UTF-8
LANGUAGE=en_US:en
LC_ALL=en_US.UTF-8

cp "$REPO/tools/install_ubuntu_dependencies.sh" /tmp/tools/ # $REPO TODO
/tmp/tools/install_ubuntu_dependencies.sh && \
    rm -rf /var/lib/apt/lists/* /tmp/* && \
    apt-get clean && \
    cd /usr/lib/gcc/arm-none-eabi/* && \
    rm -rf arm/ thumb/nofp thumb/v6* thumb/v8* thumb/v7+fp thumb/v7-r+fp.sp

apt-get update && apt-get install -y --no-install-recommends \
    apt-utils \
    alien \
    unzip \
    tar \
    curl \
    xz-utils \
    dbus \
    gcc-arm-none-eabi \
    tmux \
    vim \
    libx11-6 \
    wget \
  && rm -rf /var/lib/apt/lists/* && apt-get clean

mkdir -p /tmp/opencl-driver-intel && \
    cd /tmp/opencl-driver-intel && \
    wget https://github.com/intel/llvm/releases/download/2024-WW14/oclcpuexp-2024.17.3.0.09_rel.tar.gz && \
    wget https://github.com/oneapi-src/oneTBB/releases/download/v2021.12.0/oneapi-tbb-2021.12.0-lin.tgz && \
    mkdir -p /opt/intel/oclcpuexp_2024.17.3.0.09_rel && \
    cd /opt/intel/oclcpuexp_2024.17.3.0.09_rel && \
    tar -zxvf /tmp/opencl-driver-intel/oclcpuexp-2024.17.3.0.09_rel.tar.gz && \
    mkdir -p /etc/OpenCL/vendors && \
    echo /opt/intel/oclcpuexp_2024.17.3.0.09_rel/x64/libintelocl.so > /etc/OpenCL/vendors/intel_expcpu.icd && \
    cd /opt/intel && \
    tar -zxvf /tmp/opencl-driver-intel/oneapi-tbb-2021.12.0-lin.tgz && \
    ln -s /opt/intel/oneapi-tbb-2021.12.0/lib/intel64/gcc4.8/libtbb.so /opt/intel/oclcpuexp_2024.17.3.0.09_rel/x64 && \
    ln -s /opt/intel/oneapi-tbb-2021.12.0/lib/intel64/gcc4.8/libtbbmalloc.so /opt/intel/oclcpuexp_2024.17.3.0.09_rel/x64 && \
    ln -s /opt/intel/oneapi-tbb-2021.12.0/lib/intel64/gcc4.8/libtbb.so.12 /opt/intel/oclcpuexp_2024.17.3.0.09_rel/x64 && \
    ln -s /opt/intel/oneapi-tbb-2021.12.0/lib/intel64/gcc4.8/libtbbmalloc.so.2 /opt/intel/oclcpuexp_2024.17.3.0.09_rel/x64 && \
    mkdir -p /etc/ld.so.conf.d && \
    echo /opt/intel/oclcpuexp_2024.17.3.0.09_rel/x64 > /etc/ld.so.conf.d/libintelopenclexp.conf && \
    ldconfig -f /etc/ld.so.conf.d/libintelopenclexp.conf && \
    cd / && \
    rm -rf /tmp/opencl-driver-intel

NVIDIA_VISIBLE_DEVICES=all
NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute
QTWEBENGINE_DISABLE_SANDBOX=1

dbus-uuidgen > /etc/machine-id

USER=batman
USER_UID=1001
useradd -m -s /bin/bash -u "$USER_UID" "$USER"
usermod -aG sudo "$USER"
echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

#USER $USER

sudo -u "$USER" cp "$REPO/pyproject.toml" uv.lock "/home/$USER" && \
#sudo -u "$USER" chown "${USER}:{$USER}" "/home/$USER/pyproject.toml" "/home/$USER/uv.lock"

sudo -u "$USER" cp tools/install_python_dependencies.sh "/home/$USER/tools/"
#sudo -u "$USER" chown "${USER}:{$USER}" "/home/$USER/tools/install_python_dependencies.sh"

VIRTUAL_ENV=/home/$USER/.venv
PATH="$VIRTUAL_ENV/bin:$PATH"
sudo -u "$USER" bash -c "cd "/home/$USER" && \
    tools/install_python_dependencies.sh && \
    rm -rf tools/ pyproject.toml uv.lock .cache"

#USER root
#sudo
git config --global --add safe.directory /tmp/openpilot
