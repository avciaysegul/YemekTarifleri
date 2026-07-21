package main

import (
	"context"
	"crypto/rand"
	"embed"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"sort"
	"strings"
	"sync"
	"time"

	lua "github.com/yuin/gopher-lua"
)

//go:embed tarifler/*.json
var metadataDosyalari embed.FS

//go:embed lua/tarifler/*.lua
var tarifDosyalari embed.FS

type App struct {
	ctx    context.Context
	mu     sync.Mutex
	oturum *senaryoOturumu
}

type TarifCevirisi struct {
	Ad       string `json:"ad"`
	Aciklama string `json:"aciklama"`
}

type TarifOzeti struct {
	ID        int           `json:"id"`
	Ad        string        `json:"ad"`
	Emoji     string        `json:"emoji"`
	Aciklama  string        `json:"aciklama"`
	Sure      string        `json:"sure"`
	Zorluk    string        `json:"zorluk"`
	Kategori  string        `json:"kategori"`
	Senaryo   string        `json:"-"`
	Ingilizce TarifCevirisi `json:"ingilizce"`
}

type SenaryoSecenegi struct {
	Value     string `json:"value"`
	Label     string `json:"label"`
	VisualKey string `json:"visualKey,omitempty"`
}

type UIKomutu struct {
	Tur        string            `json:"tur"`
	Baslik     string            `json:"baslik"`
	Mesaj      string            `json:"mesaj"`
	VisualKey  string            `json:"visualKey,omitempty"`
	OnayMetni  string            `json:"onayMetni,omitempty"`
	IptalMetni string            `json:"iptalMetni,omitempty"`
	Varsayilan *float64          `json:"varsayilan,omitempty"`
	Minimum    *float64          `json:"minimum,omitempty"`
	Maksimum   *float64          `json:"maksimum,omitempty"`
	Sure       int               `json:"sure,omitempty"`
	Secenekler []SenaryoSecenegi `json:"secenekler,omitempty"`
	Ogeler     []string          `json:"ogeler,omitempty"`
}

type SenaryoGuncellemesi struct {
	OturumID       string    `json:"oturumId"`
	IstekID        string    `json:"istekId,omitempty"`
	Durum          string    `json:"durum"`
	Ilerleme       float64   `json:"ilerleme"`
	IlerlemeMesaji string    `json:"ilerlemeMesaji,omitempty"`
	Komut          *UIKomutu `json:"komut,omitempty"`
}

type SenaryoCevabi struct {
	Sayi  *float64 `json:"sayi,omitempty"`
	Metin *string  `json:"metin,omitempty"`
	Onay  *bool    `json:"onay,omitempty"`
	Eylem string   `json:"eylem,omitempty"`
	Iptal bool     `json:"iptal,omitempty"`
}

type senaryoOturumu struct {
	id             string
	l              *lua.LState
	thread         *lua.LState
	fn             *lua.LFunction
	istekSayaci    int
	bekleyenID     string
	bekleyenTur    string
	bekleyenKomut  *UIKomutu
	ilerleme       float64
	ilerlemeMesaji string
}

const uiKoprusu = `
local function ui_yield(kind, options)
  return coroutine.yield({ kind = kind, options = options or {} })
end
function dialog_number(options) return ui_yield("number", options) end
function dialog_choice(options) return ui_yield("choice", options) end
function dialog_confirm(options) return ui_yield("confirm", options) end
function dialog_ok(options) return ui_yield("ok", options) end
function show_list(options) return ui_yield("list", options) end
function show_timer(options) return ui_yield("timer", options) end
function progress(message, percentage) return ui_yield("progress", { message=message, percentage=percentage }) end
function success(options) ui_yield("success", options); error("success() sonrasinda senaryo devam edemez") end
function fail(options) ui_yield("fail", options); error("fail() sonrasinda senaryo devam edemez") end
`

