#!/bin/bash

# Ortak Fonksiyonlar Kütüphanesi
# ImageMagick Arayüzü için yardımcı fonksiyonlar

# Renkli çıktı için ANSI kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Log dosyası
LOG_FILE="$HOME/.imagemagick_gui.log"

# Log fonksiyonu
log_message() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Başarı mesajı
success_msg() {
    echo -e "${GREEN}✓ $1${NC}"
    log_message "SUCCESS" "$1"
}

# Hata mesajı
error_msg() {
    echo -e "${RED}✗ $1${NC}"
    log_message "ERROR" "$1"
}

# Uyarı mesajı
warning_msg() {
    echo -e "${YELLOW}⚠ $1${NC}"
    log_message "WARNING" "$1"
}

# Bilgi mesajı
info_msg() {
    echo -e "${BLUE}ℹ $1${NC}"
    log_message "INFO" "$1"
}

# Dosya var mı kontrol et
check_file_exists() {
    local file="$1"
    if [ ! -f "$file" ]; then
        error_msg "Dosya bulunamadı: $file"
        return 1
    fi
    return 0
}

# Dosya resim mi kontrol et
is_image_file() {
    local file="$1"
    local mime_type=$(file -b --mime-type "$file")
    
    case "$mime_type" in
        image/jpeg|image/png|image/gif|image/bmp|image/webp|image/tiff)
            return 0
            ;;
        *)
            error_msg "Geçersiz resim dosyası: $file"
            return 1
            ;;
    esac
}

# Klasör var mı kontrol et
check_directory_exists() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        error_msg "Klasör bulunamadı: $dir"
        return 1
    fi
    return 0
}

# Yazma izni var mı kontrol et
check_write_permission() {
    local path="$1"
    local dir=$(dirname "$path")
    
    if [ ! -w "$dir" ]; then
        error_msg "Yazma izni yok: $dir"
        return 1
    fi
    return 0
}

# Gerekli araçları kontrol et
check_required_tools() {
    local tools=("$@")
    local missing=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing+=("$tool")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        error_msg "Eksik araçlar: ${missing[*]}"
        info_msg "Kurmak için: sudo apt install ${missing[*]}"
        return 1
    fi
    
    success_msg "Tüm gerekli araçlar mevcut"
    return 0
}

# Resim boyutunu al
get_image_dimensions() {
    local file="$1"
    identify -format "%wx%h" "$file" 2>/dev/null
}

# Resim formatını al
get_image_format() {
    local file="$1"
    identify -format "%m" "$file" 2>/dev/null
}

# Dosya boyutunu al (human-readable)
get_file_size() {
    local file="$1"
    du -h "$file" | cut -f1
}

# Çıktı dosya adı oluştur
generate_output_filename() {
    local input="$1"
    local suffix="$2"
    local extension="$3"
    
    local basename="${input%.*}"
    local original_ext="${input##*.}"
    
    if [ -z "$extension" ]; then
        extension="$original_ext"
    fi
    
    local output="${basename}_${suffix}.${extension}"
    
    # Dosya zaten varsa numara ekle
    local counter=1
    while [ -f "$output" ]; do
        output="${basename}_${suffix}_${counter}.${extension}"
        ((counter++))
    done
    
    echo "$output"
}

# İlerleme çubuğu göster (terminal için)
show_progress() {
    local current=$1
    local total=$2
    local width=50
    
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '='
    printf "%$((width - filled))s" | tr ' ' ' '
    printf "] %d%% (%d/%d)" $percentage $current $total
    
    if [ $current -eq $total ]; then
        echo ""
    fi
}

# Disk alanı kontrolü (MB cinsinden)
check_disk_space() {
    local required_mb=$1
    local available_mb=$(df -BM . | awk 'NR==2 {print $4}' | sed 's/M//')
    
    if [ $available_mb -lt $required_mb ]; then
        error_msg "Yetersiz disk alanı! Gerekli: ${required_mb}MB, Mevcut: ${available_mb}MB"
        return 1
    fi
    return 0
}

# Yedek dosya oluştur
create_backup() {
    local file="$1"
    local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    if cp "$file" "$backup" 2>/dev/null; then
        success_msg "Yedek oluşturuldu: $backup"
        echo "$backup"
        return 0
    else
        error_msg "Yedek oluşturulamadı"
        return 1
    fi
}

# Geçici dosya oluştur
create_temp_file() {
    local prefix="$1"
    mktemp "/tmp/${prefix}_XXXXXX"
}

# Temizlik fonksiyonu
cleanup_temp_files() {
    local pattern="$1"
    rm -f /tmp/${pattern}* 2>/dev/null
    log_message "INFO" "Geçici dosyalar temizlendi: $pattern"
}

# Resim kalitesini optimize et
optimize_image() {
    local input="$1"
    local output="$2"
    local quality="${3:-85}"
    
    convert "$input" -quality "$quality" -strip "$output"
    
    if [ $? -eq 0 ]; then
        local original_size=$(stat -f%z "$input" 2>/dev/null || stat -c%s "$input")
        local new_size=$(stat -f%z "$output" 2>/dev/null || stat -c%s "$output")
        local saved=$((original_size - new_size))
        local percent=$((saved * 100 / original_size))
        
        success_msg "Optimize edildi: %${percent} tasarruf ($saved bytes)"
        return 0
    else
        error_msg "Optimizasyon başarısız"
        return 1
    fi
}

