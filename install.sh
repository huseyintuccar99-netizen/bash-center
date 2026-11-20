#!/usr/bin/env bash
#
# BASH CONTROL CENTER - Installation Script
#

set -euo pipefail

# Renk tanımlamaları
C_RESET='\033[0m'
C_GREEN='\033[38;5;114m'
C_RED='\033[38;5;203m'
C_BOLD='\033[1m'

echo -e "${C_BOLD}BASH Control Center Kurulumu Başlatılıyor...${C_RESET}"

# Betik dosyasının adı
SCRIPT_NAME="bash-center.sh"
INSTALL_NAME="bash-center"
INSTALL_PATH="/usr/local/bin/$INSTALL_NAME"

# Kaynak dosyanın varlığını kontrol et
if [[ ! -f "$SCRIPT_NAME" ]]; then
    echo -e "${C_RED}Hata: '$SCRIPT_NAME' dosyası bulunamadı! Lütfen projenin ana dizininde olduğunuzdan emin olun.${C_RESET}" >&2
    exit 1
fi

# Root (yönetici) yetkisi kontrolü (/usr/local/bin için genellikle gereklidir)
if [[ $EUID -ne 0 ]]; then
    echo -e "${C_RED}Uyarı: /usr/local/bin dizinine yazmak için yönetici yetkileri gerekebilir.${C_RESET}"
    echo "Lütfen gerektiğinde şifrenizi girin."
    SUDO="sudo"
else
    SUDO=""
fi

# Betiği hedef dizine kopyala ve çalıştırma izni ver
echo -e "Dosyalar kopyalanıyor ve izinler ayarlanıyor..."
$SUDO cp "$SCRIPT_NAME" "$INSTALL_PATH"
$SUDO chmod +x "$INSTALL_PATH"

echo -e "\n${C_GREEN}${C_BOLD}Kurulum Başarıyla Tamamlandı!${C_RESET}"
echo -e "Artık terminalinizde herhangi bir yerden şu komutu yazarak çalıştırabilirsiniz:"
echo -e "  ${C_BOLD}$INSTALL_NAME${C_RESET}\n"
