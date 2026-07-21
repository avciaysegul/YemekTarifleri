import { FormEvent, useEffect, useMemo, useState } from "react";
import { SenaryoBaslat, SenaryoCevapla, SenaryoIptal, TarifleriGetir } from "../wailsjs/go/main/App";
import hero from "./assets/images/mutfak-food-hero-v2.png";
import "./App.css";

export type Dil = "tr" | "en";
type Sayfa = "home" | "about" | "privacy";
type Ceviri = { ad: string; aciklama: string };
export type Tarif = { id: number; ad: string; emoji: string; aciklama: string; sure: string; zorluk: string; kategori: string; senaryo: string; ingilizce: Ceviri };
type Secenek = { value: string; label: string; visualKey?: string };
type Komut = { tur: string; baslik: string; mesaj: string; visualKey?: string; onayMetni?: string; iptalMetni?: string; varsayilan?: number; minimum?: number; maksimum?: number; sure?: number; secenekler?: Secenek[]; ogeler?: string[] };
type Guncelleme = { oturumId: string; istekId?: string; durum: "waiting" | "success" | "fail"; ilerleme: number; ilerlemeMesaji?: string; komut?: Komut };
type Cevap = { sayi?: number; metin?: string; onay?: boolean; eylem?: string; iptal?: boolean };

const metin = {
  tr: { title: "Mutfakta Bugün", lead: "Seçimlerinize uyum sağlayan tariflerle mutfakta adım adım ilerleyin.", eyebrow: "AKILLI TARİF REHBERİ", search: "Tarif ara", searchLabel: "Tariflerde ara", start: "Tarife başla", dynamic: "Miktarlar ve süreler seçimlerinize göre hesaplanır.", back: "Tarifi kapat", cancel: "İptal", yes: "Evet", no: "Hayır", ok: "Tamam", save: "Kaydet", timerStart: "Başlat", pause: "Duraklat", resume: "Devam et", close: "Sayacı kapat", loading: "Tarifler yükleniyor…", error: "Bir hata oluştu", exit: "Çalışan tarif iptal edilecek. Çıkılsın mı?", progress: "Tarif ilerlemesi", recipes: "Tarifleri keşfet", all: "Tümü", noResults: "Aradığınız tarifi bulamadık", noResultsText: "Aramanızı değiştirin veya tüm kategorileri yeniden gösterin.", clear: "Aramayı temizle", home: "Tarifler", about: "Hakkında", privacy: "Kişisel Veriler", contact: "İletişim", waiting: "Sıradaki adım", success: "Tarif tamamlandı", fail: "Tarif sonlandırıldı", numberLabel: "Değerinizi girin" },
  en: { title: "In the Kitchen Today", lead: "Cook step by step with recipes that adapt to your choices.", eyebrow: "SMART COOKING GUIDE", search: "Search recipes", searchLabel: "Search recipes", start: "Start recipe", dynamic: "Quantities and timings are calculated from your choices.", back: "Close recipe", cancel: "Cancel", yes: "Yes", no: "No", ok: "OK", save: "Save", timerStart: "Start", pause: "Pause", resume: "Resume", close: "Close timer", loading: "Loading recipes…", error: "Something went wrong", exit: "The running recipe will be cancelled. Exit?", progress: "Recipe progress", recipes: "Explore recipes", all: "All", noResults: "We couldn't find that recipe", noResultsText: "Try another search or show all categories again.", clear: "Clear search", home: "Recipes", about: "About", privacy: "Personal Data", contact: "Contact", waiting: "Next step", success: "Recipe completed", fail: "Recipe ended", numberLabel: "Enter your value" }
};

const kategoriCeviri: Record<string, string> = { "Ana Yemekler": "Main dishes", "Tatlılar": "Desserts", "İçecekler": "Drinks" };
const zorlukCeviri: Record<string, string> = { Kolay: "Easy", Orta: "Medium", Zor: "Hard" };
export const kategoriMetni = (kategori: string, dil: Dil) => dil === "en" ? kategoriCeviri[kategori] ?? kategori : kategori;
export const zorlukMetni = (zorluk: string, dil: Dil) => dil === "en" ? zorlukCeviri[zorluk] ?? zorluk : zorluk;
export const sureMetni = (sure: string, dil: Dil) => dil === "en" ? sure.replace(/\s*dakika$/i, " min") : sure;

