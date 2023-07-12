#!/bin/bash

START_TIME=$(date +%s)
BATCH_UUID=$(uuidgen)

COMPOSITION_DIRNAME=${SPWASHI_OUTPUT_DIRNAME:-composited-3}
COMPOSITION_DIRECTORY=out/${COMPOSITION_DIRNAME}
UUID_DIRECTORY=${COMPOSITION_DIRECTORY}/output/${BATCH_UUID}

COUNT=0
task(){
    COUNT=$(($COUNT + 1))

    FRAMERATE=$1
    BUFFER_SIZE=$2
    CRF=$3
    EXTENSION=$4

    local_start=$(date +%s)
    BATCH_OUTPUT_DIRECTORY=${UUID_DIRECTORY}/videos/crf${CRF}
    LOG_FILE=${UUID_DIRECTORY}/log.tsv

    # --- --- --- --- ---
    # --- --- --- -f-- ---
    datePrefix="<$(date '+%Y-%m-%d %H:%M:%S')>"
    SPACE_PREFIX="$(printf '%-21s' "")\t"
    PARAM_STR="$(printf '%-4s' "$EXTENSION")\t${FRAMERATE}fps\t$(printf '%-5s' "$BUFFER_SIZE")\t${CRF}crf"
    identifier="${BATCH_UUID}\t${COUNT}\t${PARAM_STR}"

    elapsed_1=0
    elapsed=0
    # --- --- --- --- ---
    # --- --- --- --- ---
    if [ $EXTENSION == 'webm' ]
    then
        mkdir -p ${BATCH_OUTPUT_DIRECTORY}/${EXTENSION}

        EXT=webm
        V_CODEC=libvpx
        FILENAME=video.fps${FRAMERATE}.crf${CRF}.buf${BUFFER_SIZE}.${EXT}
        FILEPATH=${BATCH_OUTPUT_DIRECTORY}/${EXT}/${FILENAME}
        actionkey="${datePrefix}\t${identifier}\t$(printf '%-30s' $FILENAME)"
        outputkey="${SPACE_PREFIX}\t$(printf '%-30s' $FILENAME)"
        echo -e "${actionkey}\n${outputkey}"
#        echo -e "${actionkey}" >> ${LOG_FILE}

        ffmpeg -y -loglevel error -framerate ${FRAMERATE} -i ${COMPOSITION_DIRECTORY}/frames/%d.webp -q:v 10 -crf ${CRF} -b:v ${BUFFER_SIZE} -c:v ${V_CODEC}  \
            ${FILEPATH}
            
        local_end=$(date +%s)
        elapsed="$(($local_end-$local_start))"
        total_elapsed="$(($local_end-$START_TIME))"
        filesize="$(ls -lah $FILEPATH | awk -F " " {'print $5'})"
        TIME_PASSED_STR="[${elapsed} sec](total ${total_elapsed} sec)"
        LOG_TXT="${actionkey}\t$(printf '%-26s' "${TIME_PASSED_STR}")\t$(printf '%-5s' "${filesize}")"
        CONSOLE_TXT="${SPACE_PREFIX}\t${elapsed} sec\n${SPACE_PREFIX}\t$(printf '%-5s' "${filesize}")\n\t[${total_elapsed} sec total]"
        (($elapsed)) && (echo -e "${LOG_TXT}" >> ${LOG_FILE})
        (($elapsed)) && echo -e "${CONSOLE_TXT}\n"
    fi
    # --- --- --- --- ---
    # --- --- --- --- ---

    elapsed_1=$elapsed
    elapsed=0
    local_start=$(date +%s)

    # --- --- --- --- ---
    # --- --- --- --- ---
    if [ $EXTENSION == 'mp4' ]
    then
        mkdir -p ${BATCH_OUTPUT_DIRECTORY}/${EXTENSION}

        EXT=mp4
        PIX_FMT=yuv420p 
        V_CODEC=libx264
        FILENAME=video.fps${FRAMERATE}.crf${CRF}.${EXT}
        FILEPATH=${BATCH_OUTPUT_DIRECTORY}/${EXT}/${FILENAME}

        datePrefix="<$(date '+%Y-%m-%d %H:%M:%S')>"
        actionkey="${datePrefix}\t${identifier}\t$(printf '%-30s' $FILENAME)"
        outputkey="${SPACE_PREFIX}\t$(printf '%-30s' $FILENAME)"
        echo -e "${actionkey}\n${outputkey}"
#        echo -e "${actionkey}" >> ${LOG_FILE}

        ffmpeg -y -loglevel error -framerate ${FRAMERATE} -i ${COMPOSITION_DIRECTORY}/frames/%d.webp -q:v 7 -crf ${CRF} -b:v ${BUFFER_SIZE} -pix_fmt ${PIX_FMT} -c:v ${V_CODEC}  \
            ${FILEPATH};
        
        local_end=$(date +%s)
        elapsed="$(($local_end-$local_start))"
        total_elapsed="$(($local_end-$START_TIME))"
        filesize="$(ls -lah $FILEPATH | awk -F " " {'print $5'})"
        TIME_PASSED_STR="[${elapsed} sec](total ${total_elapsed} sec)"
        LOG_TXT="${actionkey}\t$(printf '%-26s' "${TIME_PASSED_STR}")\t$(printf '%-5s' "${filesize}")"
        CONSOLE_TXT="${SPACE_PREFIX}\t${elapsed} sec\n${SPACE_PREFIX}\t$(printf '%-5s' "${filesize}")\n\t[${total_elapsed} sec total]"
        (($elapsed)) && (echo -e "${LOG_TXT}" >> ${LOG_FILE})
        (($elapsed)) && echo -e "${CONSOLE_TXT}\n"
    fi
    # --- --- --- --- ---
    # echo "            loop time: $(($elapsed+$elapsed_1)) seconds"
    # echo "            passed time: $(($local_end-$START_TIME)) seconds"
}


