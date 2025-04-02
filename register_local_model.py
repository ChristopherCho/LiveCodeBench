import os
import json
import argparse
import datetime


CUSTOM_STYLES_PATH = os.path.join(os.path.dirname(__file__), "lcb_runner", "custom_styles.json")


def main(args):
    with open(CUSTOM_STYLES_PATH, "r") as f:
        custom_styles = json.load(f)

    for entry in custom_styles:
        if entry["model_name"] == args.model_name:
            print(f"Model {args.model_name} already registered")
            return

    custom_styles.append({
        "model_name": args.model_name,
        "model_path": args.model_path,
        "release_date": datetime.datetime.now().strftime("%Y-%m-%d"),
    })

    with open(CUSTOM_STYLES_PATH, "w") as f:
        json.dump(custom_styles, f, indent=4)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--model_path", type=str, required=True)
    parser.add_argument("--model_name", type=str, required=True)
    args = parser.parse_args()
    main(args)
