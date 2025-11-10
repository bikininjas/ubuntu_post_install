#!/bin/bash

################################################################################
# Module 06 - Outils Média
# Description: FFmpeg avec x264, x265, libvpx
################################################################################

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then 
    log_error "Ce script doit être exécuté en tant que root"
    exit 1
fi

log_info "=== Installation des Outils Média ==="

# 1. Installation des dépendances de compilation
log_info "Installation des dépendances..."
apt update
DEBIAN_FRONTEND=noninteractive apt install -y \
    autoconf \
    automake \
    build-essential \
    cmake \
    git-core \
    libass-dev \
    libfreetype6-dev \
    libgnutls28-dev \
    libmp3lame-dev \
    libsdl2-dev \
    libtool \
    libva-dev \
    libvdpau-dev \
    libvorbis-dev \
    libxcb1-dev \
    libxcb-shm0-dev \
    libxcb-xfixes0-dev \
    meson \
    ninja-build \
    pkg-config \
    texinfo \
    wget \
    yasm \
    zlib1g-dev \
    nasm \
    libx264-dev \
    libx265-dev \
    libnuma-dev \
    libvpx-dev \
    libfdk-aac-dev \
    libopus-dev

# 2. Option A: Installation rapide depuis les repositories (recommandé)
log_info "Installation de FFmpeg depuis les repositories Ubuntu..."
DEBIAN_FRONTEND=noninteractive apt install -y ffmpeg

log_info "✓ FFmpeg installé"
ffmpeg -version | head -n1

# Vérification des codecs disponibles
log_info "Vérification des codecs..."
echo ""
echo -e "${YELLOW}Codecs disponibles:${NC}"
ffmpeg -codecs 2>/dev/null | grep -E "(x264|x265|libvpx|aac|opus)" || log_warning "Certains codecs peuvent ne pas être disponibles"

# 3. Installation d'outils supplémentaires
log_info "Installation d'outils média supplémentaires..."
DEBIAN_FRONTEND=noninteractive apt install -y \
    mediainfo \
    imagemagick \
    sox \
    lame \
    flac \
    vorbis-tools

log_info "=== Module Outils Média Terminé ==="
echo ""
echo -e "${GREEN}FFmpeg:${NC} $(ffmpeg -version | head -n1)"
echo -e "${GREEN}MediaInfo:${NC} $(mediainfo --version | head -n1)"
echo ""
echo -e "${YELLOW}Outils installés:${NC}"
echo "  - ffmpeg (encodage vidéo/audio)"
echo "  - mediainfo (informations médias)"
echo "  - imagemagick (traitement images)"
echo "  - sox (traitement audio)"
echo ""
echo -e "${YELLOW}Exemples d'utilisation:${NC}"
echo "  # Convertir vidéo en H.264"
echo "  ffmpeg -i input.mp4 -c:v libx264 -preset medium output.mp4"
echo ""
echo "  # Convertir vidéo en H.265"
echo "  ffmpeg -i input.mp4 -c:v libx265 -preset medium output.mp4"
echo ""
echo "  # Informations sur un fichier média"
echo "  mediainfo video.mp4"
echo ""

exit 0
