-- Fırında makarna senaryosu
-- Porsiyon, beşamel yoğunluğu ve kızarma tercihine göre bütün miktarları hesaplar.
-- Beşamel pürüzsüzleşene kadar çırpma kontrolünü sürdürür.

local en = language == "en"
local function enough(have, required)
  return have and have >= required * 0.95
end

local n = dialog_number({
  title = en and "Servings" or "Kişi sayısı",
  default = 4,
  minimum = 2,
  maximum = 10,
})
local sauce = dialog_choice({
  title = en and "Béchamel" or "Beşamel kıvamı",
  options = {
    { value = "light", label = en and "Light" or "Hafif" },
    { value = "normal", label = en and "Creamy" or "Kremamsı" },
    { value = "rich", label = en and "Rich" or "Yoğun" },
  },
})
local brown =
  dialog_confirm({ title = en and "Deep golden top?" or "Üzeri iyice kızarsın mı?" })
if not n or not sauce then
  fail({
    title = en and "Cancelled" or "İptal",
    message = en and "Selections required." or "Seçimler gerekli.",
  })
  return
end
local pasta = n * 110
local milk = n * (sauce == "light" and 90 or sauce == "rich" and 140 or 115)
local flour = n * (sauce == "rich" and 10 or 7)
local cheese = n * (brown and 35 or 25)
for _, x in ipairs({
  { en and "Pasta (g)" or "Makarna (g)", pasta },
  { en and "Milk (ml)" or "Süt (ml)", milk },
  { en and "Flour (g)" or "Un (g)", flour },
  { en and "Cheese (g)" or "Kaşar (g)", cheese },
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
  title = en and "Boil pasta" or "Makarnayı haşlayın",
  message = string.format(
    en and "Add %.0f g pasta to boiling salted water."
      or "%.0f g makarnayı kaynar tuzlu suya ekleyin.",
    pasta
  ),
})
show_timer({ title = en and "Par-cook" or "Diri haşlayın", duration = 600 })
dialog_ok({
  title = en and "Make béchamel" or "Beşamel hazırlayın",
  message = string.format(
    en and "Cook butter and %.0f g flour; gradually whisk in %.0f ml milk."
      or "Tereyağı ve %.0f g unu pişirip %.0f ml sütü yavaşça çırpın.",
    flour,
    milk
  ),
})
local smooth = false
while not smooth do
  show_timer({ title = en and "Whisk sauce" or "Sosu çırpın", duration = 120 })
  smooth = dialog_confirm({
    title = en and "Sauce check" or "Sos kontrolü",
    message = en and "Is it smooth and creamy?" or "Pürüzsüz ve kremamsı mı?",
  })
end
dialog_ok({
  title = en and "Assemble" or "Birleştirin",
  message = string.format(
    en and "Combine pasta and sauce; top with %.0f g cheese."
      or "Makarna ve sosu birleştirip %.0f g kaşar serpin.",
    cheese
  ),
})
show_timer({
  title = en and "Bake at 200°C" or "200°C'de fırınlayın",
  duration = brown and 1500 or 1200,
})
success({
  title = en and "Baked pasta is ready" or "Fırında makarna hazır",
  message = en and "Rest five minutes before slicing."
    or "Dilimlemeden önce beş dakika dinlendirin.",
  visual_key = "oven",
})
