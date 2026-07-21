# Mutfakta Bugün

Wails v2, Go, React ve Lua ile geliştirilmiş etkileşimli yemek tarifi uygulaması.

## Mimari

```text
tarifler/*.json ──► Go ──► React tarif listesi
                    │
                    └──► bağımsız Lua tarifi ⇄ UI komut köprüsü ⇄ React
```

`tarifler` klasöründeki her JSON yalnızca tek tarifin listeleme bilgisini içerir. JSON ve Lua dosyaları aynı taban adıyla otomatik eşleşir (`13_kofte.json` ↔ `13_kofte.lua`). Malzemeler, hesaplamalar, pişirme sırası, kararlar ve döngüler `lua/tarifler` altındaki bağımsız programlardadır.

Go çalışma zamanı Lua'ya `dialog_number`, `dialog_choice`, `dialog_confirm`, `dialog_ok`, `show_list`, `show_timer`, `progress`, `success` ve `fail` fonksiyonlarını sağlar. Bu fonksiyonlar coroutine'i bekletir; React kullanıcı cevabını verdiğinde aynı Lua çalışması kaldığı yerden sürer.

## Geliştirme

```powershell
Set-Location frontend
npm.cmd ci
npm.cmd test
npm.cmd run build
Set-Location ..
go test ./...
wails dev
```

Go–frontend metotları değiştiğinde `wails generate module` çalıştırılmalıdır.
