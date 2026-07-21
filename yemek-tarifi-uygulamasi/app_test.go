package main

import (
	"strings"
	"testing"
)

func TestKatalogYirmiIkiBagimsizSenaryoIcerir(t *testing.T) {
	app := NewApp()
	tarifler, err := app.TarifleriGetir()
	if err != nil {
		t.Fatal(err)
	}
	if len(tarifler) != 22 {
		t.Fatalf("22 tarif bekleniyordu, %d bulundu", len(tarifler))
	}
	gorulen := map[string]bool{}
	for _, tarif := range tarifler {
		if gorulen[tarif.Senaryo] {
			t.Fatalf("senaryo tekrar kullaniliyor: %s", tarif.Senaryo)
		}
		gorulen[tarif.Senaryo] = true
	}
}

func TestKisirinIngilizceAdiTurkishKisir(t *testing.T) {
	tarifler, err := NewApp().TarifleriGetir()
	if err != nil {
		t.Fatal(err)
	}
	for _, tarif := range tarifler {
		if tarif.ID == 4 {
			if tarif.Ingilizce.Ad != "Turkish Kısır" {
				t.Fatalf("beklenmeyen Ingilizce ad: %q", tarif.Ingilizce.Ad)
			}
			return
		}
	}
	t.Fatal("kisir katalogda bulunamadi")
}

func TestButunLuaTarifleriBasariyaKadarCalisir(t *testing.T) {
	katalog, err := NewApp().TarifleriGetir()
	if err != nil {
		t.Fatal(err)
	}
	for _, tarif := range katalog {
		tarif := tarif
		t.Run(tarif.Senaryo, func(t *testing.T) {
			app := NewApp()
			g, err := app.SenaryoBaslat(tarif.ID, "tr")
			if err != nil {
				t.Fatal(err)
			}
			for adim := 0; adim < 250 && g.Durum == "waiting"; adim++ {
				if g.Komut == nil {
					t.Fatal("bekleyen senaryoda komut yok")
				}
				cevap := varsayilanCevap(*g.Komut)
				g, err = app.SenaryoCevapla(g.OturumID, g.IstekID, cevap)
				if err != nil {
					t.Fatalf("%s cevabinda: %v", g.Komut.Tur, err)
				}
			}
			if g.Durum != "success" {
				t.Fatalf("senaryo basariyla bitmedi: %#v", g)
			}
		})
	}
}

func TestIngilizceSenaryoVeEskiCevapReddedilir(t *testing.T) {
	app := NewApp()
	g, err := app.SenaryoBaslat(1, "en")
	if err != nil {
		t.Fatal(err)
	}
	if g.Komut == nil || g.Komut.Baslik == "" {
		t.Fatal("ilk Ingilizce komut gelmedi")
	}
	if _, err = app.SenaryoCevapla(g.OturumID, "eski-id", SenaryoCevabi{}); err == nil {
		t.Fatal("eski cevap kabul edildi")
	}
	if err = app.SenaryoIptal(g.OturumID); err != nil {
		t.Fatal(err)
	}
}

func TestIlkAdimlardaIlerlemeSifirdaKalmaz(t *testing.T) {
	app := NewApp()
	g, err := app.SenaryoBaslat(1, "tr")
	if err != nil {
		t.Fatal(err)
	}
	if g.Ilerleme <= 0 {
		t.Fatalf("ilk adim ilerlemesi sifirda kaldi: %v", g.Ilerleme)
	}
	ilk := g.Ilerleme
	iki := 2.0
	g, err = app.SenaryoCevapla(g.OturumID, g.IstekID, SenaryoCevabi{Sayi: &iki})
	if err != nil {
		t.Fatal(err)
	}
	if g.Ilerleme <= ilk {
		t.Fatalf("ikinci adimda ilerleme artmadi: ilk=%v ikinci=%v", ilk, g.Ilerleme)
	}
	_ = app.SenaryoIptal(g.OturumID)
}

func TestAyniAndaIkinciOturumAcilmaz(t *testing.T) {
	app := NewApp()
	g, err := app.SenaryoBaslat(1, "tr")
	if err != nil {
		t.Fatal(err)
	}
	if _, err = app.SenaryoBaslat(2, "tr"); err == nil {
		t.Fatal("ikinci oturum acildi")
	}
	_ = app.SenaryoIptal(g.OturumID)
}

