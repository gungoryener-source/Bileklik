/* Bileklik sitesinin dil katmanı: Türkçe (sayfanın kendisi), English,
   العربية (sağdan sola), Deutsch.

   Dil sırası: adresteki ?lang=, sonra elle seçilen dil (localStorage
   "bk-lang"), sonra bağlanılan ülke, sonra tarayıcının dilleri, en sonda
   İngilizce. Statik sitede sunucu olmadığından ülke tarayıcının saat
   diliminden çıkarılır (Europe/Istanbul -> TR gibi); portal aynı tabloyu
   kullanır (portal/lib/src/locale.dart, test ikisinin aynı kaldığını denetler).

   Çeviri anahtarı sayfadaki Türkçe metnin kendisidir (boşluklar tek boşluğa
   indirilir). İçinde bağlantı ya da kalın yazı gibi satır içi öğe olan
   paragraflar bütün olarak (innerHTML) çevrilir; geri kalan her metin parçası
   ayrı çevrilir. Sözlükler i18n/<dil>.js dosyalarındadır; eksik anahtar
   Türkçe kalır ve ?i18n=eksik ile konsolda listelenir.

   Sayfa betikleri anlık metinler için window.bkI18n.t("Türkçe {ad}", {ad: …})
   çağırır ve dil değişince "bk:lang" olayını dinler. */
