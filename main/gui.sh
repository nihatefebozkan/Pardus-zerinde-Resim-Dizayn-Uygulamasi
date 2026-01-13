#!/bin/bash

# ImageMagick GUI Arayüzü - YAD ile
# Proje: Resim İşleme Aracı

# Bağımlılık kontrolü
check_dependencies() {
    if ! command -v yad &> /dev/null; then
        yad --error --text="YAD kurulu değil!\nsudo apt install yad"
        exit 1
    fi
    
    if ! command -v convert &> /dev/null; then
        yad --error --text="ImageMagick kurulu değil!\nsudo apt install imagemagick"
        exit 1
    fi
}

# Ana menü
main_menu() {
    local choice=$(yad --list \
        --title="Resim İşleme Aracı" \
        --text="İşlem seçiniz:" \
        --column="İşlem" \
        --column="Açıklama" \
        --width=500 --height=400 \
        --button="Çıkış:1" \
        --button="Seç:0" \
        "Boyutlandır" "Resim boyutunu değiştir" \
        "Format Dönüştür" "Resim formatını değiştir (jpg/png/gif)" \
        "Döndür" "Resmi döndür (90/180/270)" \
        "Efekt Ekle" "Blur, sharpen vb. efektler" \
        "Toplu İşlem" "Klasördeki tüm resimleri işle")
    
    # Çıkış butonuna basılırsa
    if [ $? -eq 1 ]; then
        return 1
    fi
    
    case "$choice" in
        *"Boyutlandır"*) resize_image ;;
        *"Format Dönüştür"*) convert_format ;;
        *"Döndür"*) rotate_image ;;
        *"Efekt Ekle"*) apply_effect ;;
        *"Toplu İşlem"*) batch_process ;;
    esac
    return 0
}

# Fonksiyonlar artık main_menu çağırmıyor, sadece return ediyor

resize_image() {
    local file=$(yad --file --title="Resim Seçin")
    [ -z "$file" ] && return

    local params=$(yad --form \
        --title="Boyutlandırma Ayarları" \
        --field="Genişlik:NUM" "800!100..4000!1" \
        --field="Yükseklik:NUM" "600!100..4000!1" \
        --field="Oran Koru:CHK" "TRUE" \
        --button="İptal:1" \
        --button="Uygula:0")
    
    [ $? -ne 0 ] && return

    local width=$(echo $params | cut -d'|' -f1 | cut -d',' -f1)
    local height=$(echo $params | cut -d'|' -f2 | cut -d',' -f1)
    local keep_ratio=$(echo $params | cut -d'|' -f3)

    # Kullanıcıdan kaydetme yeri ve isim al
local save_path=$(yad --file --save --confirm-overwrite \
    --title="Kaydedilecek Dosya" \
    --filename="${file%.*}_resized.${file##*.}" \
    --file-filter="Resim dosyaları | *.jpg *.png *.gif *.bmp *.webp")

[ -z "$save_path" ] && return  # Eğer kullanıcı iptal ederse

# Convert işlemi
if [ "$keep_ratio" = "TRUE" ]; then
    convert "$file" -resize "${width}x${height}" "$save_path"
else
    convert "$file" -resize "${width}x${height}!" "$save_path"
fi

yad --info --text="İşlem tamamlandı!\n\nKaydedildi: $save_path"

}

convert_format() {
    local file=$(yad --file --title="Resim Seçin")
    [ -z "$file" ] && return

    local format=$(yad --form \
        --title="Format Seçin" \
        --field="Çıktı Formatı:CB" "jpg!png!gif!bmp!webp" \
        --button="İptal:1" \
        --button="Dönüştür:0")
    
    [ $? -ne 0 ] && return

    local new_format=$(echo $format | cut -d'|' -f1)
    # Kullanıcıdan kaydetme yeri ve isim al
local output=$(yad --file --save --confirm-overwrite \
    --title="Kaydedilecek Dosya" \
    --filename="${file%.*}.$new_format" \
    --file-filter="Resim dosyaları | *.$new_format")

[ -z "$output" ] && return  # İptal edilirse işlemi durdur
    
    convert "$file" "$output"
    
    yad --info --text="Dönüştürme başarılı!\n\nKaydedildi: $output"
}

