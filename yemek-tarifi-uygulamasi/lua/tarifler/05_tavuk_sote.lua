-- Tavuk sote senaryosu
-- Porsiyona göre tavuk ve sebze miktarlarını hesaplar, malzemeleri tek tek doğrular.
-- Tavukta çiğ bölüm kalmayana kadar kontrollü ek pişirme uygular.

local en = language == "en"
local function enough(have, required)
  return have and have >= required * 0.95
end

local n = dialog_number({
  title = en and "Servings" or "Kişi sayısı",
  default = 2,
  minimum = 1,
  maximum = 8,
})
local hot = dialog_confirm({ title = en and "Add chilli?" or "Acı biber eklensin mi?" })
if not n then
  fail({
    title = en and "Cancelled" or "İptal",
    message = en and "Serving count required." or "Kişi sayısı gerekli.",
  })
  return
end
local chicken = n * 180
local onion = math.max(1, math.ceil(n / 3))
local pepper = math.max(1, math.ceil(n * 0.75))
local tomato = math.ceil(n * 0.75)
for _, x in ipairs({
  { en and "Chicken (g)" or "Tavuk (g)", chicken },
  { en and "Onion" or "Soğan", onion },
  { en and "Pepper" or "Biber", pepper },
  { en and "Tomato" or "Domates", tomato },
}) do
  local v = dialog_number({
    title = x[1],
    message = string.format(en and "Need %.0f. Available?" or "%.0f gerekiyor. Elinizde?", x[2]),
    default = x[2],
    minimum = 0,
  })
  if not enough(v, x[2]) then
    fail({ title = en and "Missing ingredient" or "Eksik malzeme", message = x[1] })
    return
  end
end
dialog_ok({
  title = en and "Prepare" or "Hazırlayın",
  message = en and "Use separate boards for raw chicken and vegetables; wash hands and tools."
    or "Çiğ tavuk ve sebzeler için ayrı yüzey kullanın; elleri ve araçları yıkayın.",
  visual_key = "chicken",
})
progress(en and "Prepared" or "Hazırlandı", 20)
show_timer({
  title = en and "Sear chicken" or "Tavuğu mühürleyin",
  message = string.format(
    en and "Cook %.0f g chicken in a hot pan." or "%.0f g tavuğu kızgın tavada pişirin.",
    chicken
  ),
  duration = 360,
})
dialog_ok({
  title = en and "Add vegetables" or "Sebzeleri ekleyin",
  message = string.format(
    en and "Add %d onion, %d peppers and %d tomatoes.%s"
      or "%d soğan, %d biber ve %d domates ekleyin.%s",
    onion,
    pepper,
    tomato,
    hot and (en and " Add chilli." or " Acı biber ekleyin.") or ""
  ),
})
show_timer({ title = en and "Cook together" or "Birlikte pişirin", duration = 600 })
local done = false
while not done do
  done = dialog_confirm({
    title = en and "Doneness check" or "Pişme kontrolü",
    message = en and "Is the chicken opaque throughout with no raw centre?"
      or "Tavuğun içi tamamen opak ve çiğ bölüm kalmamış mı?",
  })
  if not done then
    show_timer({ title = en and "Cook more" or "Biraz daha pişirin", duration = 180 })
  end
end
success({
  title = en and "Chicken sauté is ready" or "Tavuk sote hazır",
  message = en and "Serve hot." or "Sıcak servis edin.",
  visual_key = "chicken",
})
