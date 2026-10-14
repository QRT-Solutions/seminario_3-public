"""QRT Solutions: stage an explicit offline documentation tree for MkDocs."""

import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def documentation_ignored(directory, names):
    """Exclude local runtime/configuration; the web app deploys separately."""
    ignored = set(shutil.ignore_patterns(
        "__pycache__", "*.pyc", "node_modules", "dist", ".vercel",
        "*.private.json", "*.lnk", "*.ex5", "*.log", ".local", ".mcp.json", "mcp_config.json"
    )(directory, names))
    ignored.update(name for name in names if name.startswith(".env") and name != ".env.example")
    if Path(directory) == ROOT / "seminario_3/aplicaciones/web":
        ignored.add("src")
    return ignored


def on_config(config, **kwargs):
    config["docs_dir"] = str(ROOT / ".local/site-source")
    return config


def on_pre_build(config, **kwargs):
    destination = Path(config["docs_dir"])
    if not destination.resolve().is_relative_to(ROOT / ".local"):
        raise ValueError("Documentation staging must remain inside .local")
    if destination.exists():
        shutil.rmtree(destination)
    destination.mkdir(parents=True)
    for name in (
        "README.md",
        "README.en.md",
        "LICENSE",
        "SECURITY.md",
        "CONTRIBUTING.md",
        "CODE_OF_CONDUCT.md",
        "THIRD_PARTY_NOTICES.md",
        "CHANGELOG.md",
        "AGENTS.md",
        "CITATION.cff",
        "INSTRUCCIONES_SISTEMA_CREADOR_BOTS_IA.md",
    ):
        if (ROOT / name).exists():
            shutil.copyfile(ROOT / name, destination / name)
    (destination / "README.md").rename(destination / "index.md")
    for name in ("docs", "licenses", "quant_agentic_swarm", "TradingView", "MT5", "seminario_3"):
        shutil.copytree(
            ROOT / name, destination / name, ignore=documentation_ignored
        )
    # Include only the reviewed public skill, never local MCP configurations.
    skill_path = Path(".agents/skills/mt5-platform-operator")
    if (ROOT / skill_path).is_dir():
        shutil.copytree(
            ROOT / skill_path,
            destination / skill_path,
            ignore=shutil.ignore_patterns("__pycache__", "*.pyc"),
        )
    masterclass = destination / "masterclass"
    masterclass.mkdir()
    for name in ("index.html", "styles.css", "app.js", "guion.md", "QRT-LOGO.png"):
        shutil.copyfile(ROOT / "masterclass" / name, masterclass / name)
    html = masterclass / "index.html"
    html.write_text(
        html.read_text(encoding="utf-8").replace(
            "../docs/methodology.md", "../docs/methodology.html"
        ),
        encoding="utf-8",
    )
    if (ROOT / "masterclass/vendor").exists():
        shutil.copytree(ROOT / "masterclass/vendor", masterclass / "vendor")
    for page in destination.rglob("*.md"):
        def root_readme_link(match, current_page=page):
            target = match.group(1)
            if (current_page.parent / target).resolve() == destination / "README.md":
                return "(" + target.removesuffix("README.md") + "index.md)"
            return match.group(0)

        page.write_text(
            re.sub(r"\(([^\s()]*README\.md)\)", root_readme_link,
                   page.read_text(encoding="utf-8")),
            encoding="utf-8",
        )
