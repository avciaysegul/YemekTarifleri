-- Menemen senaryosu
-- Kişi sayısı, acı tercihi ve yumurta kıvamını kullanıcıdan alır.
-- Malzemeleri porsiyona göre hesaplar; biberler yumuşayana kadar kontrol döngüsünü sürdürür.

local en = language == "en"
local function enough(have, required)
  return have and have >= required * 0.95
end

local servings = dialog_number({
  title = en and "How many servings?" or "Kaç kişilik?",
  message = en and "Eggs and vegetables will be calculated." or "Yumurta ve sebzeler hesaplanacak.",
  default = 2,
  minimum = 1,
  maximum = 8,
  visual_key = "menemen",
})
if not servings then
  fail({
    title = en and "Cancelled" or "İptal edildi",
    message = en and "Serving count is required." or "Kişi sayısı gerekli.",
  })
  return
end
local hot = dialog_confirm({
  title = en and "Spicy?" or "Acılı olsun mu?",
  message = en and "Add hot pepper?" or "Acı biber eklensin mi?",
  visual_key = "pepper",
})
local texture = dialog_choice({
  title = en and "Egg texture" or "Yumurta kıvamı",
  message = en and "Choose the finish." or "Pişme kıvamını seçin.",
  options = {
    { value = "soft", label = en and "Soft" or "Sulu" },
    { value = "set", label = en and "Fully set" or "İyi pişmiş" },
  },
})
if not texture then
  fail({
    title = en and "Cancelled" or "İptal",
    message = en and "Texture was not selected." or "Kıvam seçilmedi.",
  })
  return
end
local eggs = math.max(2, math.ceil(servings * 1.25))
local tomatoes = math.ceil(servings)
local peppers = math.max(1, math.ceil(servings * 0.75))
local ingredients = {
  { en and "Egg" or "Yumurta", eggs, en and "pcs" or "adet" },
  { en and "Tomato" or "Domates", tomatoes, en and "pcs" or "adet" },
  { en and "Pepper" or "Biber", peppers, en and "pcs" or "adet" },
}
for _, x in ipairs(ingredients) do
  local have = dialog_number({
    title = x[1],
    message = string.format(
      en and "Need %.1f %s. How much do you have?" or "%.1f %s gerekiyor. Elinizde ne kadar var?",
      x[2],
      x[3]
    ),
    default = x[2],
    minimum = 0,
  })
  if not enough(have, x[2]) then
    fail({ title = en and "Missing ingredient" or "Eksik malzeme", message = x[1] })
    return
  end
end
progress(en and "Ingredients ready" or "Malzemeler hazır", 20)
dialog_ok({
  title = en and "Chop" or "Doğrayın",
  message = string.format(
    en and "Chop %d peppers and %d tomatoes." or "%d biberi ve %d domatesi doğrayın.",
    peppers,
    tomatoes
  ),
  visual_key = "chop",
})
show_timer({
  title = en and "Sauté peppers" or "Biberleri kavurun",
  message = hot and (en and "Add hot pepper too." or "Acı biberi de ekleyin.") or "",
  duration = 180,
})
local soft = false
while not soft do
  soft = dialog_confirm({
    title = en and "Pepper check" or "Biber kontrolü",
    message = en and "Are the peppers soft?" or "Biberler yumuşadı mı?",
  })
  if not soft then
    show_timer({ title = en and "Cook a little more" or "Biraz daha pişirin", duration = 60 })
  end
end
progress(en and "Vegetables cooked" or "Sebzeler pişti", 60)
dialog_ok({
  title = en and "Add eggs" or "Yumurtaları ekleyin",
  message = string.format(
    en and "Add %d eggs and stir." or "%d yumurtayı ekleyip karıştırın.",
    eggs
  ),
})
show_timer({
  title = en and "Cook eggs" or "Yumurtaları pişirin",
  duration = texture == "soft" and 90 or 180,
})
success({
  title = en and "Menemen is ready" or "Menemen hazır",
  message = en and "Serve immediately." or "Sıcak servis edin.",
  visual_key = "menemen",
})
