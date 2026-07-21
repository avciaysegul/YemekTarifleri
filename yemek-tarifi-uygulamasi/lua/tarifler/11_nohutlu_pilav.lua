-- Nohutlu pilav senaryosu
-- Porsiyon ve nohut tercihinden pirinç, su, nohut ve yağ miktarını hesaplar.
-- Pilav suyunu tamamen çekene kadar pişirme kontrolünü tekrarlar.

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
local chickpea = dialog_choice({
  title = en and "Chickpeas" or "Nohut miktarı",
  options = {
    { value = "light", label = en and "A little" or "Az" },
    { value = "normal", label = en and "Normal" or "Normal" },
    { value = "lots", label = en and "Plenty" or "Bol" },
  },
})
if not n or not chickpea then
  fail({
    title = en and "Cancelled" or "İptal",
    message = en and "Selections required." or "Seçimler gerekli.",
  })
  return
end
local rice = n * 70
local water = rice * 1.48
local peas = n * (chickpea == "light" and 30 or chickpea == "lots" and 65 or 45)
local butter = n * 8
for _, x in ipairs({
  { en and "Rice (g)" or "Pirinç (g)", rice },
  { en and "Cooked chickpeas (g)" or "Haşlanmış nohut (g)", peas },
  { en and "Hot water (ml)" or "Sıcak su (ml)", water },
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
  title = en and "Rinse rice" or "Pirinci yıkayın",
  message = en and "Rinse until water runs nearly clear."
    or "Su neredeyse berraklaşana kadar yıkayın.",
})
show_timer({ title = en and "Drain" or "Süzdürün", duration = 300 })
dialog_ok({
  title = en and "Toast rice" or "Pirinci kavurun",
  message = string.format(
    en and "Melt %.0f g butter and add rice." or "%.0f g tereyağını eritip pirinci ekleyin.",
    butter
  ),
})
show_timer({ title = en and "Toast" or "Kavurun", duration = 240 })
dialog_ok({
  title = en and "Cook" or "Pişirin",
  message = string.format(
    en and "Add %.0f g chickpeas and %.0f ml hot water; cover."
      or "%.0f g nohut ve %.0f ml sıcak su ekleyip kapatın.",
    peas,
    water
  ),
})
show_timer({ title = en and "Low heat" or "Kısık ateş", duration = 900 })
local absorbed = false
while not absorbed do
  absorbed = dialog_confirm({
    title = en and "Water check" or "Su kontrolü",
    message = en and "Has the water been absorbed?" or "Suyunu çekti mi?",
  })
  if not absorbed then
    show_timer({ title = en and "Cook longer" or "Biraz daha pişirin", duration = 120 })
  end
end
show_timer({ title = en and "Rest covered" or "Kapalı dinlendirin", duration = 600 })
success({
  title = en and "Pilaf is ready" or "Pilav hazır",
  message = en and "Fluff gently and serve." or "Nazikçe karıştırıp servis edin.",
  visual_key = "rice",
})
