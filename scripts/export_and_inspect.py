"""Inspect and export the provided YOLO11 shelf/product models for mobile."""

from pathlib import Path
from ultralytics import YOLO

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "_model_extract" / "AI Model & Test Images" / "Models"
OUT = ROOT / "assets" / "models"


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    models = {
        "detect_product_empty_space.pt": "detect",
        "segment_shelf_rows.pt": "segment",
    }
    for name, task in models.items():
        path = SRC / name
        model = YOLO(str(path))
        print(f"\n=== {name} ===")
        print("task:", model.task, "names:", model.names)
        model.info()
        onnx = model.export(format="onnx", imgsz=640, simplify=True, opset=12)
        print("exported:", onnx)


if __name__ == "__main__":
    main()
