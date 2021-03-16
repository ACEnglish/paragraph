#!/bin/bash

set -oe pipefail

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

echo "vcf:" $VCF
if [ -z "${VCF}" ]
then
    echo "VCF (-v) must be provided"
    HASERROR=true
fi
if [ ! -f "$VCF" ]; then
    echo "$VCF does not exist."
    HASERROR=true
fi

echo "json:" $JSON
if [ -z "${JSON}" ]
then
    echo "JSON (-j) must be provided"
    HASERROR=true
fi
if [ ! -f "$JSON" ]; then
    echo "$JSON does not exist."
    HASERROR=true
fi

echo "bam:" $BAM
if [ -z "${BAM}" ]
then
    echo "BAM (-b) must be provided"
    HASERROR=true
fi
if [ ! -f "$BAM" ]; then
    echo "$BAM does not exist."
    HASERROR=true
fi

echo "reference:" $REF
if [ -z "${REF}" ]
then
    echo "REF (-r) must be provided"
    HASERROR=true
fi
if [ ! -f "$REF" ]; then
    echo "$REF does not exist."
    HASERROR=true
fi

if [ $HASERROR = true ]; then
    echo "Error parsing parameters. Exiting"
    exit 1
fi

####
# Parameters with defaults
####
if [ -z "${THREADS}" ]
then
    THREADS=$(nproc)
    echo "THREADS (-t) set to ${THREADS}"
else
    echo "threads:" $THREADS
fi

if [ -z "${OUT}" ]
then
    OUT="result"
    echo "OUT (-o) set to ${OUT}"
else
    echo "out:" $OUT
fi

# If depth/readlength/sample is not set, estimate them from the input bam
# I bet I could with a pretty simple script.. pysam is available
HASERROR=false
if [ -z "${SAMPLE}" ]
then
    echo "SAMPLE (-s) unset"
    HASERROR=true
else
    echo "sample:" $SAMPLE
fi
if [ -z "${DEPTH}" ]
then
    echo "DEPTH (-d) unset"
    HASERROR=true
else
    echo "depth:" $DEPTH
fi
if [ -z "${RL}" ]
then
    echo "RL (-l) unset"
    HASERROR=true
else
    echo "readlen:" $RL
fi

if [ $HASERROR = true ]; then
    echo "One or more library parameters unset. Estimating..."
    python3 $QBAMSTAT $BAM > manifest.txt
    cat manifest.txt
else
    echo -e "#id\tpath\tdepth\tread length" > manifest.txt
    echo -e "${SAMPLE}\t${BAM}\t${DEPTH}\t${RL}" >> manifest.txt
fi

# Run it
echo time python3 $GRMPY -i $JSON -b $VCF -m manifest.txt -r $REF -o $OUT -t $THREADS --verbose

touch paragraph.success