function App() {
  const [dil, setDil] = useState<Dil>(() => localStorage.getItem("uygulama-dili") === "en" ? "en" : "tr");
  const [sayfa, setSayfa] = useState<Sayfa>("home");
  const [tarifler, setTarifler] = useState<Tarif[]>([]);
  const [arama, setArama] = useState("");
  const [kategori, setKategori] = useState("all");
  const [secili, setSecili] = useState<Tarif | null>(null);
  const [guncelleme, setGuncelleme] = useState<Guncelleme | null>(null);
  const [hata, setHata] = useState("");
  const [yukleniyor, setYukleniyor] = useState(true);
  const t = metin[dil];

  useEffect(() => { TarifleriGetir().then(x => setTarifler(x as unknown as Tarif[])).catch(e => setHata(String(e))).finally(() => setYukleniyor(false)); }, []);
  useEffect(() => { localStorage.setItem("uygulama-dili", dil); document.documentElement.lang = dil; }, [dil]);
  useEffect(() => { window.scrollTo({ top: 0, behavior: "auto" }); }, [secili, sayfa]);

  const kategoriler = useMemo(() => Array.from(new Set(tarifler.map(r => r.kategori))), [tarifler]);
  const liste = useMemo(() => tarifler.filter(r => {
    const x = dil === "en" ? r.ingilizce : r;
    const metinAlani = `${x.ad} ${x.aciklama} ${kategoriMetni(r.kategori, dil)} ${zorlukMetni(r.zorluk, dil)}`;
    const eslesiyor = metinAlani.toLocaleLowerCase(dil === "en" ? "en-US" : "tr-TR").includes(arama.trim().toLocaleLowerCase(dil === "en" ? "en-US" : "tr-TR"));
    return eslesiyor && (kategori === "all" || r.kategori === kategori);
  }), [tarifler, arama, kategori, dil]);

  async function baslat(r: Tarif) { try { setHata(""); setSecili(r); setGuncelleme(await SenaryoBaslat(r.id, dil) as unknown as Guncelleme); } catch (e) { setSecili(null); setHata(String(e)); } }
  async function cevapla(c: Cevap) { if (!guncelleme?.istekId) return; try { setGuncelleme(await SenaryoCevapla(guncelleme.oturumId, guncelleme.istekId, c as never) as unknown as Guncelleme); } catch (e) { setHata(String(e)); } }
  async function kapat() { if (guncelleme?.durum === "waiting" && !window.confirm(t.exit)) return; try { if (guncelleme?.oturumId) await SenaryoIptal(guncelleme.oturumId); } finally { setGuncelleme(null); setSecili(null); } }
  function anaSayfayaDon() { setSayfa("home"); setArama(""); setKategori("all"); }

  if (yukleniyor) return <Durum text={t.loading} />;
  if (secili && guncelleme) return <SenaryoEkrani tarif={secili} dil={dil} g={guncelleme} cevapla={cevapla} kapat={kapat} />;

  return <main className="uygulama">
    <header className="site-baslik">
      <button className="marka" type="button" onClick={anaSayfayaDon} aria-label={t.home}><span>Mutfakta</span><strong>Bugün</strong></button>
      <nav className="ust-menu" aria-label={dil === "en" ? "Main navigation" : "Ana menü"}>
        <button className={sayfa === "home" ? "aktif" : ""} onClick={() => setSayfa("home")}>{t.home}</button>
        <button className={sayfa === "about" ? "aktif" : ""} onClick={() => setSayfa("about")}>{t.about}</button>
        <button className={sayfa === "privacy" ? "aktif" : ""} onClick={() => setSayfa("privacy")}>{t.privacy}</button>
      </nav>
      <div className="dil-secici" aria-label={dil === "en" ? "Language" : "Dil"}>
        <button type="button" aria-pressed={dil === "tr"} className={dil === "tr" ? "aktif" : ""} onClick={() => setDil("tr")}>TR</button>
        <button type="button" aria-pressed={dil === "en"} className={dil === "en" ? "aktif" : ""} onClick={() => setDil("en")}>EN</button>
      </div>
    </header>

    {hata && <div className="hata-bandi" role="alert">{t.error}: {hata}</div>}
    {sayfa === "home" && <>
      <section className="hero-alani" style={{ backgroundImage: `linear-gradient(90deg,rgba(8,10,13,.91),rgba(8,10,13,.36)),url(${hero})` }}>
        <div className="hero-icerik"><span className="hero-etiket">{t.eyebrow}</span><h1>{t.title}</h1><p>{t.lead}</p>
          <div className="hero-arama"><label><span aria-hidden="true">⌕</span><span className="sr-only">{t.searchLabel}</span><input value={arama} onChange={e => setArama(e.target.value)} placeholder={t.search} aria-label={t.searchLabel} /></label></div>
        </div>
      </section>
      <section className="tarif-bolumu" aria-labelledby="tarif-basligi">
        <div className="bolum-basligi"><div><span className="bolum-kicker">{dil === "en" ? "CHOOSE YOUR NEXT MEAL" : "SIRADAKİ LEZZETİNİ SEÇ"}</span><h2 id="tarif-basligi">{t.recipes}</h2></div><span aria-label={`${liste.length} ${dil === "en" ? "recipes" : "tarif"}`}>{liste.length}</span></div>
        <div className="kategori-filtreleri" aria-label={dil === "en" ? "Recipe categories" : "Tarif kategorileri"}>
          <button aria-pressed={kategori === "all"} className={kategori === "all" ? "kategori aktif" : "kategori"} onClick={() => setKategori("all")}>{t.all}</button>
          {kategoriler.map(k => <button key={k} aria-pressed={kategori === k} className={kategori === k ? "kategori aktif" : "kategori"} onClick={() => setKategori(k)}>{kategoriMetni(k, dil)}</button>)}
        </div>
        {liste.length ? <div className="tarif-listesi">{liste.map(r => <TarifKarti key={r.id} tarif={r} dil={dil} baslat={baslat} />)}</div> : <div className="bos-durum" role="status"><AnimatedBowl /><h2>{t.noResults}</h2><p>{t.noResultsText}</p><button className="ana-buton" onClick={() => { setArama(""); setKategori("all"); }}>{t.clear}</button></div>}
      </section>
      <InfoStrip dil={dil} sayfaAc={setSayfa} />
    </>}
    {sayfa === "about" && <AboutPage dil={dil} />}
    {sayfa === "privacy" && <PrivacyPage dil={dil} />}
  </main>;
}

