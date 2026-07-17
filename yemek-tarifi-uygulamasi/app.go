package main

import (
	"context"
	_ "embed"
	"encoding/json"
	"fmt"
	"sort"
	"strings"

	lua "github.com/yuin/gopher-lua"
)

//go:embed lua/tarif_akisi.lua
var tarifAkisiKodu string

//go:embed tarifler/tarifler.json
var tarifVerisi []byte

// App, Wails uygulamasının ana yapısıdır.
type App struct {
	ctx context.Context
}

// TarifAdimi, tarifteki tek bir adımı temsil eder.
type TarifAdimi struct {
	Baslik    string `json:"baslik"`
	Aciklama  string `json:"aciklama"`
	Emoji     string `json:"emoji"`
	Animasyon string `json:"animasyon"`
	Bekleme   string `json:"bekleme"`
}

// YemekTarifi, bir yemeğe ait bütün bilgileri tutar.
type YemekTarifi struct {
	ID         int            `json:"id"`
	Ad         string         `json:"ad"`
	Emoji      string         `json:"emoji"`
	Aciklama   string         `json:"aciklama"`
	Sure       string         `json:"sure"`
	Zorluk     string         `json:"zorluk"`
	Kategori   string         `json:"kategori"`
	Malzemeler []string       `json:"malzemeler"`
	Adimlar    []TarifAdimi   `json:"adimlar"`
	Ingilizce  *TarifCevirisi `json:"ingilizce,omitempty"`
}

// TarifCevirisi, tarifin alternatif dildeki metin içeriğini tutar.
// Emoji, animasyon ve süre bilgisi ana tariften paylaşılır.
type TarifCevirisi struct {
	Ad         string       `json:"ad"`
	Aciklama   string       `json:"aciklama"`
	Malzemeler []string     `json:"malzemeler"`
	Adimlar    []TarifAdimi `json:"adimlar"`
}

// TarifAkisiDurumu, Lua tarif motorunun arayüze döndürdüğü anlık durumdur.
// Adım seçimi, ilerleme hesabı ve tamamlanma kararı Lua içinde verilir.
type TarifAkisiDurumu struct {
	AktifAdim     int     `json:"aktifAdim"`
	Ilerleme      float64 `json:"ilerleme"`
	Tamamlandi    bool    `json:"tamamlandi"`
	Bekleme       string  `json:"bekleme"`
	OncekiAdimVar bool    `json:"oncekiAdimVar"`
	IleriTamamlar bool    `json:"ileriTamamlar"`
}

// NewApp, yeni bir App nesnesi oluşturur.
func NewApp() *App {
	return &App{}
}

// startup, uygulama açıldığında çalışır.
func (a *App) startup(ctx context.Context) {
	a.ctx = ctx
}

// TarifleriGetir, tarif içeriklerini JSON veri kaynağından okur.
func (a *App) TarifleriGetir() ([]YemekTarifi, error) {
	var tarifler []YemekTarifi
	if err := json.Unmarshal(tarifVerisi, &tarifler); err != nil {
		return nil, fmt.Errorf("tarif JSON verisi okunamadı: %w", err)
	}
	if len(tarifler) == 0 {
		return nil, fmt.Errorf("tarif JSON verisinde tarif bulunamadı")
	}

	gorulenIDler := make(map[int]bool, len(tarifler))

	for _, tarif := range tarifler {
		if err := tarifDogrula(tarif); err != nil {
			return nil, err
		}
		if gorulenIDler[tarif.ID] {
			return nil, fmt.Errorf(
				"%d numaralı tarif kimliği birden fazla kullanılmış",
				tarif.ID,
			)
		}

		gorulenIDler[tarif.ID] = true
	}

	sort.Slice(
		tarifler,
		func(i, j int) bool {
			return tarifler[i].ID < tarifler[j].ID
		},
	)

	return tarifler, nil
}