func NewApp() *App                         { return &App{} }
func (a *App) startup(ctx context.Context) { a.ctx = ctx }
func (a *App) shutdown(context.Context)    { a.mu.Lock(); defer a.mu.Unlock(); a.oturumuKapat() }

func (a *App) TarifleriGetir() ([]TarifOzeti, error) {
	dosyalar, err := metadataDosyalari.ReadDir("tarifler")
	if err != nil {
		return nil, fmt.Errorf("tarif metadata klasoru okunamadi: %w", err)
	}

	tarifler := make([]TarifOzeti, 0, len(dosyalar))
	for _, dosya := range dosyalar {
		if dosya.IsDir() || !strings.HasSuffix(dosya.Name(), ".json") {
			continue
		}
		veri, err := metadataDosyalari.ReadFile("tarifler/" + dosya.Name())
		if err != nil {
			return nil, fmt.Errorf("%s okunamadi: %w", dosya.Name(), err)
		}
		var tarif TarifOzeti
		if err := json.Unmarshal(veri, &tarif); err != nil {
			return nil, fmt.Errorf("%s gecersiz JSON: %w", dosya.Name(), err)
		}
		tarif.Senaryo = strings.TrimSuffix(dosya.Name(), ".json") + ".lua"
		tarifler = append(tarifler, tarif)
	}
	gorulen := map[int]bool{}
	for _, tarif := range tarifler {
		if tarif.ID <= 0 || strings.TrimSpace(tarif.Ad) == "" || strings.TrimSpace(tarif.Senaryo) == "" {
			return nil, fmt.Errorf("gecersiz tarif katalog kaydi")
		}
		if gorulen[tarif.ID] {
			return nil, fmt.Errorf("%d numarali tarif birden fazla tanimli", tarif.ID)
		}
		if _, err := tarifDosyalari.ReadFile("lua/tarifler/" + tarif.Senaryo); err != nil {
			return nil, fmt.Errorf("%s senaryosu bulunamadi", tarif.Senaryo)
		}
		gorulen[tarif.ID] = true
	}
	sort.Slice(tarifler, func(i, j int) bool { return tarifler[i].ID < tarifler[j].ID })
	return tarifler, nil
}

func (a *App) SenaryoBaslat(tarifID int, dil string) (SenaryoGuncellemesi, error) {
	a.mu.Lock()
	defer a.mu.Unlock()
	if a.oturum != nil {
		return SenaryoGuncellemesi{}, fmt.Errorf("once calisan tarifi kapatin")
	}
	if dil != "tr" && dil != "en" {
		return SenaryoGuncellemesi{}, fmt.Errorf("desteklenmeyen dil")
	}
	tarifler, err := a.TarifleriGetir()
	if err != nil {
		return SenaryoGuncellemesi{}, err
	}
	var secili *TarifOzeti
	for i := range tarifler {
		if tarifler[i].ID == tarifID {
			secili = &tarifler[i]
			break
		}
	}
	if secili == nil {
		return SenaryoGuncellemesi{}, fmt.Errorf("tarif bulunamadi")
	}
	kod, err := tarifDosyalari.ReadFile("lua/tarifler/" + secili.Senaryo)
	if err != nil {
		return SenaryoGuncellemesi{}, err
	}
	l := lua.NewState()
	if err := l.DoString(uiKoprusu); err != nil {
		l.Close()
		return SenaryoGuncellemesi{}, err
	}
	l.SetGlobal("language", lua.LString(dil))
	fn, err := l.LoadString(string(kod))
	if err != nil {
		l.Close()
		return SenaryoGuncellemesi{}, fmt.Errorf("Lua senaryosu yuklenemedi: %w", err)
	}
	thread, _ := l.NewThread()
	a.oturum = &senaryoOturumu{id: yeniID(), l: l, thread: thread, fn: fn}
	return a.devamEt(nil)
}

