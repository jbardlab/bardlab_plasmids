#!/bin/bash
work_dir="/Users/jbard/Library/CloudStorage/OneDrive-TexasA&MUniversity/repos/bardlab_plasmids/1021108_191634"
template_fasta_full_path="/Users/jbard/Library/CloudStorage/OneDrive-TexasA&MUniversity/repos/bardlab_plasmids/1021108_191634/pzx020-aavs1-eebxb1-landing-pad-attb-ver1-from-pzx008.fasta"
fastq_full_path="/Users/jbard/Library/CloudStorage/OneDrive-TexasA&MUniversity/repos/bardlab_plasmids/1021108_191634/1021108_RAW_FASTQ_FILES/001_pZX020-1_reads.fastq.gz"
sample_name="001_pZX020-1"

sample_dir="${work_dir}/${sample_name}"
fastq_file=$(basename "${fastq_full_path}")

# Create sample directory if it doesn't exist
mkdir -p "${sample_dir}"
cp "${template_fasta_full_path}" "${sample_dir}/${sample_name}_template.fasta"

cp "${fastq_full_path}" "${sample_dir}/${fastq_file}"

# Check if the ontresearch/medaka image exists
if [[ -z "$(docker images -q ontresearch/medaka 2>/dev/null)" ]]; then
    echo "Image 'ontresearch/medaka' not found. Pulling from Docker Hub..."
    docker pull ontresearch/medaka
else
    echo "Image 'ontresearch/medaka' already exists."
fi

# Run minimap2 to generate SAM file
docker run --rm \
  -v "${sample_dir}":/data \
  ontresearch/medaka \
  bash -c "minimap2 -ax map-ont \
  "/data/${sample_name}_template.fasta" \
  "/data/${fastq_file}" > \
  "/data/${sample_name}_aln.sam""

# Convert SAM to BAM and sort
docker run --rm \
  -v "${sample_dir}":/data \
  ontresearch/medaka \
  bash -c "samtools view -bS "/data/${sample_name}_aln.sam" | \
  samtools sort -o "/data/${sample_name}_aln.sorted.bam""

# Index the BAM file
docker run --rm \
  -v "${sample_dir}":/data \
  ontresearch/medaka \
  bash -c "samtools index /data/${sample_name}_aln.sorted.bam"

# Run racon
pixi run racon \
  "${sample_dir}/${fastq_file}" \
  "${sample_dir}/${sample_name}_aln.sam" \
  "${sample_dir}/${sample_name}_template.fasta" > \
  "${sample_dir}/${sample_name}_draft_racon.fasta"

# Run medaka
docker run --rm \
  -v "${sample_dir}":/data \
  ontresearch/medaka \
  medaka_consensus -i "/data/${fastq_file}" \
                   -d /data/${sample_name}_draft_racon.fasta \
                   -o /data/final_output \
                   -t 4 \
                   --bacteria
