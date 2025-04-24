#!/bin/bash
repo_path="/Users/jbard/onedrive_tamu/repos/bardlab_plasmids"
map_plasmid_script="${repo_path}/scripts/map_plasmid.sh"
pixi_toml="${repo_path}/pixi.toml"
work_dir="${repo_path}/data/pMC1-4"
template_fasta_full_path="/Users/jbard/onedrive_tamu/repos/bardlab_plasmids/data/pMC1-4/pmc001-apex2-nes-part-plasmid-type-3.fasta"
fastq_full_path="/Users/jbard/onedrive_tamu/repos/bardlab_plasmids/data/pMC1-4/1023564_191876/1023564_RAW_FASTQ_FILES/001_pMC01_1_reads.fastq.gz"
sample_name="pMC01_1_test"

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
    "${fastq_file}" \
    "${pixi_toml}"