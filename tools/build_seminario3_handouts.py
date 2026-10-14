"""QRT Solutions: build two portable HTML handouts from the canonical Markdown."""

from __future__ import annotations

import hashlib
import html
import re
from pathlib import Path
from urllib.parse import unquote, urlsplit

import markdown

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "seminario_3/material/html"
DOCS = {
    ROOT / "seminario_3/guias/RESUMEN_CONFIGURACION.md": "configuracion.html",
    ROOT / "seminario_3/material/AYUDA_MEMORIA.md": "ayuda-memoria.html",
}

CSS = """
:root{--ink:#152c39;--muted:#526872;--teal:#007c71;--line:#dce6e5;--paper:#fff;--wash:#f2f6f5;--mono:ui-monospace,SFMono-Regular,Consolas,monospace}
*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:32px}body{margin:0;background:var(--wash);color:var(--ink);font:16px/1.7 system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}
a{color:var(--teal);text-underline-offset:4px}a:hover{color:#004d46}button{font:inherit;cursor:pointer}button:focus-visible,a:focus-visible,summary:focus-visible{outline:3px solid #ce862b;outline-offset:4px}
.skip{position:absolute;left:12px;top:-80px;background:white;padding:12px;z-index:5}.skip:focus{top:12px}.progress{position:fixed;top:0;left:0;height:4px;background:#15b39b;z-index:8;width:0}
.masthead{max-width:1440px;margin:auto;padding:25px 4vw;display:flex;align-items:center;justify-content:space-between;gap:20px}.brand{display:flex;align-items:center;gap:12px;text-decoration:none;color:var(--ink)}.monogram{background:var(--ink);color:white;border-radius:12px;padding:7px 11px;font-size:16px;font-weight:800;letter-spacing:-1px}.brand b{display:block;font-size:14px;letter-spacing:1px}.brand small{display:block;color:var(--muted);font-size:11px;letter-spacing:1.4px;text-transform:uppercase}
.switcher{display:flex;border:1px solid var(--line);border-radius:24px;padding:4px;background:white;gap:4px}.switcher a{padding:7px 15px;text-decoration:none;font-size:13px;color:var(--muted);border-radius:22px}.switcher a[aria-current=page]{background:var(--ink);color:white}
.layout{max-width:1440px;margin:auto;padding:0 4vw 64px;display:grid;grid-template-columns:246px minmax(0,1fr);gap:44px}.rail{position:sticky;top:30px;align-self:start;max-height:calc(100vh - 60px);overflow:auto;padding:12px 6px 20px 0}.rail-title{font-size:11px;letter-spacing:2px;text-transform:uppercase;font-weight:750;color:var(--muted);margin:0 0 18px}.toc{display:flex;flex-direction:column;gap:5px}.toc a{border-left:2px solid transparent;padding:6px 11px;font-size:13px;text-decoration:none;color:var(--muted);line-height:1.45}.toc a:hover,.toc a.active{border-left-color:var(--teal);color:var(--teal);background:#e5efec;border-radius:0 6px 6px 0}.rail-note{font-size:12px;margin-top:25px;padding-top:18px;border-top:1px solid var(--line);color:var(--muted)}
main{min-width:0}.hero{background:var(--ink);border-radius:22px;padding:44px 44px 36px;color:#fff;position:relative;overflow:hidden}.eyebrow{font-size:11px;text-transform:uppercase;letter-spacing:2.5px;font-weight:700;color:#80d6c8}.hero h1{font-size:clamp(32px,3.3vw,48px);line-height:1.13;letter-spacing:-1.5px;margin:17px 0 19px;max-width:800px}.hero p{font-size:17px;color:#c6d9dc;max-width:680px;margin:0}.chips{display:flex;gap:8px;flex-wrap:wrap;margin-top:27px}.chips span{border:1px solid #4b6570;border-radius:18px;padding:4px 11px;font-size:11px;letter-spacing:.4px;color:#e4efee}.hero-footer{display:flex;gap:16px;align-items:center;justify-content:space-between;margin-top:26px;padding-top:22px;border-top:1px solid #3a5460;font-size:12px;color:#bfd1d2}.actions{display:flex;gap:8px;flex-wrap:wrap}.action{border:1px solid #b8cfcb;background:white;color:var(--ink);border-radius:8px;padding:8px 12px;font-size:12px;font-weight:600}.action:hover{background:#e8f4f0}.action.secondary{background:transparent;color:white;border-color:#65828b}.intro{padding:22px 5px 3px;color:var(--muted)}.intro p{margin:0 0 16px}
.section{background:var(--paper);border:1px solid var(--line);border-radius:16px;padding:30px 34px;margin:22px 0;scroll-margin-top:24px}.section h2{font-size:25px;letter-spacing:-.6px;line-height:1.3;margin:0 0 23px;padding-bottom:17px;border-bottom:1px solid var(--line)}.section h3{font-size:19px;margin-top:27px}.section p{margin:15px 0}.section p:last-child{margin-bottom:0}.section ol,.section ul{padding-left:25px}.section li{margin-bottom:11px;padding-left:5px}.section li::marker{color:var(--teal);font-weight:700}strong{font-weight:700}code{font:0.86em/1.5 var(--mono);background:#edf3f1;border:1px solid #dce8e4;border-radius:4px;padding:2px 5px;color:#225447;overflow-wrap:anywhere}
pre{position:relative;background:#132b36;color:#e3f0ee;border-radius:10px;padding:48px 20px 20px;line-height:1.65;white-space:pre-wrap;overflow-wrap:anywhere;tab-size:2}pre code{background:none;border:0;color:inherit;padding:0;font-size:12px}pre .copy{position:absolute;top:9px;right:10px;border:1px solid #58747b;background:#24414e;color:white;border-radius:6px;padding:4px 10px;font-size:11px}.table-wrap{max-width:100%;overflow:auto;border:1px solid var(--line);border-radius:10px;margin:22px 0}table{width:100%;border-collapse:collapse;font-size:14px;line-height:1.55;text-align:left}thead{background:#edf4f1}th{font-size:11px;text-transform:uppercase;letter-spacing:.8px;color:#36534e;padding:13px 15px;vertical-align:top}td{padding:13px 15px;border-top:1px solid var(--line);vertical-align:top;overflow-wrap:anywhere}td:first-child{font-weight:600}tr:nth-child(even){background:#fafcfb}td code{font-size:11px}blockquote{margin:20px 0;border-left:4px solid var(--teal);padding:12px 23px;background:#eff7f3;font-size:21px;line-height:1.6;letter-spacing:-.3px}
.references{margin-top:36px}.references h2{font-size:21px}.references>p{font-size:13px;color:var(--muted)}.reference{background:white;border:1px solid var(--line);border-radius:10px;margin:10px 0;padding:15px 20px;scroll-margin-top:25px}.reference summary{font-size:14px;cursor:pointer;font-weight:650;color:var(--teal)}.reference .reference-body{margin-top:20px;font-size:14px}.reference-body h1{font-size:24px}.reference-body h2{font-size:21px}.reference-body h3{font-size:18px}.source-label{font:11px/1.5 var(--mono);overflow-wrap:anywhere;color:var(--muted)}.repo-reference{border-bottom:1px dotted #91a7a3}.doc-footer{border-top:1px solid var(--line);padding:25px 5px;display:flex;gap:15px;justify-content:space-between;font-size:12px;color:var(--muted)}.status{position:fixed;bottom:20px;left:50%;transform:translateX(-50%);border-radius:10px;padding:10px 18px;background:var(--ink);color:white;box-shadow:0 5px 20px #142f3929;z-index:7;font-size:13px}.status:empty{display:none}.mobile-nav{display:none}.presenting .layout{grid-template-columns:1fr;max-width:1200px}.presenting .rail{display:none}.presenting .section{font-size:21px}.presenting .section h2{font-size:33px}.presenting table{font-size:18px}.presenting .hero h1{font-size:52px}.presenting td code{font-size:15px}
@media(max-width:1000px){.layout{grid-template-columns:195px minmax(0,1fr);gap:24px}.hero{padding:32px}.section{padding:26px}.hero-footer{align-items:flex-start;flex-direction:column}}
@media(max-width:720px){body{font-size:15px}.masthead{padding:18px 5vw;flex-wrap:wrap;gap:15px}.switcher{width:100%;justify-content:center}.layout{display:block;padding:0 5vw 25px}.rail{display:none}.hero{padding:29px 24px;border-radius:16px}.hero h1,.presenting .hero h1{font-size:34px}.hero p{font-size:15px}.mobile-nav{display:block;background:white;border:1px solid var(--line);border-radius:10px;padding:13px 17px;margin:18px 0}.mobile-nav summary{font-size:13px;font-weight:650;color:var(--teal);cursor:pointer}.mobile-nav .toc{padding-top:12px}.section{padding:24px 19px}.section h2,.presenting .section h2{font-size:23px}table,thead,tbody,tr,td{display:block}thead{position:absolute;width:1px;height:1px;overflow:hidden;clip-path:inset(50%)}tr{padding:10px 14px;border-top:1px solid var(--line)}tr:first-child{border-top:0}td{border:0;padding:7px 0;font-size:14px}td:before{content:attr(data-label);display:block;font-size:10px;font-weight:700;letter-spacing:.8px;text-transform:uppercase;color:var(--muted);margin-bottom:4px}.table-wrap{overflow:visible}.doc-footer{flex-direction:column}.presenting .section{font-size:17px}blockquote{font-size:19px;padding:10px 17px}.reference{padding:14px}.actions{gap:7px}.hero-footer{gap:15px}pre{padding-left:14px;padding-right:14px}}
@media(prefers-reduced-motion:reduce){html{scroll-behavior:auto}}
@media print{@page{size:A4;margin:16mm}body{background:white;color:#111;font-size:10pt;line-height:1.5}.masthead,.rail,.mobile-nav,.actions,.progress,.copy,.references,.status,.skip{display:none!important}.layout,.presenting .layout{display:block;max-width:none;padding:0}.hero{background:white!important;color:#111;border-radius:0;padding:0 0 15px;border-bottom:2px solid #007c71}.hero h1,.presenting .hero h1{font-size:27pt;letter-spacing:-.6px}.hero p,.eyebrow,.hero-footer{color:#333}.hero-footer{margin:10px 0 0;padding:0;border:0}.chips{display:none}.section,.presenting .section{border:0;padding:16px 0 0;margin:12px 0;font-size:10pt}.section h2,.presenting .section h2{font-size:16pt;break-after:avoid}.section h3{break-after:avoid}.intro{padding:15px 0 0}table,.presenting table{font-size:9pt}thead{display:table-header-group}tr{break-inside:avoid}pre,blockquote{break-inside:avoid;background:#f2f5f4;color:#111}pre{padding:10px;white-space:pre-wrap}pre code{color:#111}a{color:inherit;text-decoration:none}.doc-footer{margin-top:20px;font-size:9pt}p,li{orphans:3;widows:3}}
"""