rotate_image() {
    local file=$(yad --file --title="Resim Seçin")
    [ -z "$file" ] && return

    local angle=$(yad --form \
        --title="Döndürme Açısı" \
        --field="Açı:CB" "90!180!270!Özel" \
        --field="Özel Açı (0-360):NUM" "45!0..360!1" \
        --button="İptal:1" \
        --button="Uygula:0")
    
    [ $? -ne 0 ] && return

    local selected=$(echo $angle | cut -d'|' -f1)
    local custom=$(echo $angle | cut -d'|' -f2 | cut -d',' -f1)

    [ "$selected" = "Özel" ] && selected=$custom

    # Kullanıcıdan kaydetme yeri ve isim al
local save_path=$(yad --file --save --confirm-overwrite \
    --title="Kaydedilecek Dosya" \
    --filename="${file%.*}_rotated.${file##*.}" \
    --file-filter="Resim dosyaları | *.jpg *.png *.gif *.bmp *.webp")

[ -z "$save_path" ] && return

# Convert işlemi
convert "$file" -rotate "$selected" "$save_path"

yad --info --text="Resim döndürüldü!\n\nKaydedildi: $save_path"

}

apply_effect() {
    local file=$(yad --file --title="Resim Seçin")
    [ -z "$file" ] && return

    local effect=$(yad --list \
        --title="Efekt Seçin" \
        --column="Efekt" \
        --column="Açıklama" \
        --height=300 \
        "blur" "Bulanıklaştırma" \
        "sharpen" "Keskinleştirme" \
        "grayscale" "Siyah-beyaz" \
        "sepia" "Sepya efekti" \
        "negate" "Negatif")
    
    [ -z "$effect" ] && return

    local effect_name=$(echo $effect | cut -d'|' -f1)
    local output="${file%.*}_${effect_name}.${file##*.}"

    # Kullanıcıdan kaydetme yeri ve isim al
local save_path=$(yad --file --save --confirm-overwrite \
    --title="Kaydedilecek Dosya" \
    --filename="${file%.*}_${effect_name}.${file##*.}" \
    --file-filter="Resim dosyaları | *.jpg *.png *.gif *.bmp *.webp")

[ -z "$save_path" ] && return

# Convert işlemi
case "$effect_name" in
    "blur") convert "$file" -blur 0x8 "$save_path" ;;
    "sharpen") convert "$file" -sharpen 0x3 "$save_path" ;;
    "grayscale") convert "$file" -colorspace Gray "$save_path" ;;
    "sepia") convert "$file" -sepia-tone 80% "$save_path" ;;
    "negate") convert "$file" -negate "$save_path" ;;
esac

yad --info --text="Efekt uygulandı!\n\nKaydedildi: $save_path"

}

batch_process() {
    local dir=$(yad --file --directory --title="Klasör Seçin")
    [ -z "$dir" ] && return

    local params=$(yad --form \
        --title="Toplu İşlem Ayarları" \
        --field="İşlem:CB" "Boyutlandır!Format Dönüştür!Efekt Uygula" \
        --field="Genişlik:NUM" "800!100..4000!1" \
        --field="Çıktı Formatı:CB" "jpg!png!gif" \
        --button="İptal:1" \
        --button="Başlat:0")
    
    [ $? -ne 0 ] && return

    local operation=$(echo $params | cut -d'|' -f1)
    local width=$(echo $params | cut -d'|' -f2 | cut -d',' -f1)
    local format=$(echo $params | cut -d'|' -f3)

    local count=0
    for img in "$dir"/*.{jpg,jpeg,png,gif}; do
        [ -f "$img" ] || continue

        case "$operation" in
            "Boyutlandır") convert "$img" -resize "${width}x" "${img%.*}_resized.${img##*.}" ;;
            "Format Dönüştür") convert "$img" "${img%.*}.$format" ;;
            "Efekt Uygula") convert "$img" -colorspace Gray "${img%.*}_gray.${img##*.}" ;;
        esac
        ((count++))
local save_path=$(yad --file --save --confirm-overwrite \
            --title="Kaydedilecek Dosya" \
            --filename="${file%.*}_${operation}_${count}.${file##*.}" \
            --file-filter="Resim dosyaları | *.jpg *.png *.gif *.bmp *.webp")

        [ -z "$save_path" ] && continue  # Eğer kullanıcı iptal ederse bu dosyayı atla

        # Convert işlemi
        case "$operation" in
            "Boyutlandır") convert "$file" -resize "${width}x" "$save_path" ;;
            "Format Dönüştür") convert "$file" "$save_path" ;;
            "Efekt Uygula") convert "$file" -colorspace Gray "$save_path" ;;
        esac

    yad --info --text="Toplu işlem tamamlandı!\n\n$count resim işlendi."
    done

    yad --info --text="Toplu işlem tamamlandı!\n\n$count resim işlendi."
}

# Başlat
check_dependencies

# Menü döngüsü
while true; do
    main_menu
    [ $? -ne 0 ] && break
done