func (a *App) SenaryoCevapla(oturumID, istekID string, cevap SenaryoCevabi) (SenaryoGuncellemesi, error) {
	a.mu.Lock()
	defer a.mu.Unlock()
	if a.oturum == nil || a.oturum.id != oturumID {
		return SenaryoGuncellemesi{}, fmt.Errorf("aktif tarif oturumu bulunamadi")
	}
	if a.oturum.bekleyenID != istekID {
		return SenaryoGuncellemesi{}, fmt.Errorf("cevap eski veya baska bir istege ait")
	}
	deger, err := cevabiLuaDegerineCevir(a.oturum.bekleyenTur, a.oturum.bekleyenKomut, cevap)
	if err != nil {
		return SenaryoGuncellemesi{}, err
	}
	a.oturum.bekleyenID, a.oturum.bekleyenTur = "", ""
	a.oturum.bekleyenKomut = nil
	return a.devamEt([]lua.LValue{deger})
}

func (a *App) SenaryoIptal(oturumID string) error {
	a.mu.Lock()
	defer a.mu.Unlock()
	if a.oturum == nil {
		return nil
	}
	if a.oturum.id != oturumID {
		return fmt.Errorf("aktif tarif oturumu eslesmiyor")
	}
	a.oturumuKapat()
	return nil
}

func (a *App) devamEt(args []lua.LValue) (SenaryoGuncellemesi, error) {
	o := a.oturum
	for {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		o.l.SetContext(ctx)
		state, err, values := o.l.Resume(o.thread, o.fn, args...)
		cancel()
		o.l.RemoveContext()
		args = nil
		if err != nil {
			id := o.id
			a.oturumuKapat()
			return SenaryoGuncellemesi{OturumID: id, Durum: "fail"}, fmt.Errorf("Lua senaryosu calistirilamadi: %w", err)
		}
		if state == lua.ResumeOK {
			id := o.id
			a.oturumuKapat()
			return SenaryoGuncellemesi{OturumID: id, Durum: "fail"}, fmt.Errorf("senaryo success() veya fail() ile bitmelidir")
		}
		if len(values) == 0 {
			return SenaryoGuncellemesi{}, fmt.Errorf("Lua UI komutu dondurmedi")
		}
		tablo, ok := values[0].(*lua.LTable)
		if !ok {
			return SenaryoGuncellemesi{}, fmt.Errorf("gecersiz Lua UI komutu")
		}
		tur := lua.LVAsString(tablo.RawGetString("kind"))
		opts, _ := tablo.RawGetString("options").(*lua.LTable)
		if tur == "progress" {
			o.ilerleme = luaNumber(opts, "percentage")
			o.ilerlemeMesaji = luaString(opts, "message")
			args = []lua.LValue{lua.LTrue}
			continue
		}
		komut := luaKomutunaCevir(tur, opts)
		if tur == "success" || tur == "fail" {
			id := o.id
			durum := tur
			ilerleme := o.ilerleme
			mesaj := o.ilerlemeMesaji
			if tur == "success" {
				ilerleme = 100
			}
			a.oturumuKapat()
			return SenaryoGuncellemesi{OturumID: id, Durum: durum, Ilerleme: ilerleme, IlerlemeMesaji: mesaj, Komut: &komut}, nil
		}
		o.istekSayaci++
		o.bekleyenID = fmt.Sprintf("%s-%d", o.id, o.istekSayaci)
		o.bekleyenTur = tur
		o.bekleyenKomut = &komut
		gosterilenIlerleme := o.ilerleme
		// Tarif ilk ilerleme işaretine ulaşmadan önce de kullanıcının akışın
		// başladığını ve adımların ilerlediğini görebilmesini sağla.
		if gosterilenIlerleme == 0 {
			gosterilenIlerleme = float64(o.istekSayaci * 5)
			if gosterilenIlerleme > 15 {
				gosterilenIlerleme = 15
			}
		}
		return SenaryoGuncellemesi{OturumID: o.id, IstekID: o.bekleyenID, Durum: "waiting", Ilerleme: gosterilenIlerleme, IlerlemeMesaji: o.ilerlemeMesaji, Komut: &komut}, nil
	}
}