(function () {
  "use strict";
  var SUPPORTED = ["tr", "en", "ar", "de"];
  var NAMES = { tr: "Türkçe", en: "English", ar: "العربية", de: "Deutsch" };
  var STORE_KEY = "bk-lang";
  // Ülke -> dil. Burada olmayan ülkede tarayıcı dili, o da yoksa İngilizce.
  var COUNTRY_LANG = {
    TR: "tr",
    DE: "de", AT: "de", CH: "de", LI: "de",
    SA: "ar", AE: "ar", QA: "ar", BH: "ar", KW: "ar", OM: "ar", YE: "ar",
    IQ: "ar", JO: "ar", SY: "ar", LB: "ar", PS: "ar", EG: "ar", LY: "ar",
    TN: "ar", DZ: "ar", MA: "ar", EH: "ar", SD: "ar", MR: "ar", SO: "ar",
    DJ: "ar", KM: "ar"
  };
  // Saat dilimi -> ülke (yalnızca yukarıdaki ülkeler).
  var TZ_COUNTRY = {
    "Europe/Istanbul": "TR", "Asia/Istanbul": "TR", "Turkey": "TR",
    "Europe/Berlin": "DE", "Europe/Busingen": "DE", "Europe/Vienna": "AT",
    "Europe/Zurich": "CH", "Europe/Vaduz": "LI",
    "Asia/Riyadh": "SA", "Asia/Dubai": "AE", "Asia/Qatar": "QA",
    "Asia/Bahrain": "BH", "Asia/Kuwait": "KW", "Asia/Muscat": "OM",
    "Asia/Aden": "YE", "Asia/Baghdad": "IQ", "Asia/Amman": "JO",
    "Asia/Damascus": "SY", "Asia/Beirut": "LB", "Asia/Gaza": "PS",
    "Asia/Hebron": "PS", "Africa/Cairo": "EG", "Egypt": "EG",
    "Africa/Tripoli": "LY", "Libya": "LY", "Africa/Tunis": "TN",
    "Africa/Algiers": "DZ", "Africa/Casablanca": "MA", "Africa/El_Aaiun": "EH",
    "Africa/Khartoum": "SD", "Africa/Nouakchott": "MR",
    "Africa/Mogadishu": "SO", "Africa/Djibouti": "DJ", "Indian/Comoro": "KM"
  };
  var INLINE = { A: 1, STRONG: 1, EM: 1, B: 1, I: 1, SPAN: 1, SMALL: 1, CODE: 1, BR: 1, ABBR: 1, KBD: 1, SUP: 1, SUB: 1, MARK: 1, Q: 1, TIME: 1, BDI: 1 };
  var SKIP = { SCRIPT: 1, STYLE: 1, NOSCRIPT: 1, TEMPLATE: 1, PRE: 1 };
  var ATTRS = ["alt", "placeholder", "aria-label", "title"];
  var LETTER = (function () { try { return new RegExp("\\p{L}", "u"); } catch (e) { return /[A-Za-z\u00C0-\uFFFF]/; } })();

  function read(key) { try { return localStorage.getItem(key); } catch (e) { return null; } }
  function write(key, v) { try { localStorage.setItem(key, v); } catch (e) {} }
  function norm(s) { return String(s).replace(/\s+/g, " ").trim(); }

  function timeZone() {
    try { return Intl.DateTimeFormat().resolvedOptions().timeZone || ""; } catch (e) { return ""; }
  }
  function countryFromTimeZone(tz) { return TZ_COUNTRY[tz] || null; }
  function fromBrowser() {
    var list = navigator.languages && navigator.languages.length ? navigator.languages : [navigator.language || ""];
    for (var i = 0; i < list.length; i++) {
      var l = String(list[i] || "").toLowerCase().split("-")[0];
      if (SUPPORTED.indexOf(l) >= 0) return l;
    }
    return null;
  }
  function fromQuery() {
    var m = /[?&]lang=([a-z]{2})/.exec(location.search);
    return m && SUPPORTED.indexOf(m[1]) >= 0 ? m[1] : null;
  }
  /** Otomatik dil: ülke, sonra tarayıcı, sonra İngilizce. */
  function automatic() {
    var c = countryFromTimeZone(timeZone());
    return (c && COUNTRY_LANG[c]) || fromBrowser() || "en";
  }
  function initial() {
    var q = fromQuery();
    if (q) { write(STORE_KEY, q); return q; }
    var saved = read(STORE_KEY);
    if (saved && SUPPORTED.indexOf(saved) >= 0) return saved;
    return automatic();
  }

  var dicts = window.BK_I18N = window.BK_I18N || {};
  var lang = initial();
  var root = document.documentElement;
  // Kaynak dil: sayfanın yazıldığı dil (data-source-lang, yoksa tr).
  var source = root.getAttribute("data-source-lang") || "tr";
  root.lang = lang;
  root.dir = lang === "ar" ? "rtl" : "ltr";
  var base = (function () {
    var s = document.currentScript && document.currentScript.src;
    return s ? s.replace(/[^/]*$/, "") : "";
  })();
  if (lang !== source && !dicts[lang]) {
    root.classList.add("bk-i18n-wait");
    // Ayrıştırıcı burada durur, sözlük gövdeden önce gelir; Türkçe görünüp
    // sonra değişmez. Yüklenemezse 2 sn sonra sayfa Türkçe açılır.
    document.write('<script src="' + base + "i18n/" + lang + '.js"><\/script>');
    setTimeout(function () { root.classList.remove("bk-i18n-wait"); }, 2000);
  }

  // Düğüm -> özgün metin. Çeviri hep özgünden yapılır, dil dönüşte bozulmaz.
  var originals = [];
  var collected = false;
  function hasLetters(s) { return LETTER.test(s); }
  function skipped(el) {
    return SKIP[el.tagName] || el.hasAttribute("data-i18n-skip") || el.getAttribute("translate") === "no" || (el !== root && el.hasAttribute("lang"));
  }
  /** Satır içi öğelerle karışık, bütün çevrilecek paragraf mı? */
  function isBlock(el) {
    var text = false, child = false;
    for (var n = el.firstChild; n; n = n.nextSibling) {
      if (n.nodeType === 3 && norm(n.nodeValue)) text = true;
      else if (n.nodeType === 1) child = true;
    }
    if (!text || !child) return false;
    var all = el.getElementsByTagName("*");
    for (var i = 0; i < all.length; i++) if (!INLINE[all[i].tagName]) return false;
    return true;
  }
  function collect(el) {
    for (var a = 0; a < ATTRS.length; a++) {
      var v = el.getAttribute(ATTRS[a]);
      if (v && hasLetters(v)) originals.push({ kind: "attr", el: el, name: ATTRS[a], key: norm(v), raw: v });
    }
    if (skipped(el)) return;
    if (el !== root && el.tagName !== "BODY" && isBlock(el)) {
      originals.push({ kind: "html", el: el, key: norm(el.innerHTML), raw: el.innerHTML });
      return;
    }
    for (var n = el.firstChild; n; n = n.nextSibling) {
      if (n.nodeType === 3) {
        var t = n.nodeValue;
        if (norm(t) && hasLetters(t)) originals.push({ kind: "text", node: n, key: norm(t), raw: t });
      } else if (n.nodeType === 1) collect(n);
    }
  }
  function collectAll() {
    if (collected) return;
    collected = true;
    originals.push({ kind: "title", key: norm(document.title), raw: document.title });
    var metas = document.querySelectorAll('meta[name="description"], meta[property="og:title"], meta[property="og:description"]');
    for (var i = 0; i < metas.length; i++) originals.push({ kind: "attr", el: metas[i], name: "content", key: norm(metas[i].content), raw: metas[i].content });
    collect(document.body);
  }
  function lookup(key) {
    if (lang === source) return null;
    var d = dicts[lang];
    return d && Object.prototype.hasOwnProperty.call(d, key) ? d[key] : null;
  }
  /** Anlık metin: Türkçe kaynak, {ad} yer tutucularıyla. */
  function t(text, vars) {
    var s = lookup(norm(text));
    if (s == null) s = text;
    if (vars) s = s.replace(/\{(\w+)\}/g, function (m, k) { return vars[k] != null ? vars[k] : m; });
    return s;
  }
  var missing = [];
  function apply() {
    collectAll();
    missing = [];
    for (var i = 0; i < originals.length; i++) {
      var o = originals[i];
      var tr = lookup(o.key);
      if (tr == null && lang !== source) missing.push(o.key);
      if (o.kind === "text") {
        // Baştaki ve sondaki boşluk korunur (komşu öğelerle aralık için).
        o.node.nodeValue = tr == null ? o.raw : o.raw.match(/^\s*/)[0] + tr + o.raw.match(/\s*$/)[0];
      } else if (o.kind === "html") {
        o.el.innerHTML = tr == null ? o.raw : tr;
      } else if (o.kind === "attr") {
        o.el.setAttribute(o.name, tr == null ? o.raw : tr);
      } else if (o.kind === "title") {
        document.title = tr == null ? o.raw : tr;
      }
    }
    var og = document.querySelector('meta[property="og:locale"]');
    if (og) og.content = { tr: "tr_TR", en: "en_US", ar: "ar_AR", de: "de_DE" }[lang];
    // Portala giden bağlantılar seçilen dili taşır.
    var links = document.querySelectorAll("a[data-lang-link]");
    for (var j = 0; j < links.length; j++) {
      var a = links[j];
      var href = a.getAttribute("href");
      var hash = href.indexOf("#/");
      if (hash >= 0) {
        // Tarayıcıdaki portal demosu: yol adresin # kısmında (#/panel?lang=ar).
        var route = href.slice(hash).replace(/([?&])lang=[a-z]{2}(&|$)/, "$1").replace(/[?&]$/, "");
        a.setAttribute("href", href.slice(0, hash) + route + (route.indexOf("?") >= 0 ? "&" : "?") + "lang=" + lang);
        continue;
      }
      try {
        var u = new URL(href, location.href);
        u.searchParams.set("lang", lang);
        a.setAttribute("href", u.toString());
      } catch (e) {}
    }
    var hidden = document.querySelectorAll('input[name="lang"]');
    for (var h = 0; h < hidden.length; h++) hidden[h].value = lang;
    var pickers = document.querySelectorAll("select[data-lang-picker]");
    for (var p = 0; p < pickers.length; p++) pickers[p].value = lang;
    if (/[?&]i18n=eksik/.test(location.search) && missing.length) {
      console.warn("Bileklik i18n: " + lang + " için " + missing.length + " eksik metin", missing);
    }
    root.classList.remove("bk-i18n-wait");
  }
  function setLang(next, manual) {
    if (SUPPORTED.indexOf(next) < 0) return;
    if (manual) write(STORE_KEY, next);
    lang = next;
    root.lang = next;
    root.dir = next === "ar" ? "rtl" : "ltr";
    var done = function () {
      apply();
      try { document.dispatchEvent(new CustomEvent("bk:lang", { detail: next })); } catch (e) {}
    };
    if (next === source || dicts[next]) { done(); return; }
    var s = document.createElement("script");
    s.src = base + "i18n/" + next + ".js";
    s.onload = done;
    s.onerror = done;
    document.head.appendChild(s);
  }
  function setupPickers() {
    var pickers = document.querySelectorAll("select[data-lang-picker]");
    for (var i = 0; i < pickers.length; i++) {
      var sel = pickers[i];
      if (!sel.options.length) {
        for (var k = 0; k < SUPPORTED.length; k++) {
          var opt = document.createElement("option");
          opt.value = SUPPORTED[k];
          opt.lang = SUPPORTED[k];
          opt.textContent = NAMES[SUPPORTED[k]];
          sel.appendChild(opt);
        }
      }
      sel.value = lang;
      sel.addEventListener("change", function (e) { setLang(e.target.value, true); });
    }
  }
  function start() { setupPickers(); apply(); }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", start);
  else start();

  window.bkI18n = {
    get lang() { return lang; },
    supported: SUPPORTED,
    names: NAMES,
    t: t,
    set: function (l) { setLang(l, true); },
    automatic: automatic,
    countryFromTimeZone: countryFromTimeZone,
    countryLanguage: function (c) { return COUNTRY_LANG[String(c || "").toUpperCase()] || null; },
    missing: function () { return missing.slice(); },
    /** Sayfadaki çevrilecek tüm anahtarlar (sözlük hazırlamak için). */
    keys: function () { collectAll(); return originals.map(function (o) { return o.key; }); }
  };
})();
