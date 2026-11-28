import 'locale.dart';

/// Hekim panelinin tasarım sistemi: tokenlar, yerleşim ve bileşenler.
///
/// Uygulamanın koyu Cam kimliği korunur (gökyüzü degradesi, cam yüzeyler,
/// turkuaz vurgu #45D6B8, yeşilden maviye ana düğme) ama panel bir iş
/// aracıdır: daha sık yerleşim, daha az yuvarlaklık, sakin yüzeyler.
/// Durum renkleri her yerde aynı anlamı taşır:
///
/// - `--st-stable`  turkuaz-yeşil: veri geliyor, sinyal yok
/// - `--st-watch`   mavi: izlenecek (tek değer, düşük uyum, eğilim)
/// - `--st-attn`    kehribar: bakılmalı
/// - `--st-crit`    ölçülü kırmızı: açık kritik uyarı
/// - `--st-off`     gri: izlenmiyor
///
/// Ölçüm renkleri uygulamanın `DataColors` değerleridir; aynı tür web'de de
/// aynı renkte görünür. Yazdırma (PDF rapor) açık zeminde kalır.
String panelCss() =>
    '''
:root { color-scheme: dark;
  --page: #0B0F15; --sky-1: #1B2945; --sky-2: #2C4469;
  --surface: rgba(19,24,32,.78); --surface-2: rgba(255,255,255,.035); --surface-3: rgba(255,255,255,.07); --solid: #151A22; --field: rgba(9,12,17,.6);
  --line: rgba(255,255,255,.08); --line-2: rgba(255,255,255,.14); --edge: rgba(255,255,255,.12);
  --fg: #F3F6FA; --fg-2: rgba(232,238,246,.74); --fg-3: rgba(232,238,246,.52);
  --muted: var(--fg-2); --soft: var(--surface-3); --card: var(--surface); --bg: rgba(255,255,255,.025);
  --accent: #45D6B8; --accent-ink: #9DF2D8; --accent-bg: rgba(69,214,184,.14);
  --cta: linear-gradient(120deg, #17735E, #2C5FC4);
  --st-stable: #3FD4A2; --st-watch: #7DB4FF; --st-attn: #F2B84B; --st-crit: #FF6B81; --st-off: #8D98A8;
  --st-stable-bg: rgba(63,212,162,.12); --st-watch-bg: rgba(125,180,255,.12); --st-attn-bg: rgba(242,184,75,.13); --st-crit-bg: rgba(255,107,129,.13); --st-off-bg: rgba(141,152,168,.12);
  --heart: #FF5C84; --hrv: #2EE6C9; --oxygen: #4FC3FF; --temp: #FFAA5C; --steps: #9BE15D; --stress: #C59BFF; --resp: #6FE3F5; --pressure: #FF9DB4; --deep: #5C6CFF; --light: #8FA6FF; --rem: #D08CFF; --awake: #F2D45C; --body: #F2D45C;
  --danger: #FFB3C0; --danger-bg: #B4294F; --ok: var(--st-stable); --wait: var(--st-attn);
  --r-sm: 8px; --r: 12px; --r-lg: 16px;
  --shadow: 0 1px 0 rgba(255,255,255,.04) inset, 0 10px 30px rgba(0,0,0,.28);
  --sheen: linear-gradient(160deg, rgba(255,255,255,.05), rgba(255,255,255,0) 40%);
  --side-w: 244px;
}
* { box-sizing: border-box; }
html { background: var(--page); }
body { margin: 0; font: 14.5px/1.5 Manrope, Inter, "Segoe UI", system-ui, -apple-system, sans-serif; color: var(--fg); background: transparent; -webkit-font-smoothing: antialiased; min-height: 100vh; position: relative; font-feature-settings: "tnum" 0; }
body::before { content: ""; position: fixed; inset: 0; z-index: -2; pointer-events: none; background: radial-gradient(60vmax 50vmax at 8% -10%, rgba(76,141,255,.20), transparent 70%), radial-gradient(50vmax 50vmax at 100% 30%, rgba(125,139,160,.12), transparent 70%), radial-gradient(50vmax 40vmax at 0% 100%, rgba(69,214,184,.08), transparent 70%), linear-gradient(180deg, var(--sky-1) 0%, #1A2A44 30%, #111822 70%, var(--page) 100%); }
body::after { content: ""; position: fixed; left: -4vw; right: -4vw; bottom: 0; height: 34vh; z-index: -1; pointer-events: none; opacity: .16; background: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 1000 500' preserveAspectRatio='none'%3E%3Cpath d='M0 500L0 290 120 250 220 280 330 235 700 250 820 220 920 260 1000 240 1000 500Z' fill='%2352627C'/%3E%3Cpath d='M0 500L0 360 180 300 300 210 400 130 500 30 580 100 660 165 780 225 900 290 1000 320 1000 500Z' fill='%233A4352'/%3E%3Cpath d='M500 30 580 100 660 165 640 182 625 150 600 190 575 160 548 200 520 168 490 205 465 170 440 196 420 160 400 182 375 160 300 210 400 130Z' fill='%23EEF2F8' fill-opacity='.7'/%3E%3C/svg%3E") center bottom / 100% 100% no-repeat; -webkit-mask-image: linear-gradient(#000 40%, transparent); mask-image: linear-gradient(#000 40%, transparent); }
a { color: var(--accent); text-underline-offset: 2px; }
a:hover { color: var(--accent-ink); }
:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
::selection { background: rgba(69,214,184,.35); }
h1 { font-size: 1.6rem; line-height: 1.2; font-weight: 800; letter-spacing: -.02em; margin: 0; }
h2 { font-size: 1.02rem; line-height: 1.3; font-weight: 750; letter-spacing: -.005em; margin: 0; }
h3 { font-size: .92rem; font-weight: 700; margin: 16px 0 8px; }
p { margin: 8px 0; }
.muted { color: var(--fg-2); } .faint { color: var(--fg-3); } .small { font-size: .86rem; } .tiny { font-size: .76rem; }
.num, .tabular { font-variant-numeric: tabular-nums; }
.nowrap { white-space: nowrap; } .pre { white-space: pre-wrap; overflow-wrap: anywhere; }
.error { color: var(--danger); font-weight: 650; }
.ok { color: var(--st-stable); }
.sr { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; }

/* ---------- Yerleşim: yan menü + üst çubuk + içerik ---------- */
.shell { display: grid; grid-template-columns: var(--side-w) minmax(0, 1fr); min-height: 100vh; }
.side { position: sticky; top: 0; height: 100vh; display: flex; flex-direction: column; gap: 18px; padding: 18px 12px 14px; background: rgba(13,17,24,.82); border-inline-end: 1px solid var(--line); backdrop-filter: blur(18px) saturate(1.2); -webkit-backdrop-filter: blur(18px) saturate(1.2); overflow-y: auto; }
.brand { display: inline-flex; align-items: center; gap: 10px; font-weight: 800; font-size: 17px; letter-spacing: -.01em; color: var(--fg); padding: 2px 8px; text-decoration: none; }
.brand small { display: block; font-weight: 700; font-size: 10px; color: var(--fg-3); letter-spacing: .14em; text-transform: uppercase; }
.brand .mark { display: grid; place-items: center; width: 32px; height: 32px; border-radius: 9px; background: radial-gradient(circle at 30% 25%, #9DF2D8, #2E9E86 55%, #0B4A40); box-shadow: 0 4px 14px rgba(51,209,168,.35), inset 0 1px 0 rgba(255,255,255,.4); flex: 0 0 auto; }
.brand.large { font-size: 22px; padding: 0; } .brand.large .mark { width: 40px; height: 40px; border-radius: 11px; }
.menu { display: grid; gap: 2px; }
.menu-label { font-size: .7rem; font-weight: 750; letter-spacing: .12em; text-transform: uppercase; color: var(--fg-3); padding: 14px 12px 6px; }
.menu a { position: relative; display: flex; align-items: center; gap: 11px; min-height: 40px; padding: 8px 12px; border-radius: var(--r-sm); color: var(--fg-2); text-decoration: none; font-weight: 650; }
.menu a:hover { background: var(--surface-3); color: var(--fg); }
.menu a[aria-current] { background: linear-gradient(90deg, rgba(69,214,184,.16), rgba(69,214,184,.04)); color: var(--fg); }
.menu a[aria-current]::before { content: ""; position: absolute; inset-inline-start: -12px; top: 8px; bottom: 8px; width: 3px; border-radius: 3px; background: var(--accent); }
.menu a[aria-current] svg { color: var(--accent); }
.menu .count { margin-inline-start: auto; min-width: 22px; height: 20px; padding: 0 6px; border-radius: 999px; display: inline-grid; place-items: center; font-size: .72rem; font-weight: 800; background: var(--st-crit-bg); color: var(--st-crit); }
.menu .count.calm { background: var(--surface-3); color: var(--fg-2); }
.side-foot { margin-top: auto; display: grid; gap: 8px; }
.who { display: flex; align-items: center; gap: 10px; padding: 10px; border-radius: var(--r); background: var(--surface-2); border: 1px solid var(--line); min-width: 0; }
.who strong { display: block; font-size: 13.5px; line-height: 1.3; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.who small { display: block; color: var(--fg-3); font-size: 12px; line-height: 1.3; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.who > span:last-child { min-width: 0; }
.side-links { display: flex; flex-wrap: wrap; gap: 2px 12px; padding: 0 10px; font-size: .78rem; }
.side-links a { color: var(--fg-3); text-decoration: none; } .side-links a:hover { color: var(--fg); }
.side-foot form { margin: 0; }
.content { min-width: 0; display: flex; flex-direction: column; }
.topbar { position: sticky; top: 0; z-index: 5; display: flex; align-items: center; gap: 12px; min-height: 60px; padding: 10px clamp(16px, 2.6vw, 32px); background: rgba(14,19,27,.72); border-bottom: 1px solid var(--line); backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px); }
.crumbs { display: flex; align-items: center; gap: 8px; min-width: 0; font-size: .88rem; color: var(--fg-3); flex: 1 1 auto; }
.crumbs a { color: var(--fg-2); text-decoration: none; } .crumbs a:hover { color: var(--fg); }
.crumbs span[aria-current] { color: var(--fg); font-weight: 700; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.crumbs .sep { opacity: .5; }
[dir="rtl"] .crumbs .sep { transform: scaleX(-1); display: inline-block; }
.gsearch { position: relative; flex: 0 1 300px; }
.gsearch input { min-height: 38px; margin: 0; padding: 6px 12px 6px 36px; border-radius: 10px; background: var(--surface-2); font-size: .9rem; }
[dir="rtl"] .gsearch input { padding: 6px 36px 6px 12px; }
.gsearch svg { position: absolute; inset-inline-start: 11px; top: 50%; transform: translateY(-50%); color: var(--fg-3); pointer-events: none; }
main { width: 100%; max-width: 1480px; margin: 0 auto; padding: 22px clamp(16px, 2.6vw, 32px) 56px; }
main.narrow { max-width: 440px; }
.navtoggle { position: absolute; opacity: 0; pointer-events: none; width: 1px; height: 1px; }
.burger { display: none; }
.scrim { display: none; }

/* Dil seçimi: üst çubukta açılır */
details.pop { position: relative; }
details.pop > summary { list-style: none; display: inline-flex; align-items: center; gap: 6px; min-height: 38px; padding: 0 10px; border-radius: 10px; border: 1px solid var(--line-2); background: var(--surface-2); color: var(--fg-2); font-weight: 700; font-size: .85rem; cursor: pointer; }
details.pop > summary::-webkit-details-marker { display: none; }
details.pop[open] > summary { color: var(--fg); border-color: var(--edge); }
details.pop > .pop-body { position: absolute; inset-inline-end: 0; top: calc(100% + 6px); z-index: 20; padding: 6px; border-radius: var(--r); background: var(--solid); border: 1px solid var(--edge); box-shadow: 0 18px 40px rgba(0,0,0,.45); }
.pop-body .langswitch { display: grid; background: none; border: 0; padding: 0; gap: 2px; }
.pop-body .langswitch svg { display: none; }
.pop-body .langswitch a, .pop-body .langswitch .lang-on { min-width: 140px; border-radius: 8px; }

/* ---------- Sayfa başlığı ---------- */
.page-head { display: flex; flex-wrap: wrap; align-items: flex-end; gap: 12px 16px; margin: 4px 0 20px; }
.page-head .titles { flex: 1 1 320px; min-width: 0; }
.page-head .sub { margin: 4px 0 0; color: var(--fg-2); font-size: .92rem; }
.actions { display: flex; flex-wrap: wrap; gap: 8px; align-items: center; }
.eyebrow { font-size: .72rem; font-weight: 750; letter-spacing: .12em; text-transform: uppercase; color: var(--fg-3); }
.demo-tag { display: inline-flex; align-items: center; gap: 6px; padding: 3px 9px; border-radius: 999px; font-size: .72rem; font-weight: 800; letter-spacing: .06em; text-transform: uppercase; color: var(--st-attn); background: var(--st-attn-bg); border: 1px solid rgba(242,184,75,.35); vertical-align: middle; }

/* ---------- Izgara ---------- */
.grid { display: grid; gap: 16px; }
.grid > *, .stack > * { min-width: 0; }
.cols-main { grid-template-columns: minmax(0, 1.75fr) minmax(300px, 1fr); align-items: start; }
.cols-2 { grid-template-columns: repeat(2, minmax(0, 1fr)); align-items: start; }
.stack { display: grid; gap: 16px; align-content: start; }
.mt { margin-top: 16px; }

/* ---------- Panel (kart) ---------- */
.panel, .card { background: var(--sheen), var(--surface); border: 1px solid var(--edge); border-radius: var(--r-lg); box-shadow: var(--shadow); min-width: 0; }
.card { padding: 18px; margin: 14px 0; }
.panel-head { display: flex; flex-wrap: wrap; align-items: center; gap: 8px 12px; padding: 14px 18px; border-bottom: 1px solid var(--line); }
.panel-head h2 { flex: 1 1 auto; display: flex; align-items: center; gap: 8px; }
.panel-head .hint { width: 100%; margin: 0; font-size: .82rem; color: var(--fg-3); }
.panel-head a.more { font-size: .85rem; font-weight: 700; text-decoration: none; white-space: nowrap; }
.panel-body { padding: 16px 18px; }
.panel-body.flush { padding: 0; }
.panel-foot a, .what a, .why a { text-decoration: none; font-weight: 700; }
.panel-foot { padding: 10px 18px; border-top: 1px solid var(--line); font-size: .82rem; color: var(--fg-3); }
.panel.alert-edge { border-color: rgba(255,107,129,.35); }

/* ---------- Gösterge şeridi ---------- */
.kpis { display: grid; grid-template-columns: repeat(auto-fit, minmax(170px, 1fr)); }
.kpi { padding: 16px 18px; border-inline-end: 1px solid var(--line); display: grid; gap: 4px; text-decoration: none; color: inherit; min-width: 0; }
.kpi:last-child { border-inline-end: 0; }
a.kpi:hover { background: var(--surface-2); color: inherit; }
.kpi .label { font-size: .8rem; font-weight: 650; color: var(--fg-2); display: flex; align-items: center; gap: 6px; }
.kpi .value { font-size: 1.9rem; line-height: 1.1; font-weight: 800; letter-spacing: -.02em; font-variant-numeric: tabular-nums; }
.kpi .value small { font-size: .95rem; font-weight: 700; color: var(--fg-3); letter-spacing: 0; margin-inline-start: 2px; }
.kpi .foot { font-size: .78rem; color: var(--fg-3); }
.kpi.crit .value { color: var(--st-crit); } .kpi.attn .value { color: var(--st-attn); } .kpi.stable .value { color: var(--st-stable); }
.dot { display: inline-block; width: 8px; height: 8px; border-radius: 50%; background: currentColor; flex: 0 0 auto; }

/* ---------- Durum rozeti ---------- */
.badge, .status { display: inline-flex; align-items: center; gap: 6px; padding: 2px 9px; min-height: 22px; border-radius: 999px; font-size: .75rem; font-weight: 750; white-space: nowrap; border: 1px solid transparent; background: var(--surface-3); color: var(--fg-2); }
.badge::before, .status::before { content: ""; width: 6px; height: 6px; border-radius: 50%; background: currentColor; }
.st-critical, .badge.alert { color: var(--st-crit); background: var(--st-crit-bg); border-color: rgba(255,107,129,.3); }
.st-attention, .badge.wait { color: var(--st-attn); background: var(--st-attn-bg); border-color: rgba(242,184,75,.3); }
.st-watch { color: var(--st-watch); background: var(--st-watch-bg); border-color: rgba(125,180,255,.28); }
.st-stable, .badge.on { color: var(--st-stable); background: var(--st-stable-bg); border-color: rgba(63,212,162,.28); }
.st-inactive { color: var(--st-off); background: var(--st-off-bg); }
.badge.alert.strong { background: var(--danger-bg); color: #fff; border-color: var(--danger-bg); }
.tag { display: inline-flex; align-items: center; padding: 1px 8px; border-radius: 6px; font-size: .74rem; font-weight: 700; background: var(--surface-3); color: var(--fg-2); white-space: nowrap; }

/* ---------- Avatar ---------- */
.avatar { flex: 0 0 auto; display: grid; place-items: center; width: 34px; height: 34px; border-radius: 50%; font-weight: 800; font-size: 12.5px; letter-spacing: .02em; color: #0C1016; background: hsl(var(--h, 160) 62% 68%); box-shadow: inset 0 0 0 2px rgba(255,255,255,.18); }
.avatar.lg { width: 64px; height: 64px; font-size: 22px; }
.avatar.anon { background: var(--surface-3); color: var(--fg-2); box-shadow: inset 0 0 0 1px var(--line-2); }
.avatar.ring-critical { box-shadow: 0 0 0 2px var(--page), 0 0 0 4px var(--st-crit); }
.avatar.ring-attention { box-shadow: 0 0 0 2px var(--page), 0 0 0 4px var(--st-attn); }
.who .avatar { background: #5BE37D; }
.ident { display: flex; align-items: center; gap: 12px; min-width: 0; }
.ident .names { min-width: 0; }
.ident .names a, .ident .names strong { display: block; font-weight: 750; color: var(--fg); text-decoration: none; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.ident .names a:hover { color: var(--accent-ink); }
.ident .names span { display: block; font-size: .78rem; color: var(--fg-3); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

/* ---------- Tablo ---------- */
.table-wrap { overflow-x: auto; }
.panel > .table-wrap, .panel-body.flush > .table-wrap { border: 0; }
.table-wrap.boxed { border: 1px solid var(--edge); border-radius: var(--r-lg); background: var(--sheen), var(--surface); box-shadow: var(--shadow); }
table { width: 100%; border-collapse: collapse; }
th, td { text-align: start; padding: 11px 14px; border-bottom: 1px solid var(--line); vertical-align: middle; }
thead th { position: sticky; top: 0; font-size: .7rem; font-weight: 750; letter-spacing: .08em; text-transform: uppercase; color: var(--fg-3); background: rgba(16,21,29,.6); white-space: nowrap; }
thead th a { color: inherit; text-decoration: none; display: inline-flex; align-items: center; gap: 4px; }
thead th a:hover, thead th a[aria-sort] { color: var(--fg); }
tbody tr:hover td { background: var(--surface-2); }
tbody tr:last-child td { border-bottom: 0; }
td a { font-weight: 700; text-decoration: none; }
td a:hover { text-decoration: underline; }
td.num, th.num { text-align: end; font-variant-numeric: tabular-nums; white-space: nowrap; }
th[scope=row] { font-weight: 650; }
tr.row-alert td:first-child { box-shadow: inset 3px 0 0 var(--st-crit); }
[dir="rtl"] tr.row-alert td:first-child { box-shadow: inset -3px 0 0 var(--st-crit); }
tr.row-attn td:first-child { box-shadow: inset 3px 0 0 var(--st-attn); }
[dir="rtl"] tr.row-attn td:first-child { box-shadow: inset -3px 0 0 var(--st-attn); }
table.compact th, table.compact td { padding: 7px 12px; font-size: .88rem; }
td .reason { display: block; font-weight: 650; }
td .reason + .faint { display: block; font-size: .78rem; }
.cell-go { width: 44px; text-align: end; }
.go { display: inline-grid; place-items: center; width: 32px; height: 32px; border-radius: 8px; color: var(--fg-2); border: 1px solid var(--line-2); text-decoration: none; }
.go:hover { color: var(--fg); background: var(--surface-3); text-decoration: none; }
[dir="rtl"] .go svg { transform: scaleX(-1); }
.vals { display: flex; flex-wrap: wrap; gap: 4px 14px; font-variant-numeric: tabular-nums; }
.vals span { white-space: nowrap; } .vals b { font-weight: 750; } .vals i { font-style: normal; color: var(--fg-3); font-size: .78rem; margin-inline-start: 2px; }
.vals .out b { color: var(--st-attn); } .vals .crit b { color: var(--st-crit); }

/* ---------- Araç çubuğu, filtre, sayfalama ---------- */
.toolbar { display: flex; flex-wrap: wrap; gap: 10px 12px; align-items: center; padding: 12px 18px; border-bottom: 1px solid var(--line); }
.toolbar form { display: flex; gap: 8px; margin: 0; flex: 1 1 260px; }
.toolbar input[type=search] { margin: 0; min-height: 38px; }
.seg { display: inline-flex; flex-wrap: wrap; gap: 4px; padding: 3px; border-radius: 10px; background: var(--surface-2); border: 1px solid var(--line); }
.seg > a, .seg > span { display: inline-flex; align-items: center; gap: 6px; min-height: 32px; padding: 0 11px; border-radius: 7px; font-size: .84rem; font-weight: 700; color: var(--fg-2); text-decoration: none; white-space: nowrap; }
.seg a:hover { color: var(--fg); background: var(--surface-3); }
.seg > [aria-current] { background: var(--surface-3); color: var(--fg); box-shadow: inset 0 0 0 1px var(--line-2); }
.seg .n { font-size: .72rem; color: var(--fg-3); font-variant-numeric: tabular-nums; }
.seg .dot { width: 7px; height: 7px; padding: 0; min-height: 0; }
.pager { display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 8px 16px; padding: 10px 18px; border-top: 1px solid var(--line); font-size: .84rem; color: var(--fg-3); }
.pager nav { display: flex; gap: 4px; flex-wrap: wrap; }
.pager a, .pager span.pg { display: inline-grid; place-items: center; min-width: 34px; height: 34px; padding: 0 10px; border-radius: 8px; border: 1px solid var(--line-2); color: var(--fg-2); text-decoration: none; font-weight: 700; }
.pager a:hover { color: var(--fg); background: var(--surface-3); }
.pager [aria-current] { background: var(--accent-bg); border-color: rgba(69,214,184,.4); color: var(--accent-ink); }
.pager .off { opacity: .35; }

/* ---------- Dağılım çubuğu ---------- */
.dist { display: flex; height: 12px; border-radius: 999px; overflow: hidden; background: var(--surface-3); gap: 2px; }
.dist span { display: block; min-width: 4px; }
.dist .critical { background: var(--st-crit); } .dist .attention { background: var(--st-attn); } .dist .watch { background: var(--st-watch); } .dist .stable { background: var(--st-stable); } .dist .inactive { background: var(--st-off); opacity: .6; }
.legend { list-style: none; margin: 14px 0 0; padding: 0; display: grid; gap: 2px; }
.legend a { display: grid; grid-template-columns: 12px 1fr auto 46px; align-items: center; gap: 10px; padding: 8px 8px; border-radius: 8px; color: var(--fg); text-decoration: none; }
.legend a:hover { background: var(--surface-2); }
.legend .lbl small { display: block; color: var(--fg-3); font-size: .76rem; }
.legend b { font-size: 1.05rem; font-variant-numeric: tabular-nums; }
.legend .pct { text-align: end; color: var(--fg-3); font-size: .8rem; font-variant-numeric: tabular-nums; }
.c-critical { color: var(--st-crit); } .c-attention { color: var(--st-attn); } .c-watch { color: var(--st-watch); } .c-stable { color: var(--st-stable); } .c-inactive { color: var(--st-off); }

/* ---------- Uyum noktaları ve ölçer ---------- */
.dots { display: inline-flex; gap: 2px; vertical-align: middle; }
.dots i { width: 6px; height: 14px; border-radius: 2px; background: var(--surface-3); }
.dots i.on { background: var(--st-stable); opacity: .85; }
.adh { display: flex; align-items: center; gap: 8px; white-space: nowrap; }
.adh b { font-size: .82rem; font-variant-numeric: tabular-nums; min-width: 34px; }
.adh.low b { color: var(--st-watch); }
.meter { height: 6px; border-radius: 999px; background: var(--surface-3); overflow: hidden; }
.meter > span { display: block; height: 100%; background: var(--st-stable); border-radius: inherit; }

/* ---------- Grafikler ---------- */
.spark { display: block; width: 120px; height: 30px; overflow: visible; color: var(--accent); }
.spark .ln { fill: none; stroke: currentColor; stroke-width: 1.6; stroke-linejoin: round; stroke-linecap: round; }
.spark .ar { fill: currentColor; opacity: .12; }
.spark .pt { fill: currentColor; }
.chart { width: 100%; height: auto; max-height: 320px; margin: 4px 0; color: var(--accent); overflow: visible; }
.chart text { font: 12.5px Manrope, system-ui, sans-serif; fill: var(--fg-3); }
.chart .grid { stroke: rgba(255,255,255,.07); stroke-width: 1; }
.chart .axis { stroke: rgba(255,255,255,.18); }
.chart .ref { fill: var(--st-stable); opacity: .07; }
.chart .refline { stroke: var(--st-stable); stroke-opacity: .45; stroke-dasharray: 4 4; }
.chart .band { fill: currentColor; opacity: .16; }
.chart .line { fill: none; stroke: currentColor; stroke-width: 2; stroke-linejoin: round; stroke-linecap: round; }
.chart circle.line { fill: currentColor; stroke: none; }
.chart .line2 { fill: none; stroke: var(--pressure); stroke-width: 2; stroke-dasharray: 0; opacity: .9; }
.chart circle.line2 { fill: var(--pressure); stroke: none; }
.chart .pt { fill: currentColor; }
.chart .pt.out { fill: var(--st-attn); stroke: var(--page); stroke-width: 1.5; }
.chart .pt.crit { fill: var(--st-crit); stroke: var(--page); stroke-width: 1.5; }
.chart .bar { fill: currentColor; opacity: .75; }
.chart .bar2 { fill: currentColor; opacity: .25; }
.chart .hit { fill: transparent; }
.chart .hit:hover { fill: rgba(255,255,255,.06); }
.chart-scroll { overflow-x: auto; overscroll-behavior-x: contain; }
.chart-legend { display: flex; flex-wrap: wrap; gap: 6px 16px; font-size: .8rem; color: var(--fg-2); margin: 6px 0 0; padding: 0; list-style: none; }
.chart-legend li { display: inline-flex; align-items: center; gap: 6px; }
.chart-legend .sw { width: 14px; height: 4px; border-radius: 2px; background: currentColor; }
.chart-legend .sw.box { height: 10px; opacity: .35; }
.chart-legend .sw.ref { background: var(--st-stable); opacity: .3; height: 10px; }
.chart-legend .sw.out { width: 8px; height: 8px; border-radius: 50%; background: var(--st-attn); }

/* Ölçüm renkleri (uygulamanın DataColors değerleri) */
.m-heartRate { color: var(--heart); } .m-hrv { color: var(--hrv); } .m-spo2 { color: var(--oxygen); } .m-temperature { color: var(--temp); } .m-steps { color: var(--steps); } .m-stress { color: var(--stress); } .m-respiration { color: var(--resp); } .m-bloodPressure { color: var(--pressure); } .m-sleep { color: var(--light); } .m-weight { color: var(--body); }

/* ---------- Ölçüm kartları ---------- */
.vitals { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 12px; }
a.vital { display: grid; gap: 6px; padding: 14px 14px 12px; border-radius: var(--r); border: 1px solid var(--line-2); background: var(--surface-2); color: var(--fg); text-decoration: none; min-width: 0; position: relative; }
a.vital:hover { border-color: var(--edge); background: var(--surface-3); color: var(--fg); }
a.vital[aria-current] { border-color: currentColor; box-shadow: inset 0 0 0 1px currentColor; }
a.vital .vh { display: flex; align-items: center; gap: 7px; font-size: .8rem; font-weight: 700; color: var(--fg-2); min-width: 0; }
a.vital .vh .lbl { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
a.vital .vh .status { margin-inline-start: auto; flex: 0 0 auto; font-size: .68rem; padding: 1px 7px; min-height: 18px; }
a.vital .vh .dot { color: inherit; }
a.vital .vv { font-size: 1.55rem; font-weight: 800; letter-spacing: -.02em; line-height: 1.1; font-variant-numeric: tabular-nums; color: var(--fg); }
a.vital .vv small { font-size: .82rem; color: var(--fg-3); font-weight: 700; margin-inline-start: 3px; letter-spacing: 0; }
a.vital .vf { display: flex; justify-content: space-between; align-items: end; gap: 8px; font-size: .75rem; color: var(--fg-3); }
a.vital .spark { width: 84px; height: 26px; }
.delta { font-weight: 750; font-variant-numeric: tabular-nums; white-space: nowrap; }
.delta.up-bad, .delta.down-bad { color: var(--st-attn); } .delta.flat, .delta.up, .delta.down { color: var(--fg-2); }

/* ---------- Sinyaller ve içgörüler ---------- */
ul.signals, ul.insights, ol.timeline { list-style: none; margin: 0; padding: 0; }
ul.signals li { display: grid; grid-template-columns: 4px 1fr auto; gap: 12px; align-items: center; padding: 10px 18px; border-bottom: 1px solid var(--line); }
ul.signals li:last-child { border-bottom: 0; }
ul.signals li::before { content: ""; align-self: stretch; border-radius: 4px; background: currentColor; }
ul.signals .what { font-weight: 700; color: var(--fg); } ul.signals .why { display: block; font-size: .8rem; color: var(--fg-3); font-weight: 500; }
ul.insights li { border-bottom: 1px solid var(--line); }
ul.insights li:last-child { border-bottom: 0; }
ul.insights details > summary { list-style: none; display: grid; grid-template-columns: 28px 1fr auto; gap: 10px; align-items: center; padding: 12px 18px; cursor: pointer; }
ul.insights details > summary::-webkit-details-marker { display: none; }
ul.insights details > summary:hover { background: var(--surface-2); }
ul.insights .ico { display: grid; place-items: center; width: 28px; height: 28px; border-radius: 8px; background: currentColor; }
ul.insights .ico svg { color: var(--page); }
ul.insights .ttl { font-weight: 700; } ul.insights .ttl small { display: block; font-weight: 500; color: var(--fg-3); font-size: .8rem; }
ul.insights .cnt { font-weight: 800; font-variant-numeric: tabular-nums; color: var(--fg); background: var(--surface-3); border-radius: 999px; padding: 2px 10px; font-size: .8rem; }
ul.insights .body { padding: 0 18px 14px 56px; font-size: .86rem; color: var(--fg-2); }
[dir="rtl"] ul.insights .body { padding: 0 56px 14px 18px; }
ul.insights .body ul { margin: 8px 0 0; padding: 0; list-style: none; display: grid; gap: 4px; }
ul.insights .body li { border: 0; display: flex; justify-content: space-between; gap: 12px; }

/* ---------- Zaman çizelgesi ---------- */
ol.timeline li { display: grid; grid-template-columns: 30px 1fr auto; gap: 10px; padding: 10px 18px; position: relative; }
ol.timeline li::after { content: ""; position: absolute; inset-inline-start: 32px; top: 40px; bottom: -4px; width: 1px; background: var(--line-2); }
ol.timeline li:last-child::after { display: none; }
ol.timeline .ti { display: grid; place-items: center; width: 30px; height: 30px; border-radius: 50%; background: var(--surface-3); color: var(--fg-2); }
ol.timeline .ti.critical { background: var(--st-crit-bg); color: var(--st-crit); } ol.timeline .ti.attention { background: var(--st-attn-bg); color: var(--st-attn); } ol.timeline .ti.stable { background: var(--st-stable-bg); color: var(--st-stable); } ol.timeline .ti.watch { background: var(--st-watch-bg); color: var(--st-watch); }
ol.timeline .tx { min-width: 0; font-size: .88rem; } ol.timeline .tx a { color: var(--fg); font-weight: 700; text-decoration: none; } ol.timeline .tx a:hover { color: var(--accent-ink); } ol.timeline .tx b { font-weight: 700; } ol.timeline .tx p { margin: 2px 0 0; color: var(--fg-3); font-size: .8rem; overflow-wrap: anywhere; }
ol.timeline time { font-size: .76rem; color: var(--fg-3); white-space: nowrap; font-variant-numeric: tabular-nums; }
.day-sep { padding: 10px 18px 4px; font-size: .72rem; font-weight: 750; letter-spacing: .1em; text-transform: uppercase; color: var(--fg-3); }

/* ---------- Hasta başlığı ve sekmeler ---------- */
.phead { display: grid; grid-template-columns: auto minmax(0, 1fr) auto; gap: 16px 20px; align-items: center; padding: 18px 20px; }
.phead h1 { display: flex; flex-wrap: wrap; align-items: center; gap: 10px; font-size: 1.5rem; }
.phead .meta { display: flex; flex-wrap: wrap; gap: 4px 18px; margin-top: 6px; font-size: .86rem; color: var(--fg-2); }
.phead .meta span { white-space: nowrap; } .phead .meta b { color: var(--fg-3); font-weight: 600; margin-inline-end: 4px; }
.tabs { display: flex; gap: 2px; padding: 0 14px; border-top: 1px solid var(--line); overflow-x: auto; }
.tabs a, .tabs span { display: inline-flex; align-items: center; gap: 8px; min-height: 46px; padding: 0 12px; color: var(--fg-2); text-decoration: none; font-weight: 700; font-size: .9rem; border-bottom: 2px solid transparent; white-space: nowrap; }
.tabs a:hover { color: var(--fg); }
.tabs [aria-current] { color: var(--fg); border-bottom-color: var(--accent); }
.tabs .off { opacity: .4; }
.facts-inline { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 0; }
.facts-inline div { padding: 12px 18px; border-inline-end: 1px solid var(--line); }
.facts-inline dt { font-size: .74rem; color: var(--fg-3); font-weight: 650; } .facts-inline dd { margin: 2px 0 0; font-weight: 700; font-variant-numeric: tabular-nums; }
.chart-stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(110px, 1fr)); border-top: 1px solid var(--line); }
.chart-stats div { padding: 10px 18px; border-inline-end: 1px solid var(--line); }
.chart-stats div:last-child { border-inline-end: 0; }
.chart-stats dt { font-size: .72rem; color: var(--fg-3); font-weight: 650; text-transform: uppercase; letter-spacing: .06em; } .chart-stats dd { margin: 2px 0 0; font-weight: 800; font-size: 1.05rem; font-variant-numeric: tabular-nums; }

/* Uyku evreleri (uygulamadaki uyku kartının renkleri) */
.nights { display: grid; gap: 8px; }
.night { display: grid; grid-template-columns: 70px 1fr auto; align-items: center; gap: 10px; font-size: .8rem; }
.night .bar { display: flex; height: 14px; border-radius: 4px; overflow: hidden; background: var(--surface-3); }
.night .bar span { display: block; }
.s-deep { background: var(--deep); } .s-light { background: var(--light); } .s-rem { background: var(--rem); } .s-awake { background: var(--awake); }
.night b { text-align: end; font-variant-numeric: tabular-nums; white-space: nowrap; min-width: 70px; }
.chart-legend .s-deep { background: var(--deep); } .chart-legend .s-light { background: var(--light); } .chart-legend .s-rem { background: var(--rem); } .chart-legend .s-awake { background: var(--awake); }

/* Uyum takvimi */
.cal { display: grid; grid-template-columns: repeat(auto-fill, minmax(26px, 1fr)); gap: 4px; }
.cal span { aspect-ratio: 1; border-radius: 5px; background: var(--surface-3); display: grid; place-items: center; font-size: .66rem; color: var(--fg-3); font-variant-numeric: tabular-nums; }
.cal span.l1 { background: rgba(63,212,162,.25); color: var(--fg-2); } .cal span.l2 { background: rgba(63,212,162,.5); color: var(--fg); } .cal span.l3 { background: rgba(63,212,162,.8); color: #06231B; }
.cal span.today { box-shadow: inset 0 0 0 1.5px var(--fg-2); }

/* ---------- Formlar ve düğmeler ---------- */
label { display: block; margin: 10px 0; font-weight: 650; font-size: .88rem; color: var(--fg-2); }
input, textarea, select { display: block; width: 100%; min-height: 42px; margin-top: 6px; padding: 9px 12px; font: inherit; font-weight: 500; color: var(--fg); border: 1px solid var(--line-2); border-radius: 10px; background: var(--field); color-scheme: dark; }
input::placeholder, textarea::placeholder { color: var(--fg-3); }
input:focus, textarea:focus, select:focus { border-color: var(--accent); outline: none; box-shadow: 0 0 0 3px rgba(69,214,184,.2); }
select option { background: var(--solid); color: var(--fg); }
label.check { display: inline-flex; align-items: center; gap: 8px; margin: 4px 6px 4px 0; min-height: 38px; padding: 4px 12px; border: 1px solid var(--line-2); border-radius: 999px; font-weight: 650; color: var(--fg-2); cursor: pointer; background: var(--surface-2); }
label.check:has(input:checked) { border-color: rgba(69,214,184,.6); background: var(--accent-bg); color: var(--accent-ink); }
label.check input { display: inline; width: auto; min-height: 0; margin: 0; accent-color: var(--accent); }
fieldset { border: 1px solid var(--line); border-radius: var(--r); margin: 12px 0; padding: 10px 12px; }
legend { font-weight: 700; padding: 0 6px; color: var(--fg-2); font-size: .88rem; }
button, a.button, summary.button { display: inline-flex; align-items: center; justify-content: center; gap: 8px; min-height: 40px; padding: 8px 16px; font: inherit; font-size: .9rem; font-weight: 750; border: 0; border-radius: 10px; background: var(--cta); color: #fff; cursor: pointer; text-decoration: none; box-shadow: 0 6px 18px rgba(51,209,168,.18), inset 0 1px 0 rgba(255,255,255,.22); transition: filter .15s, transform .15s cubic-bezier(.2,.8,.2,1); white-space: nowrap; }
button:hover, a.button:hover { filter: brightness(1.1); color: #fff; }
button:active, a.button:active { transform: scale(.97); }
@media (prefers-reduced-motion: reduce) { button:active, a.button:active { transform: none; } * { transition: none !important; } }
button.wide { width: 100%; }
a.button.secondary, button.secondary, summary.button.secondary { background: var(--surface-3); color: var(--fg); border: 1px solid var(--line-2); box-shadow: none; }
a.button.secondary:hover, button.secondary:hover, summary.button.secondary:hover { background: rgba(255,255,255,.12); color: var(--fg); }
a.button.ghost, button.ghost { background: transparent; color: var(--fg-2); border: 1px solid var(--line-2); box-shadow: none; }
button.small, a.button.small { min-height: 32px; padding: 4px 12px; font-size: .82rem; border-radius: 8px; }
button.link { background: none; color: var(--fg-2); padding: 6px 8px; min-height: 36px; box-shadow: none; font-weight: 650; }
button.link:hover { color: var(--danger); filter: none; }
form.unlink { display: grid; gap: 6px; justify-items: start; margin-top: 14px; padding-top: 14px; border-top: 1px solid var(--line); }
button.danger { background: var(--danger-bg); box-shadow: none; }
.row { display: flex; flex-wrap: wrap; gap: 10px 14px; align-items: flex-end; }
.row > label { flex: 1 1 200px; }
.row > button, .row > a.button { flex: 0 0 auto; margin-bottom: 10px; }
form.ack { display: flex; gap: 6px; align-items: center; flex-wrap: wrap; margin: 0; }
form.ack input { min-width: 0; flex: 1 1 120px; min-height: 34px; margin: 0; padding: 5px 10px; font-size: .85rem; }
form.ack button { min-height: 34px; padding: 4px 12px; font-size: .82rem; }
.grid2 { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 0 16px; }

/* CSS ile açılan pencere (betik yok): details açılınca özet tüm ekranı kaplar */
details.modal > summary { list-style: none; }
details.modal > summary::-webkit-details-marker { display: none; }
details.modal[open] > summary::before { content: ""; position: fixed; inset: 0; z-index: 40; background: rgba(5,8,12,.62); backdrop-filter: blur(3px); cursor: default; }
details.modal > .dialog { position: fixed; z-index: 41; top: 50%; left: 50%; transform: translate(-50%, -50%); width: min(560px, calc(100vw - 24px)); max-height: calc(100vh - 32px); overflow-y: auto; padding: 22px; border-radius: var(--r-lg); background: var(--solid); border: 1px solid var(--edge); box-shadow: 0 30px 80px rgba(0,0,0,.6); text-align: start; }
.dialog h2 { margin-bottom: 4px; }

/* ---------- Boş durum ---------- */
.empty { display: grid; justify-items: center; gap: 6px; padding: 28px 18px; text-align: center; color: var(--fg-2); }
.empty svg { color: var(--fg-3); }
.empty strong { color: var(--fg); }
.empty p { margin: 0; max-width: 420px; font-size: .88rem; }

/* ---------- Eski sayfaların parçaları (kayıt, hesap, rapor) ---------- */
.warn { background: var(--st-attn-bg); color: #FFE3A6; border: 1px solid rgba(242,184,75,.4); border-radius: var(--r); padding: 10px 14px; font-weight: 650; margin: 0 0 16px; }
.notice { background: var(--st-stable-bg); border: 1px solid rgba(63,212,162,.35); color: var(--st-stable); border-radius: var(--r); padding: 10px 14px; font-weight: 650; }
.big { font-size: 2rem; font-weight: 800; letter-spacing: -.02em; margin: 4px 0; font-variant-numeric: tabular-nums; }
.codebox { display: flex; flex-wrap: wrap; align-items: center; gap: 20px; }
.qr { display: block; width: 168px; height: 168px; border-radius: 10px; }
.code { font: 800 2.3rem/1.2 ui-monospace, "SF Mono", Menlo, monospace; letter-spacing: .2em; color: var(--accent-ink); background: var(--surface-3); border: 1px solid var(--edge); border-radius: var(--r); padding: 12px 18px; display: inline-block; }
.stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 12px; margin: 8px 0; }
.stat { background: var(--sheen), var(--surface); border: 1px solid var(--edge); border-radius: var(--r-lg); padding: 14px 16px; display: grid; gap: 2px; }
.stat b { font-size: 1.7rem; line-height: 1.1; font-weight: 800; font-variant-numeric: tabular-nums; }
.stat span { color: var(--fg-2); font-size: .84rem; font-weight: 650; }
.stat.danger b, .stat.heart b { color: var(--st-crit); } .stat.accent b { color: var(--accent); } .stat.wait b { color: var(--st-attn); } .stat.ok b { color: var(--st-stable); }
ul.care, ol.care { list-style: none; padding: 0; margin: 8px 0 16px; display: grid; gap: 8px; }
.care li { display: flex; gap: 12px; align-items: center; justify-content: space-between; flex-wrap: wrap; padding: 10px 14px; border: 1px solid var(--line); border-radius: var(--r); background: var(--surface-2); }
.care li p { margin: 4px 0 0; }
dl.facts { display: grid; grid-template-columns: max-content 1fr; gap: 8px 20px; margin: 0; }
dl.facts dt { color: var(--fg-3); font-weight: 600; }
dl.facts dd { margin: 0; overflow-wrap: anywhere; font-weight: 650; }
details summary { cursor: pointer; padding: 4px 0; font-weight: 700; }
.nav { display: flex; flex-wrap: wrap; gap: 4px 16px; }
.nav a { text-decoration: none; padding: 10px 2px; color: var(--fg-2); }
.nav a[aria-current] { font-weight: 700; color: var(--fg); border-bottom: 2px solid var(--accent); }
.report-head h1 { margin: 0 0 12px; }
ul.findings { padding-inline-start: 20px; } ul.findings li { margin: 6px 0; }
.sign { margin-top: 32px; display: flex; justify-content: flex-end; }
.sign span { border-top: 1px solid var(--fg); padding-top: 4px; min-width: 240px; text-align: center; }
details.daily > summary { font-weight: 700; }
article.report .card h2 { margin: 0 0 10px; font-size: 1.1rem; }
article.report .card h3 { margin-top: 14px; }

/* Tek sütunlu sayfalar (hesap, yeni hasta, hata ve onay sayfaları) */
.legacy { max-width: 960px; }
.legacy > h1 { margin: 4px 0 18px; }
.legacy h2 { margin: 28px 0 12px; }
.legacy > p:first-child a { text-decoration: none; font-weight: 700; }
main.narrow.solo { margin: 6vh auto 48px; padding: 28px; background: var(--sheen), var(--surface); border: 1px solid var(--edge); border-radius: var(--r-lg); box-shadow: var(--shadow); max-width: 560px; }
main.narrow.solo h1 { margin: 18px 0 8px; }
main.narrow.solo .card { background: none; border: 0; box-shadow: none; padding: 0; }
@media (max-width: 720px) { main.narrow.solo { margin: 0; border-radius: 0; border: 0; padding: 20px 16px 40px; } }

/* ---------- Giriş ---------- */
.auth { display: grid; grid-template-columns: minmax(0, 1.1fr) minmax(360px, 480px); min-height: 100vh; }
.auth-hero { display: flex; flex-direction: column; justify-content: center; gap: 18px; padding: clamp(32px, 6vw, 88px); }
.auth-hero h1 { font-size: clamp(2rem, 3.4vw, 2.8rem); margin: 18px 0 0; max-width: 560px; text-wrap: balance; }
.auth-hero p { margin: 0; font-size: 1.06rem; color: var(--fg-2); max-width: 500px; }
.auth-hero ul { margin: 6px 0 0; padding: 0; list-style: none; display: grid; gap: 10px; }
.auth-hero li { display: flex; gap: 10px; align-items: center; font-weight: 650; color: var(--fg-2); }
.auth-hero li::before { content: ""; width: 7px; height: 7px; border-radius: 50%; background: var(--accent); box-shadow: 0 0 10px var(--accent); flex: 0 0 auto; }
.auth-hero .ecg { width: 100%; max-width: 460px; height: 56px; margin-top: 10px; overflow: visible; }
.auth-hero .ecg polyline { fill: none; stroke: var(--heart); stroke-width: 2.2; stroke-linejoin: round; filter: drop-shadow(0 0 6px rgba(255,92,132,.55)); }
.auth-preview { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 10px; max-width: 560px; margin-top: 8px; }
.auth-preview div { padding: 12px 14px; border-radius: var(--r); border: 1px solid var(--line-2); background: var(--surface-2); }
.auth-preview b { display: block; font-size: 1.3rem; font-weight: 800; } .auth-preview span { font-size: .78rem; color: var(--fg-3); }
.auth main.narrow { align-self: stretch; display: flex; flex-direction: column; justify-content: center; margin: 0; padding: 40px 36px; max-width: none; background: rgba(13,17,24,.86); border-inline-start: 1px solid var(--line); backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px); }
.auth main.narrow h2 { font-size: 1.45rem; margin: 22px 0 4px; }
.auth main.narrow .card { background: none; border: 0; box-shadow: none; padding: 0; margin: 8px 0; }
.auth main.narrow details.card { border-top: 1px solid var(--line); border-radius: 0; padding-top: 12px; }
${PortalLocale.switcherCss}

@page { size: A4; margin: 14mm 12mm; }
@media (max-width: 1180px) { .cols-main { grid-template-columns: minmax(0, 1fr); } }
@media (max-width: 1000px) {
  .shell { grid-template-columns: minmax(0, 1fr); }
  .burger { display: inline-grid; place-items: center; width: 40px; height: 40px; border-radius: 10px; border: 1px solid var(--line-2); color: var(--fg); cursor: pointer; flex: 0 0 auto; }
  .side { position: fixed; z-index: 30; inset-block: 0; inset-inline-start: 0; width: min(300px, 86vw); transform: translateX(-102%); transition: transform .22s cubic-bezier(.2,.8,.2,1); box-shadow: 0 0 60px rgba(0,0,0,.5); }
  [dir="rtl"] .side { transform: translateX(102%); }
  .navtoggle:checked ~ .shell .side { transform: none; }
  .scrim { position: fixed; inset: 0; z-index: 25; background: rgba(5,8,12,.55); }
  .navtoggle:checked ~ .shell .scrim { display: block; }
  .cols-2 { grid-template-columns: minmax(0, 1fr); }
  .gsearch { flex: 1 1 auto; }
  .crumbs { display: none; }
  .auth { grid-template-columns: minmax(0, 1fr); }
  .auth-hero { padding: 28px 20px 8px; }
  .auth-hero ul, .auth-hero .ecg, .auth-preview { display: none; }
  .auth main.narrow { padding: 24px 20px 40px; border: 0; background: none; }
}
@media (max-width: 720px) {
  main { padding: 16px 12px 48px; }
  .topbar { padding: 8px 12px; gap: 8px; }
  .page-head { margin-bottom: 14px; }
  h1 { font-size: 1.35rem; }
  .kpi { border-bottom: 1px solid var(--line); padding: 12px 14px; }
  .kpi .value { font-size: 1.5rem; }
  .kpis { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  .panel-head, .panel-body, .toolbar, .pager { padding-inline: 14px; }
  .phead { grid-template-columns: auto minmax(0, 1fr); align-items: start; padding: 14px; }
  .vitals { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 8px; }
  .chart-scroll .chart { min-width: 600px; }
  .seg { max-width: 100%; overflow-x: auto; }
  .phead .actions { grid-column: 1 / -1; }
  .avatar.lg { width: 52px; height: 52px; font-size: 18px; }
  /* Tablolar telefonda karta dönüşür */
  table.cards thead { display: none; }
  table.cards, table.cards tbody, table.cards tr, table.cards td { display: block; width: 100%; }
  table.cards tr { display: grid; grid-template-columns: minmax(0, 1fr) auto; gap: 6px 10px; padding: 12px 14px; border-bottom: 1px solid var(--line); }
  table.cards td { border: 0; padding: 0; }
  table.cards td[data-l]::before { content: attr(data-l); display: block; font-size: .68rem; font-weight: 750; letter-spacing: .08em; text-transform: uppercase; color: var(--fg-3); }
  table.cards td.c-wide { grid-column: 1 / -1; }
  table.cards td.cell-go { grid-row: 1; grid-column: 2; }
  table.cards td.hide-m { display: none; }
  table.cards tr.row-alert, table.cards tr.row-attn { box-shadow: none; }
  table.cards tr.row-alert td:first-child, table.cards tr.row-attn td:first-child { box-shadow: none; }
  ul.insights .body { padding-inline: 18px; }
  .gsearch input { font-size: 16px; }
  input, textarea, select { font-size: 16px; }
  dl.facts { grid-template-columns: 1fr; gap: 0; } dl.facts dd { margin-bottom: 8px; }
}
@media print {
  :root { color-scheme: light; --page: #fff; --fg: #000; --fg-2: #333; --fg-3: #555; --muted: #444; --surface: #fff; --surface-2: #fff; --surface-3: #f2f2f2; --line: #ccc; --line-2: #bbb; --edge: #bbb; --accent: #0B6B58; --accent-ink: #0B6B58; --heart: #B4294F; --pressure: #B4294F; --danger: #9B1C1C; --st-stable: #1A7F37; --st-attn: #8A5A00; --st-crit: #9B1C1C; --sheen: none; --shadow: none; }
  html, body { background: #fff; }
  body::before, body::after { display: none; }
  body { font-size: 11pt; color: #000; }
  .noprint, .side, .topbar, .tabs, .warn, .navtoggle, .scrim { display: none !important; }
  .shell { display: block; }
  main { max-width: none; padding: 0; }
  .card, .stat, .table-wrap, .panel { border: 0; border-top: 1px solid #bbb; border-radius: 0; padding: 8px 0; margin: 8px 0; box-shadow: none; background: none; }
  thead th { background: none; position: static; }
  .avoid, tr, .chart { break-inside: avoid; }
  h2 { break-after: avoid; }
  details.daily > summary { display: none; }
  details.daily:not([open]) { display: none; }
  .table-wrap { overflow: visible; }
  a { color: inherit; text-decoration: none; }
}
''';
