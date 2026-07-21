-- Sıcak çikolata senaryosu
-- Fincan sayısı, yoğunluk ve tatlılığa göre süt, çikolata ve kakao oranını belirler.
-- İçecek pürüzsüz ve istenen kıvamda olana kadar çırpma kontrolünü tekrarlar.

local en = language == "en"
local function enough(have, required)
  return have and have >= required * 0.95
end

local cups = dialog_number({
  title = en and "Cup count" or "Fincan sayısı",
  default = 2,
  minimum = 1,
  maximum = 8,
})
local rich = dialog_choice({
  title = en and "Richness" or "Yoğunluk",
  options = {
    { value = "light", label = en and "Light" or "Hafif" },
    { value = "normal", label = en and "Classic" or "Klasik" },
    { value = "rich", label = en and "Very rich" or "Çok yoğun" },
  },
})
local sweet = dialog_confirm({ title = en and "Extra sweet?" or "Daha tatlı olsun mu?" })
if not cups or not rich then
  fail({
    title = en and "Cancelled" or "İptal",
    message = en and "Selections required." or "Seçimler gerekli.",
  })
  return
end
local milk = cups * 200
local chocolate = cups * (rich == "light" and 25 or rich == "rich" and 55 or 40)
local cocoa = cups * (rich == "rich" and 8 or 5)
local sugar = cups * (sweet and 12 or 6)
for _, x in ipairs({
  { en and "Milk (ml)" or "Süt (ml)", milk },
  { en and "Chocolate (g)" or "Çikolata (g)", chocolate },
  { en and "Cocoa (g)" or "Kakao (g)", cocoa },
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
  title = en and "Warm milk" or "Sütü ısıtın",
  message = string.format(
    en and "Warm %.0f ml milk without boiling." or "%.0f ml sütü kaynatmadan ısıtın.",
    milk
  ),
})
show_timer({ title = en and "Heat gently" or "Kısık ateşte ısıtın", duration = 240 })
dialog_ok({
  title = en and "Add chocolate" or "Çikolatayı ekleyin",
  message = string.format(
    en and "Whisk in %.0f g chocolate, %.0f g cocoa and %.0f g sugar."
      or "%.0f g çikolata, %.0f g kakao ve %.0f g şekeri çırpın.",
    chocolate,
    cocoa,
    sugar
  ),
})
local smooth = false
while not smooth do
  show_timer({ title = en and "Whisk" or "Çırpın", duration = 60 })
  smooth = dialog_confirm({
    title = en and "Texture check" or "Kıvam kontrolü",
    message = en and "Is it smooth and at your preferred thickness?"
      or "Pürüzsüz ve istediğiniz yoğunlukta mı?",
  })
  if not smooth then
    dialog_ok({
      title = en and "Adjust" or "Ayarlayın",
      message = en and "For thinner chocolate add milk; for thicker, simmer briefly."
        or "İnceltmek için süt ekleyin; koyulaştırmak için kısa süre pişirin.",
    })
  end
end
success({
  title = en and "Hot chocolate is ready" or "Sıcak çikolata hazır",
  message = en and "Pour into warmed cups." or "Ilık fincanlara dökün.",
  visual_key = "chocolate",
})
