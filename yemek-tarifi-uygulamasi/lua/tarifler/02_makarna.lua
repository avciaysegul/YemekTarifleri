-- Domates soslu makarna senaryosu
-- Porsiyon, sos yoğunluğu ve makarna kıvamına göre miktar ve süre hesaplar.
-- Su gerçekten kaynayana kadar bekler; kapatılan sayaç için devam kararını kullanıcıya bırakır.

local en = language == "en"
local function enough(have, required)
  return have and have >= required * 0.95
end

local n = dialog_number({
  title = en and "Servings" or "Kişi sayısı",
  message = en and "Amounts depend on this." or "Miktarlar buna göre hesaplanır.",
  default = 2,
  minimum = 1,
  maximum = 8,
  visual_key = "pasta",
})
if not n then
  fail({
    title = en and "Cannot start" or "Başlatılamadı",
    message = en and "Serving count is missing." or "Kişi sayısı girilmedi.",
  })
  return
end
local sauce = dialog_choice({
  title = en and "Sauce" or "Sos tercihi",
  options = {
    { value = "light", label = en and "Light" or "Hafif" },
    { value = "normal", label = en and "Normal" or "Normal" },
    { value = "rich", label = en and "Rich" or "Bol soslu" },
  },
})
local doneness = dialog_choice({
  title = en and "Pasta texture" or "Makarna kıvamı",
  options = {
    { value = "al_dente", label = en and "Al dente" or "Diri" },
    { value = "normal", label = en and "Normal" or "Normal" },
    { value = "soft", label = en and "Soft" or "Yumuşak" },
  },
})
if not sauce or not doneness then
  fail({
    title = en and "Cancelled" or "İptal",
    message = en and "Preferences are required." or "Tercihler gerekli.",
  })
  return
end
local pasta = n * 100
local water = math.max(2, n * 0.75)
local tomato = math.ceil(n * (sauce == "rich" and 1.5 or sauce == "light" and 0.75 or 1))
local paste = n * (sauce == "rich" and 20 or sauce == "light" and 8 or 12)
local req = {
  { en and "Pasta (g)" or "Makarna (g)", pasta },
  { en and "Tomatoes" or "Domates", tomato },
  { en and "Tomato paste (g)" or "Salça (g)", paste },
}
local missing = {}
for _, x in ipairs(req) do
  local have = dialog_number({
    title = x[1],
    message = string.format(
      en and "Required: %.1f. Available?" or "Gereken: %.1f. Elinizdeki?",
      x[2]
    ),
    default = x[2],
    minimum = 0,
  })
  if not enough(have, x[2]) then
    table.insert(missing, x[1])
  end
end
if #missing > 0 then
  show_list({ title = en and "Missing ingredients" or "Eksik malzemeler", items = missing })
  fail({
    title = en and "Ingredients insufficient" or "Malzemeler yetersiz",
    message = en and "Complete the list first." or "Önce eksikleri tamamlayın.",
  })
  return
end
progress(en and "Ingredients checked" or "Malzemeler kontrol edildi", 15)
dialog_ok({
  title = en and "Heat water" or "Suyu ısıtın",
  message = string.format(
    en and "Heat %.1f litres of salted water." or "%.1f litre tuzlu suyu ısıtın.",
    water
  ),
  visual_key = "water",
})
local boiling = false
while not boiling do
  show_timer({ title = en and "Heating water" or "Su ısınıyor", duration = 60 })
  boiling = dialog_confirm({
    title = en and "Water check" or "Su kontrolü",
    message = en and "Is it boiling vigorously?" or "Su fokurdayarak kaynıyor mu?",
  })
end
progress(en and "Water boiled" or "Su kaynadı", 40)
dialog_ok({
  title = en and "Add pasta" or "Makarnayı ekleyin",
  message = string.format(en and "Add %d g pasta." or "%d g makarnayı ekleyin.", pasta),
})
local seconds = doneness == "al_dente" and 420 or doneness == "soft" and 660 or 540
local timer =
  show_timer({ title = en and "Cook pasta" or "Makarnayı pişirin", duration = seconds })
if
  timer == "closed"
  and not dialog_confirm({
    title = en and "Continue?" or "Devam edilsin mi?",
    message = en and "Continue without timer?" or "Sayaç olmadan devam edilsin mi?",
  })
then
  fail({
    title = en and "Stopped" or "Durduruldu",
    message = en and "Cooking was stopped." or "Pişirme durduruldu.",
  })
  return
end
dialog_ok({
  title = en and "Prepare sauce" or "Sosu hazırlayın",
  message = string.format(
    en and "Cook %d tomatoes with %d g paste." or "%d domatesi %d g salçayla pişirin.",
    tomato,
    paste
  ),
})
show_timer({
  title = en and "Sauce cooking" or "Sos pişiyor",
  duration = sauce == "rich" and 480 or sauce == "light" and 240 or 300,
})
progress(en and "Combine" or "Birleştirin", 90)
dialog_ok({
  title = en and "Combine" or "Birleştirin",
  message = en and "Drain pasta and mix with sauce." or "Makarnayı süzüp sosla karıştırın.",
})
success({
  title = en and "Pasta is ready" or "Makarna hazır",
  message = string.format(en and "%d servings. Enjoy!" or "%d kişilik. Afiyet olsun!", n),
  visual_key = "pasta",
})
