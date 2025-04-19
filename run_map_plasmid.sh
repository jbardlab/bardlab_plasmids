#!/bin/bash
map_plasmid_script="/Users/jbard/Library/CloudStorage/OneDrive-TexasA&MUniversity/repos/bardlab_plasmids/map_plasmid.sh"
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

# Run the analysis script
bash "${map_plasmid_script}" \
    "${sample_dir}" \
    "${sample_name}" \
    "${sample_name}_template.fasta" \
    "${fastq_file}"