func TestIptalFailIleBiter(t *testing.T) {
	app := NewApp()
	g, err := app.SenaryoBaslat(2, "tr")
	if err != nil {
		t.Fatal(err)
	}
	g, err = app.SenaryoCevapla(g.OturumID, g.IstekID, SenaryoCevabi{Iptal: true})
	if err != nil {
		t.Fatal(err)
	}
	if g.Durum != "fail" {
		t.Fatalf("iptal fail ile bitmedi: %#v", g)
	}
}

func TestCevapSinirlariVeSeceneklerDogrulanir(t *testing.T) {
	app := NewApp()
	g, err := app.SenaryoBaslat(2, "tr")
	if err != nil {
		t.Fatal(err)
	}
	az := 0.0
	if _, err = app.SenaryoCevapla(g.OturumID, g.IstekID, SenaryoCevabi{Sayi: &az}); err == nil {
		t.Fatal("minimum alti sayi kabul edildi")
	}
	iki := 2.0
	g, err = app.SenaryoCevapla(g.OturumID, g.IstekID, SenaryoCevabi{Sayi: &iki})
	if err != nil {
		t.Fatal(err)
	}
	yanlis := "olmayan"
	if _, err = app.SenaryoCevapla(g.OturumID, g.IstekID, SenaryoCevabi{Metin: &yanlis}); err == nil {
		t.Fatal("bilinmeyen secenek kabul edildi")
	}
	_ = app.SenaryoIptal(g.OturumID)
}

func TestMakarnaSuIsitmaSayaciHerTurdanSonraSuyuKontrolEder(t *testing.T) {
	app := NewApp()
	g, err := app.SenaryoBaslat(2, "tr")
	if err != nil {
		t.Fatal(err)
	}

	for adim := 0; adim < 30; adim++ {
		if g.Komut != nil && g.Komut.Tur == "timer" && g.Komut.Baslik == "Su ısınıyor" {
			break
		}
		g, err = app.SenaryoCevapla(g.OturumID, g.IstekID, varsayilanCevap(*g.Komut))
		if err != nil {
			t.Fatal(err)
		}
	}
	if g.Komut == nil || g.Komut.Tur != "timer" || g.Komut.Baslik != "Su ısınıyor" {
		t.Fatalf("su isitma sayacina ulasilamadi: %#v", g)
	}

	g, err = app.SenaryoCevapla(g.OturumID, g.IstekID, SenaryoCevabi{Eylem: "completed"})
	if err != nil {
		t.Fatal(err)
	}
	if g.Komut == nil || g.Komut.Tur != "confirm" || g.Komut.Baslik != "Su kontrolü" {
		t.Fatalf("sayactan sonra su kontrolu gosterilmedi: %#v", g)
	}

	hayir := false
	g, err = app.SenaryoCevapla(g.OturumID, g.IstekID, SenaryoCevabi{Onay: &hayir})
	if err != nil {
		t.Fatal(err)
	}
	if g.Komut == nil || g.Komut.Tur != "timer" || g.Komut.Baslik != "Su ısınıyor" {
		t.Fatalf("su kaynamadi cevabinda yeni sayac acilmadi: %#v", g)
	}

	g, err = app.SenaryoCevapla(g.OturumID, g.IstekID, SenaryoCevabi{Eylem: "completed"})
	if err != nil {
		t.Fatal(err)
	}
	evet := true
	g, err = app.SenaryoCevapla(g.OturumID, g.IstekID, SenaryoCevabi{Onay: &evet})
	if err != nil {
		t.Fatal(err)
	}
	if g.Komut == nil || g.Komut.Baslik != "Makarnayı ekleyin" {
		t.Fatalf("su kaynadi cevabinda sonraki adima gecilmedi: %#v", g)
	}
	_ = app.SenaryoIptal(g.OturumID)
}

