-- Sebzeli bulgur pilavı senaryosu
-- Porsiyon ve acılık tercihine göre bulgur, su ve sebze miktarlarını belirler.
-- Bulgur suyu çekip yumuşayana kadar kontrollü ek pişirme uygular.

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
local hot = dialog_choice({
  title = en and "Heat" or "Acılık",
  options = {
    { value = "none", label = en and "None" or "Acısız" },
    { value = "mild", label = en and "Mild" or "Hafif" },
    { value = "hot", label = en and "Hot" or "Acı" },
  },
})
if not n or not hot then
  fail({
    title = en and "Cancelled" or "İptal",
    message = en and "Selections required." or "Seçimler gerekli.",
  })
  return
end
local bulgur = n * 70
local water = bulgur * 1.8
local tomato = math.ceil(n / 4)
local pepper = math.ceil(n / 4)
local onion = math.max(1, math.ceil(n / 6))
for _, x in ipairs({
  { en and "Bulgur (g)" or "Bulgur (g)", bulgur },
  { en and "Hot water (ml)" or "Sıcak su (ml)", water },
  { en and "Tomatoes" or "Domates", tomato },
  { en and "Peppers" or "Biber", pepper },
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
  title = en and "Prepare vegetables" or "Sebzeleri hazırlayın",
  message = string.format(
    en and "Chop %d onion, %d tomato and %d pepper."
      or "%d soğan, %d domates ve %d biberi doğrayın.",
    onion,
    tomato,
    pepper
  ),
})
show_timer({
  title = en and "Sauté" or "Kavurun",
  message = hot == "none" and ""
    or (en and "Add chilli to taste." or "Tercihinize göre acı ekleyin."),
  duration = 300,
})
dialog_ok({
  title = en and "Add bulgur" or "Bulguru ekleyin",
  message = string.format(
    en and "Add %.0f g bulgur and %.0f ml hot water; cover."
      or "%.0f g bulgur ve %.0f ml sıcak su ekleyip kapatın.",
    bulgur,
    water
  ),
})
show_timer({ title = en and "Cook gently" or "Kısık ateşte pişirin", duration = 900 })
local tender = false
while not tender do
  tender = dialog_confirm({
    title = en and "Check pilaf" or "Pilavı kontrol edin",
    message = en and "Is the water absorbed and bulgur tender?"
      or "Suyunu çekmiş ve bulgur yumuşamış mı?",
  })
  if not tender then
    show_timer({ title = en and "Extra cooking" or "Ek pişirme", duration = 180 })
  end
end
show_timer({ title = en and "Rest" or "Dinlendirin", duration = 300 })
success({
  title = en and "Bulgur pilaf is ready" or "Bulgur pilavı hazır",
  message = en and "Fluff and serve." or "Karıştırıp servis edin.",
  visual_key = "rice",
})
