-- Sütlaç senaryosu
-- Kase sayısı ve şeker tercihine göre süt, pirinç, şeker ve nişastayı hesaplar.
-- Pirinç yumuşaklığı ile son kıvamı ayrı kontrol döngülerinde izler.

local en = language == "en"
local function enough(have, required)
  return have and have >= required * 0.95
end

local bowls = dialog_number({
  title = en and "How many bowls?" or "Kaç kase?",
  default = 6,
  minimum = 2,
  maximum = 12,
})
local sweet = dialog_choice({
  title = en and "Sweetness" or "Şeker",
  options = {
    { value = "light", label = en and "Light" or "Az" },
    { value = "normal", label = en and "Normal" or "Normal" },
    { value = "sweet", label = en and "Sweet" or "Tatlı" },
  },
})
if not bowls or not sweet then
  fail({
    title = en and "Cancelled" or "İptal",
    message = en and "Selections required." or "Seçimler gerekli.",
  })
  return
end
local milk = bowls * 170
local rice = bowls * 14
local sugar = bowls * (sweet == "light" and 20 or sweet == "sweet" and 35 or 28)
local starch = bowls * 2.2
for _, x in ipairs({
  { en and "Milk (ml)" or "Süt (ml)", milk },
  { en and "Rice (g)" or "Pirinç (g)", rice },
  { en and "Sugar (g)" or "Şeker (g)", sugar },
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
  title = en and "Cook rice" or "Pirinci pişirin",
  message = string.format(
    en and "Rinse %.0f g rice and cover with water." or "%.0f g pirinci yıkayıp suyla kapatın.",
    rice
  ),
})
show_timer({ title = en and "Boil rice" or "Pirinci haşlayın", duration = 600 })
local tender = false
while not tender do
  tender = dialog_confirm({
    title = en and "Rice check" or "Pirinç kontrolü",
    message = en and "Is the rice tender?" or "Pirinç yumuşadı mı?",
  })
  if not tender then
    show_timer({ title = en and "Cook more" or "Biraz daha pişirin", duration = 120 })
  end
end
dialog_ok({
  title = en and "Add milk" or "Sütü ekleyin",
  message = string.format(
    en and "Add %.0f ml milk and %.0f g sugar." or "%.0f ml süt ve %.0f g şeker ekleyin.",
    milk,
    sugar
  ),
})
show_timer({ title = en and "Simmer" or "Pişirin", duration = 600 })
dialog_ok({
  title = en and "Thicken" or "Kıvam verin",
  message = string.format(
    en and "Dissolve %.0f g starch in cold water and stir in."
      or "%.0f g nişastayı soğuk suyla açıp karıştırın.",
    starch
  ),
})
local thick = false
while not thick do
  show_timer({ title = en and "Stir" or "Karıştırın", duration = 120 })
  thick = dialog_confirm({
    title = en and "Consistency" or "Kıvam",
    message = en and "Does it lightly coat the spoon?" or "Kaşığı hafifçe kaplıyor mu?",
  })
end
success({
  title = en and "Rice pudding is ready" or "Sütlaç hazır",
  message = en and "Divide into bowls and chill." or "Kaselere paylaştırıp soğutun.",
  visual_key = "dessert",
})
