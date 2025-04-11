import pathlib

from lcb_runner.lm_styles import LanguageModel, LMStyle
from lcb_runner.utils.scenarios import Scenario


def ensure_dir(path: str, is_file=True):
    if is_file:
        pathlib.Path(path).parent.mkdir(parents=True, exist_ok=True)
    else:
        pathlib.Path(path).mkdir(parents=True, exist_ok=True)
    return


def get_cache_path(model_repr:str, args) -> str:
    scenario: Scenario = args.scenario
    n = args.n
    temperature = args.temperature
    path = f"cache/{model_repr}/{scenario}_{n}_{temperature}.json"
    ensure_dir(path)
    return path


def get_output_path(model_repr:str, args, **args_overrides) -> str:
    output_dir = args_overrides.get("output_dir", args.output_dir)
    if output_dir is None:
        output_dir = f"output/{model_repr}"

    scenario: Scenario = args_overrides.get("scenario", args.scenario)
    n = args_overrides.get("n", args.n)
    temperature = args_overrides.get("temperature", args.temperature)
    cot_suffix = "_cot" if args_overrides.get("cot_code_execution", args.cot_code_execution) else ""
    debug_suffix = "_DEBUG" if args_overrides.get("debug", args.debug) else ""

    path = f"{output_dir}/{scenario}_{n}_{temperature}{cot_suffix}{debug_suffix}.json"
    ensure_dir(path)
    return path


def get_eval_all_output_path(model_repr:str, args, **args_overrides) -> str:
    output_dir = args_overrides.get("output_dir", args.output_dir)
    if output_dir is None:
        output_dir = f"output/{model_repr}"

    scenario: Scenario = args_overrides.get("scenario", args.scenario)
    n = args_overrides.get("n", args.n)
    temperature = args_overrides.get("temperature", args.temperature)
    cot_suffix = "_cot" if args_overrides.get("cot_code_execution", args.cot_code_execution) else ""
    debug_suffix = "_DEBUG" if args_overrides.get("debug", args.debug) else ""
    path = f"{output_dir}/{scenario}_{n}_{temperature}{cot_suffix}{debug_suffix}_eval_all.json"
    return path
