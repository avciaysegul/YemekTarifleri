-- İrmik helvası senaryosu
-- Porsiyon, kavurma rengi ve şeker tercihine göre malzemeleri hesaplar.
-- İrmik seçilen renge ulaşana kadar kavurma ve renk kontrolünü tekrarlar.

local en = language == "en"
local function enough(have, required)
  return have and have >= required * 0.95
end

local n = dialog_number({
  title = en and "Servings" or "Kişi sayısı",
  default = 6,
  minimum = 2,
  maximum = 12,
})
local roast = dialog_choice({
  title = en and "Roast colour" or "Kavurma rengi",
  options = {
    { value = "light", label = en and "Golden" or "Altın" },
    { value = "dark", label = en and "Deep brown" or "Koyu" },
  },
})
local sweet = dialog_confirm({ title = en and "Extra sweet?" or "Tatlı olsun mu?" })
if not n or not roast then
  fail({
    title = en and "Cancelled" or "İptal",
    message = en and "Selections required." or "Seçimler gerekli.",
  })
  return
end
local semolina = n * 42
local butter = n * 17
local sugar = n * (sweet and 35 or 27)
local milk = n * 50
local nuts = n * 8
for _, x in ipairs({
  { en and "Semolina (g)" or "İrmik (g)", semolina },
  { en and "Butter (g)" or "Tereyağı (g)", butter },
  { en and "Sugar (g)" or "Şeker (g)", sugar },
  { en and "Milk (ml)" or "Süt (ml)", milk },
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
  title = en and "Start roasting" or "Kavurmaya başlayın",
  message = string.format(
    en and "Melt %.0f g butter; add %.0f g semolina and %.0f g nuts."
      or "%.0f g tereyağını eritip %.0f g irmik ve %.0f g fıstık ekleyin.",
    butter,
    semolina,
    nuts
  ),
})
local colour = false
while not colour do
  show_timer({ title = en and "Stir continuously" or "Sürekli karıştırın", duration = 180 })
  colour = dialog_confirm({
    title = en and "Colour check" or "Renk kontrolü",
    message = roast == "dark"
        and (en and "Is it deep brown and nutty?" or "Koyu kahve ve güzel kokulu mu?")
      or (en and "Is it evenly golden?" or "Eşit altın renginde mi?"),
  })
end
progress(en and "Syrup stage" or "Şerbet aşaması", 65)
dialog_ok({
  title = en and "Add liquid carefully" or "Sıvıyı dikkatle ekleyin",
  message = string.format(
    en and "Mix %.0f ml warm milk with %.0f g sugar; add gradually, protecting from steam."
      or "%.0f ml ılık sütü %.0f g şekerle karıştırıp buhardan korunarak yavaşça ekleyin.",
    milk,
    sugar
  ),
})
show_timer({ title = en and "Absorb" or "Çektirin", duration = 300 })
show_timer({ title = en and "Rest covered" or "Kapalı dinlendirin", duration = 600 })
success({
  title = en and "Halva is ready" or "Helva hazır",
  message = en and "Fluff and serve." or "Havalandırıp servis edin.",
  visual_key = "dessert",
})