// TarifAkisiniCalistir, tarifin bir sonraki durumunu Lua tarif motoruna
// hesaplatır. Arayüz yalnızca bu sonucu görüntüler; akış kararı Go veya
// TypeScript'te verilmez.
func (a *App) TarifAkisiniCalistir(tarifID, adimSayisi, mevcutAdim int, komut, animasyon, bekleme string) (TarifAkisiDurumu, error) {
	if tarifID <= 0 {
		return TarifAkisiDurumu{}, fmt.Errorf("geçersiz tarif kimliği")
	}

	// Akışın girdisi arayüzden gelen görsel bilgi değil, tarifin gerçek
	// adımlarıdır. Böylece hangi adıma geçileceği ve o adımın bekleme süresi
	// Lua tarafından tarifin kendisine göre belirlenir.
	tarifler, err := a.TarifleriGetir()
	if err != nil {
		return TarifAkisiDurumu{}, err
	}

	var tarif *YemekTarifi
	for i := range tarifler {
		if tarifler[i].ID == tarifID {
			tarif = &tarifler[i]
			break
		}
	}
	if tarif == nil {
		return TarifAkisiDurumu{}, fmt.Errorf("%d numaralı tarif bulunamadı", tarifID)
	}
	if adimSayisi != len(tarif.Adimlar) {
		return TarifAkisiDurumu{}, fmt.Errorf("tarif adım sayısı güncel değil")
	}

	luaDurumu := lua.NewState()
	defer luaDurumu.Close()

	if err := luaDurumu.DoString(tarifAkisiKodu); err != nil {
		return TarifAkisiDurumu{}, fmt.Errorf("Lua tarif motoru çalıştırılamadı: %w", err)
	}

	f := luaDurumu.GetGlobal("tarif_akisini_calistir")
	if f.Type() != lua.LTFunction {
		return TarifAkisiDurumu{}, fmt.Errorf("Lua tarif motorunda tarif_akisini_calistir fonksiyonu bulunamadı")
	}

	girdi := luaDurumu.NewTable()
	girdi.RawSetString("tarif_id", lua.LNumber(tarifID))
	girdi.RawSetString("adim_sayisi", lua.LNumber(adimSayisi))
	girdi.RawSetString("mevcut_adim", lua.LNumber(mevcutAdim))
	girdi.RawSetString("komut", lua.LString(komut))
	adimlar := luaDurumu.NewTable()
	for i, adim := range tarif.Adimlar {
		luaAdimi := luaDurumu.NewTable()
		luaAdimi.RawSetString("animasyon", lua.LString(adim.Animasyon))
		luaAdimi.RawSetString("bekleme", lua.LString(adim.Bekleme))
		adimlar.RawSetInt(i+1, luaAdimi)
	}
	girdi.RawSetString("adimlar", adimlar)

	if err := luaDurumu.CallByParam(lua.P{Fn: f, NRet: 1, Protect: true}, girdi); err != nil {
		return TarifAkisiDurumu{}, fmt.Errorf("Lua tarif algoritması çalıştırılamadı: %w", err)
	}
	deger := luaDurumu.Get(-1)
	luaDurumu.Pop(1)
	sonuc, tamam := deger.(*lua.LTable)
	if !tamam {
		return TarifAkisiDurumu{}, fmt.Errorf("Lua tarif algoritması tablo sonucu döndürmelidir")
	}

	return TarifAkisiDurumu{
		AktifAdim:     tablodanIntAl(sonuc, "aktif_adim"),
		Ilerleme:      float64(tablodanSayiAl(sonuc, "ilerleme")),
		Tamamlandi:    lua.LVAsBool(sonuc.RawGetString("tamamlandi")),
		Bekleme:       tablodanMetinAl(sonuc, "bekleme"),
		OncekiAdimVar: lua.LVAsBool(sonuc.RawGetString("onceki_adim_var")),
		IleriTamamlar: lua.LVAsBool(sonuc.RawGetString("ileri_tamamlar")),
	}, nil
}

// tarifDogrula, JSON tarif verisinin arayüz için eksiksiz olduğunu doğrular.
func tarifDogrula(tarif YemekTarifi) error {
	if tarif.ID <= 0 {
		return fmt.Errorf("tarif id bilgisi eksik")
	}
	if strings.TrimSpace(tarif.Ad) == "" || strings.TrimSpace(tarif.Emoji) == "" {
		return fmt.Errorf("%d numaralı tarifin adı veya emojisi eksik", tarif.ID)
	}
	if strings.TrimSpace(tarif.Sure) == "" || strings.TrimSpace(tarif.Zorluk) == "" {
		return fmt.Errorf("%d numaralı tarifin süre veya zorluk bilgisi eksik", tarif.ID)
	}
	if len(tarif.Malzemeler) == 0 || len(tarif.Adimlar) == 0 {
		return fmt.Errorf("%d numaralı tarifin malzemeleri veya adımları eksik", tarif.ID)
	}
	for indeks, adim := range tarif.Adimlar {
		if strings.TrimSpace(adim.Baslik) == "" || strings.TrimSpace(adim.Aciklama) == "" {
			return fmt.Errorf("%d numaralı tarifin %d. adımı eksik", tarif.ID, indeks+1)
		}
	}
	return nil
}

// tablodanMetinAl, Lua algoritması sonucundan metin alır.
func tablodanMetinAl(
	tablo *lua.LTable,
	alan string,
) string {
	deger := tablo.RawGetString(alan)

	metin, tamam := deger.(lua.LString)

	if tamam {
		return string(metin)
	}

	return ""
}

// tablodanIntAl, Lua tablosundan sayı alır.
func tablodanIntAl(
	tablo *lua.LTable,
	alan string,
) int {
	deger := tablo.RawGetString(alan)

	sayi, tamam := deger.(lua.LNumber)

	if tamam {
		return int(sayi)
	}

	return 0
}

func tablodanSayiAl(tablo *lua.LTable, alan string) float64 {
	if sayi, tamam := tablo.RawGetString(alan).(lua.LNumber); tamam {
		return float64(sayi)
	}
	return 0
}
