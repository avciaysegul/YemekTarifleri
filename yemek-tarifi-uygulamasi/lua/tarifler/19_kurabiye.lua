-- Elmalı kurabiye senaryosu
-- Adet, boyut ve tarçın tercihinden hamur, iç harç ve tepsi sayısını hesaplar.
-- Her tepsiyi ayrı pişirir ve kenarların kızarmasını kontrol eder.

local en = language == "en"
local function enough(have, required)
  return have and have >= required * 0.95
end

local count = dialog_number({
  title = en and "Cookie count" or "Kurabiye adedi",
  default = 18,
  minimum = 6,
  maximum = 40,
})
local size = dialog_choice({
  title = en and "Size" or "Boyut",
  options = {
    { value = "small", label = en and "Small" or "Küçük" },
    { value = "medium", label = en and "Medium" or "Orta" },
    { value = "large", label = en and "Large" or "Büyük" },
  },
})
local cinnamon = dialog_confirm({ title = en and "Extra cinnamon?" or "Tarçını bol olsun mu?" })
if not count or not size then
  fail({
    title = en and "Cancelled" or "İptal",
    message = en and "Selections required." or "Seçimler gerekli.",
  })
  return
end
count = math.floor(count)
local f = size == "small" and 0.75 or size == "large" and 1.35 or 1
local flour = count * 17 * f
local butter = count * 7 * f
local apple = math.max(1, math.ceil(count / 8))
local sugar = count * 3
local trays = math.ceil(count / 12)
for _, x in ipairs({
  { en and "Flour (g)" or "Un (g)", flour },
  { en and "Butter (g)" or "Tereyağı (g)", butter },
  { en and "Apples" or "Elma", apple },
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
  title = en and "Apple filling" or "Elmalı harç",
  message = string.format(
    en and "Cook %d grated apples with %.0f g sugar%s."
      or "%d rendelenmiş elmayı %.0f g şekerle%s pişirin.",
    apple,
    sugar,
    cinnamon and (en and " and extra cinnamon" or " ve bol tarçınla") or ""
  ),
})
show_timer({ title = en and "Cook filling" or "Harcı pişirin", duration = 480 })
dialog_ok({
  title = en and "Make dough" or "Hamuru hazırlayın",
  message = string.format(
    en and "Knead %.0f g flour with %.0f g butter, egg and powdered sugar."
      or "%.0f g unu %.0f g tereyağı, yumurta ve pudra şekeriyle yoğurun.",
    flour,
    butter
  ),
})
show_timer({ title = en and "Rest dough" or "Hamuru dinlendirin", duration = 300 })
for tray = 1, trays do
  dialog_ok({
    title = string.format(en and "Tray %d/%d" or "Tepsi %d/%d", tray, trays),
    message = en and "Fill, shape and arrange evenly."
      or "İçini doldurup şekillendirin ve eşit dizin.",
  })
  show_timer({
    title = en and "Bake at 180°C" or "180°C'de pişirin",
    duration = size == "large" and 1500 or size == "small" and 960 or 1200,
  })
  local golden = dialog_confirm({
    title = en and "Bake check" or "Pişme kontrolü",
    message = en and "Are the edges lightly golden?" or "Kenarlar hafif kızardı mı?",
  })
  if not golden then
    show_timer({ title = en and "Bake longer" or "Biraz daha pişirin", duration = 180 })
  end
  progress(en and "Baking trays" or "Tepsiler pişiyor", 20 + (tray / trays) * 75)
end
success({
  title = en and "Apple cookies are ready" or "Elmalı kurabiyeler hazır",
  message = en and "Cool before dusting with sugar." or "Pudra şekeri serpmeden önce soğutun.",
  visual_key = "cookie",
})
