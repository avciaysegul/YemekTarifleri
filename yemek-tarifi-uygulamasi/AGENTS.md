# AGENTS.md

## Proje

**Mutfakta Bugün**: Wails v2 masaüstü uygulaması.

- Backend: Go (`main.go`, `app.go`)
- Frontend: React + TypeScript + Vite (`frontend/src`)
- Tarif verisi: JSON (`tarifler/tarifler.json`); tarif akışı algoritması: Lua (`lua/tarif_akisi.lua`)
- Diller: Türkçe ve İngilizce

## Dizinler

| Konum | Amaç |
| --- | --- |
| `main.go` | Wails pencere ve gömülü varlık yapılandırması |
| `app.go` | Tarif modelleri, JSON okuma/doğrulama, Lua akış köprüsü, Wails metotları |
| `tarifler/tarifler.json` | Tarif içerikleri ve İngilizce çevirileri |
| `lua/tarif_akisi.lua` | Tarif adımı geçiş, süre, ilerleme ve bitiş algoritması |
| `frontend/src/App.tsx` | Ekranlar, filtreleme, tarif akışı, dil seçimi |
| `frontend/src/App.css` | Stil ve animasyonlar |
| `frontend/wailsjs/`, `frontend/dist/` | Üretilmiş dosyalar; elle düzenlemeyin |

## Komutlar

Proje kökünde çalıştırın:

```powershell
wails dev

Set-Location frontend
npm.cmd run build

Set-Location ..
wails build
```

Bağımlılık değişirse `frontend` içinde `npm install` çalıştırın ve `package-lock.json` dosyasını güncelleyin.

## Tarif veri biçimi

`tarifler/tarifler.json`, benzersiz ve pozitif `id` değerli tariflerden oluşan bir JSON dizisidir:

```json
[
  {
    "id": 1,
    "ad": "Tarif adı",
    "emoji": "🍲",
    "aciklama": "Kısa açıklama",
    "sure": "30 dakika",
    "zorluk": "Kolay",
    "kategori": "Ana Yemekler",
    "malzemeler": ["1 örnek malzeme"],
    "adimlar": [
      { "baslik": "Adım", "aciklama": "Açıklama", "emoji": "🥄", "animasyon": "karistirma", "bekleme": "5 dk" }
    ],
    "ingilizce": {
      "ad": "Recipe name",
      "aciklama": "Short English description",
      "malzemeler": ["1 sample ingredient"],
      "adimlar": [
        { "baslik": "Step", "aciklama": "Description", "emoji": "🥄", "animasyon": "karistirma", "bekleme": "5 min" }
      ]
    }
  }
]
```

- Zorunlu alanlar: `id`, `ad`, `emoji`, `sure`, `zorluk`, en az bir malzeme ve adım.
- Her adımda `baslik` ve `aciklama` gerekir.
- Her tarifte eksiksiz `ingilizce` bölümü olmalıdır; aksi halde İngilizce görünümde Türkçe içerik kalır.
- İngilizce adımlarda `emoji` ve `animasyon` ana tarifle aynı olmalı; süreler `min` veya `hours` ile yazılmalıdır.
- Yeni `animasyon` için `App.tsx` içindeki `varsayilanBekleme` ve CSS eşlemelerini güncelleyin.
- Kategori ekleme/değiştirme, `KategoriFiltresi`, kategori seçenekleri ve `tarifKategorisi` ile birlikte yapılır.

## Uygulama kuralları

- Türkçe metinlerde UTF-8 ve `tr-TR` karşılaştırmalarını koruyun.
- Tüm yeni kullanıcı metinlerini Türkçe ve İngilizce ekleyin.
- Dil tercihi `localStorage` içindeki `uygulama-dili` anahtarında tutulur.
- Seçili tarifi özgün veri olarak saklayın; ekranda `goruntulenecekTarif` ile seçili dile göre gösterin.
- Zorluk görünümü: `Kolay/Orta/Zor` ve `Easy/Medium/Hard`; filtre değerleri Türkçe kalır.
- Popüler aramalar: `Makarna/Çorba/Tatlı/Tavuk` ve `Pasta/Soup/Dessert/Chicken`.
- Erişilebilir düğmeler, `aria-label`, klavye kullanımı ve yeterli kontrast sağlayın.
- Yeni görselleri `frontend/src/assets/` altında, modül importuyla kullanın.
- Go–frontend köprüsü değişirse Wails bağlarını yeniden üretin. Tariflerin dağıtım paketindeki `tarifler` klasöründe kaldığından emin olun.

## Teslim öncesi

1. İlgili `go test ./...` ve/veya `npm.cmd run build` komutunu çalıştırın.
2. Tariflerde ID, zorunlu alanlar, İngilizce bölüm, kategori ve animasyon eşlemelerini kontrol edin.
3. Üretilmiş dosyalarda veya ilgisiz kullanıcı dosyalarında değişiklik bırakmayın.
