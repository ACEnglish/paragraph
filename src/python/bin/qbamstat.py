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

readlensum = 0
readcnt = 0
covsum = 0
covcnt = 0

while NRGN > 0:
    NRGN -= 1
    pos = random.randint(1, reflen)
    try:
        readlensum += next(bam.fetch(chrom, pos, pos + RGNSZ)).qlen
        readcnt += 1
    except Exception as e:
        continue
    c = bam.count_coverage(chrom, pos, pos + RGNSZ)
    cov = [sum(x) for x in zip(*c)]
    cov = sum([sum(x) for x in zip(*c)]) 
    msum = cov / RGNSZ
    covsum += msum
    covcnt += 1

if covcnt < MINPASS:
    sys.stderr.write(f"Could only get reads from {covcnt} regions. Coverage may be inaccurate\n")

coverage = int(covsum / covcnt)
readlen = int(readlensum / readcnt)
print("#id\tpath\tdepth\tread length")
print(f"{sample}\t{bam_name}\t{coverage}\t{readlen}")