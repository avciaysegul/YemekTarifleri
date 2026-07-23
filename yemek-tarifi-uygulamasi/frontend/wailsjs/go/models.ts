export namespace main {
	
	export class SenaryoCevabi {
	    sayi?: number;
	    metin?: string;
	    onay?: boolean;
	    eylem?: string;
	    iptal?: boolean;
	
	    static createFrom(source: any = {}) {
	        return new SenaryoCevabi(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.sayi = source["sayi"];
	        this.metin = source["metin"];
	        this.onay = source["onay"];
	        this.eylem = source["eylem"];
	        this.iptal = source["iptal"];
	    }
	}
	export class SenaryoSecenegi {
	    value: string;
	    label: string;
	    visualKey?: string;
	
	    static createFrom(source: any = {}) {
	        return new SenaryoSecenegi(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.value = source["value"];
	        this.label = source["label"];
	        this.visualKey = source["visualKey"];
	    }
	}
	export class UIKomutu {
	    tur: string;
	    baslik: string;
	    mesaj: string;
	    visualKey?: string;
	    onayMetni?: string;
	    iptalMetni?: string;
	    varsayilan?: number;
	    minimum?: number;
	    maksimum?: number;
	    sure?: number;
	    secenekler?: SenaryoSecenegi[];
	    ogeler?: string[];
	
	    static createFrom(source: any = {}) {
	        return new UIKomutu(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.tur = source["tur"];
	        this.baslik = source["baslik"];
	        this.mesaj = source["mesaj"];
	        this.visualKey = source["visualKey"];
	        this.onayMetni = source["onayMetni"];
	        this.iptalMetni = source["iptalMetni"];
	        this.varsayilan = source["varsayilan"];
	        this.minimum = source["minimum"];
	        this.maksimum = source["maksimum"];
	        this.sure = source["sure"];
	        this.secenekler = this.convertValues(source["secenekler"], SenaryoSecenegi);
	        this.ogeler = source["ogeler"];
	    }
	
		convertValues(a: any, classs: any, asMap: boolean = false): any {
		    if (!a) {
		        return a;
		    }
		    if (a.slice && a.map) {
		        return (a as any[]).map(elem => this.convertValues(elem, classs));
		    } else if ("object" === typeof a) {
		        if (asMap) {
		            for (const key of Object.keys(a)) {
		                a[key] = new classs(a[key]);
		            }
		            return a;
		        }
		        return new classs(a);
		    }
		    return a;
		}
	}
	export class SenaryoGuncellemesi {
	    oturumId: string;
	    istekId?: string;
	    durum: string;
	    ilerleme: number;
	    ilerlemeMesaji?: string;
	    komut?: UIKomutu;
	
	    static createFrom(source: any = {}) {
	        return new SenaryoGuncellemesi(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.oturumId = source["oturumId"];
	        this.istekId = source["istekId"];
	        this.durum = source["durum"];
	        this.ilerleme = source["ilerleme"];
	        this.ilerlemeMesaji = source["ilerlemeMesaji"];
	        this.komut = this.convertValues(source["komut"], UIKomutu);
	    }
	
		convertValues(a: any, classs: any, asMap: boolean = false): any {
		    if (!a) {
		        return a;
		    }
		    if (a.slice && a.map) {
		        return (a as any[]).map(elem => this.convertValues(elem, classs));
		    } else if ("object" === typeof a) {
		        if (asMap) {
		            for (const key of Object.keys(a)) {
		                a[key] = new classs(a[key]);
		            }
		            return a;
		        }
		        return new classs(a);
		    }
		    return a;
		}
	}
	
	export class TarifCevirisi {
	    ad: string;
	    aciklama: string;
	
	    static createFrom(source: any = {}) {
	        return new TarifCevirisi(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.ad = source["ad"];
	        this.aciklama = source["aciklama"];
	    }
	}
	export class TarifOzeti {
	    id: number;
	    ad: string;
	    emoji: string;
	    aciklama: string;
	    sure: string;
	    zorluk: string;
	    kategori: string;
	    ingilizce: TarifCevirisi;
	
	    static createFrom(source: any = {}) {
	        return new TarifOzeti(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.id = source["id"];
	        this.ad = source["ad"];
	        this.emoji = source["emoji"];
	        this.aciklama = source["aciklama"];
	        this.sure = source["sure"];
	        this.zorluk = source["zorluk"];
	        this.kategori = source["kategori"];
	        this.ingilizce = this.convertValues(source["ingilizce"], TarifCevirisi);
	    }
	
		convertValues(a: any, classs: any, asMap: boolean = false): any {
		    if (!a) {
		        return a;
		    }
		    if (a.slice && a.map) {
		        return (a as any[]).map(elem => this.convertValues(elem, classs));
		    } else if ("object" === typeof a) {
		        if (asMap) {
		            for (const key of Object.keys(a)) {
		                a[key] = new classs(a[key]);
		            }
		            return a;
		        }
		        return new classs(a);
		    }
		    return a;
		}
	}

}

