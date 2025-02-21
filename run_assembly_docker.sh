#!/bin/bash
work_dir="./test"
template_fasta="test.fasta"
sample_name="007_pZX009-4"
fastq_file="${sample_name}_reads.fastq.gz"

# Check if the ontresearch/medaka image exists
if [[ -z "$(docker images -q ontresearch/medaka 2>/dev/null)" ]]; then
    echo "Image 'ontresearch/medaka' not found. Pulling from Docker Hub..."
    docker pull ontresearch/medaka
else
    echo "Image 'ontresearch/medaka' already exists."
fi

docker run --rm \
  -v "${work_dir}":/data \
  ontresearch/medaka \
  bash -c "minimap2 -ax map-ont \
  "/data/${template_fasta}" \
  "/data/${fastq_file}" > \
  "/data/${sample_name}_aln.sam""

pixi run racon \
  "${work_dir}/${fastq_file}" \
  "${work_dir}/${sample_name}_aln.sam" \
  "${work_dir}/${template_fasta}" >\
  "${work_dir}/${sample_name}_consensus_racon.fasta"

docker run --rm \
  -v "${work_dir}":/data \
  ontresearch/medaka \
  medaka_consensus -i "/data/${fastq_file}" \
                   -d /data/${sample_name}_consensus_racon.fasta \
                   -o /data/${sample_name}_output \
                   -t 4 \
                   --bacteria