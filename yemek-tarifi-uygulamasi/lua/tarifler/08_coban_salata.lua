-- Çoban salata senaryosu
-- Porsiyon, soğan ve sos tercihine göre sebze ve sos miktarlarını belirler.
-- Son tat kontrolünde kullanıcıya tuz ve ekşilik ayarlama fırsatı verir.

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
local onion = dialog_confirm({ title = en and "Add onion?" or "Soğan eklensin mi?" })
local tang = dialog_choice({
  title = en and "Dressing" or "Sos",
  options = {
    { value = "mild", label = en and "Mild" or "Hafif" },
    { value = "normal", label = en and "Balanced" or "Dengeli" },
    { value = "tangy", label = en and "Tangy" or "Ekşi" },
  },
})
if not n or not tang then
  fail({
    title = en and "Cancelled" or "İptal",
    message = en and "Selections required." or "Seçimler gerekli.",
  })
  return
end
local tomato = math.ceil(n * 0.75)
local cucumber = math.ceil(n * 0.5)
local pepper = math.max(1, math.ceil(n * 0.5))
local oil = n * (tang == "mild" and 5 or 8)
local lemon = n * (tang == "tangy" and 6 or 3)
local needed = {
  { en and "Tomatoes" or "Domates", tomato },
  { en and "Cucumbers" or "Salatalık", cucumber },
  { en and "Peppers" or "Biber", pepper },
}
for _, x in ipairs(needed) do
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
  title = en and "Wash and chop" or "Yıkayıp doğrayın",
  message = string.format(
    en and "Dice %d tomatoes, %d cucumbers and %d peppers.%s"
      or "%d domates, %d salatalık ve %d biberi doğrayın.%s",
    tomato,
    cucumber,
    pepper,
    onion and (en and " Add finely sliced onion." or " İnce soğan ekleyin.") or ""
  ),
  visual_key = "salad",
})
progress(en and "Vegetables ready" or "Sebzeler hazır", 55)
dialog_ok({
  title = en and "Dress" or "Soslayın",
  message = string.format(
    en and "Mix with %.0f ml olive oil and %.0f ml lemon juice."
      or "%.0f ml zeytinyağı ve %.0f ml limon suyuyla karıştırın.",
    oil,
    lemon
  ),
})
local balanced = dialog_confirm({
  title = en and "Taste" or "Tadına bakın",
  message = en and "Is the seasoning balanced?" or "Tuz ve ekşilik dengeli mi?",
})
if not balanced then
  dialog_ok({
    title = en and "Adjust" or "Ayarlayın",
    message = en and "Add lemon or salt a little at a time, tasting between additions."
      or "Limon veya tuzu azar azar ekleyip tekrar tadın.",
  })
end
success({
  title = en and "Salad is ready" or "Salata hazır",
  message = en and "Serve immediately." or "Bekletmeden servis edin.",
  visual_key = "salad",
})
