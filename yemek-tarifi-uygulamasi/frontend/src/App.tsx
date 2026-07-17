import { useEffect, useMemo, useState, type ReactNode } from "react";
import { TarifAkisiniCalistir, TarifleriGetir } from "../wailsjs/go/main/App";
import heroGorseli from "./assets/images/mutfak-food-hero-v2.png";
import "./App.css";

interface TarifAdimi {
  baslik: string;
  aciklama: string;
  emoji: string;
  animasyon: string;
  bekleme?: string;
}

interface YemekTarifi {
  id: number;
  ad: string;
  emoji: string;
  aciklama: string;
  sure: string;
  zorluk: string;
  kategori?: string;
  malzemeler: string[];
  adimlar: TarifAdimi[];
  ingilizce?: {
    ad: string;
    aciklama: string;
    malzemeler: string[];
    adimlar: TarifAdimi[];
  };
}

interface LuaTarifDurumu {
  aktifAdim: number;
  ilerleme: number;
  tamamlandi: boolean;
  bekleme: string;
  oncekiAdimVar: boolean;
  ileriTamamlar: boolean;
}

type Ekran = "anaSayfa" | "hakkimizda" | "iletisim" | "detay" | "tarif" | "tamamlandi";
type Dil = "tr" | "en";
type ZorlukFiltresi = "Tümü" | "Kolay" | "Orta" | "Zor";
type KategoriFiltresi = "Tümü" | "Ana Yemekler" | "Tatlılar" | "İçecekler";

const zorluklar: ZorlukFiltresi[] = ["Tümü", "Kolay", "Orta", "Zor"];
const kategoriler: KategoriFiltresi[] = ["Tümü", "Ana Yemekler", "Tatlılar", "İçecekler"];

const metinler = {
  tr: {
    recipes: "Tarifler", about: "Hakkımızda", contact: "Bize ulaşın", settings: "Ayarlar", language: "Dil", turkish: "Türkçe", english: "English",
    contactShort: "İletişim", dailyGuide: "GÜNLÜK MUTFAK REHBERİ", heroTitle: <>Kolay ve pratik<br />yemek tarifleri</>,
    heroText: "Ölçüsü net, adımları anlaşılır tariflerle mutfakta her gün yeni bir lezzet keşfedin.", searchPlaceholder: "Tarif veya malzeme ara", search: "Tarif ara", popular: "Popüler:",
    filter: "Sonuçları filtreleyin", results: "tarif bulundu", step: "adım", viewRecipe: "Tarifi gör", noRecipe: "Tarif bulunamadı", noRecipeText: "Arama ifadenizi veya filtrenizi değiştirin.",
    loading: "Tarifler hazırlanıyor…", errorTitle: "Bir hata oluştu", retry: "Tekrar dene", loadError: "Tarifler yüklenemedi. Lütfen uygulamayı yeniden deneyin.",
    backRecipes: "← Tariflere dön", recipe: "YEMEK TARİFİ", ingredients: "Malzemeler", ready: "hazır", start: "▶ Tarife başla", finishedText: "Eline sağlık, bütün adımları tamamladın.", repeat: "Tarifi tekrarla", chooseAnother: "Başka tarif seç",
    recipeInfo: "← Tarif bilgileri", waiting: "Bekleme süresi", previous: "← Önceki", complete: "Tarifi tamamla", next: "Sonraki adım →", progress: "İlerleme",
  },
  en: {
    recipes: "Recipes", about: "About", contact: "Contact us", settings: "Settings", language: "Language", turkish: "Türkçe", english: "English",
    contactShort: "Contact", dailyGuide: "EVERYDAY KITCHEN GUIDE", heroTitle: <>Easy, practical<br />recipes</>,
    heroText: "Discover a new flavour every day with clearly measured recipes and easy-to-follow steps.", searchPlaceholder: "Search recipes or ingredients", search: "Search", popular: "Popular:",
    filter: "Filter results", results: "recipes found", step: "steps", viewRecipe: "View recipe", noRecipe: "No recipes found", noRecipeText: "Try changing your search or filter.",
    loading: "Preparing recipes…", errorTitle: "Something went wrong", retry: "Try again", loadError: "Recipes could not be loaded. Please try again.",
    backRecipes: "← Back to recipes", recipe: "RECIPE", ingredients: "Ingredients", ready: "ready", start: "▶ Start cooking", finishedText: "Well done, you completed every step.", repeat: "Cook again", chooseAnother: "Choose another recipe",
    recipeInfo: "← Recipe details", waiting: "Waiting time", previous: "← Previous", complete: "Complete recipe", next: "Next step →", progress: "Progress",
  },
} as const;

