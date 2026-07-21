-- Muzlu smoothie senaryosu
-- Bardak sayısı, kıvam ve tatlılığa göre meyve ile sıvı oranını hesaplar.
-- Kullanıcı istediği kıvama ulaşana kadar süt veya yoğunlaştırıcı ekleyebilir.

local en = language == "en"
local function enough(have, required)
  return have and have >= required * 0.95
end

local glasses = dialog_number({
  title = en and "Glasses" or "Bardak sayısı",
  default = 2,
  minimum = 1,
  maximum = 8,
})
local thick = dialog_choice({
  title = en and "Texture" or "Kıvam",
  options = {
    { value = "thin", label = en and "Drinkable" or "Akışkan" },
    { value = "normal", label = en and "Normal" or "Normal" },
    { value = "thick", label = en and "Thick" or "Koyu" },
  },
})
local sweet = dialog_confirm({ title = en and "Add honey?" or "Bal eklensin mi?" })
if not glasses or not thick then
  fail({
    title = en and "Cancelled" or "İptal",
    message = en and "Selections required." or "Seçimler gerekli.",
  })
  return
end
local banana = math.ceil(glasses * 0.6)
local milk = glasses * (thick == "thin" and 180 or thick == "thick" and 100 or 140)
local yogurt = glasses * (thick == "thick" and 60 or 35)
local honey = sweet and glasses * 7 or 0
for _, x in ipairs({
  { en and "Bananas" or "Muz", banana },
  { en and "Milk (ml)" or "Süt (ml)", milk },
  { en and "Yoghurt (g)" or "Yoğurt (g)", yogurt },
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
  title = en and "Fill blender" or "Blendera ekleyin",
  message = string.format(
    en and "Add %d bananas, %.0f ml milk, %.0f g yoghurt%s."
      or "%d muz, %.0f ml süt, %.0f g yoğurt%s ekleyin.",
    banana,
    milk,
    yogurt,
    sweet and string.format(en and " and %.0f ml honey" or " ve %.0f ml bal", honey) or ""
  ),
})
show_timer({ title = en and "Blend" or "Karıştırın", duration = 45 })
local right = false
while not right do
  right = dialog_confirm({
    title = en and "Texture check" or "Kıvam kontrolü",
    message = en and "Is the texture right?" or "Kıvam istediğiniz gibi mi?",
  })
  if not right then
    local action = dialog_choice({
      title = en and "Adjust" or "Ayarlayın",
      options = {
        { value = "milk", label = en and "Add a little milk" or "Biraz süt ekle" },
        { value = "banana", label = en and "Add banana/yoghurt" or "Muz/yoğurt ekle" },
      },
    })
    dialog_ok({
      title = en and "Adjust and blend" or "Ayarlayıp karıştırın",
      message = action == "milk" and (en and "Add 30 ml milk." or "30 ml süt ekleyin.")
        or (en and "Add a little banana or yoghurt." or "Biraz muz veya yoğurt ekleyin."),
    })
    show_timer({ title = en and "Blend again" or "Tekrar karıştırın", duration = 20 })
  end
end
success({
  title = en and "Smoothie is ready" or "Smoothie hazır",
  message = en and "Serve immediately." or "Bekletmeden servis edin.",
  visual_key = "smoothie",
})
