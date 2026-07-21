# AGENTS.md

## Proje

**Mutfakta Bugün**: Wails v2 masaüstü uygulaması.

- Backend: Go (`main.go`, `app.go`)
- Frontend: React + TypeScript + Vite (`frontend/src`)
- Tarif metadata dosyaları: `tarifler/*.json`
- Bağımsız tarif programları: `lua/tarifler/*.lua`
- Diller: Türkçe ve İngilizce

## Mimari kurallar

- Her tarifin metadata bilgisi aynı taban adlı ayrı JSON dosyasındadır; `13_kofte.json` otomatik olarak `13_kofte.lua` ile eşleşir.
- JSON yalnızca kimlik, başlık, açıklama, kategori, süre, zorluk ve emoji tutar.
- Malzemeler, hesaplamalar, hazırlama/pişirme sırası, kararlar ve döngüler ilgili Lua tarifinde bulunur.
- Tarifler ortak bir adım motoru, standart ileri/geri akışı veya ortak Lua yardımcı modülü kullanmaz.
- Küçük tekrarlar gerektiğinde yalnızca ilgili tarif dosyasında `local function` tanımlayın.
- Go Lua ortamına `dialog_number`, `dialog_choice`, `dialog_confirm`, `dialog_ok`, `show_list`, `show_timer`, `progress`, `success` ve `fail` sağlar.
- React tarif sırası hesaplamaz; Go'dan gelen UI komutunu gösterip cevabı bekleyen oturum/istek kimliğiyle geri yollar.
- Her yeni kullanıcı metnini Türkçe ve İngilizce ekleyin. Aktif oturum sırasında dil değişmez.
- Yeni görsellerde Lua yalnızca `visual_key` gönderir; frontend bilinen yerel çizime eşler.
- `success()` veya `fail()` her Lua programının terminal çağrısıdır.
- Lua dosyalarını kısa bölüm yorumlarıyla açıklayın ve `stylua.toml` biçimini koruyun.

## Komutlar

```powershell
Set-Location frontend
npm.cmd ci
npm.cmd test
npm.cmd run build
Set-Location ..
wails generate module
go test ./...
wails build
```

Go–frontend köprüsü değiştiğinde Wails bağlarını yeniden üretin. `frontend/wailsjs` ve `frontend/dist` dosyalarını elle düzenlemeyin.

## Teslim öncesi

1. Katalogdaki her senaryo dosyasının bulunduğunu ve kimliklerin benzersiz olduğunu kontrol edin.
2. Bütün Lua tariflerini varsayılan cevap sürücüsüyle `success()` sonucuna kadar test edin.
3. İptal, eksik malzeme, sayaç kapatma, `for` ve `while` yollarını ilgili testlerde doğrulayın.
4. `go test ./...`, `npm.cmd run build` ve `wails build` çalıştırın.
