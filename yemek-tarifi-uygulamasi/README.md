# Mutfakta Bugün

**Mutfakta Bugün**, Türkçe ve İngilizce tarifleri adım adım sunan Wails v2 masaüstü uygulamasıdır. React tabanlı arayüz, Go uygulama katmanı ve Lua ile çalışan tarif akış motorunu birleştirir.

## Özellikler

- Tarif, malzeme, kategori ve zorluk filtreleme
- Türkçe / İngilizce arayüz ve tarif içerikleri
- Malzeme hazırlık kontrol listesi
- Adım bazlı animasyonlu tarif ekranı
- Lua tarafından hesaplanan ilerleme, bekleme, geri/ileri ve tamamlanma durumu

## Mimari

```text
tarifler/tarifler.json ──► Go (app.go) ──► React arayüzü
                                  │
                                  └──► Lua (lua/tarif_akisi.lua) ──► akış durumu
```

### Veri ve algoritma ayrımı

| Katman | Sorumluluk |
| --- | --- |
| `tarifler/tarifler.json` | Tarif başlıkları, açıklamalar, malzemeler, adımlar ve çeviriler |
| `lua/tarif_akisi.lua` | Aktif adım, ilerleme, bekleme süresi, geri/ileri durumu ve bitiş kararı |
| `app.go` | JSON doğrulama, Lua motorunu çalıştırma ve Wails köprüsü |
| `frontend/src/App.tsx` | Lua’nın döndürdüğü durumu kullanıcıya gösterme |

Lua veri kaynağı olarak kullanılmaz. Tarif içerikleri JSON’dan okunur; tarif akışı algoritması Lua’da çalışır.

## Proje yapısı

```text
.
├── app.go                    # Go uygulama katmanı ve Wails metotları
├── app_test.go               # Tarif akışı testleri
├── main.go                   # Wails uygulama başlangıcı
├── lua/
│   └── tarif_akisi.lua       # Lua tarif algoritması
├── tarifler/
│   └── tarifler.json         # Tarif verileri
└── frontend/
    └── src/
        ├── App.tsx           # React arayüzü
        └── App.css           # Stiller ve animasyonlar
```

## Gereksinimler

- Go 1.25 veya üzeri
- Node.js ve npm
- Wails CLI

Wails CLI kurulumu:

```powershell
go install github.com/wailsapp/wails/v2/cmd/wails@latest
```

## Kurulum ve çalıştırma

Proje kök dizininde:

```powershell
wails dev
```

## Test ve derleme

Go testleri:

```powershell
go test ./...
```

Frontend üretim derlemesi:

```powershell
Set-Location frontend
npm.cmd run build
```

Masaüstü üretim paketi:

```powershell
wails build
```

## Tarif verisi ekleme

Yeni tarifleri `tarifler/tarifler.json` içindeki diziye ekleyin. Her tarifin `id` değeri benzersiz ve pozitif olmalıdır.

```json
{
  "id": 23,
  "ad": "Örnek Tarif",
  "emoji": "🍲",
  "aciklama": "Kısa açıklama.",
  "sure": "20 dakika",
  "zorluk": "Kolay",
  "kategori": "Ana Yemekler",
  "malzemeler": ["1 örnek malzeme"],
  "adimlar": [
    {
      "baslik": "Hazırlayın",
      "aciklama": "Malzemeyi hazırlayın.",
      "emoji": "🥄",
      "animasyon": "karistirma",
      "bekleme": "2 dk"
    }
  ],
  "ingilizce": {
    "ad": "Sample Recipe",
    "aciklama": "Short description.",
    "malzemeler": ["1 sample ingredient"],
    "adimlar": [
      {
        "baslik": "Prepare",
        "aciklama": "Prepare the ingredient.",
        "emoji": "🥄",
        "animasyon": "karistirma",
        "bekleme": "2 min"
      }
    ]
  }
}
```

Zorunlu alanlar: `id`, `ad`, `emoji`, `sure`, `zorluk`, en az bir malzeme ve en az bir adımdır. Her adımda `baslik` ve `aciklama` bulunmalıdır.

## Lua akış motoru

Lua fonksiyonu `tarif_akisini_calistir`, komuta göre tarifin sonraki durumunu üretir:

- `baslat`: İlk adıma geçer.
- `ileri`: Sonraki adıma geçer; son adımda tarifi tamamlar.
- `geri`: Önceki adıma geçer.

Fonksiyon ayrıca hedef adımın `bekleme` değerini kullanır. Bu değer yoksa animasyon türüne göre varsayılan bekleme süresini belirler.
