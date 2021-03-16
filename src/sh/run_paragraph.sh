#!/bin/bash

set -oe pipefail

function LOG {
    echo -e "[$(date)] [INFO]" $@
}

function LOGE {
    echo -e "[$(date)] [ERROR]" $@
}

# Entrypoint script for basic paragraph running
GRMPY=/opt/paragraph-build/bin/multigrmpy.py
QBAMSTAT=/opt/paragraph-build/bin/qbamstat.py

while getopts v:j:b:s:d:l:o:t:r: flag
do
    case "${flag}" in
        v) VCF=${OPTARG};;
        j) JSON=${OPTARG};;
        b) BAM=${OPTARG};;
        s) SAMPLE=${OPTARG};;
        d) DEPTH=${OPTARG};;
        l) RL=${OPTARG};;
        o) OUT=${OPTARG};;
        t) THREADS=${OPTARG};;
        r) REF=${OPTARG};;
    esac
done

####
# Required parameters
####
HASERROR=false

LOG "Checking Parameters"
if [ -z "${VCF}" ]
then
    LOGE "VCF (-v) must be provided"
    HASERROR=true
elif [ ! -f "$VCF" ]; then
    LOGE "$VCF does not exist."
    HASERROR=true
else
    LOG "vcf:" $VCF
fi

if [ -z "${JSON}" ]
then
    LOGE "JSON (-j) must be provided"
    HASERROR=true
elif [ ! -f "$JSON" ]; then
    LOGE "$JSON does not exist."
    HASERROR=true
else
    LOG "json:" $JSON
fi

if [ -z "${BAM}" ]
then
    LOGE "BAM (-b) must be provided"
    HASERROR=true
elif [ ! -f "$BAM" ]; then
    LOGE "$BAM does not exist."
    HASERROR=true
else
    LOG "bam:" $BAM
fi

if [ -z "${REF}" ]
then
    LOGE "REF (-r) must be provided"
    HASERROR=true
elif [ ! -f "$REF" ]; then
    LOGE "$REF does not exist."
    HASERROR=true
else
    LOG "reference:" $REF
fi

if [ $HASERROR = true ]; then
    LOGE "Error parsing parameters. Exiting"
    exit 1
fi

####
# Parameters with defaults
####
if [ -z "${THREADS}" ]
then
    THREADS=$(nproc)
    LOG "THREADS (-t) set to ${THREADS}"
else
    LOG "threads:" $THREADS
fi

if [ -z "${OUT}" ]
then
    OUT="result"
    LOG "OUT (-o) set to ${OUT}"
else
    LOG "out:" $OUT
fi

# If depth/readlength/sample is not set, estimate them from the input bam
# I bet I could with a pretty simple script.. pysam is available
HASERROR=false
if [ -z "${SAMPLE}" ]
then
    LOG "SAMPLE (-s) unset"
    HASERROR=true
else
    LOG "sample:" $SAMPLE
fi
if [ -z "${DEPTH}" ]
then
    LOG "DEPTH (-d) unset"
    HASERROR=true
else
    LOG "depth:" $DEPTH
fi
if [ -z "${RL}" ]
then
    LOG "RL (-l) unset"
    HASERROR=true
else
    LOG "readlen:" $RL
fi

if [ $HASERROR = true ]; then
    LOG "One or more library parameters unset. Estimating..."
    python3 $QBAMSTAT $BAM > manifest.txt
    cat manifest.txt
else
    echo -e "#id\tpath\tdepth\tread length" > manifest.txt
    echo -e "${SAMPLE}\t${BAM}\t${DEPTH}\t${RL}" >> manifest.txt
fi

# Run it
time python3 $GRMPY -i $JSON -b $VCF -m manifest.txt -r $REF -o $OUT -t $THREADS --verbose

LOG "Finished Successfully"
touch paragraph.success