func luaKomutunaCevir(tur string, t *lua.LTable) UIKomutu {
	k := UIKomutu{Tur: tur}
	if t == nil {
		return k
	}
	k.Baslik = luaString(t, "title")
	k.Mesaj = luaString(t, "message")
	k.VisualKey = luaString(t, "visual_key")
	k.OnayMetni = luaString(t, "confirm_button")
	k.IptalMetni = luaString(t, "cancel_button")
	k.Sure = int(luaNumber(t, "duration"))
	k.Varsayilan = luaOptionalNumber(t, "default")
	k.Minimum = luaOptionalNumber(t, "minimum")
	k.Maksimum = luaOptionalNumber(t, "maximum")
	if options, ok := t.RawGetString("options").(*lua.LTable); ok {
		options.ForEach(func(_, v lua.LValue) {
			if x, ok := v.(*lua.LTable); ok {
				k.Secenekler = append(k.Secenekler, SenaryoSecenegi{Value: luaString(x, "value"), Label: luaString(x, "label"), VisualKey: luaString(x, "visual_key")})
			}
		})
	}
	if items, ok := t.RawGetString("items").(*lua.LTable); ok {
		items.ForEach(func(_, v lua.LValue) { k.Ogeler = append(k.Ogeler, lua.LVAsString(v)) })
	}
	return k
}

func cevabiLuaDegerineCevir(tur string, komut *UIKomutu, c SenaryoCevabi) (lua.LValue, error) {
	if c.Iptal {
		return lua.LNil, nil
	}
	switch tur {
	case "number":
		if c.Sayi == nil {
			return nil, fmt.Errorf("sayisal cevap gerekli")
		}
		if komut != nil && komut.Minimum != nil && *c.Sayi < *komut.Minimum {
			return nil, fmt.Errorf("sayi minimum degerin altinda")
		}
		if komut != nil && komut.Maksimum != nil && *c.Sayi > *komut.Maksimum {
			return nil, fmt.Errorf("sayi maksimum degerin ustunde")
		}
		return lua.LNumber(*c.Sayi), nil
	case "choice":
		if c.Metin == nil {
			return nil, fmt.Errorf("secim cevabi gerekli")
		}
		gecerli := false
		if komut != nil {
			for _, secenek := range komut.Secenekler {
				if secenek.Value == *c.Metin {
					gecerli = true
					break
				}
			}
		}
		if !gecerli {
			return nil, fmt.Errorf("secim sunulan seceneklerden biri degil")
		}
		return lua.LString(*c.Metin), nil
	case "confirm":
		if c.Onay == nil {
			return nil, fmt.Errorf("onay cevabi gerekli")
		}
		return lua.LBool(*c.Onay), nil
	case "timer":
		if c.Eylem != "completed" && c.Eylem != "closed" {
			return nil, fmt.Errorf("gecersiz sayac sonucu")
		}
		return lua.LString(c.Eylem), nil
	case "ok", "list":
		return lua.LTrue, nil
	default:
		return nil, fmt.Errorf("bilinmeyen cevap turu")
	}
}

func (a *App) oturumuKapat() {
	if a.oturum != nil {
		a.oturum.l.Close()
		a.oturum = nil
	}
}
func yeniID() string {
	b := make([]byte, 8)
	if _, e := rand.Read(b); e != nil {
		return "oturum"
	}
	return hex.EncodeToString(b)
}
func luaString(t *lua.LTable, k string) string {
	if t == nil {
		return ""
	}
	return lua.LVAsString(t.RawGetString(k))
}
func luaNumber(t *lua.LTable, k string) float64 {
	if t == nil {
		return 0
	}
	if n, ok := t.RawGetString(k).(lua.LNumber); ok {
		return float64(n)
	}
	return 0
}
func luaOptionalNumber(t *lua.LTable, k string) *float64 {
	if t == nil {
		return nil
	}
	if n, ok := t.RawGetString(k).(lua.LNumber); ok {
		v := float64(n)
		return &v
	}
	return nil
}
