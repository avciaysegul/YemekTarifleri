-- Kısır senaryosu
-- Acılık ve ekşilik tercihlerini miktar hesabına dahil eder.
-- Bulgur yeterince yumuşamazsa sıcak su ekleyip dinlendirme döngüsünü tekrarlar.

local en = language == "en"
local function enough(have, required)
  return have and have >= required * 0.95
end

local n = dialog_number({
  title = en and "Servings" or "Kişi sayısı",
  default = 4,
  minimum = 1,
  maximum = 12,
})
local heat = dialog_choice({
  title = en and "Heat" or "Acılık",
  options = {
    { value = "none", label = en and "None" or "Acısız" },
    { value = "medium", label = en and "Medium" or "Orta" },
    { value = "hot", label = en and "Hot" or "Acı" },
  },
})
local tangy = dialog_confirm({ title = en and "Extra tangy?" or "Ekşiliği bol olsun mu?" })
if not n or not heat then
  fail({
    title = en and "Cancelled" or "İptal",
    message = en and "Selections missing." or "Seçimler eksik.",
  })
  return
end
local bulgur = n * 75
local water = bulgur * 0.75
local paste = n * 12
local lemon = n * (tangy and 12 or 7)
local missing = {}
for _, x in ipairs({
  { en and "Fine bulgur (g)" or "İnce bulgur (g)", bulgur },
  { en and "Paste (g)" or "Salça (g)", paste },
  { en and "Lemon juice (ml)" or "Limon suyu (ml)", lemon },
}) do
  local v = dialog_number({
    title = x[1],
    message = string.format(en and "Need %.0f; available?" or "%.0f gerekiyor; elinizde?", x[2]),
    default = x[2],
    minimum = 0,
  })
  if not enough(v, x[2]) then
    table.insert(missing, x[1])
  end
end
if #missing > 0 then
  show_list({ title = en and "Missing" or "Eksikler", items = missing })
  fail({
    title = en and "Cannot prepare" or "Hazırlanamaz",
    message = en and "Ingredients are incomplete." or "Malzemeler eksik.",
  })
  return
end
dialog_ok({
  title = en and "Soak bulgur" or "Bulguru ıslatın",
  message = string.format(
    en and "Pour %.0f ml hot water over %.0f g bulgur and cover."
      or "%.0f g bulgura %.0f ml sıcak su döküp kapatın.",
    water,
    bulgur
  ),
})
show_timer({ title = en and "Rest" or "Dinlendirin", duration = 900 })
local soft = false
while not soft do
  soft = dialog_confirm({
    title = en and "Bulgur check" or "Bulgur kontrolü",
    message = en and "Is the bulgur tender?" or "Bulgur yumuşadı mı?",
  })
  if not soft then
    dialog_ok({
      title = en and "Add water" or "Su ekleyin",
      message = en and "Add two tablespoons hot water."
        or "İki yemek kaşığı sıcak su ekleyin.",
    })
    show_timer({ title = en and "Rest again" or "Tekrar dinlendirin", duration = 300 })
  end
end
progress(en and "Seasoning" or "Soslama", 65)
dialog_ok({
  title = en and "Mix" or "Karıştırın",
  message = string.format(
    en and "Add %.0f g paste, %.0f ml lemon and herbs.%s"
      or "%.0f g salça, %.0f ml limon ve yeşillikleri ekleyin.%s",
    paste,
    lemon,
    heat == "none" and "" or (en and " Add chilli." or " Pul biber ekleyin.")
  ),
})
success({
  title = en and "Kısır is ready" or "Kısır hazır",
  message = en and "Taste once more and serve." or "Son kez tadını kontrol edip servis edin.",
  visual_key = "salad",
})