function TarifKarti({ tarif, dil, baslat }: { tarif: Tarif; dil: Dil; baslat: (r: Tarif) => Promise<void> }) {
  const t = metin[dil]; const x = dil === "en" ? tarif.ingilizce : tarif;
  return <article className="tarif-karti"><div className="kart-emoji" aria-hidden="true">{tarif.id === 15 ? <><VisualScene anahtar="baked-pasta" emoji={tarif.emoji} compact /><i /></> : <><span>{tarif.emoji}</span><i /></>}</div><div className="kart-icerigi"><span className="ust-etiket">{kategoriMetni(tarif.kategori, dil)}</span><h3>{x.ad}</h3><p>{x.aciklama}</p><div className="tarif-bilgileri"><span>⏱ {sureMetni(tarif.sure, dil)}</span><span>◈ {zorlukMetni(tarif.zorluk, dil)}</span></div><p className="dinamik-not">{t.dynamic}</p><button className="ana-buton" onClick={() => void baslat(tarif)}>{t.start}<span aria-hidden="true">→</span></button></div></article>;
}

function InfoStrip({ dil, sayfaAc }: { dil: Dil; sayfaAc: (s: Sayfa) => void }) { const t = metin[dil]; return <section className="bilgi-alani"><div><span className="bolum-kicker">{t.about}</span><h2>{dil === "en" ? "A calm, private kitchen companion" : "Sade, kişisel ve güvenli bir mutfak yardımcısı"}</h2><p>{dil === "en" ? "Recipes run locally on your device and adapt to the answers you give during cooking." : "Tarifler cihazınızda çalışır ve yemek sırasında verdiğiniz yanıtlara göre size uyarlanır."}</p></div><div className="iletisim-karti"><AnimatedBowl /><h3>{t.contact}</h3><p>{dil === "en" ? "Questions, feedback or recipe suggestions are welcome." : "Soru, geri bildirim ve tarif önerilerinizi paylaşabilirsiniz."}</p><button className="ana-buton" onClick={() => sayfaAc("about")}>{dil === "en" ? "Contact details" : "İletişim bilgileri"}</button></div></section>; }

