-- Ev yapımı limonata senaryosu
-- Litre, tatlılık ve ekşilik tercihlerinden limon, şeker ve su miktarını hesaplar.
-- Tat dengesi sağlanana kadar kullanıcı seçimine göre küçük ayarlamalar yapar.

local en = language == "en"
local function enough(have, required)
  return have and have >= required * 0.95
end

local litres = dialog_number({
  title = en and "How many litres?" or "Kaç litre?",
  default = 1,
  minimum = 0.5,
  maximum = 5,
})
local sweet = dialog_choice({
  title = en and "Sweetness" or "Tatlılık",
  options = {
    { value = "light", label = en and "Less sweet" or "Az şekerli" },
    { value = "normal", label = en and "Balanced" or "Dengeli" },
    { value = "sweet", label = en and "Sweet" or "Tatlı" },
  },
})
local tang = dialog_choice({
  title = en and "Tartness" or "Ekşilik",
  options = {
    { value = "mild", label = en and "Mild" or "Hafif" },
    { value = "tangy", label = en and "Tangy" or "Ekşi" },
  },
})
if not litres or not sweet or not tang then
  fail({
    title = en and "Cancelled" or "İptal",
    message = en and "Selections required." or "Seçimler gerekli.",
  })
  return
end
local lemons = math.ceil(litres * (tang == "tangy" and 5 or 3.5))
local sugar = litres * (sweet == "light" and 120 or sweet == "sweet" and 230 or 180)
local water = litres * 1000
for _, x in ipairs({
  { en and "Lemons" or "Limon", lemons },
  { en and "Sugar (g)" or "Şeker (g)", sugar },
  { en and "Water (ml)" or "Su (ml)", water },
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
  title = en and "Prepare lemons" or "Limonları hazırlayın",
  message = string.format(
    en and "Wash %d lemons; grate only the yellow zest and squeeze."
      or "%d limonu yıkayın; yalnız sarı kabuğu rendeleyip suyunu sıkın.",
    lemons
  ),
})
dialog_ok({
  title = en and "Mix" or "Karıştırın",
  message = string.format(
    en and "Rub zest with %.0f g sugar, then add juice and %.0f ml cold water."
      or "Kabuğu %.0f g şekerle ovup limon suyu ve %.0f ml soğuk su ekleyin.",
    sugar,
    water
  ),
})
show_timer({ title = en and "Infuse" or "Dinlendirin", duration = 300 })
local balanced = false
while not balanced do
  balanced = dialog_confirm({
    title = en and "Taste" or "Tadına bakın",
    message = en and "Is the sweet-tart balance right?"
      or "Tatlı-ekşi dengesi istediğiniz gibi mi?",
  })
  if not balanced then
    local fix = dialog_choice({
      title = en and "Adjust" or "Ayarlayın",
      options = {
        { value = "water", label = en and "Add water" or "Su ekle" },
        { value = "sugar", label = en and "Add sugar syrup" or "Şeker şurubu ekle" },
        { value = "lemon", label = en and "Add lemon" or "Limon ekle" },
      },
    })
    dialog_ok({
      title = en and "Adjust gradually" or "Azar azar ayarlayın",
      message = fix == "water" and (en and "Add 100 ml cold water." or "100 ml soğuk su ekleyin.")
        or fix == "sugar" and (en and "Add a little dissolved sugar." or "Biraz eritilmiş şeker ekleyin.")
        or (en and "Add a little lemon juice." or "Biraz limon suyu ekleyin."),
    })
  end
end
success({
  title = en and "Lemonade is ready" or "Limonata hazır",
  message = en and "Strain, add ice and serve." or "Süzüp buzla servis edin.",
  visual_key = "lemon",
})
