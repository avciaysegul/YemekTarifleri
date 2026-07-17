# Mutfakta Bugün

**Mutfakta Bugün**, Türkçe ve İngilizce yemek tariflerini adım adım gösteren Wails v2 masaüstü uygulamasıdır.

## Özellikler

* Tarif, kategori, malzeme ve zorluk filtreleme
* Türkçe ve İngilizce dil desteği
* Malzeme kontrol listesi
* Animasyonlu tarif adımları
* Geri, ileri, bekleme ve tamamlanma işlemleri

## Kullanılan Teknolojiler

* React ve TypeScript
* Go
* Lua
* Wails v2
* JSON

## Proje Yapısı

```text
tarifler.json → Go → React arayüzü
                  ↓
             Lua akış motoru
```

Tarif bilgileri JSON dosyasından okunur. Go, uygulama katmanını ve Wails bağlantısını yönetir. Lua ise tarif adımlarının ilerleyişini kontrol eder.


```

Yeni tarifler `tarifler/tarifler.json` dosyasına eklenebilir. Her tarifin benzersiz bir `id` değeri, en az bir malzemesi ve bir adımı bulunmalıdır.
