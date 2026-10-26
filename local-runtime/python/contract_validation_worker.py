import json
import sys
from pathlib import Path

# `python -I` nimmt das Skriptverzeichnis nicht in den Suchpfad auf; ohne es fehlt `novooa_ml`.
sys.path.insert(0, str(Path(__file__).resolve().parent))

from novooa_ml.transformation_capabilities import validate_contract  # noqa: E402


def main():
    payload = json.loads(sys.stdin.read())
    sys.stdout.write(json.dumps(validate_contract(payload)))


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        sys.stderr.write(f"Die Vertragsprüfung ist fehlgeschlagen: {error}")
        sys.exit(1)