function AboutPage({ dil }: { dil: Dil }) { const t = metin[dil]; return <section className="bilgi-sayfasi"><div className="bilgi-kahraman"><AnimatedBowl /><span className="bolum-kicker">{t.about}</span><h1>{dil === "en" ? "Cooking guidance without the clutter" : "Karmaşa olmadan, adım adım yemek rehberi"}</h1><p>{dil === "en" ? "Mutfakta Bugün turns each recipe into a clear interactive flow and recalculates quantities from your choices." : "Mutfakta Bugün, her tarifi anlaşılır bir etkileşimli akışa dönüştürür ve miktarları seçimlerinize göre yeniden hesaplar."}</p></div><div className="bilgi-kartlari"><article className="hakkimizda-karti"><div className="bilgi-ikon" aria-hidden="true">✦</div><span className="bolum-kicker">{dil === "en" ? "OUR APPROACH" : "YAKLAŞIMIMIZ"}</span><h2>{dil === "en" ? "Useful at the exact moment you need it" : "Tam ihtiyaç duyduğunuz anda faydalı"}</h2><p>{dil === "en" ? "Instead of a long static page, the app asks only what matters and presents the next action clearly." : "Uzun ve durağan bir sayfa yerine uygulama yalnızca gerekli soruları sorar ve sıradaki işlemi açıkça gösterir."}</p><div className="degerler"><span>✓ {dil === "en" ? "22 adaptive recipes" : "22 uyarlanabilir tarif"}</span><span>✓ {dil === "en" ? "Turkish and English" : "Türkçe ve İngilizce"}</span><span>✓ {dil === "en" ? "Works locally" : "Yerel çalışma"}</span></div></article><article className="iletisim-sayfa-karti"><div className="bilgi-ikon" aria-hidden="true">✉</div><span className="bolum-kicker">{t.contact}</span><h2>{dil === "en" ? "Let's improve the kitchen together" : "Mutfağı birlikte geliştirelim"}</h2><p>{dil === "en" ? "For feedback, accessibility issues and recipe suggestions, contact the developer." : "Geri bildirim, erişilebilirlik sorunları ve tarif önerileri için geliştiriciyle iletişime geçebilirsiniz."}</p><p className="eposta-adresi">Ayşegül Avcı<br />152927504+KLU5230505062@users.noreply.github.com</p><a className="ana-buton" href="mailto:152927504+KLU5230505062@users.noreply.github.com">{dil === "en" ? "Send an email" : "E-posta gönder"}</a></article></div></section>; }

function PrivacyPage({ dil }: { dil: Dil }) { return <section className="bilgi-sayfasi"><div className="bilgi-kahraman"><div className="bilgi-ikon merkez" aria-hidden="true">⌁</div><span className="bolum-kicker">{dil === "en" ? "PRIVACY" : "GİZLİLİK"}</span><h1>{dil === "en" ? "Your cooking choices stay on your device" : "Mutfak tercihleriniz cihazınızda kalır"}</h1><p>{dil === "en" ? "This version does not require an account and does not send recipe answers to an external service." : "Bu sürüm hesap gerektirmez ve tarif yanıtlarınızı harici bir servise göndermez."}</p></div><div className="gizlilik-listesi"><article><span>01</span><div><h2>{dil === "en" ? "Data we use" : "Kullandığımız veriler"}</h2><p>{dil === "en" ? "The app temporarily uses your recipe answers to calculate the current cooking flow. They are discarded when the session closes." : "Uygulama, mevcut yemek akışını hesaplamak için tarif yanıtlarınızı geçici olarak kullanır. Oturum kapandığında bu yanıtlar silinir."}</p></div></article><article><span>02</span><div><h2>{dil === "en" ? "Stored preference" : "Saklanan tercih"}</h2><p>{dil === "en" ? "Only your selected interface language is stored locally so the next launch opens in the same language." : "Yalnızca seçtiğiniz arayüz dili, sonraki açılışta aynı dili göstermek amacıyla yerel olarak saklanır."}</p></div></article><article><span>03</span><div><h2>{dil === "en" ? "No account or analytics" : "Hesap ve analiz yok"}</h2><p>{dil === "en" ? "There is no sign-up, advertising profile or built-in analytics tracking in this version." : "Bu sürümde üyelik, reklam profili veya yerleşik analiz takibi bulunmaz."}</p></div></article></div></section>; }

