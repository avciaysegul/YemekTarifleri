-- Tarif akış motoru. Bu dosya veri deposu değildir; gerçek tarif adımlarını
-- girdi olarak alır ve geçiş, bekleme, ilerleme ve bitiş kararlarını üretir.
local varsayilan_beklemeler = {
  dograma = "2 dk", tava = "4 dk", ekleme = "1 dk", yumurta = "3 dk",
  pisirme = "8 dk", kaynama = "10 dk", karistirma = "5 dk", tamamlandi = "1 dk"
}

local function tam_sayi(deger, ad)
  if type(deger) ~= "number" or deger % 1 ~= 0 then
    error(ad .. " tam sayı olmalıdır")
  end
end

function tarif_akisini_calistir(girdi)
  if type(girdi) ~= "table" then error("tarif girdisi tablo olmalıdır") end
  tam_sayi(girdi.tarif_id, "tarif_id")
  tam_sayi(girdi.adim_sayisi, "adim_sayisi")
  tam_sayi(girdi.mevcut_adim, "mevcut_adim")
  if girdi.adim_sayisi < 1 then error("tarif en az bir adıma sahip olmalıdır") end
  if type(girdi.adimlar) ~= "table" or #girdi.adimlar ~= girdi.adim_sayisi then
    error("tarif adımları eksik veya tutarsız")
  end

  local aktif_adim = math.max(0, math.min(girdi.mevcut_adim, girdi.adim_sayisi - 1))
  local tamamlandi = false

  if girdi.komut == "baslat" then
    aktif_adim = 0
  elseif girdi.komut == "ileri" then
    if aktif_adim == girdi.adim_sayisi - 1 then
      tamamlandi = true
    else
      aktif_adim = aktif_adim + 1
    end
  elseif girdi.komut == "geri" then
    aktif_adim = math.max(0, aktif_adim - 1)
  else
    error("bilinmeyen tarif komutu: " .. tostring(girdi.komut))
  end

  -- Komuttan sonra etkin olan adım seçilir. Bekleme bilgisi de önceki
  -- ekrandan değil, bu hedef adımdan türetilir.
  local adim = girdi.adimlar[aktif_adim + 1]
  local bekleme = adim.bekleme
  if type(bekleme) ~= "string" or bekleme == "" then
    bekleme = varsayilan_beklemeler[adim.animasyon] or "2 dk"
  end

  return {
    aktif_adim = aktif_adim,
    ilerleme = ((aktif_adim + 1) / girdi.adim_sayisi) * 100,
    tamamlandi = tamamlandi,
    bekleme = bekleme,
    onceki_adim_var = aktif_adim > 0,
    ileri_tamamlar = aktif_adim == girdi.adim_sayisi - 1
  }
end
