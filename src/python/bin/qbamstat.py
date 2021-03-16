# Estimates the coverage
import sys
import random
import pysam

random.seed(42)
bam_name = sys.argv[1]
bam = pysam.AlignmentFile(bam_name)
sample = bam.header["RG"][0]["SM"]
chrom = bam.get_reference_name(next(bam).tid)
reflen = bam.get_reference_length(chrom)

# region's size
RGNSZ=1000
# number of regions
NRGN=100
# If fewer than MINPASS regions have reads, exit with an error
MINPASS=80

readlen = 0
cnt = 0
covsum = 0

while NRGN > 0:
    NRGN -= 1
    pos = random.randint(1, reflen)
    try:
        readlen = max(readlen, next(bam.fetch(chrom, pos, pos + RGNSZ)).qlen)
    except Exception as e:
        continue
    c = bam.count_coverage(chrom, pos, pos + RGNSZ)
    covsum += sum([sum(x) for x in zip(*c)]) / RGNSZ
    cnt += 1

if cnt < MINPASS:
    sys.stderr.write(f"Could only get reads from {cnt} regions. Coverage may be inaccurate\n")

coverage = int(covsum / cnt)
print("#id\tpath\tdepth\tread length")
print(f"{sample}\t{bam_name}\t{coverage}\t{readlen}")