function SenaryoEkrani({ tarif, dil, g, cevapla, kapat }: { tarif: Tarif; dil: Dil; g: Guncelleme; cevapla: (c: Cevap) => Promise<void>; kapat: () => Promise<void> }) {
  const t = metin[dil]; const ad = dil === "en" ? tarif.ingilizce.ad : tarif.ad; const k = g.komut; const ilerleme = Math.max(0, Math.min(100, g.ilerleme));
  return <main className="uygulama senaryo-sayfasi"><header className="senaryo-ust"><button className="geri-buton" onClick={() => void kapat()}>← {t.back}</button><div><span aria-hidden="true">{tarif.emoji}</span><strong>{ad}</strong></div></header><div className="senaryo-ilerleme"><div className="ilerleme-cubugu" role="progressbar" aria-label={t.progress} aria-valuemin={0} aria-valuemax={100} aria-valuenow={Math.round(ilerleme)}><div className="ilerleme" style={{ width: `${ilerleme}%` }} /></div><span>{g.ilerlemeMesaji || `${Math.round(ilerleme)}%`}</span></div><section className={`komut-karti sonuc-${g.durum}`}><Gorsel anahtar={k?.visualKey} emoji={tarif.emoji} /><span className="ust-etiket">{g.durum === "waiting" ? t.waiting : g.durum === "success" ? t.success : t.fail}</span><h1>{k?.baslik || ad}</h1>{k?.mesaj && <p>{k.mesaj}</p>}{g.durum === "waiting" && k && <KomutGovdesi key={g.istekId} komut={k} cevapla={cevapla} dil={dil} />}{g.durum !== "waiting" && <button className="ana-buton" onClick={() => void kapat()}>{dil === "en" ? "Back to recipes" : "Tariflere dön"}</button>}</section></main>;
}

function KomutGovdesi({ komut, cevapla, dil }: { komut: Komut; cevapla: (c: Cevap) => Promise<void>; dil: Dil }) { const t = metin[dil]; const [sayi, setSayi] = useState(String(komut.varsayilan ?? "")); const inputId = "tarif-sayisi"; if (komut.tur === "number") return <form className="komut-form" onSubmit={(e: FormEvent) => { e.preventDefault(); const n = Number(sayi); if (Number.isFinite(n)) void cevapla({ sayi: n }); }}><label className="sr-only" htmlFor={inputId}>{komut.baslik || t.numberLabel}</label><input id={inputId} aria-label={komut.baslik || t.numberLabel} autoFocus type="number" value={sayi} min={komut.minimum} max={komut.maksimum} step="any" onChange={e => setSayi(e.target.value)} /><div className="komut-butonlari"><button type="button" className="ikincil-buton" onClick={() => void cevapla({ iptal: true })}>{komut.iptalMetni || t.cancel}</button><button className="ana-buton">{komut.onayMetni || t.save}</button></div></form>; if (komut.tur === "choice") return <div className="secenek-listesi">{komut.secenekler?.map(s => <button key={s.value} onClick={() => void cevapla({ metin: s.value })}><span aria-hidden="true">{ikon(s.visualKey || s.value)}</span><strong>{s.label}</strong></button>)}<button className="metin-buton" onClick={() => void cevapla({ iptal: true })}>{t.cancel}</button></div>; if (komut.tur === "confirm") return <div className="komut-butonlari"><button className="ikincil-buton" onClick={() => void cevapla({ onay: false })}>{komut.iptalMetni || t.no}</button><button className="ana-buton" onClick={() => void cevapla({ onay: true })}>{komut.onayMetni || t.yes}</button></div>; if (komut.tur === "list") return <><ul className="komut-listesi">{komut.ogeler?.map((x, i) => <li key={i}>{x}</li>)}</ul><button className="ana-buton" onClick={() => void cevapla({ onay: true })}>{komut.onayMetni || t.ok}</button></>; if (komut.tur === "timer") return <Sayac sure={komut.sure || 0} dil={dil} bitir={eylem => cevapla({ eylem })} />; return <button className="ana-buton" onClick={() => void cevapla({ onay: true })}>{komut.onayMetni || t.ok}</button>; }

