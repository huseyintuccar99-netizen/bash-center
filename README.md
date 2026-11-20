# BASH CONTROL CENTER (v4.2.0)

**Bash Control Center**, harici kütüphanelere (`ncurses`, `dialog`, `whiptail` vb.) ihtiyaç duymadan tamamen saf (pure) Bash ile geliştirilmiş, etkileşimli bir Terminal Kullanıcı Arayüzü (TUI) ve kabuk yönetim aracıdır. Karmaşık Bash komutlarını güvenli bir ortamda test etmenize, kabuk bayraklarını (flags) dinamik olarak yapılandırmanıza ve çıktıları izlemenize olanak tanır.

---

## ✨ Özellikler

* **Sıfır Bağımlılık (Standalone):** Sadece Bash 4.3+ ve standart POSIX/GNU araçları ile çalışır.
* **Dinamik Kabuk Yapılandırması:** `-e` (errexit), `-u` (nounset), `pipefail`, `-x` (xtrace), `--posix`, `-l` (login) ve `-i` (interactive) gibi ayarları menü üzerinden tek tuşla açıp kapatma.
* **Hazır Profiller:** *Default*, *Strict*, *Login* ve *Interactive* modları arasında tek tıkla geçiş.
* **Sözdizimi Doğrulama (Syntax Validation):** Komutları çalıştırmadan önce `bash -n` ile sözdizimi hatalarını denetleme.
* **Ortam ve Argüman Yönetimi:** Çalışma dizinini değiştirme, özel ortam değişkenleri (`ENV`) ekleme/silme ve konumsal argümanlar (`$1`, `$2`...) tanımlama.
* **Zaman Aşımı (Timeout) Koruması:** Sonsuz döngüye giren komutları belirlenen saniye sonunda otomatik olarak sonlandırma.
* **Çıktı Yakalama ve Geçmiş:** `STDOUT` ve `STDERR` çıktılarını ayrı ayrı görüntüleme, çalıştırılan son 100 komutu geçmişten geri çağırma.
* **Dosya Entegrasyonu & Loglama:** Yazılan komutları dosyaya kaydetme/yükleme ve tüm işlemleri `~/.bash_center.log` dosyasına kaydetme.
* **Tema Desteği:** *Default Blue*, *Emerald Green* ve *Cyberpunk* renk temaları arasında geçiş yapabilme.

---

## 📋 Gereksinimler

* **Bash:** Sürüm `4.3` veya üzeri
* **İşletim Sistemi:** Linux, macOS (Homebrew Bash ile) veya WSL
* **Standart Araçlar:** `stty`, `awk`, `mktemp`, `timeout` (GNU coreutils)

---

## 🚀 Kurulum

Projeyi bilgisayarınıza klonlayın ve kurulum betiğini çalıştırarak `bash-center` komutunu sisteminize global olarak ekleyin:

```bash
git clone https://github.com/KULLANICI_ADINIZ/bash-control-center.git
cd bash-control-center
chmod +x install.sh bash-center.sh
./install.sh
```

> **Not:** Kurulum betiği dosyayı `/usr/local/bin/bash-center` dizinine kopyalayacağı için `sudo` şifrenizi isteyebilir.

---

## 💻 Kullanım

Kurulum tamamlandıktan sonra terminalinizde herhangi bir dizindeyken aşağıdaki komutu çalıştırmanız yeterlidir:

```bash
bash-center
```

*(Eğer sistem geneline kurulum yapmadıysanız proje dizininde `./bash-center.sh` komutu ile de doğrudan başlatabilirsiniz.)*

### ⌨️ Klavye Kısayolları

| Tuş | İşlev |
| :--- | :--- |
| **`↑` / `↓`** veya **`J` / `K`** | Menüde yukarı ve aşağı gezinme (Vim tuşları desteklenir) |
| **`Enter`** | Seçili menü öğesini çalıştırma / ayarı değiştirme |
| **`Home` / `End`** | Menünün en başına veya en sonuna gitme |
| **`Q`** | Uygulamadan güvenli çıkış (Terminal ayarlarını sıfırlar) |
| **`Ctrl + C`** | Çalışan komutu durdurma veya uygulamadan çıkma |

---

## 🛠️ Menü Seçenekleri Özeti

* **Command Editor:** Çalıştırılacak Bash komutunu veya tek satırlık betiği düzenler.
* **Syntax Validation:** Girilen komutun sözdizimi açısından geçerli olup olmadığını kontrol eder.
* **Positional Arguments & Environment:** Komuta dışarıdan parametre veya geçici ortam değişkeni aktarır.
* **Save / Load Command:** Hazırladığınız komut şablonlarını diske kaydeder veya mevcut bir dosyadan okur.
* **Toggle Color Theme:** Arayüz renk paletini değiştirir.
* **Execute Command:** Seçili profil ve ayarlarla komutu izole bir alt kabukta (subshell) çalıştırır.

---

## 📄 Lisans

Bu proje açık kaynaklıdır ve **MIT Lisansı** altında dağıtılmaktadır.