func TestMakarnaMalzemesindeYuzdeBesEksikMiktarKabulEdilir(t *testing.T) {
	app := NewApp()
	g, err := app.SenaryoBaslat(2, "tr")
	if err != nil {
		t.Fatal(err)
	}
	for adim := 0; adim < 10; adim++ {
		if g.Komut != nil && g.Komut.Baslik == "Makarna (g)" {
			break
		}
		g, err = app.SenaryoCevapla(g.OturumID, g.IstekID, varsayilanCevap(*g.Komut))
		if err != nil {
			t.Fatal(err)
		}
	}
	if g.Komut == nil || g.Komut.Baslik != "Makarna (g)" {
		t.Fatalf("makarna miktari adimina ulasilamadi: %#v", g)
	}

	// İki kişilik tarif 200 g ister; yüzde 5 toleransla 190 g yeterlidir.
	yuzDoksan := 190.0
	g, err = app.SenaryoCevapla(g.OturumID, g.IstekID, SenaryoCevabi{Sayi: &yuzDoksan})
	if err != nil {
		t.Fatal(err)
	}
	if g.Komut == nil || g.Komut.Baslik != "Domates" {
		t.Fatalf("yuzde bes tolerans kabul edilmedi: %#v", g)
	}
	_ = app.SenaryoIptal(g.OturumID)
}

func TestMakarnaMalzemesindeYuzdeBestenFazlaEksikMiktarReddedilir(t *testing.T) {
	app := NewApp()
	g, err := app.SenaryoBaslat(2, "tr")
	if err != nil {
		t.Fatal(err)
	}
	for adim := 0; adim < 10; adim++ {
		if g.Komut != nil && g.Komut.Baslik == "Makarna (g)" {
			break
		}
		g, err = app.SenaryoCevapla(g.OturumID, g.IstekID, varsayilanCevap(*g.Komut))
		if err != nil {
			t.Fatal(err)
		}
	}
	yuzSeksenDokuz := 189.0
	g, err = app.SenaryoCevapla(g.OturumID, g.IstekID, SenaryoCevabi{Sayi: &yuzSeksenDokuz})
	if err != nil {
		t.Fatal(err)
	}
	for adim := 0; adim < 10 && g.Durum == "waiting"; adim++ {
		if g.Komut == nil {
			t.Fatal("bekleyen senaryoda komut yok")
		}
		g, err = app.SenaryoCevapla(g.OturumID, g.IstekID, varsayilanCevap(*g.Komut))
		if err != nil {
			t.Fatal(err)
		}
	}
	if g.Durum != "fail" {
		t.Fatalf("yuzde besten fazla eksik miktar reddedilmedi: %#v", g)
	}
}

func TestTumTariflerMalzemelerdeYuzdeBesToleranslaTamamlanir(t *testing.T) {
	katalog, err := NewApp().TarifleriGetir()
	if err != nil {
		t.Fatal(err)
	}
	for _, tarif := range katalog {
		tarif := tarif
		t.Run(tarif.Senaryo, func(t *testing.T) {
			app := NewApp()
			g, err := app.SenaryoBaslat(tarif.ID, "tr")
			if err != nil {
				t.Fatal(err)
			}
			for adim := 0; adim < 250 && g.Durum == "waiting"; adim++ {
				if g.Komut == nil {
					t.Fatal("bekleyen senaryoda komut yok")
				}
				cevap := varsayilanCevap(*g.Komut)
				if g.Komut.Tur == "number" && g.Komut.Varsayilan != nil &&
					(strings.Contains(g.Komut.Mesaj, "gerekiyor") || strings.Contains(g.Komut.Mesaj, "Gereken:")) {
					v := *g.Komut.Varsayilan * 0.95
					cevap = SenaryoCevabi{Sayi: &v}
				}
				g, err = app.SenaryoCevapla(g.OturumID, g.IstekID, cevap)
				if err != nil {
					t.Fatalf("%s cevabinda: %v", g.Komut.Tur, err)
				}
			}
			if g.Durum != "success" {
				t.Fatalf("yuzde bes toleransla senaryo tamamlanmadi: %#v", g)
			}
		})
	}
}

func varsayilanCevap(k UIKomutu) SenaryoCevabi {
	switch k.Tur {
	case "number":
		v := 1.0
		if k.Varsayilan != nil {
			v = *k.Varsayilan
		}
		return SenaryoCevabi{Sayi: &v}
	case "choice":
		v := "normal"
		if len(k.Secenekler) > 0 {
			v = k.Secenekler[0].Value
		}
		return SenaryoCevabi{Metin: &v}
	case "confirm":
		v := true
		return SenaryoCevabi{Onay: &v}
	case "timer":
		return SenaryoCevabi{Eylem: "completed"}
	default:
		v := true
		return SenaryoCevabi{Onay: &v}
	}
}
