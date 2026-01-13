## ImageMagick Tabanlı Resim Dizayn Aracı (GUI & TUI)

Bu proje, **ImageMagick** altyapısını kullanarak Linux ortamında temel resim işleme işlemlerini gerçekleştiren bir **Bash Script** uygulamasıdır.  
Uygulama **Pardus GNU/Linux** üzerinde test edilmiştir.

Proje iki farklı kullanım seçeneği sunar:

- **GUI (Grafik Arayüz)** – `gui.sh` (YAD kullanır)
- **TUI (Terminal Arayüz)** – `tui.sh` (Whiptail kullanır)

### Kullanılan teknolojiler :

- Bash Script
- ImageMagick
- YAD (Yet Another Dialog)
- Whiptail
- Pardus GNU/Linux (Debian tabanlı)


# Pardus işletim sistemi
<a href="https://www.oracle.com/tr/virtualization/virtualbox/"> Virtual Box Kurulumu</a>

<a href ="https://pardus.org.tr/"> Pardus Dosyası </a>

### Bu linkleri sırasıyla indirip Virtual box üzerinden sanal makine ile Pardus işletim sistemini çalıştırabilirsiniz.

## Uygulama Kurulumu

Uygulamanın kurulumuna gelirsek öncelikle terminale aşağıdaki kodları yazarak güncelleme ve uygulamada kullanacağımız bileşenleri yüklüyoruz.
```
sudo apt update
sudo apt install imagemagick yad whiptail git -y
```

Uygulamayı aşağıdaki komutları terminale yazarak indiriyoruz.
```
git clone https://github.com/nihatefebozkan/Pardus-Uzerinde-Resim-Dizayn-Uygulamasi.git
cd Pardus-Uzerinde-Resim-Dizayn-Uygulamasi/main
```

Ve son olarak aşağıdaki komutları terminale yazarak dosyalara çalıştırma izni veriyoruz.
```
chmod +x gui.sh tui.sh
```

# KULLANIM KILAVUZU

Kurulum işlemleri bittikten sonra terminale ```./tui.sh``` veya ```./gui.sh``` komutları ile metin (tui) veya görsel (gui) arayüz ile uygulamayı çalıştırabilirsiniz.

## Tui.sh

Terminal üzerinde Imagemagick kullanarak çalışır, Whiptail kütüphanesi ile oluşturulmuştur ve kullanıcıya menü tabanlı bir kullanım sunar. Yön tuşları ile kullanırız.
###  Kullanıcı bu arayüz sayesinde:
####   - Resim formatını dönüştürebilir.
####  - Resim boyutlandırma işlemi yapabilir.
####   - Efekt ve döndürme gibi temel işlemleri uygulayabilir.
####   - Bir klasördeki bütün resimlere üstteki işlemlerin hepsini tek bir tuşla uygulayabilir.

Seçeneklere işlem yapacağınız resmin/dosyanın yolunu yazarak işleme devam edebilirsiniz.
Resmi/Dosyayı seçtikten sonra seçtiğiniz işleme göre resmi/resimleri dizayn edip yeni bir isim vererek istediğiniz yere kaydedebilirsiniz.

Bu mod grafik arayüz gerektirmediği için düşük sistem kaynakları kullanır. Sunucularda ve minimal sistemlerde çalışmaya uygundur.


## Gui.sh

Terminal üzerinde Imagemagick kullanarak çalışır.YAD (Yet Another Dialog) kullanılarak oluşturulmuştur ve kullanıcıya pencere tabanlı, fare ile kontrol edilebilen bir kullanım sunar.
###  Kullanıcı bu arayüz sayesinde:
####   - Resim formatını dönüştürebilir.
####   - Resim boyutlandırma işlemi yapabilir.
####   - Efekt ve döndürme gibi temel işlemleri uygulayabilir.
####   - Bir klasördeki bütün resimlere üstteki işlemlerin hepsini tek bir tuşla uygulayabilir.

Seçeneklere işlem yapacağınız resmi/dosyayı klasörlerinizden seçerek ilerleyebilirsiniz bu size kolaylık sağlar.
Seçilen resim/resimler üzerinde işlem yaparken açılan pencere üzerinde görüntünün TUI'e göre daha iyi olması ve fare kullanımı olması GUI nin daha kullanıcı dostu olmasını sağlıyor.

Bu mod, masaüstü ortamı (XFCE, GNOME vb.) bulunan sistemler için uygundur.

## Function.sh 
Bu dosya, GUI (gui.sh) ve TUI (tui.sh) betiklerinde tekrar eden işlemleri tek bir yerde toplamak amacıyla oluşturulmuştur.

Bu betikler tarafından "source" edilerek kullanılır. (```source function.sh```)

###  Bu dosyada yer alan fonksiyonlar genellikle:
####   - Dosya seçme işlemleri
####   - ImageMagick komutlarının çağrılması
####   - Hata kontrolü
####   - Ortak mesaj ve uyarı pencereleri
####   - Tekrarlayan yardımcı işlemler

###  Not:
Bu dosya doğrudan çalıştırılmamalıdır. ```./function.sh ``` şeklinde çalıştırılması önerilmez.



