export function Sayac({ sure, dil, bitir }: { sure: number; dil: Dil; bitir: (x: string) => Promise<void> }) { const t = metin[dil]; const [kalan, setKalan] = useState(sure); const [calisiyor, setCalisiyor] = useState(false); useEffect(() => { if (!calisiyor || kalan <= 0) return; const id = window.setInterval(() => setKalan(x => Math.max(0, x - 1)), 1000); return () => clearInterval(id); }, [calisiyor, kalan]); useEffect(() => { if (kalan === 0) void bitir("completed"); }, [kalan]); const dk = Math.floor(kalan / 60), sn = kalan % 60; return <div className="sayac"><div className="sayac-zaman" role="timer" aria-live="polite">{String(dk).padStart(2, "0")}:{String(sn).padStart(2, "0")}</div><div className="komut-butonlari">{!calisiyor && kalan === sure && <button className="ana-buton" onClick={() => setCalisiyor(true)}>{t.timerStart}</button>}{calisiyor && <button className="ikincil-buton" onClick={() => setCalisiyor(false)}>{t.pause}</button>}{!calisiyor && kalan < sure && kalan > 0 && <button className="ana-buton" onClick={() => setCalisiyor(true)}>{t.resume}</button>}<button className="metin-buton" onClick={() => void bitir("closed")}>{t.close}</button></div></div>; }
function Gorsel({ anahtar, emoji }: { anahtar?: string; emoji: string }) { return <div className="senaryo-gorsel"><VisualScene anahtar={anahtar} emoji={emoji} /></div>; }
function VisualScene({ anahtar, emoji, compact = false }: { anahtar?: string; emoji: string; compact?: boolean }) {
  if (anahtar === "baked-pasta") return <svg className={`recipe-visual baked-pasta-visual${compact ? " compact" : ""}`} viewBox="0 0 180 150" role="img" aria-label=""><ellipse className="plate-shadow" cx="90" cy="124" rx="58" ry="10"/><circle className="baked-backdrop" cx="90" cy="70" r="56"/><path className="baked-dish" d="M39 75h102l-10 42H49z"/><path className="baked-rim" d="M35 75h110"/><path className="pasta-line bp1" d="M52 87c12-10 21 10 33 0s21 10 33 0 18 7 22 2"/><path className="pasta-line bp2" d="M54 99c11-9 19 9 30 0s19 9 30 0 17 7 21 2"/><circle className="cheese-dot bc1" cx="65" cy="82" r="4"/><circle className="cheese-dot bc2" cx="101" cy="91" r="4"/><circle className="cheese-dot bc3" cx="123" cy="83" r="3"/><path className="heat heat-one" d="M68 65c-7-7 7-10 0-17"/><path className="heat heat-two" d="M90 62c-7-7 7-10 0-17"/><path className="heat heat-three" d="M112 65c-7-7 7-10 0-17"/><path className="spark sp1" d="M37 39l4 8 8 4-8 4-4 8-4-8-8-4 8-4z"/><path className="spark sp2" d="M143 31l3 6 6 3-6 3-3 6-3-6-6-3 6-3z"/></svg>;
  if (anahtar === "oven") return <svg className={`recipe-visual oven-visual${compact ? " compact" : ""}`} viewBox="0 0 180 150" role="img" aria-label=""><rect className="oven-shell" x="24" y="16" width="132" height="118" rx="20"/><circle className="oven-knob" cx="48" cy="38" r="6"/><circle className="oven-knob" cx="68" cy="38" r="6"/><path className="oven-window" d="M40 54h100v62H40z"/><rect className="casserole" x="55" y="77" width="70" height="28" rx="8"/><path className="pasta-line p1" d="M64 86c10-9 18 9 28 0s18 9 28 0"/><path className="pasta-line p2" d="M64 95c10-9 18 9 28 0s18 9 28 0"/><circle className="cheese-dot c1" cx="74" cy="83" r="3"/><circle className="cheese-dot c2" cx="104" cy="91" r="3"/><path className="heat heat-one" d="M68 70c-7-7 7-10 0-17"/><path className="heat heat-two" d="M90 70c-7-7 7-10 0-17"/><path className="heat heat-three" d="M112 70c-7-7 7-10 0-17"/></svg>;
  if (anahtar === "water" || anahtar === "soup") return <svg className="recipe-visual pot-visual" viewBox="0 0 180 150" role="img" aria-label=""><path className="steam s1" d="M65 47c-9-10 9-15 0-28"/><path className="steam s2" d="M90 43c-9-10 9-15 0-28"/><path className="steam s3" d="M115 47c-9-10 9-15 0-28"/><path className="pot-rim" d="M43 63h94"/><path className="pot-body" d="M48 64h84l-8 58H56z"/><path className="pot-handle" d="M48 76H30m102 0h18"/><circle className="bubble b1" cx="72" cy="78" r="5"/><circle className="bubble b2" cx="92" cy="88" r="4"/><circle className="bubble b3" cx="112" cy="75" r="6"/></svg>;
  if (anahtar === "chop") return <svg className="recipe-visual chop-visual" viewBox="0 0 180 150" role="img" aria-label=""><rect className="board" x="30" y="70" width="120" height="56" rx="15"/><circle className="veg v1" cx="72" cy="96" r="14"/><circle className="veg v2" cx="105" cy="99" r="12"/><path className="knife" d="M48 40l83 20-8 17-80-28z"/><path className="knife-handle" d="M48 40L30 31"/></svg>;
  if (["pasta", "rice", "salad", "beans", "dessert", "pancake", "smoothie", "meatball", "chocolate", "cookie", "lemon", "ayran", "potato", "chicken", "menemen", "pepper"].includes(anahtar || "")) return <svg className="recipe-visual bowl-visual" viewBox="0 0 180 150" role="img" aria-label=""><ellipse className="plate-shadow" cx="90" cy="124" rx="58" ry="10"/><path className="food-bowl" d="M36 66h108c-5 42-23 62-54 62S41 108 36 66z"/><path className="bowl-rim" d="M32 66h116"/><text className="food-emoji" x="90" y="78" textAnchor="middle">{ikon(anahtar) || emoji}</text><path className="spark sp1" d="M42 38l4 9 9 4-9 4-4 9-4-9-9-4 9-4z"/><path className="spark sp2" d="M138 30l3 6 6 3-6 3-3 6-3-6-6-3 6-3z"/></svg>;
  return <svg className="recipe-visual default-visual" viewBox="0 0 180 150" role="img" aria-label=""><circle className="visual-orbit" cx="90" cy="75" r="54"/><circle className="visual-core" cx="90" cy="75" r="42"/><text className="default-emoji" x="90" y="91" textAnchor="middle">{emoji}</text><circle className="orbit-dot" cx="90" cy="21" r="6"/></svg>;
}
function ikon(k?: string) { const m: Record<string, string> = { pasta: "🍝", water: "💧", pepper: "🌶️", chop: "🔪", soup: "🥣", salad: "🥗", chicken: "🍗", potato: "🥔", dessert: "🍮", oven: "♨️", pancake: "🥞", rice: "🍚", smoothie: "🍌", meatball: "🍖", beans: "🫛", chocolate: "🍫", cookie: "🍪", lemon: "🍋", ayran: "🥛", light: "◌", normal: "◉", rich: "●", soft: "〰", set: "✓", small: "●", medium: "●", large: "⬤" }; return k ? m[k] || "◆" : ""; }
function AnimatedBowl() { return <svg className="animated-bowl" viewBox="0 0 120 90" role="img" aria-label=""><path className="steam steam-one" d="M42 31c-8-8 8-12 0-21" /><path className="steam steam-two" d="M61 28c-8-8 8-12 0-21" /><path className="steam steam-three" d="M80 31c-8-8 8-12 0-21" /><path className="bowl" d="M19 39h82c-2 27-17 41-41 41S21 66 19 39Z" /><path className="bowl-rim" d="M15 39h90" /></svg>; }
function Durum({ text }: { text: string }) { return <main className="uygulama durum-ekrani"><AnimatedBowl /><h1>{text}</h1></main>; }
export default App;