function App() {
  const [dil, setDil] = useState<Dil>(() => localStorage.getItem("uygulama-dili") === "en" ? "en" : "tr");
  const [ayarlarAcik, setAyarlarAcik] = useState(false);
  const [tarifler, setTarifler] = useState<YemekTarifi[]>([]);
  const [seciliTarif, setSeciliTarif] = useState<YemekTarifi | null>(null);
  const [aktifAdim, setAktifAdim] = useState(0);
  const [luaBekleme, setLuaBekleme] = useState("");
  const [luaIlerleme, setLuaIlerleme] = useState(0);
  const [oncekiAdimVar, setOncekiAdimVar] = useState(false);
  const [ileriTamamlar, setIleriTamamlar] = useState(false);
  const [ekran, setEkran] = useState<Ekran>("anaSayfa");
  const [arama, setArama] = useState("");
  const [zorluk, setZorluk] = useState<ZorlukFiltresi>("Tümü");
  const [kategori, setKategori] = useState<KategoriFiltresi>("Tümü");
  const [tamamlananMalzemeler, setTamamlananMalzemeler] = useState<string[]>([]);
  const [yukleniyor, setYukleniyor] = useState(true);
  const [hata, setHata] = useState("");
  const t = metinler[dil];

  function goruntulenecekTarif(tarif: YemekTarifi): YemekTarifi {
    if (dil !== "en" || !tarif.ingilizce) return tarif;
    return { ...tarif, ...tarif.ingilizce };
  }

  function zorluguGoster(zorlukDegeri: YemekTarifi["zorluk"]) {
    if (dil !== "en") return zorlukDegeri;
    return ({ Kolay: "Easy", Orta: "Medium", Zor: "Hard" } as Record<string, string>)[zorlukDegeri] || zorlukDegeri;
  }

  function zorlukFiltresiniGoster(zorlukDegeri: ZorlukFiltresi) {
    if (dil !== "en") return zorlukDegeri;
    return ({ "Tümü": "All", Kolay: "Easy", Orta: "Medium", Zor: "Hard" } as Record<ZorlukFiltresi, string>)[zorlukDegeri];
  }

  useEffect(() => {
    void tarifleriYukle();
  }, []);

  useEffect(() => {
    localStorage.setItem("uygulama-dili", dil);
    document.documentElement.lang = dil;
  }, [dil]);

  const filtrelenmisTarifler = useMemo(() => {
    const aramaMetni = arama.trim().toLocaleLowerCase("tr-TR");

    return tarifler.filter((tarif) => {
      const gorunenTarif = goruntulenecekTarif(tarif);
      const aramaEslesiyor =
        !aramaMetni ||
        `${gorunenTarif.ad} ${gorunenTarif.aciklama} ${gorunenTarif.malzemeler.join(" ")}`
          .toLocaleLowerCase("tr-TR")
          .includes(aramaMetni);
      const zorlukEslesiyor = zorluk === "Tümü" || tarif.zorluk === zorluk;
      const kategoriEslesiyor = kategori === "Tümü" || tarifKategorisi(tarif) === kategori;

      return aramaEslesiyor && zorlukEslesiyor && kategoriEslesiyor;
    });
  }, [arama, tarifler, zorluk, kategori]);

  async function tarifleriYukle() {
    try {
      setYukleniyor(true);
      setHata("");
      setTarifler((await TarifleriGetir()) as YemekTarifi[]);
    } catch (yakalananHata) {
      console.error(yakalananHata);
      setHata(t.loadError);
    } finally {
      setYukleniyor(false);
    }
  }

  function tarifDetayiniAc(tarif: YemekTarifi) {
    setSeciliTarif(tarif);
    setAktifAdim(0);
    setLuaBekleme("");
    setLuaIlerleme(0);
    setOncekiAdimVar(false);
    setIleriTamamlar(false);
    setTamamlananMalzemeler([]);
    setEkran("detay");
  }

  function anaSayfayaDon() {
    setSeciliTarif(null);
    setAktifAdim(0);
    setLuaBekleme("");
    setLuaIlerleme(0);
    setOncekiAdimVar(false);
    setIleriTamamlar(false);
    setTamamlananMalzemeler([]);
    setEkran("anaSayfa");
  }

  function malzemeyiDegistir(malzeme: string) {
    setTamamlananMalzemeler((onceki) =>
      onceki.includes(malzeme)
        ? onceki.filter((deger) => deger !== malzeme)
        : [...onceki, malzeme]
    );
  }

  async function luaTarifKomutu(komut: "baslat" | "ileri" | "geri") {
    if (!seciliTarif) return;
    const gorunenTarif = goruntulenecekTarif(seciliTarif);
    const mevcut = gorunenTarif.adimlar[aktifAdim];

    try {
      const durum = await TarifAkisiniCalistir(
        seciliTarif.id,
        gorunenTarif.adimlar.length,
        aktifAdim,
        komut,
        mevcut?.animasyon || "",
        mevcut?.bekleme || "",
      ) as unknown as LuaTarifDurumu;
      setAktifAdim(durum.aktifAdim);
      setLuaBekleme(durum.bekleme);
      setLuaIlerleme(durum.ilerleme);
      setOncekiAdimVar(durum.oncekiAdimVar);
      setIleriTamamlar(durum.ileriTamamlar);
      if (durum.tamamlandi) setEkran("tamamlandi");
    } catch (yakalananHata) {
      console.error(yakalananHata);
      setHata(t.loadError);
    }
  }

  if (yukleniyor) {
    return <DurumEkrani emoji="🍲" baslik={t.loading} yukleniyor />;
  }

  if (hata) {
    return (
      <DurumEkrani emoji="⚠️" baslik={t.errorTitle} metin={hata}>
        <button className="ana-buton" onClick={() => void tarifleriYukle()}>
          {t.retry}
        </button>
      </DurumEkrani>
    );
  }

  if (ekran === "anaSayfa") {
    return (
      <main className="uygulama">
        <header className="site-baslik">
          <button className="marka" onClick={anaSayfayaDon}><span>Mutfakta</span><strong>Bugün</strong></button>
          <nav className="ust-menu" aria-label="Ana menü"><a href="#tarifler">{t.recipes}</a><button onClick={() => setEkran("hakkimizda")}>{t.about}</button><button onClick={() => setEkran("iletisim")}>{t.contact}</button></nav>
          <div className="ust-islemler"><button className="ayarlar-buton" onClick={() => setAyarlarAcik((onceki) => !onceki)} aria-expanded={ayarlarAcik}>⚙ {t.settings}</button>{ayarlarAcik && <div className="dil-paneli"><span>{t.language}</span><button className={dil === "tr" ? "aktif" : ""} onClick={() => { setDil("tr"); setAyarlarAcik(false); }}>{t.turkish}</button><button className={dil === "en" ? "aktif" : ""} onClick={() => { setDil("en"); setAyarlarAcik(false); }}>{t.english}</button></div>}<button className="profil-buton" onClick={() => setEkran("iletisim")} aria-label={t.contact}><span>✉</span><b>{t.contactShort}</b></button></div>
        </header>

        <section className="hero-alani" style={{ backgroundImage: `linear-gradient(90deg, rgba(8, 10, 13, .9), rgba(8, 10, 13, .42)), url(${heroGorseli})` }}>
          <div className="hero-icerik"><span className="hero-etiket">{t.dailyGuide}</span><h1>{t.heroTitle}</h1><p>{t.heroText}</p>
            <div className="hero-arama"><label><span>⌕</span><input value={arama} onChange={(olay) => setArama(olay.target.value)} placeholder={t.searchPlaceholder} aria-label={t.searchPlaceholder} /></label><button>{t.search}</button></div>
            <div className="populer-aramalar"><b>{t.popular}</b><button onClick={() => setArama(dil === "en" ? "pasta" : "makarna")}>{dil === "en" ? "Pasta" : "Makarna"}</button><button onClick={() => setArama(dil === "en" ? "soup" : "çorba")}>{dil === "en" ? "Soup" : "Çorba"}</button><button onClick={() => setArama(dil === "en" ? "cake" : "tatlı")}>{dil === "en" ? "Dessert" : "Tatlı"}</button><button onClick={() => setArama(dil === "en" ? "chicken" : "tavuk")}>{dil === "en" ? "Chicken" : "Tavuk"}</button></div>
          </div>
        </section>

        <section className="tarif-bolumu" id="tarifler" aria-label="Tarifler">
          <div className="kesfet-araclari">
            <span className="filtre-baslik">{t.filter}</span>
            <div className="filtreler" aria-label="Zorluk filtresi">
              {zorluklar.map((secenek) => (
                <button
                  className={zorluk === secenek ? "filtre aktif" : "filtre"}
                  key={secenek}
                  onClick={() => setZorluk(secenek)}
                >
                  {zorlukFiltresiniGoster(secenek)}
                </button>
              ))}
            </div>
          </div>
          <div className="bolum-basligi">
            <h2>{t.recipes}</h2>
            <span>{filtrelenmisTarifler.length} {t.results}</span>
          </div>

          {filtrelenmisTarifler.length ? (
            <div className="tarif-listesi">{filtrelenmisTarifler.map((tarif) => {
              const gorunenTarif = goruntulenecekTarif(tarif);
              return <article className="tarif-karti" key={tarif.id}>
                  <div className="kart-emoji">{gorunenTarif.emoji}</div>
                  <div className="kart-icerigi">
                    <h3>{gorunenTarif.ad}</h3>
                    <p>{gorunenTarif.aciklama}</p>
                    <div className="tarif-bilgileri">
                      <span>⏱ {sureyiGoster(gorunenTarif.sure, dil)}</span>
                      <span>📊 {zorluguGoster(gorunenTarif.zorluk)}</span>
                      <span>📝 {gorunenTarif.adimlar.length} {t.step}</span>
                    </div>
                    <button className="ana-buton" onClick={() => tarifDetayiniAc(tarif)}>
                      {t.viewRecipe} <span aria-hidden="true">→</span>
                    </button>
                  </div>
                </article>;
            })}</div>
          ) : (
            <div className="bos-durum"><span>🔎</span><h2>{t.noRecipe}</h2><p>{t.noRecipeText}</p></div>
          )}
        </section>
      </main>
    );
  }

  if (ekran === "hakkimizda") return <HakkimizdaSayfasi geriDon={() => setEkran("anaSayfa")} dil={dil} />;
  if (ekran === "iletisim") return <IletisimSayfasi geriDon={() => setEkran("anaSayfa")} dil={dil} />;

  if (!seciliTarif) return null;

  if (ekran === "detay") {
    const gosterilenTarif = goruntulenecekTarif(seciliTarif);
    const malzemeSayisi = gosterilenTarif.malzemeler.length;
    return (
      <main className="uygulama">
        <button className="geri-buton" onClick={anaSayfayaDon}>{t.backRecipes}</button>
        <section className="detay-karti">
          <div className="detay-ust">
            <div className="detay-emoji">{gosterilenTarif.emoji}</div>
            <div><span className="ust-etiket">{t.recipe}</span><h1>{gosterilenTarif.ad}</h1><p>{gosterilenTarif.aciklama}</p>
              <div className="detay-bilgileri"><span>⏱ {sureyiGoster(gosterilenTarif.sure, dil)}</span><span>📊 {zorluguGoster(gosterilenTarif.zorluk)}</span><span>📝 {gosterilenTarif.adimlar.length} {t.step}</span></div>
            </div>
          </div>
          <div className="malzeme-alani">
            <div className="malzeme-baslik"><h2>{t.ingredients}</h2><span>{tamamlananMalzemeler.length}/{malzemeSayisi} {t.ready}</span></div>
            <ul className="malzeme-listesi">
              {gosterilenTarif.malzemeler.map((malzeme, indeks) => {
                const tamamlandi = tamamlananMalzemeler.includes(malzeme);
                const { olcu, ad } = malzemeyiParcala(malzeme);
                return <li key={`${malzeme}-${indeks}`} className={tamamlandi ? "hazir" : ""}>
                  <label><input type="checkbox" checked={tamamlandi} onChange={() => malzemeyiDegistir(malzeme)} /><span className="onay-isareti" aria-hidden="true">✓</span><span className="malzeme-metni">{olcu && <strong className="malzeme-olcusu">{olcu}</strong>}{ad}</span></label>
                </li>;
              })}
            </ul>
          </div>
          <button className="basla-buton" onClick={() => void luaTarifKomutu("baslat").then(() => setEkran("tarif"))}>{t.start}</button>
        </section>
      </main>
    );
  }

  if (ekran === "tamamlandi") {
    const gosterilenTarif = goruntulenecekTarif(seciliTarif);
    return <DurumEkrani emoji={gosterilenTarif.emoji} baslik={`${gosterilenTarif.ad} ${dil === "en" ? "is ready!" : "hazır!"}`} metin={t.finishedText}>
      <div className="tamamlandi-butonlari"><button className="ikincil-buton" onClick={() => void luaTarifKomutu("baslat").then(() => setEkran("tarif"))}>{t.repeat}</button><button className="ana-buton" onClick={anaSayfayaDon}>{t.chooseAnother}</button></div>
    </DurumEkrani>;
  }

  const gosterilenTarif = goruntulenecekTarif(seciliTarif);
  const adim = gosterilenTarif.adimlar[aktifAdim];
  const ilerleme = luaIlerleme;
  return (
    <main className="uygulama tarif-ekrani">
      <header className="tarif-ust-menu"><button className="geri-buton" onClick={() => setEkran("detay")}>{t.recipeInfo}</button><span className="adim-sayisi">{dil === "en" ? "Step" : "Adım"} {aktifAdim + 1} / {gosterilenTarif.adimlar.length}</span></header>
      <div className="ilerleme-cubugu" aria-label={`${t.progress}: ${Math.round(ilerleme)}%`}><div className="ilerleme" style={{ width: `${ilerleme}%` }} /></div>
      <section className="adim-karti" key={aktifAdim}>
        <CookingIllustration tur={adim.animasyon} emoji={adim.emoji} />
        <span className="ust-etiket">{gosterilenTarif.ad.toLocaleUpperCase(dil === "en" ? "en-US" : "tr-TR")}</span><h1>{adim.baslik}</h1><p>{adim.aciklama}</p>
        <div className="bekleme-bilgisi" aria-label={`${t.waiting}: ${luaBekleme || adim.bekleme || "2 dk"}`}>
          <svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="8.5"/><path d="M12 7v5l3 2"/></svg>
          <span>{t.waiting}</span><strong>{luaBekleme || adim.bekleme || "2 dk"}</strong>
        </div>
        <div className="adim-butonlari"><button className="ikincil-buton" onClick={() => oncekiAdimVar ? void luaTarifKomutu("geri") : setEkran("detay")}>{t.previous}</button><button className="ana-buton" onClick={() => void luaTarifKomutu("ileri")}>{ileriTamamlar ? t.complete : t.next}</button></div>
      </section>
    </main>
  );
}

