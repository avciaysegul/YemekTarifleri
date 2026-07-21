-- Mozaik pasta senaryosu
-- Dilim sayısı ve çikolata yoğunluğuna göre sos ile bisküvi miktarını hesaplar.
-- Pasta temiz dilimlenecek kadar sertleşene kadar soğutmayı tekrarlar.

local en = language == "en"
local function enough(have, required)
  return have and have >= required * 0.95
end

local slices = dialog_number({
  title = en and "Slice count" or "Dilim sayısı",
  default = 10,
  minimum = 6,
  maximum = 20,
})
local rich = dialog_choice({
  title = en and "Chocolate intensity" or "Çikolata yoğunluğu",
  options = {
    { value = "mild", label = en and "Mild" or "Hafif" },
    { value = "normal", label = en and "Classic" or "Klasik" },
    { value = "rich", label = en and "Intense" or "Yoğun" },
  },
})
if not slices or not rich then
  fail({
    title = en and "Cancelled" or "İptal",
    message = en and "Selections required." or "Seçimler gerekli.",
  })
  return
end
local biscuits = slices * 30
local chocolate = slices * (rich == "mild" and 7 or rich == "rich" and 14 or 10)
local milk = slices * 20
local butter = slices * 10
local cocoa = slices * (rich == "rich" and 3 or 2)
for _, x in ipairs({
  { en and "Biscuits (g)" or "Bisküvi (g)", biscuits },
  { en and "Chocolate (g)" or "Çikolata (g)", chocolate },
  { en and "Milk (ml)" or "Süt (ml)", milk },
  { en and "Butter (g)" or "Tereyağı (g)", butter },
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
  title = en and "Make chocolate sauce" or "Çikolata sosunu hazırlayın",
  message = string.format(
    en and "Gently melt %.0f g chocolate, %.0f g butter, %.0f ml milk and %.0f g cocoa."
      or "%.0f g çikolata, %.0f g tereyağı, %.0f ml süt ve %.0f g kakaoyu kısık ateşte eritin.",
    chocolate,
    butter,
    milk,
    cocoa
  ),
})
show_timer({ title = en and "Stir sauce" or "Sosu karıştırın", duration = 300 })
dialog_ok({
  title = en and "Add biscuits" or "Bisküvileri ekleyin",
  message = string.format(
    en and "Fold in %.0f g roughly broken biscuits without crushing them."
      or "%.0f g iri kırılmış bisküviyi ezmeden karıştırın.",
    biscuits
  ),
})
dialog_ok({
  title = en and "Shape" or "Şekillendirin",
  message = en and "Wrap tightly and shape into a log."
    or "Streç filme sıkıca sarıp rulo şekli verin.",
})
show_timer({ title = en and "Chill" or "Soğutun", duration = 7200 })
local firm = false
while not firm do
  firm = dialog_confirm({
    title = en and "Firmness check" or "Sertlik kontrolü",
    message = en and "Is it firm enough to slice cleanly?"
      or "Düzgün dilimlenecek kadar sert mi?",
  })
  if not firm then
    show_timer({ title = en and "Chill longer" or "Biraz daha soğutun", duration = 1800 })
  end
end
success({
  title = en and "Mosaic cake is ready" or "Mozaik pasta hazır",
  message = string.format(en and "Cut into %d slices." or "%d dilime kesin.", slices),
  visual_key = "chocolate",
})
