#!/bin/bash

# Plasmid analysis script
# This script performs analysis on plasmid sequencing data
# Usage: plasmid_analysis.sh <sample_dir> <sample_name> <template_fasta> <fastq_file>

# Check if arguments are provided
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <sample_dir> <sample_name> <template_fasta> <fastq_file> <pixi_toml>"
    echo "Example: $0 /path/to/sampledir sample1 template.fasta reads.fastq.gz /path/to/pixi.toml"
    exit 1
fi

# Get arguments
sample_dir="$1"
sample_name="$2"
template_fasta="$3"
fastq_file="$4"
pixi_toml="$5"

echo "## Starting analysis for sample: ${sample_name}"
echo "## Sample directory: ${sample_dir}"
echo "## Template FASTA: ${template_fasta}"
echo "## FASTQ file: ${fastq_file}"
echo "## PIXI toml: ${pixi_toml}"


# Run minimap2 to generate SAM file
echo "Running minimap2 alignment..."
docker run --rm \
  -v "${sample_dir}":/data \
  ontresearch/medaka \
  bash -c "minimap2 -ax map-ont \
  "/data/${template_fasta}" \
  "/data/${fastq_file}" > \
  "/data/${sample_name}_aln.sam""

# Convert SAM to BAM and sort
echo "## Converting SAM to BAM and sorting..."
docker run --rm \
  -v "${sample_dir}":/data \
  ontresearch/medaka \
  bash -c "samtools view -bS "/data/${sample_name}_aln.sam" | \
  samtools sort -o "/data/${sample_name}_aln.sorted.bam""

# Index the BAM file
echo "## Indexing BAM file..."
docker run --rm \
  -v "${sample_dir}":/data \
  ontresearch/medaka \
  bash -c "samtools index /data/${sample_name}_aln.sorted.bam"

# Run racon
echo "## Running racon consensus..."
pixi run --manifest-path "${pixi_toml}" racon \
  "${sample_dir}/${fastq_file}" \
  "${sample_dir}/${sample_name}_aln.sam" \
  "${sample_dir}/${template_fasta}" > \
  "${sample_dir}/${sample_name}_draft_racon.fasta"

# Run medaka
echo "## Running medaka for final consensus..."
docker run --rm \
  -v "${sample_dir}":/data \
  ontresearch/medaka \
  medaka_consensus -i "/data/${fastq_file}" \
                   -d "/data/${sample_name}_draft_racon.fasta" \
                   -o "/data/${sample_name}_final_output" \
                   -t 4 \
                   --bacteria

mv "${sample_dir}/${sample_name}_final_output/consensus.fasta" "${sample_dir}/${sample_name}_final_output/${sample_name}_consensus.fasta"

echo "## Analysis completed for sample: ${sample_name}"