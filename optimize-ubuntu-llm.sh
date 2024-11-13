#!/bin/bash

# Sprawdzenie czy skrypt jest uruchomiony z uprawnieniami root
if [ "$EUID" -ne 0 ]; then
    echo "Proszę uruchomić jako root (sudo)"
    exit 1
fi

echo "Rozpoczynam optymalizację systemu Ubuntu 24.10 pod LLM..."

# Aktualizacja systemu
echo "Aktualizacja systemu..."
apt update && apt upgrade -y

# Instalacja niezbędnych narzędzi
echo "Instalacja narzędzi..."
apt install -y htop nvtop cmake build-essential python3-dev nvidia-cuda-toolkit cpupower-gui

# Konfiguracja SWAP
echo "Konfiguracja SWAP..."
SWAP_SIZE="110G"  # Dla Llama 3.2 Vision
swapoff -a
# Utworzenie pliku SWAP
dd if=/dev/zero of=/swapfile bs=1G count=110
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
# Dodanie do /etc/fstab jeśli nie istnieje
if ! grep -q "/swapfile" /etc/fstab; then
    echo "/swapfile none swap sw 0 0" >> /etc/fstab
fi

# Optymalizacja parametrów kernela
echo "Konfiguracja parametrów systemowych..."
cat > /etc/sysctl.d/99-llm-optimization.conf << EOF
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_ratio=60
vm.dirty_background_ratio=30
net.core.rmem_max=26214400
net.core.wmem_max=26214400
net.ipv4.tcp_rmem=4096 87380 26214400
net.ipv4.tcp_wmem=4096 87380 26214400
EOF

sysctl -p /etc/sysctl.d/99-llm-optimization.conf

# Optymalizacja NVIDIA
echo "Konfiguracja NVIDIA..."
# Włączenie trybu persistenced
nvidia-smi -pm 1
# Wyłączenie auto-boost
nvidia-smi --auto-boost-default=0
# Maksymalne takty (wartości przykładowe - dostosuj do swojej karty)
nvidia-smi -ac 3615,1530

# Konfiguracja CPU
echo "Konfiguracja CPU..."
# Ustawienie governor na performance
for governor in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo "performance" > $governor
done

# Utworzenie skryptu startowego dla Ollama
echo "Tworzenie skryptu startowego dla Ollama..."
cat > /usr/local/bin/run-ollama << EOF
#!/bin/bash
# Ustawienie zmiennych środowiskowych
export CUDA_VISIBLE_DEVICES=0
export OMP_NUM_THREADS=\$(nproc)

# Zwiększenie limitów systemowych
ulimit -n 1048576
ulimit -v unlimited

# Uruchomienie Ollama z odpowiednimi parametrami
exec ollama "\$@"
EOF

chmod +x /usr/local/bin/run-ollama

# Wyłączenie zbędnych usług
echo "Wyłączanie zbędnych usług..."
systemctl disable snapd
systemctl stop snapd
systemctl disable packagekit
systemctl stop packagekit

# Optymalizacja I/O dla dysków
echo "Optymalizacja I/O..."
for disk in $(lsblk -d -o name | grep -v NAME); do
    if [[ $disk == nvme* ]]; then
        echo "deadline" > /sys/block/$disk/queue/scheduler
    fi
done

# Tworzenie skryptu monitorującego
echo "Tworzenie skryptu monitorującego..."
cat > /usr/local/bin/monitor-llm << EOF
#!/bin/bash
tmux new-session -d -s monitor
tmux split-window -h
tmux send-keys -t 0 'htop' C-m
tmux send-keys -t 1 'nvtop' C-m
tmux attach-session -t monitor
EOF

chmod +x /usr/local/bin/monitor-llm

echo "Optymalizacja zakończona. Proszę zrestartować system."
echo "Po restarcie możesz:"
echo "1. Używać 'run-ollama' do uruchamiania Ollama z optymalnymi ustawieniami"
echo "2. Użyć 'monitor-llm' do monitorowania zasobów"
echo "3. Sprawdzić logi systemowe w przypadku problemów: journalctl -xe"