import json
import sys
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parent))

from novooa_ml.model_input.worker import transform_payload


def main():
    payload = json.loads(sys.stdin.read())
    sys.stdout.write(json.dumps(transform_payload(payload)))


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        sys.stderr.write(str(error))
        sys.exit(1)
