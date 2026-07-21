-- Fırında sebze senaryosu
-- Porsiyon, doğrama büyüklüğü ve kızarma tercihinden fırın süresini türetir.
-- Patatesler yumuşayıp kenarlar kızarana kadar ek sürelerle devam eder.

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
local cut = dialog_choice({
  title = en and "Cut size" or "Doğrama büyüklüğü",
  options = {
    { value = "small", label = en and "Small" or "Küçük" },
    { value = "medium", label = en and "Medium" or "Orta" },
    { value = "large", label = en and "Large" or "Büyük" },
  },
})
local brown = dialog_confirm({ title = en and "Deeply browned?" or "İyice kızarsın mı?" })
if not n or not cut then
  fail({
    title = en and "Cancelled" or "İptal",
    message = en and "Selections missing." or "Seçimler eksik.",
  })
  return
end
local potato = math.ceil(n * 0.5)
local courgette = math.ceil(n * 0.3)
local carrot = math.ceil(n * 0.3)
local pepper = math.ceil(n * 0.3)
local oil = n * 8
for _, x in ipairs({
  { en and "Potatoes" or "Patates", potato },
  { en and "Courgettes" or "Kabak", courgette },
  { en and "Carrots" or "Havuç", carrot },
  { en and "Peppers" or "Biber", pepper },
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
  title = en and "Preheat" or "Fırını ısıtın",
  message = en and "Preheat oven to 200°C." or "Fırını 200°C'ye ısıtın.",
})
dialog_ok({
  title = en and "Prepare vegetables" or "Sebzeleri hazırlayın",
  message = string.format(
    en and "Cut evenly (%s), toss with %.0f ml oil and seasoning."
      or "Eşit (%s) doğrayıp %.0f ml yağ ve baharatla harmanlayın.",
    cut,
    oil
  ),
})
progress(en and "Into the oven" or "Fırına verildi", 35)
local duration = cut == "small" and 1200 or cut == "large" and 2100 or 1800
if brown then
  duration = duration + 300
end
show_timer({ title = en and "Roast" or "Fırınlayın", duration = duration })
local tender = false
while not tender do
  tender = dialog_confirm({
    title = en and "Check vegetables" or "Sebzeleri kontrol edin",
    message = en and "Are potatoes tender and edges browned?"
      or "Patatesler yumuşak, kenarlar kızarmış mı?",
  })
  if not tender then
    show_timer({ title = en and "Roast longer" or "Biraz daha fırınlayın", duration = 300 })
  end
end
success({
  title = en and "Vegetables are ready" or "Sebzeler hazır",
  message = en and "Serve hot." or "Sıcak servis edin.",
  visual_key = "oven",
})
