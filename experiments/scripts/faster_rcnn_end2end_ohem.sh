#!/bin/bash
# Usage:
# ./experiments/scripts/faster_rcnn_end2end.sh GPU NET DATASET [options args to {train,test}_net.py]
# DATASET is either pascal_voc or coco.
#
# Example:
# ./experiments/scripts/faster_rcnn_end2end.sh 0 VGG_CNN_M_1024 pascal_voc \
#   --set EXP_DIR foobar RNG_SEED 42 TRAIN.SCALES "[400, 500, 600, 700]"

set -x
set -e

export PYTHONUNBUFFERED="True"

GPU_ID=$1
NET=$2
NET_lc=${NET,,}
DATASET=$3

array=( $@ )
len=${#array[@]}
EXTRA_ARGS=${array[@]:3:$len}
EXTRA_ARGS_SLUG=${EXTRA_ARGS// /_}


case $DATASET in
  pascal_voc)
    TRAIN_IMDB="voc_2007_trainval"
    TEST_IMDB="voc_2007_test"
    PT_DIR="pascal_voc"
    ITERS=70000   
    ;;
  coco)
    TRAIN_IMDB="coco_2014_train"
    TEST_IMDB="coco_2014_minival"
    PT_DIR="coco"
    ITERS=490000
    ;;  

  caltech_voc)
    TRAIN_IMDB="voc_2007_trainval"
    TEST_IMDB="voc_2007_test"
    PT_DIR="caltech"
    ITERS=70000   
    ;;
  caltech_all)
    TRAIN_IMDB="caltech_all_trainval"
    TEST_IMDB="caltech_all_test"
    PT_DIR="caltech"
    ITERS=90000
    ;;
  caltech_reasonable)
    TRAIN_IMDB="caltech_reasonable_trainval"
    TEST_IMDB="caltech_reasonable_test"
    PT_DIR="caltech"
    ITERS=70000
    ;;
  inria_all)
    TRAIN_IMDB="inria_all_trainval"
    TEST_IMDB="inria_all_test"
    PT_DIR="caltech"
    ITERS=60000
    ;;
  inria_reasonable)
    TRAIN_IMDB="inria_reasonable_trainval"
    TEST_IMDB="inria_reasonable_test"
    PT_DIR="caltech"
    ITERS=40000
    ;;
  eth_all)
    TRAIN_IMDB="inria_all_trainval"
    TEST_IMDB="inria_all_test"
    PT_DIR="caltech"
    ITERS=70000
    ;;
  eth_reasonable)
    TRAIN_IMDB="eth_reasonable_trainval"
    TEST_IMDB="eth_reasonable_test"
    PT_DIR="caltech"
    ITERS=70000
    ;;
    *)
    echo "No dataset given"
    exit
    ;;
esac

LOG="experiments/logs/${DATASET}_ohem_${NET}.txt.`date +'%Y-%m-%d_%H-%M-%S'`"
exec &> >(tee -a "$LOG")
echo Logging output to "$LOG"

time ./tools/train_net.py --gpu ${GPU_ID} \
  --solver models/${PT_DIR}/${NET}/faster_rcnn_end2end_ohem/solver.prototxt \
  --weights data/imagenet_models/${NET}.v2.caffemodel \
  --imdb ${TRAIN_IMDB} \
  --iters ${ITERS} \
  --cfg experiments/cfgs/faster_rcnn_end2end_ohem.yml \
  ${EXTRA_ARGS}



set +x
NET_FINAL=`grep -B 1 "done solving" ${LOG} | grep "Wrote snapshot" | awk '{print $4}'`
set -x

time ./tools/test_net.py --gpu ${GPU_ID} \
  --def models/${PT_DIR}/${NET}/faster_rcnn_end2end_ohem/test.prototxt \
  --net ${NET_FINAL} \
  --imdb ${TEST_IMDB} \
  --cfg experiments/cfgs/faster_rcnn_end2end_ohem.yml \
  ${EXTRA_ARGS}
