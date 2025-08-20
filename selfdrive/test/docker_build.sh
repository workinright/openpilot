#!/bin/bash

#sudo mkdir -p /state1 /diff_output && sudo mount -t tmpfs tmpfs /state1 && sudo mount -t tmpfs tmpfs /diff_output
#time sudo rsync -a --info=progress2 -m --exclude=/dev -m --exclude=/proc -m --exclude=/sys -m --exclude=/state1 -m / /state1 --delete --delete-excluded

tac /proc/mounts | grep /overlay | while read line; do umount "$line"; done

sudo mkdir -p /upper /work /overlay
mounts="$(cat /proc/mounts)"
sudo mount -t overlay overlay -o lowerdir=/,upperdir=/upper,workdir=/work /overlay
echo "$mounts" | cut -d" " -f2 | while read line
do
    if [ "$line" != "/" ]
    then
        sudo mount --bind "$line" "/overlay$line"
    fi
done
sudo mount --make-rprivate /
cd /overlay
sudo mkdir -p old
mount
sudo pivot_root . old

PYTHONUNBUFFERED=1

DEBIAN_FRONTEND=noninteractive

REPO="/home/runner/work/openpilot/openpilot"

mkdir -p /tmp/tools
cp "$REPO/tools/install_ubuntu_dependencies.sh" /tmp/tools/ # $REPO TODO
sudo /tmp/tools/install_ubuntu_dependencies.sh && \

sudo apt-get install -y --no-install-recommends \
    sudo tzdata locales ssh pulseaudio xvfb x11-xserver-utils gnome-screenshot python3-tk python3-dev \
    apt-utils alien unzip tar curl xz-utils dbus gcc-arm-none-eabi tmux vim libx11-6 wget && \
sudo rm -rf /var/lib/apt/lists/* && sudo apt-get clean

sudo rm -rf /var/lib/apt/lists/* && \
    sudo apt-get clean && \
    cd /usr/lib/gcc/arm-none-eabi/* && \
    sudo rm -rf arm/ thumb/nofp thumb/v6* thumb/v8* thumb/v7+fp thumb/v7-r+fp.sp

sudo sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && sudo locale-gen
LANG=en_US.UTF-8
LANGUAGE=en_US:en
LC_ALL=en_US.UTF-8

mkdir -p /tmp/opencl-driver-intel && \
    cd /tmp/opencl-driver-intel && \
    wget https://github.com/intel/llvm/releases/download/2024-WW14/oclcpuexp-2024.17.3.0.09_rel.tar.gz && \
    wget https://github.com/oneapi-src/oneTBB/releases/download/v2021.12.0/oneapi-tbb-2021.12.0-lin.tgz && \
    sudo mkdir -p /opt/intel/oclcpuexp_2024.17.3.0.09_rel && \
    cd /opt/intel/oclcpuexp_2024.17.3.0.09_rel && \
    sudo tar -zxvf /tmp/opencl-driver-intel/oclcpuexp-2024.17.3.0.09_rel.tar.gz && \
    sudo mkdir -p /etc/OpenCL/vendors && \
    sudo bash -c "echo /opt/intel/oclcpuexp_2024.17.3.0.09_rel/x64/libintelocl.so > /etc/OpenCL/vendors/intel_expcpu.icd" && \
    cd /opt/intel && \
    sudo tar -zxvf /tmp/opencl-driver-intel/oneapi-tbb-2021.12.0-lin.tgz && \
    sudo ln -s /opt/intel/oneapi-tbb-2021.12.0/lib/intel64/gcc4.8/libtbb.so /opt/intel/oclcpuexp_2024.17.3.0.09_rel/x64 && \
    sudo ln -s /opt/intel/oneapi-tbb-2021.12.0/lib/intel64/gcc4.8/libtbbmalloc.so /opt/intel/oclcpuexp_2024.17.3.0.09_rel/x64 && \
    sudo ln -s /opt/intel/oneapi-tbb-2021.12.0/lib/intel64/gcc4.8/libtbb.so.12 /opt/intel/oclcpuexp_2024.17.3.0.09_rel/x64 && \
    sudo ln -s /opt/intel/oneapi-tbb-2021.12.0/lib/intel64/gcc4.8/libtbbmalloc.so.2 /opt/intel/oclcpuexp_2024.17.3.0.09_rel/x64 && \
    sudo mkdir -p /etc/ld.so.conf.d && \
    sudo bash -c "echo /opt/intel/oclcpuexp_2024.17.3.0.09_rel/x64 > /etc/ld.so.conf.d/libintelopenclexp.conf" && \
    sudo ldconfig -f /etc/ld.so.conf.d/libintelopenclexp.conf && \
    cd / && \
    rm -rf /tmp/opencl-driver-intel

sudo rm -rf /tmp/*

NVIDIA_VISIBLE_DEVICES=all
NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute
QTWEBENGINE_DISABLE_SANDBOX=1

sudo bash -c "dbus-uuidgen > /etc/machine-id"

USER=batman
USER_UID=1002
sudo useradd -m -s /bin/bash -u "$USER_UID" "$USER"
sudo usermod -aG sudo "$USER"
sudo bash -c "echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"

#USER $USER

sudo mkdir -p "/home/$USER/tools"
sudo chown "${USER}:${USER}" "/home/$USER/tools"

sudo cp "$REPO/pyproject.toml" uv.lock "/home/$USER" && \
sudo chown "${USER}:${USER}" "/home/$USER/pyproject.toml" "/home/$USER/uv.lock"

sudo cp "$REPO/tools/install_python_dependencies.sh" "/home/$USER/tools/"
sudo chown "${USER}:${USER}" "/home/$USER/tools/install_python_dependencies.sh"

VIRTUAL_ENV=/home/$USER/.venv
PATH="$VIRTUAL_ENV/bin:$PATH"
sudo -u "$USER" bash -c 'cd "/home/$USER" && \
    tools/install_python_dependencies.sh && \
    rm -rf tools/ pyproject.toml uv.lock .cache'

sudo git config --global --add safe.directory /tmp/openpilot

#time sudo rsync -a --info=progress2 -m --exclude=/dev -m --exclude=/proc -m --exclude=/sys -m --exclude=/state1 -m --exclude=/diff_output -m --compare-dest=/state1 -m / /diff_output --delete --delete-excluded \
#    && time find /diff_output -type d -empty -exec rmdir -p --ignore-fail-on-non-empty {} + 2>/dev/null || true \
#    && time find /diff_output -type d -empty -exec rmdir -p --ignore-fail-on-non-empty {} + 2>/dev/null || true \
#    && umount /state1

sudo du -sh /old/upper
sudo tar -Izstd -C /old/upper/ -cf /old/tmp/rootfs_cache.tar.zstd /old/upper/