JS = """
// Author: QRT Solutions. Local document controls; no network or storage.
const status=document.querySelector('.status');let statusTimer;
function announce(message){status.textContent=message;clearTimeout(statusTimer);statusTimer=setTimeout(()=>status.textContent='',3500);}
document.querySelector('#print').addEventListener('click',()=>window.print());
document.querySelector('#present').addEventListener('click',event=>{const on=document.body.classList.toggle('presenting');event.currentTarget.setAttribute('aria-pressed',String(on));event.currentTarget.textContent=on?'Vista normal':'Modo presentación';});
for(const pre of document.querySelectorAll('pre')){const code=pre.querySelector('code');if(!code)continue;const button=document.createElement('button');button.className='copy';button.type='button';button.textContent='Copiar comando';button.addEventListener('click',async()=>{try{await navigator.clipboard.writeText(code.textContent);announce('Comando copiado. Sustituye los valores de ejemplo antes de ejecutarlo.');}catch{const selection=window.getSelection(),range=document.createRange();range.selectNodeContents(code);selection.removeAllRanges();selection.addRange(range);announce('Texto seleccionado. Usa Ctrl+C o ⌘C para copiar.');}});pre.append(button);}
for(const table of document.querySelectorAll('table')){const labels=[...table.querySelectorAll('thead th')].map(t=>t.textContent);for(const tr of table.querySelectorAll('tbody tr'))[...tr.children].forEach((cell,i)=>cell.dataset.label=labels[i]||'');const wrap=document.createElement('div');wrap.className='table-wrap';table.before(wrap);wrap.append(table);}
function openReference(hash){if(!hash.startsWith('#ref-'))return;const ref=document.getElementById(hash.slice(1));if(ref instanceof HTMLDetailsElement){ref.open=true;ref.scrollIntoView({block:'start'});}}
document.querySelectorAll('a[href^="#ref-"]').forEach(link=>link.addEventListener('click',()=>openReference(link.hash)));
window.addEventListener('hashchange',()=>openReference(location.hash));openReference(location.hash);
document.querySelectorAll('.mobile-nav .toc a').forEach(link=>link.addEventListener('click',()=>document.querySelector('.mobile-nav').open=false));
const sections=[...document.querySelectorAll('main>.section')],links=[...document.querySelectorAll('.toc a')];let ticking=false;
function update(){const y=window.scrollY,max=document.documentElement.scrollHeight-innerHeight;document.querySelector('.progress').style.width=(max>0?Math.min(100,100*y/max):0)+'%';let current=sections[0]?.id;for(const section of sections)if(section.getBoundingClientRect().top<180)current=section.id;for(const link of links){const active=link.hash==='#'+current;link.classList.toggle('active',active);if(active)link.setAttribute('aria-current','location');else link.removeAttribute('aria-current');}ticking=false;}
window.addEventListener('scroll',()=>{if(!ticking){requestAnimationFrame(update);ticking=true;}},{passive:true});window.addEventListener('resize',update);update();
"""


