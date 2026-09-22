from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
SOURCE = ROOT / "assets" / "icons" / "app_mark.png"


if __name__ == "__main__":
    sizes = (16, 20, 24, 32, 40, 48, 64, 128, 256)
    source = Image.open(SOURCE).convert("RGBA")
    source.save(OUTPUT, format="ICO", sizes=[(size, size) for size in sizes])
    print(OUTPUT)
