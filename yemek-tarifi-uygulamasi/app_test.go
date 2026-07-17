package main

import "testing"

func TestTarifAkisiniCalistir(t *testing.T) {
	app := NewApp()
	tarifler, err := app.TarifleriGetir()
	if err != nil {
		t.Fatalf("tarifler okunamadı: %v", err)
	}
	if len(tarifler) == 0 {
		t.Fatal("test edilecek tarif yok")
	}
	tarif := tarifler[0]

	baslangic, err := app.TarifAkisiniCalistir(tarif.ID, len(tarif.Adimlar), len(tarif.Adimlar)-1, "baslat", "", "")
	if err != nil {
		t.Fatalf("başlatma hatası: %v", err)
	}
	if baslangic.AktifAdim != 0 || baslangic.Tamamlandi || baslangic.Bekleme == "" || baslangic.OncekiAdimVar {
		t.Fatalf("beklenmeyen başlangıç durumu: %#v", baslangic)
	}

	son, err := app.TarifAkisiniCalistir(tarif.ID, len(tarif.Adimlar), len(tarif.Adimlar)-1, "ileri", "", "")
	if err != nil {
		t.Fatalf("ilerletme hatası: %v", err)
	}
	if !son.Tamamlandi || son.AktifAdim != len(tarif.Adimlar)-1 || son.Ilerleme != 100 || !son.IleriTamamlar {
		t.Fatalf("beklenmeyen bitiş durumu: %#v", son)
	}
}
