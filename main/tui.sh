#!/bin/bash

# ImageMagick TUI Arayüzü - Whiptail ile
# Proje: Resim İşleme Aracı (Terminal Sürümü)

# Bağımlılık kontrolü
check_dependencies() {
    if ! command -v whiptail &> /dev/null; then
        echo "HATA: Whiptail kurulu değil!"
        echo "Kurmak için: sudo apt install whiptail"
        exit 1
    fi
    
    if ! command -v convert &> /dev/null; then
        whiptail --title "Hata" --msgbox "ImageMagick kurulu değil!\n\nKurmak için: sudo apt install imagemagick" 10 60
        exit 1
    fi
}

# Ana menü
main_menu() {
    local choice=$(whiptail --title "Resim İşleme Aracı" \
        --menu "İşlem seçiniz:" 20 70 6 \
        "1" "Resim Boyutlandır" \
        "2" "Format Dönüştür" \
        "3" "Resmi Döndür" \
        "4" "Efekt Uygula" \
        "5" "Toplu İşlem" \
        "6" "Çıkış" \
        3>&1 1>&2 2>&3)
    
    case $choice in
        1) resize_image ;;
        2) convert_format ;;
        3) rotate_image ;;
        4) apply_effect ;;
        5) batch_process ;;
        6) return 1 ;;   # döngü için break sinyali
        *) return 1 ;;
    esac
    return 0
}

# Resim boyutlandırma
resize_image() {
    local file=$(whiptail --title "Dosya Yolu" \
        --inputbox "Resim dosyasının tam yolunu girin:" 10 60 \
        3>&1 1>&2 2>&3)
    
    if [ -z "$file" ] || [ ! -f "$file" ]; then
        whiptail --title "Hata" --msgbox "Geçersiz dosya yolu!" 8 40
        return
    fi
    
    local width=$(whiptail --title "Genişlik" \
        --inputbox "Yeni genişlik (px):" 10 40 "800" \
        3>&1 1>&2 2>&3)
    
    if [ -z "$width" ]; then
        return
    fi
    
    local output="${file%.*}_resized.${file##*.}"
    
    if convert "$file" -resize "${width}x" "$output" 2>/dev/null; then
        whiptail --title "Başarılı" \
            --msgbox "Resim boyutlandırıldı!\n\nKaydedildi: $output" 10 60
    else
        whiptail --title "Hata" --msgbox "İşlem başarısız!" 8 40
    fi
    return
}

# Format dönüştürme
convert_format() {
    local file=$(whiptail --title "Dosya Yolu" \
        --inputbox "Resim dosyasının tam yolunu girin:" 10 60 \
        3>&1 1>&2 2>&3)
    
    if [ -z "$file" ] || [ ! -f "$file" ]; then
        whiptail --title "Hata" --msgbox "Geçersiz dosya yolu!" 8 40
        return
    fi
    
    local format=$(whiptail --title "Format Seçimi" \
        --menu "Hedef formatı seçin:" 15 50 5 \
        "jpg" "JPEG Format" \
        "png" "PNG Format" \
        "gif" "GIF Format" \
        "bmp" "BMP Format" \
        "webp" "WebP Format" \
        3>&1 1>&2 2>&3)
    
    if [ -z "$format" ]; then
        return
    fi
    
    local output="${file%.*}.$format"
    
    if convert "$file" "$output" 2>/dev/null; then
        whiptail --title "Başarılı" \
            --msgbox "Format dönüştürme tamamlandı!\n\nKaydedildi: $output" 10 60
    else
        whiptail --title "Hata" --msgbox "Dönüştürme başarısız!" 8 40
    fi
    return
}

# Resmi döndürme
rotate_image() {
    local file=$(whiptail --title "Dosya Yolu" \
        --inputbox "Resim dosyasının tam yolunu girin:" 10 60 \
        3>&1 1>&2 2>&3)
    
    if [ -z "$file" ] || [ ! -f "$file" ]; then
        whiptail --title "Hata" --msgbox "Geçersiz dosya yolu!" 8 40
        return
    fi
    
    local angle=$(whiptail --title "Döndürme Açısı" \
        --menu "Açı seçin:" 15 50 4 \
        "90" "90 derece sağa" \
        "180" "180 derece" \
        "270" "270 derece (90 sola)" \
        "custom" "Özel açı gir" \
        3>&1 1>&2 2>&3)
    
    if [ -z "$angle" ]; then
        return
    fi
    
    if [ "$angle" = "custom" ]; then
        angle=$(whiptail --title "Özel Açı" \
            --inputbox "Döndürme açısını girin (0-360):" 10 40 "45" \
            3>&1 1>&2 2>&3)
        
        if [ -z "$angle" ]; then
            return
        fi
    fi
    
    local output="${file%.*}_rotated.${file##*.}"
    
    if convert "$file" -rotate "$angle" "$output" 2>/dev/null; then
        whiptail --title "Başarılı" \
            --msgbox "Resim döndürüldü!\n\nKaydedildi: $output" 10 60
    else
        whiptail --title "Hata" --msgbox "İşlem başarısız!" 8 40
    fi
    return
}

