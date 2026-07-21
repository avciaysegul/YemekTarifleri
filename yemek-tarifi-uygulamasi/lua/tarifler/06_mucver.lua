-- Patates mücveri senaryosu
-- İstenen adet ve çıtırlığa göre harcı ve kızartma süresini hesaplar.
-- Mücverleri partiler halinde pişiren gerçek bir for döngüsü kullanır.

local en = language == "en"
local function enough(have, required)
  return have and have >= required * 0.95
end

local n = dialog_number({
  title = en and "How many fritters?" or "Kaç mücver?",
  default = 10,
  minimum = 4,
  maximum = 30,
})
local crisp = dialog_confirm({ title = en and "Extra crisp?" or "Çıtır olsun mu?" })
if not n then
  fail({
    title = en and "Cancelled" or "İptal",
    message = en and "Count required." or "Adet gerekli.",
  })
  return
end
local potato = math.ceil(n / 4)
local egg = math.max(1, math.ceil(n / 12))
local flour = math.ceil(n * 0.3)
local batches = math.ceil(n / 4)
for _, x in ipairs({
  { en and "Potatoes" or "Patates", potato },
  { en and "Eggs" or "Yumurta", egg },
  { en and "Flour (tbsp)" or "Un (yemek kaşığı)", flour },
}) do
  local v = dialog_number({
    title = x[1],
    message = string.format(en and "Need %d. Available?" or "%d gerekiyor. Elinizde?", x[2]),
    default = x[2],
    minimum = 0,
  })
  if not enough(v, x[2]) then
    fail({ title = en and "Missing ingredient" or "Eksik malzeme", message = x[1] })
    return
  end
end
dialog_ok({
  title = en and "Make batter" or "Harcı hazırlayın",
  message = string.format(
    en and "Grate and squeeze %d potatoes; mix with %d eggs and %d tbsp flour."
      or "%d patatesi rendeleyip suyunu sıkın; %d yumurta ve %d kaşık unla karıştırın.",
    potato,
    egg,
    flour
  ),
})
progress(en and "Batter ready" or "Harç hazır", 30)
for batch = 1, batches do
  dialog_ok({
    title = string.format(en and "Batch %d/%d" or "Parti %d/%d", batch, batches),
    message = en and "Place four spoonfuls in hot oil."
      or "Kızgın yağa dört kaşık harç bırakın.",
  })
  show_timer({ title = en and "Fry" or "Kızartın", duration = crisp and 300 or 240 })
  local golden = dialog_confirm({
    title = en and "Colour check" or "Renk kontrolü",
    message = en and "Are both sides golden?" or "İki yüzü de altın renginde mi?",
  })
  if not golden then
    show_timer({ title = en and "Finish this batch" or "Bu partiyi tamamlayın", duration = 60 })
  end
  progress(en and "Frying batches" or "Partiler kızarıyor", 30 + (batch / batches) * 65)
end
success({
  title = en and "Fritters are ready" or "Mücverler hazır",
  message = en and "Drain on paper towel and serve."
    or "Kağıt havluda yağını alıp servis edin.",
  visual_key = "potato",
})
