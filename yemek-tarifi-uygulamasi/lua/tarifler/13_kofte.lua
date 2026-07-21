-- Izgara köfte senaryosu
-- Adet, boyut ve pişme tercihinden harç miktarı ile parti sayısını hesaplar.
-- Her partinin içi tamamen pişene kadar ayrı kontrol döngüsü çalıştırır.

local en = language == "en"
local function enough(have, required)
  return have and have >= required * 0.95
end

local count = dialog_number({
  title = en and "Meatball count" or "Köfte adedi",
  default = 12,
  minimum = 4,
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
local well = dialog_confirm({ title = en and "Well cooked?" or "İyi pişmiş olsun mu?" })
if not count or not size then
  fail({
    title = en and "Cancelled" or "İptal",
    message = en and "Count and size required." or "Adet ve boyut gerekli.",
  })
  return
end
count = math.floor(count)
local grams = count * (size == "small" and 28 or size == "large" and 55 or 40)
local onion = math.max(1, math.ceil(grams / 500))
local eggs = math.max(1, math.ceil(grams / 650))
local batches = math.ceil(count / 6)
for _, x in ipairs({
  { en and "Ground beef (g)" or "Kıyma (g)", grams },
  { en and "Onions" or "Soğan", onion },
  { en and "Eggs" or "Yumurta", eggs },
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
  title = en and "Mix" or "Harcı yoğurun",
  message = string.format(
    en and "Knead %.0f g beef with onion, egg, crumbs and seasoning."
      or "%.0f g kıymayı soğan, yumurta, galeta unu ve baharatla yoğurun.",
    grams
  ),
})
show_timer({ title = en and "Rest chilled" or "Soğukta dinlendirin", duration = 900 })
for batch = 1, batches do
  dialog_ok({
    title = string.format(en and "Grill batch %d/%d" or "Parti %d/%d", batch, batches),
    message = en and "Shape evenly and place on the hot grill."
      or "Eşit şekillendirip sıcak ızgaraya yerleştirin.",
  })
  show_timer({
    title = en and "Cook and turn" or "Pişirip çevirin",
    duration = (size == "large" and 600 or 420) + (well and 120 or 0),
  })
  local done = false
  while not done do
    done = dialog_confirm({
      title = en and "Doneness check" or "Pişme kontrolü",
      message = en and "Is the centre fully cooked with no raw meat?"
        or "Ortası tamamen pişmiş ve çiğ et kalmamış mı?",
    })
    if not done then
      show_timer({ title = en and "Cook more" or "Ek pişirme", duration = 120 })
    end
  end
  progress(en and "Grilling" or "Izgara", 20 + (batch / batches) * 75)
end
success({
  title = en and "Meatballs are ready" or "Köfteler hazır",
  message = en and "Serve hot." or "Sıcak servis edin.",
  visual_key = "meatball",
})