# initialize a semaphore with a given number of tokens
open_sem(){
    mkfifo pipe-$$
    exec 3<>pipe-$$
    rm pipe-$$
    local i=$1
    for((;i>0;i--)); do
        printf %s 000 >&3
    done
}

# run the given command asynchronously and pop/push tokens
run_with_lock(){
    local x
    # this read waits until there is something to read
    read -u 3 -n 3 x && ((0==x)) || exit $x
    (
     ( "$@"; )
    # push the return code of the command to the semaphore
    printf '%.3d' $? >&3
    )&
}

echo "Generating task list"
TODO_FILE=${COMPOSITION_DIRECTORY}/output/queue.txt
ACTIVE_FILE=${COMPOSITION_DIRECTORY}/output/queue_active.txt
(
    for EXTENSION in mp4 webm
    do
        ONE_DONE=false
        for BUFFER_SIZE in 500K 1M 5M 15M
        do
            for FRAMERATE in 52 26 13
            do
                for CRF in 26 5
                do
                    if [[ $EXTENSION == "mp4" ]];
                    then :
                        if [ "$ONE_DONE" = true ] ; 
                        then :
                        else    
                            echo "$BATCH_UUID $FRAMERATE $BUFFER_SIZE $CRF $EXTENSION" >> ${TODO_FILE}; 
                        fi
                    else
                        echo "$BATCH_UUID $FRAMERATE $BUFFER_SIZE $CRF $EXTENSION" >> ${TODO_FILE}; 
                    fi
                done
            done
            ONE_DONE=true
        done
    done
)



lastline=100

digest_line() {
    FILE=$1
    OUTPUT_FILE=$2
    line=$(head -n 1 $FILE)
    tail -n +2 "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
    echo $line >> $OUTPUT_FILE
    echo $line
}

echo "Digesting task list"
while [[ ! -z "$lastline" ]];
do
    lastline=$(digest_line $TODO_FILE $ACTIVE_FILE)
    echo "queueing: $lastline"
    sleep .1
done

while grep -q "^${BATCH_UUID}" "$ACTIVE_FILE";
do
    line=$(grep -m 1 "^${BATCH_UUID}" $ACTIVE_FILE)
#    echo "processing: [${line}]"
    read -r LINE_UUID LINE_FRAMERATE LINE_BUFFER_SIZE LINE_CRF LINE_EXTENSION <<< $line
#    echo -e "          : [${LINE_UUID} ${LINE_FRAMERATE} ${LINE_BUFFER_SIZE} ${LINE_CRF} ${LINE_EXTENSION}]"

    task "${LINE_FRAMERATE}" "${LINE_BUFFER_SIZE}" "${LINE_CRF}" "$LINE_EXTENSION"
    sed -i '' -E "1,/${line}/ s/(${line})/[done]\1/" $ACTIVE_FILE


    sleep .05
done


# (
#     for EXTENSION in mp4 webm
#     do
#         for CRF in 26 13 5
#         do
#             for FRAMERATE in 52 26 13 5
#             do
#                 ONE_DONE=false
#                 for BUFFER_SIZE in 500K 1M 5M 15M
#                 do
#                     if [[ $EXTENSION == "mp4" ]];
#                     then :
#                         if [ "$ONE_DONE" = true ] ; 
#                         then :
#                         else    
#                             task $FRAMERATE $BUFFER_SIZE $CRF $EXTENSION ; 
#                         fi
#                     else
#                         task $FRAMERATE $BUFFER_SIZE $CRF $EXTENSION
#                     fi
#                     ONE_DONE=true
#                 done
#             done
#         done
#     done
# )


# N=${BATCH_SIZE:-6}
# open_sem $N
# (
#     for EXTENSION in mp4 webm
#     do
#         for CRF in 26 13 5
#         do
#             for FRAMERATE in 52 26 13 5
#             do
#                 ONE_DONE=false
#                 for BUFFER_SIZE in 500K 1M 5M 15M
#                 do
#                     if [[ $EXTENSION == "mp4" ]];
#                     then :
#                         if [ "$ONE_DONE" = true ] ;
#                         then :
#                         else
#                             run_with_lock task $FRAMERATE $BUFFER_SIZE $CRF $EXTENSION ;
#                         fi
#                     else
#                         run_with_lock task $FRAMERATE $BUFFER_SIZE $CRF $EXTENSION
#                     fi
#                     ONE_DONE=true
#                 done
#             done
#         done
#     done
# )


# N=${BATCH_SIZE:-6}
# (
#     for EXTENSION in mp4 webm
#     do
#         for CRF in 26 13 5
#         do
#             for FRAMERATE in 52 26 13 5
#             do
#                 ONE_DONE=false
#                 for BUFFER_SIZE in 500K 1M 5M 15M
#                 do
#                     if [[ $EXTENSION == "mp4" ]];
#                     then :
#                         if [ "$ONE_DONE" = true ] ; 
#                         then :
#                         else    
#                             ((i=i%N)); ((i++==0)) && wait && task $FRAMERATE $BUFFER_SIZE $CRF $EXTENSION &
#                         fi
#                     else
#                         ((i=i%N)); ((i++==0)) && wait && task $FRAMERATE $BUFFER_SIZE $CRF $EXTENSION &
#                     fi
#                     ONE_DONE=true
#                 done
#             done
#         done
#     done
# )

wait < <(jobs -p)

echo "=============="
echo "finished processing"
end=$(date +%s)
echo "Elapsed Time: $(($end-$START_TIME)) seconds"