function sureyiGoster(sure: string, dil: Dil = "tr") {
  return dil === "en" ? `About ${sure.replace("dakika", "min")}` : `Ortalama ${sure.replace("dakika", "dk")}`;
}

function tarifKategorisi(tarif: YemekTarifi): Exclude<KategoriFiltresi, "Tümü"> {
  if (tarif.kategori === "Tatlılar" || tarif.kategori === "İçecekler" || tarif.kategori === "Ana Yemekler") return tarif.kategori;
  if (["Sütlaç"].includes(tarif.ad)) return "Tatlılar";
  return "Ana Yemekler";
}

function malzemeyiParcala(malzeme: string) {
  const eslesme = malzeme.match(/^((?:\d+(?:[,.]\d+)?|Yarım|yarım|1\/2)(?:\s+(?:adet|paket|litre|ml|g|dal|demet|küp|su bardağı|çay bardağı|yemek kaşığı|tatlı kaşığı|çay kaşığı))?(?:\s+(?:orta boy|büyük|küçük))?)\s+(.+)$/u);
  return eslesme ? { olcu: eslesme[1], ad: eslesme[2] } : { olcu: "Ölçüsü tarifte belirtilmiştir", ad: malzeme };
}

function CookingIllustration({ tur, emoji }: { tur: string; emoji: string }) {
  return <div className={`adim-animasyonu svg-animasyon ${tur}`} aria-label="Tarif adımı animasyonu">
    <svg viewBox="0 0 240 240" role="img" aria-hidden="true">
      <defs><linearGradient id="pot" x1="0" y1="0" x2="1" y2="1"><stop stopColor="#f38b57"/><stop offset="1" stopColor="#cb472f"/></linearGradient></defs>
      <circle cx="120" cy="120" r="108" fill="#fff3d5"/>
      <path className="buhar buhar-bir" d="M88 89c-10-12 9-20 0-33"/><path className="buhar buhar-iki" d="M120 83c-10-12 9-20 0-33"/><path className="buhar buhar-uc" d="M152 89c-10-12 9-20 0-33"/>
      <path className="tencere-kulpu" d="M54 127h24M162 127h24"/><path className="tencere" d="M72 111h96l-9 58H81z" fill="url(#pot)"/><ellipse cx="120" cy="111" rx="48" ry="13" fill="#733426"/>
      <g className="kasik"><path d="M153 55l-27 61"/><ellipse cx="158" cy="47" rx="12" ry="18" fill="#e7bb75"/></g>
      <text x="120" y="151" textAnchor="middle" className="svg-emoji">{emoji}</text>
      <circle className="kabarcik kabarcik-bir" cx="98" cy="103" r="5"/><circle className="kabarcik kabarcik-iki" cx="139" cy="105" r="4"/>
    </svg>
  </div>;
}

