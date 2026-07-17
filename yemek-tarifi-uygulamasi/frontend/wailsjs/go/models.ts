export namespace main {
	
	export class TarifAdimi {
	    baslik: string;
	    aciklama: string;
	    emoji: string;
	    animasyon: string;
	    bekleme: string;
	
	    static createFrom(source: any = {}) {
	        return new TarifAdimi(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.baslik = source["baslik"];
	        this.aciklama = source["aciklama"];
	        this.emoji = source["emoji"];
	        this.animasyon = source["animasyon"];
	        this.bekleme = source["bekleme"];
	    }
	}
	export class TarifAkisiDurumu {
	    aktifAdim: number;
	    ilerleme: number;
	    tamamlandi: boolean;
	    bekleme: string;
	    oncekiAdimVar: boolean;
	    ileriTamamlar: boolean;
	
	    static createFrom(source: any = {}) {
	        return new TarifAkisiDurumu(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.aktifAdim = source["aktifAdim"];
	        this.ilerleme = source["ilerleme"];
	        this.tamamlandi = source["tamamlandi"];
	        this.bekleme = source["bekleme"];
	        this.oncekiAdimVar = source["oncekiAdimVar"];
	        this.ileriTamamlar = source["ileriTamamlar"];
	    }
	}
	export class TarifCevirisi {
	    ad: string;
	    aciklama: string;
	    malzemeler: string[];
	    adimlar: TarifAdimi[];
	
	    static createFrom(source: any = {}) {
	        return new TarifCevirisi(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.ad = source["ad"];
	        this.aciklama = source["aciklama"];
	        this.malzemeler = source["malzemeler"];
	        this.adimlar = this.convertValues(source["adimlar"], TarifAdimi);
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
	export class YemekTarifi {
	    id: number;
	    ad: string;
	    emoji: string;
	    aciklama: string;
	    sure: string;
	    zorluk: string;
	    kategori: string;
	    malzemeler: string[];
	    adimlar: TarifAdimi[];
	    ingilizce?: TarifCevirisi;
	
	    static createFrom(source: any = {}) {
	        return new YemekTarifi(source);
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
	        this.malzemeler = source["malzemeler"];
	        this.adimlar = this.convertValues(source["adimlar"], TarifAdimi);
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

