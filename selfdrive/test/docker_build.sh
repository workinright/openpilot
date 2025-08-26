#!/usr/bin/env bash

REPO="/home/$USER/work/openpilot/openpilot"
ROOTFS_FILE_PATH="/tmp/rootfs_cache.tar"

if [ -f "$ROOTFS_FILE_PATH" ]
then
    echo "restoring rootfs from the native build cache"
    cd /
    sudo tar -xf "$ROOTFS_FILE_PATH"
    cd
    rm "$ROOTFS_FILE_PATH"

    mkdir -p /tmp/openpilot /tmp/scons_cache /tmp/comma_download_cache /tmp/openpilot_cache
    sudo mount --bind "$REPO" /tmp/openpilot
    sudo mount --bind "$REPO/.ci_cache/scons_cache" /tmp/scons_cache || true
    sudo mount --bind "$REPO/.ci_cache/comma_download_cache" /tmp/comma_download_cache || true
    sudo mount --bind "$REPO/.ci_cache/openpilot_cache" /tmp/openpilot_cache || true

    sudo chmod 755 /sys/fs/pstore

    exit 0
else
    echo "no native build cache entry restored, rebuilding"
fi

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
sudo pivot_root . old

PYTHONUNBUFFERED=1

DEBIAN_FRONTEND=noninteractive

mkdir -p /tmp/tools
cp "$REPO/tools/install_ubuntu_dependencies.sh" /tmp/tools/
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

NVIDIA_VISIBLE_DEVICES=all
NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute
QTWEBENGINE_DISABLE_SANDBOX=1

sudo bash -c "dbus-uuidgen > /etc/machine-id"

sudo mkdir -p "/home/$USER/tools"
sudo chown "${USER}:${USER}" "/home/$USER/tools"

sudo cp "$REPO/pyproject.toml" "$REPO/uv.lock" "/home/$USER" && \
sudo chown "${USER}:${USER}" "/home/$USER/pyproject.toml" "/home/$USER/uv.lock"

sudo cp "$REPO/tools/install_python_dependencies.sh" "/home/$USER/tools/"
sudo chown "${USER}:${USER}" "/home/$USER/tools/install_python_dependencies.sh"

export VIRTUAL_ENV=/home/$USER/.venv
PATH="$VIRTUAL_ENV/bin:$PATH"
sudo -u "$USER" bash -c "echo $USER ; export HOME="/home/$USER" ; export VIRTUAL_ENV=/home/$USER/.venv ; export XDG_CONFIG_HOME="/home/$USER/.config" ; env ; cd "/home/$USER" && \
    tools/install_python_dependencies.sh && \
    rm -rf tools/ pyproject.toml uv.lock ; \
    export UV_BIN="/home/$USER/.local/bin"; export PATH="$UV_BIN:$PATH" ; source /home/$USER/.venv/bin/activate"

sudo git config --global --add safe.directory /tmp/openpilot

sudo du -sh /old/upper
sudo rm -rf /old/tmp/rootfs_cache.tar
cd /old/upper
sudo tar -cf /old/tmp/rootfs_cache.tar --exclude old --exclude tmp/rootfs_cache.tar --exclude old/tmp/rootfs_cache.tar .
mkdir -p /tmp/rootfs_cache
sudo mv /old/tmp/rootfs_cache.tar /tmp/rootfs_cache.tar


mkdir -p /tmp/openpilot /tmp/scons_cache /tmp/comma_download_cache /tmp/openpilot_cache
sudo mount --bind "$REPO" /tmp/openpilot
sudo mount --bind "$REPO/.ci_cache/scons_cache" /tmp/scons_cache || true
sudo mount --bind "$REPO/.ci_cache/comma_download_cache" /tmp/comma_download_cache || true
sudo mount --bind "$REPO/.ci_cache/openpilot_cache" /tmp/openpilot_cache || true

sudo chmod 755 /sys/fs/pstore