function LoadingSvg() {
  return <svg viewBox="0 0 120 120" aria-label="Yükleniyor"><circle className="yukleme-halka" cx="60" cy="60" r="42"/><path className="yukleme-cizgi" d="M60 30v30l20 12"/><circle cx="60" cy="60" r="4"/></svg>;
}

function HakkimizdaSayfasi({ geriDon, dil }: { geriDon: () => void; dil: Dil }) {
  const ingilizce = dil === "en";
  return <main className="uygulama bilgi-sayfasi">
    <button className="geri-buton" onClick={geriDon}>{ingilizce ? "← Back to recipes" : "← Tariflere dön"}</button>
    <header className="bilgi-kahraman"><span className="ust-etiket">MUTFAKTA BUGÜN</span><h1>{ingilizce ? "A little guide to keep you company in the kitchen." : "Mutfağa eşlik eden küçük bir rehber."}</h1><p>{ingilizce ? "We are here for clear measurements, practical recipes and an enjoyable cooking experience." : "Net ölçüler, pratik tarifler ve keyifli bir pişirme deneyimi için buradayız."}</p></header>
    <section className="tek-bilgi-karti"><article className="hakkimizda-karti"><div className="bilgi-ikon">♥</div><span className="ust-etiket">{ingilizce ? "ABOUT" : "HAKKIMIZDA"}</span><h2>{ingilizce ? "We make recipes simpler." : "Tarifleri sadeleştiriyoruz."}</h2><p>{ingilizce ? "We provide every recipe with measured ingredients and waiting times for each step, so you can always follow along with confidence." : "Her tarifin malzemesini ölçüsüyle, adımlarını bekleme süresiyle sunuyoruz. Böylece mutfakta ne yapacağınızı her zaman kolayca takip edebilirsiniz."}</p><div className="degerler"><span>✓ {ingilizce ? "Clear measurements" : "Net ölçüler"}</span><span>✓ {ingilizce ? "Step-by-step guidance" : "Adım adım anlatım"}</span><span>✓ {ingilizce ? "For every skill level" : "Her seviyeye uygun"}</span></div></article></section>
  </main>;
}

