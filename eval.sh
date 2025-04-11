while getopts "m:n:t:o:d" opt; do
    case $opt in
        m) MODEL_PATH=$OPTARG ;;
        n) MODEL_NAME=$OPTARG ;;
        t) TASK=$OPTARG ;;
        o) OUTPUT_DIR=$OPTARG ;;
        d) DEBUG=true ;;
    esac
done


if [ -z "$MODEL_PATH" ]; then
    echo "Missing model path"
    exit 1
fi


DEBUG_ARG=""
if [ "$DEBUG" = true ]; then
    DEBUG_ARG="--debug"
    DEBUG_SUFFIX="_DEBUG"
fi


if [ -d ${MODEL_PATH} ]; then
    echo "Use local model ${MODEL_PATH}"
    
    MODEL_NAME=$(basename ${MODEL_PATH})
    MODEL_EVAL_NAME="${MODEL_NAME}"
    LOCAL_MODEL_ARG="--local_model_path ${MODEL_PATH}"

    python register_local_model.py --model_name ${MODEL_NAME} --model_path ${MODEL_PATH}
else
    MODEL_EVAL_NAME="${MODEL_NAME}"
    MODEL_NAME="${MODEL_PATH}"
    LOCAL_MODEL_ARG=""
fi

if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR=result/${MODEL_EVAL_NAME}
    echo "OUTPUT_DIR is not provided. Set to $OUTPUT_DIR"
fi

SUPPORTED_TASKS=(
    "codegeneration"
    "selfrepair"
    "testoutputprediction"
    "codeexecution"
    "codeexecution_cot"
)
if [ -z "$TASK" ]; then
    TASKS=${SUPPORTED_TASKS[@]}
else
    if [[ ! " ${SUPPORTED_TASKS[@]} " =~ " ${TASK} " ]]; then
        echo "Task ${TASK} is not supported. Supported tasks: ${SUPPORTED_TASKS[@]}"
        exit 1
    fi
    TASKS=($TASK)
fi


eval() {
    local scenario=$1
    local n=$2

    local cot_suffix=""
    if [ $# -ge 3 ]; then
        local cot=$3
        if [ "$cot" = true ]; then
            cot_suffix="_cot"
        fi
    fi

    output_file_path=${OUTPUT_DIR}/Scenario.${scenario}_${n}_0.2${cot_suffix}${DEBUG_SUFFIX}_eval_all.json
    if [ -f ${output_file_path} ]; then
        (
            python -m lcb_runner.evaluation.compute_scores \
                --eval_all_file ${output_file_path} \
                --output_dir ${OUTPUT_DIR}
        ) >${OUTPUT_DIR}/${scenario}${cot_suffix}${DEBUG_SUFFIX}_scores.log
    else
        echo "File ${output_file_path} does not exist. Check if the model is renamed in output."
    fi
}


codegeneration() {
    echo "Evaluating ${MODEL_NAME} on codegeneration"
    SECONDS=0
    python -m lcb_runner.runner.main \
        --model ${MODEL_NAME} \
        ${LOCAL_MODEL_ARG} \
        --scenario codegeneration \
        --evaluate \
        --release_version release_v5 \
        --continue_existing_with_eval \
        --output_dir ${OUTPUT_DIR} \
        ${DEBUG_ARG}
    eval codegeneration 10
    duration=$SECONDS
    echo "Time taken: $duration seconds" >> ${OUTPUT_DIR}/codegeneration${DEBUG_SUFFIX}_scores.log
}


selfrepair() {
    echo "Evaluating ${MODEL_NAME} on selfrepair"

    SECONDS=0
    python -m lcb_runner.runner.main \
        --model ${MODEL_NAME} \
        ${LOCAL_MODEL_ARG} \
        --scenario selfrepair \
        --n 1 \
        --evaluate \
        --continue_existing_with_eval \
        --output_dir ${OUTPUT_DIR} \
        ${DEBUG_ARG}
    eval selfrepair 1
    duration=$SECONDS
    echo "Time taken: $duration seconds" >> ${OUTPUT_DIR}/selfrepair${DEBUG_SUFFIX}_scores.log
}


testoutputprediction() {
    echo "Evaluating ${MODEL_NAME} on testoutputprediction"
    SECONDS=0
    python -m lcb_runner.runner.main \
        --model ${MODEL_NAME} \
        ${LOCAL_MODEL_ARG} \
        --scenario testoutputprediction \
        --evaluate \
        --continue_existing_with_eval \
        --output_dir ${OUTPUT_DIR} \
        ${DEBUG_ARG}
    eval testoutputprediction 10
    duration=$SECONDS
    echo "Time taken: $duration seconds" >> ${OUTPUT_DIR}/testoutputprediction${DEBUG_SUFFIX}_scores.log
}


codeexecution() {
    echo "Evaluating ${MODEL_NAME} on codeexecution"
    SECONDS=0
    python -m lcb_runner.runner.main \
        --model ${MODEL_NAME} \
        ${LOCAL_MODEL_ARG} \
        --scenario codeexecution \
        --evaluate \
        --continue_existing_with_eval \
        --output_dir ${OUTPUT_DIR} \
        ${DEBUG_ARG}
    eval codeexecution 10
    duration=$SECONDS
    echo "Time taken: $duration seconds" >> ${OUTPUT_DIR}/codeexecution${DEBUG_SUFFIX}_scores.log
}


codeexecution_cot() {
    echo "Evaluating ${MODEL_NAME} on codeexecution with CoT"
    SECONDS=0
    python -m lcb_runner.runner.main \
        --model ${MODEL_NAME} \
        ${LOCAL_MODEL_ARG} \
        --scenario codeexecution \
        --cot_code_execution \
        --evaluate \
        --continue_existing_with_eval \
        --output_dir ${OUTPUT_DIR} \
        ${DEBUG_ARG}
    eval codeexecution 10 true
    duration=$SECONDS
    echo "Time taken: $duration seconds" >> ${OUTPUT_DIR}/codeexecution_cot${DEBUG_SUFFIX}_scores.log
}


for task in ${TASKS[@]}; do
    ${task}
done