def build(source: Path, filename: str) -> None:
    references: dict[Path, str] = {}
    titles: dict[Path, str] = {}

    def convert(text: str, base: Path, include: bool) -> str:
        rendered = markdown.markdown(text, extensions=["tables", "fenced_code", "toc", "sane_lists"])

        def link(match: re.Match) -> str:
            href, label = html.unescape(match[1]), match[2]
            parsed = urlsplit(href)
            if parsed.scheme in {"https", "http", "mailto"}:
                return f'<a href="{html.escape(href, quote=True)}" target="_blank" rel="noopener noreferrer">{label}</a>'
            if not parsed.path:
                return match[0]
            target = (base.parent / unquote(parsed.path)).resolve()
            if target.parent == OUT and target.name in DOCS.values():
                url = "#top" if target.name == filename else target.name
                return f'<a href="{url}">{label}</a>'
            if not target.is_relative_to(ROOT) or not target.is_file():
                raise ValueError(f"Invalid reference in {base.relative_to(ROOT)}")
            if target in DOCS:
                url = "#top" if target == source else DOCS[target]
                return f'<a href="{url}">{label}</a>'
            if include and target.suffix == ".md":
                if target not in references:
                    references[target] = f"ref-{len(references) + 1}"
                    titles[target] = re.sub("<[^>]+>", "", label)
                return f'<a href="#{references[target]}">{label}</a>'
            relative = html.escape(str(target.relative_to(ROOT)), quote=True)
            return f'<span class="repo-reference" title="Archivo complementario del repositorio: {relative}">{label}</span>'

        return re.sub(r'<a href="([^"]+)"[^>]*>(.*?)</a>', link, rendered, flags=re.S)

    text = source.read_text(encoding="utf-8")
    rendered = convert(text, source, True)
    rendered = re.sub(r"<h1[^>]*>.*?</h1>\s*", "", rendered, count=1, flags=re.S)
    rendered = re.sub(r"<p>Autoría:.*?</p>\s*", "", rendered, count=1, flags=re.S)
    rendered = re.sub(r'<p><a href="#top">Abrir versión HTML</a>.*?</p>\s*', "", rendered, count=1, flags=re.S)
    sections = re.split(r'(<h2 id="[^"]+">.*?</h2>)', rendered)
    intro = sections[0]
    cards, nav = [], []
    for i in range(1, len(sections), 2):
        heading, body = sections[i], sections[i + 1]
        match = re.fullmatch(r'<h2 id="([^"]+)">(.*?)</h2>', heading, re.S)
        anchor, title = match.groups()
        nav.append(f'<a href="#{anchor}">{title}</a>')
        cards.append(f'<section id="{anchor}" class="section" aria-labelledby="title-{anchor}"><h2 id="title-{anchor}">{title}</h2>{body}</section>')
    extras = []
    for path, anchor in references.items():
        content = convert(path.read_text(encoding="utf-8"), path, False)
        content = re.sub(r'\s+id="[^"]+"', "", content)
        extras.append(f'<details class="reference" id="{anchor}"><summary>{html.escape(titles[path])}</summary><div class="reference-body"><p class="source-label">Fuente: {html.escape(str(path.relative_to(ROOT)))}</p>{content}</div></details>')
    guide = filename == "configuracion.html"
    title = "De MT5 a la nube.<br>Configuración paso a paso." if guide else "Todo listo para<br>la presentación."
    page_title = "Configuración · Supabase, Telegram y Vercel" if guide else "Ayuda memoria · Presentación Seminario 3"
    subtitle = "Una ruta para conectar tu cuenta demo, guardar su historia y explicar cada decisión." if guide else "Un guion de 15 minutos. Qué mostrar, qué explicar y qué tener a mano."
    chips = ["8 pasos", "Supabase · Telegram · Vercel", "Cuenta demo"] if guide else ["15 minutos", "Guion docente", "Comandos y preguntas"]
    navigation = ''.join(nav)
    template = '''<!doctype html>
<html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="author" content="QRT Solutions"><meta name="description" content="__SUBTITLE__">
<title>__PAGE_TITLE__ · QRT Solutions</title><style>__CSS__</style></head>
<body id="top"><a class="skip" href="#contenido">Saltar al contenido</a><div class="progress" aria-hidden="true"></div>
<header class="masthead"><a class="brand" href="https://www.qrtsolutions.com" target="_blank" rel="noopener noreferrer"><span class="monogram">QRT</span><span><b>QRT SOLUTIONS</b><small>Seminario 03 / Bitácora conectada</small></span></a>
<nav class="switcher" aria-label="Documentos"><a href="configuracion.html" __GUIDE_CURRENT__>Configuración</a><a href="ayuda-memoria.html" __MEMO_CURRENT__>Presentación</a></nav></header>
<div class="layout"><aside class="rail"><p class="rail-title">En este documento</p><nav class="toc" aria-label="Índice">__NAV__</nav><p class="rail-note">Material de QRT Solutions.<br>Lectura sin conexión y referencias incluidas.<br><a href="#referencias">Ver referencias</a></p></aside>
<main id="contenido"><div class="hero"><div class="eyebrow">__EYEBROW__</div><h1>__TITLE__</h1><p>__SUBTITLE__</p><div class="chips">__CHIPS__</div>
<div class="hero-footer"><span>8 de octubre de 2026 · QRT Solutions</span><div class="actions"><button class="action secondary" id="present" type="button" aria-pressed="false">Modo presentación</button><button class="action" id="print" type="button">Imprimir / PDF</button></div></div></div>
<details class="mobile-nav"><summary>Ir a una sección</summary><nav class="toc" aria-label="Índice móvil">__NAV__</nav></details>
<div class="intro">__INTRO__</div>__CARDS__
<section class="references" id="referencias"><h2>Referencias incluidas</h2><p>Documentos complementarios del repositorio, incluidos para consultar sin conexión. No se imprimen con el resumen. Las referencias más profundas se identifican por su ruta en el repositorio; los enlaces oficiales requieren internet.</p>__REFERENCES__</section>
<footer class="doc-footer"><span>QRT Solutions · <a href="https://www.qrtsolutions.com">www.qrtsolutions.com</a></span><span>Seminario 3 · Material de formación</span></footer></main></div>
<div class="status" role="status" aria-live="polite"></div><script>__JS__</script></body></html>'''
    replacements = {
        "PAGE_TITLE": html.escape(page_title), "CSS": CSS, "JS": JS,
        "SUBTITLE": html.escape(subtitle), "TITLE": title,
        "EYEBROW": "Guía de instalación" if guide else "Ayuda memoria del docente",
        "GUIDE_CURRENT": 'aria-current="page"' if guide else "",
        "MEMO_CURRENT": '' if guide else 'aria-current="page"',
        "NAV": navigation, "INTRO": intro, "CARDS": ''.join(cards),
        "CHIPS": ''.join(f'<span>{html.escape(c)}</span>' for c in chips),
        "REFERENCES": ''.join(extras),
    }
    for key, value in replacements.items():
        template = template.replace(f"__{key}__", value)
    digest = hashlib.sha256(source.read_bytes()).hexdigest()
    template = template.replace("<!doctype html>", f"<!doctype html>\n<!-- Author: QRT Solutions. Generated from {source.relative_to(ROOT)}; SHA256 {digest}. -->", 1)
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / filename).write_text(template, encoding="utf-8")
    print(f"Generated {filename}: {len(cards)} sections, {len(extras)} embedded references")


if __name__ == "__main__":
    try:
        for source, filename in DOCS.items():
            build(source, filename)
    except Exception as err:
        raise SystemExit(type(err).__name__ + " (detalles omitidos por seguridad)") from None