function IletisimSayfasi({ geriDon, dil }: { geriDon: () => void; dil: Dil }) {
  const ingilizce = dil === "en";
  return <main className="uygulama bilgi-sayfasi">
    <button className="geri-buton" onClick={geriDon}>{ingilizce ? "← Back to recipes" : "← Tariflere dön"}</button>
    <header className="bilgi-kahraman"><span className="ust-etiket">{ingilizce ? "CONTACT US" : "BİZE ULAŞIN"}</span><h1>{ingilizce ? "Need a hand while following a recipe?" : "Tarif sırasında takıldığınız bir nokta mı var?"}</h1><p>{ingilizce ? "Write to us whenever you need help with ingredient measures, cooking times or using the app." : "Malzeme ölçüleri, pişirme süresi veya uygulamanın kullanımıyla ilgili desteğe ihtiyacınız olduğunda bize yazın; size yardımcı olalım."}</p></header>
    <section className="tek-bilgi-karti"><article className="iletisim-sayfa-karti"><div className="bilgi-ikon">✉</div><span className="ust-etiket">{ingilizce ? "CONTACT" : "İLETİŞİM"}</span><h2>{ingilizce ? "Share your ideas with us." : "Fikirlerinizi bizimle paylaşın."}</h2><p>{ingilizce ? "You can email us recipe suggestions, content collaborations and app improvement ideas. We reply on weekdays within two business days." : "Yeni tarif önerilerinizi, içerik iş birliklerinizi ve uygulama geliştirme fikirlerinizi e-posta üzerinden iletebilirsiniz. Mesajlara hafta içi en geç iki iş günü içinde dönüş yapıyoruz."}</p><div className="degerler"><span>✓ {ingilizce ? "Recipe suggestion" : "Yeni tarif önerisi"}</span><span>✓ {ingilizce ? "Collaboration request" : "İş birliği talebi"}</span><span>✓ {ingilizce ? "App improvement idea" : "Uygulama geliştirme fikri"}</span></div><a className="ana-buton" href="mailto:merhaba@mutfaktabugun.com?subject=Mutfakta%20Bug%C3%BCn%20ileti%C5%9Fim">{ingilizce ? "Send a message" : "Mesaj gönder"}</a><p className="eposta-adresi">{ingilizce ? "Email" : "E-posta"}: merhaba@mutfaktabugun.com</p><p className="eposta-adresi">{ingilizce ? "Phone" : "Telefon"}: <a href="tel:+902125550123">+90 (212) 555 01 23</a></p></article></section>
  </main>;
}

function DurumEkrani({ emoji, baslik, metin, children, yukleniyor = false }: { emoji: string; baslik: string; metin?: string; children?: ReactNode; yukleniyor?: boolean }) {
  return <main className="uygulama durum-ekrani"><div className={yukleniyor ? "durum-emoji yukleme-svg" : "durum-emoji"}>{yukleniyor ? <LoadingSvg /> : emoji}</div><span className="ust-etiket">AFİYET OLSUN</span><h1>{baslik}</h1>{metin && <p>{metin}</p>}{children}</main>;
}

export default App;
