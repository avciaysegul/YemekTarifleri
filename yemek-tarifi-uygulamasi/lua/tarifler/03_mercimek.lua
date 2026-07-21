-- Mercimek çorbası senaryosu
-- Seçilen porsiyon ve kıvama göre mercimek, sebze ve su miktarını hesaplar.
-- Mercimek tamamen yumuşayana kadar ek pişirme süreleri uygular.

local en = language == "en"
local function enough(have, required)
  return have and have >= required * 0.95
end

local n = dialog_number({
  title = en and "Servings" or "Kişi sayısı",
  default = 4,
  minimum = 1,
  maximum = 10,
})
local consistency = dialog_choice({
  title = en and "Consistency" or "Kıvam",
  options = {
    { value = "thick", label = en and "Thick" or "Koyu" },
    { value = "normal", label = en and "Normal" or "Normal" },
    { value = "thin", label = en and "Thin" or "Akışkan" },
  },
})
if not n or not consistency then
  fail({
    title = en and "Cancelled" or "İptal",
    message = en and "Selections missing." or "Seçimler eksik.",
  })
  return
end
local lentils = n * 45
local water = n * (consistency == "thick" and 220 or consistency == "thin" and 320 or 270)
local onion = math.max(1, math.ceil(n / 4))
local carrot = math.max(1, math.ceil(n / 5))
for _, x in ipairs({
  { en and "Lentils (g)" or "Mercimek (g)", lentils },
  { en and "Water (ml)" or "Su (ml)", water },
  { en and "Onion" or "Soğan", onion },
  { en and "Carrot" or "Havuç", carrot },
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
progress(en and "Preparation" or "Hazırlık", 20)
dialog_ok({
  title = en and "Prepare vegetables" or "Sebzeleri hazırlayın",
  message = en and "Chop onion and carrot; rinse lentils."
    or "Soğan ve havucu doğrayın; mercimeği yıkayın.",
})
show_timer({
  title = en and "Sauté" or "Kavurun",
  message = en and "Sauté onion and carrot." or "Soğan ve havucu kavurun.",
  duration = 240,
})
dialog_ok({
  title = en and "Add lentils" or "Mercimeği ekleyin",
  message = string.format(
    en and "Add %.0f g lentils and %.0f ml water." or "%.0f g mercimek ve %.0f ml su ekleyin.",
    lentils,
    water
  ),
})
show_timer({ title = en and "Simmer" or "Kaynatın", duration = 1200 })
local tender = false
while not tender do
  tender = dialog_confirm({
    title = en and "Texture check" or "Yumuşaklık kontrolü",
    message = en and "Are the lentils completely soft?" or "Mercimek tamamen yumuşadı mı?",
  })
  if not tender then
    show_timer({ title = en and "Extra cooking" or "Ek pişirme", duration = 180 })
  end
end
progress(en and "Blend" or "Blenderdan geçirin", 85)
dialog_ok({
  title = en and "Blend safely" or "Dikkatlice karıştırın",
  message = en and "Blend until smooth and adjust with hot water if needed."
    or "Pürüzsüz olana kadar blenderdan geçirin; gerekirse sıcak su ekleyin.",
})
success({
  title = en and "Soup is ready" or "Çorba hazır",
  message = en and "Season and serve." or "Baharatını ayarlayıp servis edin.",
  visual_key = "soup",
})
