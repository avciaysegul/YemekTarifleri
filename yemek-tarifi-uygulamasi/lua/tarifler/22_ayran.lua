-- Köpüklü ayran senaryosu
-- Bardak sayısı, kıvam ve tuz tercihinden yoğurt, su, tuz ve buz miktarını hesaplar.
-- Belirgin köpük oluşana kadar çırpma döngüsünü sürdürür.

local en = language == "en"
local function enough(have, required)
  return have and have >= required * 0.95
end

local glasses = dialog_number({
  title = en and "Glass count" or "Bardak sayısı",
  default = 2,
  minimum = 1,
  maximum = 10,
})
local texture = dialog_choice({
  title = en and "Texture" or "Kıvam",
  options = {
    { value = "thick", label = en and "Thick" or "Koyu" },
    { value = "normal", label = en and "Normal" or "Normal" },
    { value = "thin", label = en and "Thin" or "Akışkan" },
  },
})
local salty = dialog_confirm({ title = en and "Salty?" or "Tuzlu olsun mu?" })
if not glasses or not texture then
  fail({
    title = en and "Cancelled" or "İptal",
    message = en and "Selections required." or "Seçimler gerekli.",
  })
  return
end
local yogurt = glasses * (texture == "thick" and 140 or texture == "thin" and 80 or 100)
local water = glasses * (texture == "thick" and 100 or texture == "thin" and 170 or 140)
local salt = glasses * (salty and 1.2 or 0.6)
local ice = glasses * 2
for _, x in ipairs({
  { en and "Yoghurt (g)" or "Yoğurt (g)", yogurt },
  { en and "Cold water (ml)" or "Soğuk su (ml)", water },
  { en and "Ice cubes" or "Buz", ice },
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
  title = en and "Combine" or "Birleştirin",
  message = string.format(
    en and "Whisk %.0f g yoghurt with %.0f ml cold water and %.1f g salt."
      or "%.0f g yoğurdu %.0f ml soğuk su ve %.1f g tuzla çırpın.",
    yogurt,
    water,
    salt
  ),
})
show_timer({ title = en and "Whisk" or "Çırpın", duration = 60 })
local foamy = false
while not foamy do
  foamy = dialog_confirm({
    title = en and "Foam check" or "Köpük kontrolü",
    message = en and "Is there a thick foam layer?" or "Üzerinde belirgin köpük var mı?",
  })
  if not foamy then
    show_timer({ title = en and "Whisk again" or "Tekrar çırpın", duration = 30 })
  end
end
local taste = dialog_confirm({
  title = en and "Taste" or "Tadına bakın",
  message = en and "Are salt and texture right?" or "Tuz ve kıvam uygun mu?",
})
if not taste then
  dialog_ok({
    title = en and "Adjust" or "Ayarlayın",
    message = en and "Add water, yoghurt or a pinch of salt, then whisk briefly."
      or "Su, yoğurt veya bir tutam tuz ekleyip kısa çırpın.",
  })
end
success({
  title = en and "Ayran is ready" or "Ayran hazır",
  message = string.format(
    en and "Add %d ice cubes and serve." or "%d buz ekleyip servis edin.",
    ice
  ),
  visual_key = "ayran",
})
