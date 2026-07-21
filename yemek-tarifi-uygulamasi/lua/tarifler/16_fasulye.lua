-- Zeytinyağlı taze fasulye senaryosu
-- Porsiyon, yumuşaklık ve servis sıcaklığı tercihlerine göre akışı değiştirir.
-- Fasulye istenen yumuşaklığa gelene kadar pişirme döngüsüne devam eder.

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
local soft = dialog_choice({
  title = en and "Tenderness" or "Yumuşaklık",
  options = {
    { value = "firm", label = en and "Slightly firm" or "Hafif diri" },
    { value = "soft", label = en and "Very tender" or "Yumuşak" },
  },
})
local cold = dialog_confirm({ title = en and "Serve cold?" or "Soğuk servis mi?" })
if not n or not soft then
  fail({
    title = en and "Cancelled" or "İptal",
    message = en and "Selections required." or "Seçimler gerekli.",
  })
  return
end
local beans = n * 140
local tomato = math.ceil(n * 0.5)
local onion = math.max(1, math.ceil(n / 5))
local oil = n * 12
local water = n * 55
for _, x in ipairs({
  { en and "Green beans (g)" or "Taze fasulye (g)", beans },
  { en and "Tomatoes" or "Domates", tomato },
  { en and "Onions" or "Soğan", onion },
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
  title = en and "Trim beans" or "Fasulyeleri ayıklayın",
  message = string.format(
    en and "Wash and trim %.0f g beans." or "%.0f g fasulyeyi yıkayıp ayıklayın.",
    beans
  ),
})
progress(en and "Beans prepared" or "Fasulyeler hazır", 25)
dialog_ok({
  title = en and "Layer pot" or "Tencereye dizin",
  message = string.format(
    en and "Layer onion, beans and %d tomatoes; add %.0f ml oil and %.0f ml water."
      or "Soğan, fasulye ve %d domatesi dizip %.0f ml yağ ve %.0f ml su ekleyin.",
    tomato,
    oil,
    water
  ),
})
show_timer({
  title = en and "Cook covered" or "Kapalı pişirin",
  duration = soft == "soft" and 2100 or 1650,
})
local tender = false
while not tender do
  tender = dialog_confirm({
    title = en and "Bean check" or "Fasulye kontrolü",
    message = en and "Are the beans at your preferred tenderness?"
      or "Fasulyeler istediğiniz yumuşaklıkta mı?",
  })
  if not tender then
    show_timer({ title = en and "Cook longer" or "Biraz daha pişirin", duration = 300 })
  end
end
if cold then
  show_timer({ title = en and "Cool before serving" or "Servis öncesi soğutun", duration = 900 })
end
success({
  title = en and "Green beans are ready" or "Taze fasulye hazır",
  message = cold and (en and "Chill fully before serving." or "Tamamen soğutup servis edin.")
    or (en and "Serve warm." or "Ilık servis edin."),
  visual_key = "beans",
})
