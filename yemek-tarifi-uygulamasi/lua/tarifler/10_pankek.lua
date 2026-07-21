-- Pankek senaryosu
-- Adet ve boyuta göre un, süt, yumurta ve pişirme süresini hesaplar.
-- Pankekleri tava kapasitesine göre partiler halinde pişirir ve çevirme anını kontrol eder.

local en = language == "en"
local function enough(have, required)
  return have and have >= required * 0.95
end

local count = dialog_number({
  title = en and "Pancake count" or "Pankek adedi",
  default = 8,
  minimum = 2,
  maximum = 30,
})
local size = dialog_choice({
  title = en and "Size" or "Boyut",
  options = {
    { value = "small", label = en and "Small" or "Küçük" },
    { value = "medium", label = en and "Medium" or "Orta" },
    { value = "large", label = en and "Large" or "Büyük" },
  },
})
if not count or not size then
  fail({
    title = en and "Cancelled" or "İptal",
    message = en and "Count and size required." or "Adet ve boyut gerekli.",
  })
  return
end
count = math.floor(count)
local factor = size == "small" and 0.75 or size == "large" and 1.4 or 1
local flour = count * 18 * factor
local milk = count * 28 * factor
local eggs = math.max(1, math.ceil(count / 8))
local batches = math.ceil(count / 3)
for _, x in ipairs({
  { en and "Flour (g)" or "Un (g)", flour },
  { en and "Milk (ml)" or "Süt (ml)", milk },
  { en and "Eggs" or "Yumurta", eggs },
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
  title = en and "Make batter" or "Harcı hazırlayın",
  message = string.format(
    en and "Whisk %.0f g flour, %.0f ml milk and %d eggs until smooth."
      or "%.0f g un, %.0f ml süt ve %d yumurtayı pürüzsüz çırpın.",
    flour,
    milk,
    eggs
  ),
})
show_timer({ title = en and "Rest batter" or "Harcı dinlendirin", duration = 180 })
for batch = 1, batches do
  dialog_ok({
    title = string.format(en and "Batch %d/%d" or "Parti %d/%d", batch, batches),
    message = en and "Pour batter into the lightly greased pan."
      or "Harcı hafif yağlı tavaya dökün.",
  })
  show_timer({
    title = en and "Cook first side" or "İlk yüzü pişirin",
    duration = size == "large" and 150 or 90,
  })
  local bubbles = dialog_confirm({
    title = en and "Flip check" or "Çevirme kontrolü",
    message = en and "Are bubbles set around the edges?"
      or "Kenarlardaki kabarcıklar sabitlendi mi?",
  })
  if not bubbles then
    show_timer({ title = en and "Wait before flipping" or "Çevirmeden bekleyin", duration = 30 })
  end
  dialog_ok({
    title = en and "Flip" or "Çevirin",
    message = en and "Flip carefully." or "Dikkatlice çevirin.",
  })
  show_timer({ title = en and "Second side" or "İkinci yüz", duration = 60 })
  progress(en and "Cooking pancakes" or "Pankekler pişiyor", 20 + (batch / batches) * 75)
end
success({
  title = en and "Pancakes are ready" or "Pankekler hazır",
  message = string.format(en and "%d pancakes are ready." or "%d pankek hazır.", count),
  visual_key = "pancake",
})
