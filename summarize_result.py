import os
import re
import argparse

from tabulate import tabulate


def get_last_pass_at_1(file_path):
    with open(file_path, "r") as f:
        content = f.read()

    matches = re.findall(r'^Pass@1\s*=\s*([\.\d]+)', content, re.MULTILINE)
    if matches:
        last_pass_at_1 = matches[-1]
        last_pass_at_1 = f"{float(last_pass_at_1)*100:.1f}"
    else:
        last_pass_at_1 = "N/A"
    
    return last_pass_at_1


def get_time_taken(file_path):
    with open(file_path, "r") as f:
        content = f.read()

    matches = re.findall(r'^Time taken: (\d+) seconds', content, re.MULTILINE)
    if matches:
        time_taken = matches[-1]
    else:
        time_taken = "N/A"
    
    return time_taken


def get_model_result(model_path):
    model_name = os.path.basename(model_path)
    tasks = [
        "codegeneration",
        "selfrepair",
        "testoutputprediction",
        "codeexecution",
        "codeexecution_cot",
    ]
    
    model_result = [model_name]
    for task in tasks:
        file_path = os.path.join(model_path, f"{task}_scores.log")
        if not os.path.exists(file_path):
            last_pass_at_1 = "N/A"
            time_taken = "N/A"
        else:
            last_pass_at_1 = get_last_pass_at_1(file_path)
            time_taken = get_time_taken(file_path)

        model_result.append(f"{last_pass_at_1} ({time_taken}s)")
    
    return model_result


def main(args):
    table = [
        ["Score: Pass@1 (Time Taken)", "", "", "", "Code Execution", ""],
        ["Model", "Code Generation", "Self Repair", "Test Output Prediction", "Base", "CoT"],
    ]    
    
    for model_path in os.listdir(args.result_dir):
        model_result = get_model_result(os.path.join(args.result_dir, model_path))
        table.append(model_result)
    
    print(tabulate(table, headers="firstrow", tablefmt="github"))
    

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--result_dir", type=str, default="output")
    args = parser.parse_args()

    main(args)