# Toplu işlem için resim listesi al
get_image_list() {
    local dir="$1"
    find "$dir" -maxdepth 1 -type f \( \
        -iname "*.jpg" -o \
        -iname "*.jpeg" -o \
        -iname "*.png" -o \
        -iname "*.gif" -o \
        -iname "*.bmp" -o \
        -iname "*.webp" \
    \) 2>/dev/null
}

# Resim sayısını say
count_images() {
    local dir="$1"
    get_image_list "$dir" | wc -l
}

# Watermark ekle
add_watermark() {
    local input="$1"
    local output="$2"
    local text="$3"
    local position="${4:-SouthEast}"
    
    convert "$input" \
        -gravity "$position" \
        -pointsize 24 \
        -fill white \
        -stroke black \
        -strokewidth 2 \
        -annotate +10+10 "$text" \
        "$output"
}

# Resimleri karşılaştır
compare_images() {
    local img1="$1"
    local img2="$2"
    local output="$3"
    
    compare "$img1" "$img2" "$output" 2>/dev/null
}

# Metadata göster
show_metadata() {
    local file="$1"
    identify -verbose "$file" | grep -E "Format|Geometry|Resolution|Colorspace|Quality"
}

# EXIF verisini temizle
strip_exif() {
    local input="$1"
    local output="$2"
    
    convert "$input" -strip "$output"
}

# Çoklu resmi birleştir (montaj)
create_montage() {
    local output="$1"
    shift
    local images=("$@")
    
    montage "${images[@]}" \
        -tile 2x \
        -geometry +5+5 \
        -background white \
        "$output"
}

# Hata ayıklama modu
enable_debug() {
    set -x
    log_message "DEBUG" "Debug modu aktif"
}

disable_debug() {
    set +x
    log_message "DEBUG" "Debug modu kapalı"
}

# Sistem bilgilerini göster
show_system_info() {
    echo "=== Sistem Bilgileri ==="
    echo "ImageMagick Versiyon: $(convert -version | head -1)"
    echo "İşletim Sistemi: $(uname -s) $(uname -r)"
    echo "Disk Kullanımı: $(df -h . | awk 'NR==2 {print $5}')"
    echo "Bellek Kullanımı: $(free -h | awk 'NR==2 {print $3 "/" $2}')"
    echo "========================"
}

# Konfigurasyon dosyası oluştur
create_config() {
    local config_file="$HOME/.imagemagick_gui.conf"
    
    if [ ! -f "$config_file" ]; then
        cat > "$config_file" << EOF
# ImageMagick GUI Konfigürasyon
DEFAULT_WIDTH=800
DEFAULT_HEIGHT=600
DEFAULT_QUALITY=85
DEFAULT_FORMAT=jpg
BACKUP_ENABLED=true
LOG_ENABLED=true
EOF
        success_msg "Konfigurasyon dosyası oluşturuldu: $config_file"
    fi
}

# Konfigurasyon oku
load_config() {
    local config_file="$HOME/.imagemagick_gui.conf"
    
    if [ -f "$config_file" ]; then
        source "$config_file"
        success_msg "Konfigurasyon yüklendi"
    else
        warning_msg "Konfigurasyon dosyası bulunamadı, varsayılanlar kullanılıyor"
        create_config
    fi
}

# İstatistikleri göster
show_statistics() {
    local dir="$1"
    local total=$(count_images "$dir")
    
    echo "=== Klasör İstatistikleri ==="
    echo "Toplam Resim: $total"
    echo "JPG: $(find "$dir" -iname "*.jpg" -o -iname "*.jpeg" | wc -l)"
    echo "PNG: $(find "$dir" -iname "*.png" | wc -l)"
    echo "GIF: $(find "$dir" -iname "*.gif" | wc -l)"
    echo "Toplam Boyut: $(du -sh "$dir" | cut -f1)"
    echo "============================="
}

# Versiyon bilgisi
show_version() {
    echo "ImageMagick GUI Wrapper v1.0"
    echo "Geliştirici: [Adınız]"
    echo "Proje: Linux Scriptleri Dönem Projesi"
    echo ""
    convert -version | head -3
}

# Yardım menüsü
show_help() {
    cat << EOF
ImageMagick GUI Wrapper - Yardım

Kullanılabilir Fonksiyonlar:
  - Resim Boyutlandırma
  - Format Dönüştürme
  - Döndürme İşlemleri
  - Efekt Uygulama
  - Toplu İşlemler
  - Watermark Ekleme
  - EXIF Temizleme

Daha fazla bilgi için README.md dosyasına bakınız.
EOF
}

# Başlangıç kontrolü
initialize() {
    info_msg "Sistem başlatılıyor..."
    
    # Log dosyası oluştur
    touch "$LOG_FILE" 2>/dev/null
    
    # Gerekli araçları kontrol et
    check_required_tools convert identify montage compare
    
    # Konfigurasyon yükle
    load_config
    
    success_msg "Sistem hazır!"
}

# Export fonksiyonları
export -f log_message
export -f success_msg
export -f error_msg
export -f warning_msg
export -f info_msg
export -f check_file_exists
export -f is_image_file
export -f generate_output_filename