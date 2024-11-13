benchmark and performance improvement tool

### Basic Installation
```bash
pip install inspectomat
```

## DEvelopment



## Development Setup

1. Install development dependencies:
```bash
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
pip install -r requirements-dev.txt
```

2. Run tests:
```bash
python -m pytest
```

```bash
pip install -e .
```




Aby zwiększyć efektywność komputera pod kątem uruchamiania dużych modeli LLM jak Llama 3.2 Vision, należy zoptymalizować kilka kluczowych aspektów:

1. Pamięć RAM:
- Minimum 64GB RAM dla modelu 55GB
- Użyj pamięci o wysokiej przepustowości i niskich opóźnieniach (DDR5 jeśli możliwe)
- Włącz XMP w BIOS dla lepszej wydajności RAM
- Skonfiguruj odpowiedni swap (minimum 32GB)

2. GPU:
- Użyj karty z dużą ilością VRAM (minimum 16GB)
- Włącz tryb wydajności w sterowniku
- Zoptymalizuj chłodzenie dla utrzymania wysokiego zegara
- W przypadku NVIDIA włącz CUDA i cuDNN

3. Dysk:
- Użyj szybkiego NVMe SSD dla plików modelu
- Zoptymalizuj system plików (np. ext4 z odpowiednimi opcjami montowania)
- Rozważ osobny dysk dla swap

4. System:
```bash
# Optymalizacja parametrów jądra
sudo sysctl -w vm.swappiness=10
sudo sysctl -w vm.vfs_cache_pressure=50
sudo sysctl -w vm.dirty_ratio=10
sudo sysctl -w vm.dirty_background_ratio=5
```

5. Ollama:
- Użyj najnowszej wersji
- Rozważ parametry uruchomieniowe:
```bash
OLLAMA_CUDA=1 ollama run llama3.2-vision:90b --gpu-layers 35
```

6. Procesy w tle:
- Wyłącz zbędne usługi
- Zamknij niepotrzebne aplikacje
- Monitoruj zużycie zasobów:
```bash
htop
nvidia-smi
```

7. Chłodzenie:
- Zapewnij dobrą wentylację obudowy
- Rozważ podkręcenie wentylatorów
- Monitoruj temperatury CPU/GPU

8. Optymalizacja energii:
```bash
# Dla procesorów Intel
sudo cpupower frequency-set -g performance

# Dla NVIDIA
sudo nvidia-smi --persistence-mode=1
sudo nvidia-smi -pl <maximum power limit>
```




---


Aby zwiększyć efektywność komputera do pracy z dużymi modelami LLM jak Llama 3.2 Vision, należy zoptymalizować kilka kluczowych aspektów:

1. RAM i pamięć wirtualna:
- Zwiększ SWAP (pamięć wirtualną) - minimum 2x rozmiaru modelu, więc około 110GB
- Użyj szybkiego dysku SSD na SWAP
- Konfiguracja w /etc/sysctl.conf:
```bash
vm.swappiness=10
vm.vfs_cache_pressure=50
```

2. GPU:
- Włącz maksymalną wydajność karty:
```bash
sudo nvidia-smi -pm 1
sudo nvidia-smi --auto-boost-default=0
sudo nvidia-smi -ac 3615,1530  # Przykładowe wartości, dostosuj do swojej karty
```
- Monitoruj temperaturę i wykorzystanie:
```bash
watch -n 1 nvidia-smi
```

3. CPU:
- Ustaw governor na performance:
```bash
sudo cpupower frequency-set -g performance
```
- Wyłącz hyperthreading jeśli nie jest potrzebny:
```bash
echo off | sudo tee /sys/devices/system/cpu/smt/control
```

4. Optymalizacja Ollama:
- Użyj flag kompilacji dla swojej architektury
- Zwiększ limit pamięci dla procesu:
```bash
ulimit -v unlimited
```
- Dodaj do ~/.bashrc lub ~/.zshrc:
```bash
export CUDA_VISIBLE_DEVICES=0  # Jeśli masz więcej GPU, wybierz najlepszy
export OMP_NUM_THREADS=liczba_rdzeni_cpu
```

5. System:
- Wyłącz zbędne usługi:
```bash
systemctl disable snapd
systemctl disable packagekit
```
- Zoptymalizuj I/O:
```bash
echo "deadline" | sudo tee /sys/block/nvme0n1/queue/scheduler  # dla NVMe
```

6. Monitorowanie:
```bash
htop  # monitor CPU i RAM
nvtop # monitor GPU
```

7. Rozważ użycie kwantyzacji:
- GGUF format z niższą precyzją (np. Q4_K_M)
- Możesz stracić trochę na jakości, ale zyskasz na wydajności

