#!/bin/bash

echo "Sart time=$(date +"%T")"
IMG_USER="hihi313"
IMG_NAME="co-slam"
IMG_TAG="eval"
CTNR_NAME="${IMG_NAME}_${IMG_TAG}_ctnr"
WORKDIR="/app"

VOLUME=""
while getopts "f:b:ei:t:v:r:" opt
do
  case $opt in
    f)
        DOCKERFILE="$OPTARG"
        ;;
    b) 
        if [ "$OPTARG" == "n" ]; then
            CACHE="--no-cache"
        else
            CACHE=""
        fi

        START="$(TZ=UTC0 printf '%(%s)T\n' '-1')" # `-1`  is the current time
        
        # Include ./external into build context
        docker rmi $IMG_NAME
        if [ -z ${DOCKERFILE+x} ]; then
            docker build $CACHE -t ${IMG_NAME}:${IMG_TAG} -f ./docker/Dockerfile .
        else
            docker build $CACHE -t ${IMG_NAME}:${IMG_TAG} -f ${DOCKERFILE} .
        fi

        # Pring elapsed time
        ELAPSED=$(( $(TZ=UTC0 printf '%(%s)T\n' '-1') - START ))
        TZ=UTC0 printf 'Build duration=%(%H:%M:%S)T\n' "$ELAPSED"
        ;;
    e)
        docker exec -it --user=root $CTNR_NAME /entrypoint.sh bash
        ;;
    i)
        IMG_NAME="$OPTARG"
        ;;
    t)
        IMG_TAG="$OPTARG"
        ;;
    v)
        VOLUME="-v $OPTARG ${VOLUME}"
        ;;
    r)
        RM=""
        GPU=""
        DISPLAY_ENV="DISPLAY=$DISPLAY"
        DISPLAY_VOLUME="--volume=/tmp/.X11-unix:/tmp/.X11-unix:rw"
        if [[ $OPTARG == *"m"* ]]; then
            RM="--rm"
        fi
        if [[ $OPTARG == *"g"* ]]; then
            GPU="--gpus all"
        fi
        if [[ $OPTARG == *"d"* ]]; then
            DISPLAY_ENV="DISPLAY=host.docker.internal:0"
            DISPLAY_VOLUME=""
        fi
        # Enable tracing
        set -x
        # --mount type=volume,src="",dst="" \
        # --mount type=bind,src="",dst="" \
        # --user="$(id -u):$(id -g)" \

        # sudo xhost + localhost &&
        sudo xhost + local:docker &&
            docker run -it $RM $GPU $DISPLAY_VOLUME $VOLUME \
                -e QT_X11_NO_MITSHM=1 \
                -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR \
                --net=host \
                --privileged \
                --init \
                --ipc=host \
                --shm-size 20G \
                --env="$DISPLAY_ENV" \
                --mount type=volume,src="vscode-extensions",dst="/root/.vscode-server/extensions" \
                --volume="$PWD:$WORKDIR" \
                --workdir $WORKDIR \
                --name $CTNR_NAME \
                "$IMG_USER/$IMG_NAME:$IMG_TAG"

        # Disable tracing
        set +x
        ;;
    \?) 
        echo "Invalid option -$OPTARG" >&2
        exit 1
        ;;
    :)
        echo "Option -$OPTARG requires an argument." >&2
        exit 1
        ;;
    *)
        echo "*"
        ;;
  esac
done