# Efekt uygulama
apply_effect() {
    local file=$(whiptail --title "Dosya Yolu" \
        --inputbox "Resim dosyasının tam yolunu girin:" 10 60 \
        3>&1 1>&2 2>&3)
    
    if [ -z "$file" ] || [ ! -f "$file" ]; then
        whiptail --title "Hata" --msgbox "Geçersiz dosya yolu!" 8 40
        return
    fi
    
    local effect=$(whiptail --title "Efekt Seçimi" \
        --menu "Uygulanacak efekti seçin:" 18 60 6 \
        "blur" "Bulanıklaştırma" \
        "sharpen" "Keskinleştirme" \
        "grayscale" "Siyah-Beyaz" \
        "sepia" "Sepya Tonu" \
        "negate" "Negatif" \
        "edge" "Kenar Algılama" \
        3>&1 1>&2 2>&3)
    
    if [ -z "$effect" ]; then
        return
    fi
    
    local output="${file%.*}_${effect}.${file##*.}"
    
    case "$effect" in
        "blur")
            convert "$file" -blur 0x8 "$output"
            ;;
        "sharpen")
            convert "$file" -sharpen 0x3 "$output"
            ;;
        "grayscale")
            convert "$file" -colorspace Gray "$output"
            ;;
        "sepia")
            convert "$file" -sepia-tone 80% "$output"
            ;;
        "negate")
            convert "$file" -negate "$output"
            ;;
        "edge")
            convert "$file" -edge 1 "$output"
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        whiptail --title "Başarılı" \
            --msgbox "Efekt uygulandı!\n\nKaydedildi: $output" 10 60
    else
        whiptail --title "Hata" --msgbox "İşlem başarısız!" 8 40
    fi
    return
}

# Toplu işlem
batch_process() {
    local dir=$(whiptail --title "Klasör Yolu" \
        --inputbox "Resim klasörünün tam yolunu girin:" 10 60 \
        3>&1 1>&2 2>&3)
    
    if [ -z "$dir" ] || [ ! -d "$dir" ]; then
        whiptail --title "Hata" --msgbox "Geçersiz klasör yolu!" 8 40
        return
    fi
    
    local operation=$(whiptail --title "Toplu İşlem" \
        --menu "İşlem türünü seçin:" 15 60 3 \
        "1" "Tüm resimleri boyutlandır" \
        "2" "Tüm resimleri JPG'ye dönüştür" \
        "3" "Tüm resimlere Grayscale efekti" \
        3>&1 1>&2 2>&3)
    
    if [ -z "$operation" ]; then
        return
    fi
    
    local count=0
    
    case "$operation" in
        "1")
            local width=$(whiptail --inputbox "Hedef genişlik:" 10 40 "800" 3>&1 1>&2 2>&3)
            for img in "$dir"/*.{jpg,jpeg,png,gif}; do
                [ -f "$img" ] || continue
                convert "$img" -resize "${width}x" "${img%.*}_resized.${img##*.}" 2>/dev/null
                ((count++))
            done
            ;;
        "2")
            for img in "$dir"/*.{png,gif,bmp}; do
                [ -f "$img" ] || continue
                convert "$img" "${img%.*}.jpg" 2>/dev/null
                ((count++))
            done
            ;;
        "3")
            for img in "$dir"/*.{jpg,jpeg,png,gif}; do
                [ -f "$img" ] || continue
                convert "$img" -colorspace Gray "${img%.*}_gray.${img##*.}" 2>/dev/null
                ((count++))
            done
            ;;
    esac
    
    whiptail --title "Tamamlandı" \
        --msgbox "Toplu işlem tamamlandı!\n\n$count resim işlendi." 10 50
    return
}

# Başlat
check_dependencies

# Ana döngü
while true; do
    main_menu
    if [ $? -ne 0 ]; then
        break
    fi
done
