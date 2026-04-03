#!/bin/bash
set -e

# paths
path_gen="/mnt/e/Lilith/my_dataset_better_BIDS"
wf_dir="${path_gen}/derivatives"
tbss_dir="${path_gen}/derivatives/tbss_no_cuts"
randomise_folder="randomise"
mkdir -p ${randomise_folder}

cd ${tbss_dir}

# ===Subjects ===
# reduced sample
#participants=("sub-001" "sub-005" "sub-013" "sub-017" "sub-019" "sub-021" "sub-023" "sub-024" "sub-035" "sub-039" "sub-040" "sub-041" "sub-045" "sub-049" "sub-051" "sub-052" "sub-055" "sub-056" "sub-057" "sub-059")

# full sample
participants=("sub-001" "sub-002" "sub-003" "sub-005" "sub-007" "sub-008" "sub-013" "sub-014" "sub-016" "sub-017" "sub-018" "sub-019" "sub-021" "sub-022" "sub-023" "sub-024" "sub-026" "sub-030" "sub-031" "sub-033" "sub-035" "sub-036" "sub-039" "sub-040" "sub-041" "sub-043" "sub-044" "sub-045" "sub-047" "sub-049" "sub-051" "sub-052" "sub-054" "sub-055" "sub-056" "sub-057" "sub-059")

# === Run tbss_non_FA ===
tbss_non_FA masks

# === Binarise skeleton mask ===
mkdir -p ${tbss_dir}/masks_tbss_2

fslmaths stats/all_masks_skeletonised.nii.gz \
         -bin \
         masks_tbss_2/binary_masks_skeletonised.nii.gz

#Split into subject-wise masks
fslsplit masks_tbss_2/binary_masks_skeletonised.nii.gz masks_tbss_2/mask_ -t

i=0
for ptc in "${participants[@]}"; do
    src="masks_tbss_2/mask_$(printf "%04d" "$i").nii.gz" 
    dst="masks_tbss_2/mask_${ptc}.nii.gz"
	echo "[$i] $src -> $dst"

    if [[ -f "$src" ]]; then
        mv "$src" "$dst"
    else
        echo "Missing: $src"
        break
    fi   
    i=$((i+1))
done

# === Other non-fa ===

echo "start other non-fa maps"
metrics=(MD L1 RD)

for metric in "${metrics[@]}"; do

    mkdir -p ${tbss_dir}/${metric}

    for ptc in "${participants[@]}"; do
      
        src=${wf_dir}/dti/${ptc}/${ptc}_dti_${metric}.nii.gz
        dst=${tbss_dir}/${metric}/FA_${ptc}.nii.gz

        cp ${src} ${dst}
    done

    tbss_non_FA ${metric}

  # Split all_<metric>.nii.gz back to subject files
    fslsplit stats/all_${metric}.nii.gz tmp_${metric}_ -t

    i=0
    for ptc in "${participants[@]}"; do
		idx=$(printf "%04d" "$i")
		src="tmp_${metric}_${idx}.nii.gz"
		dst="FA/${metric}_${ptc}_FA_to_target.nii.gz"
		
		echo "[$i] $src -> $dst"

		if [[ -f "$src" ]]; then
			mv "$src" "$dst"
		else
			echo "Missing: $src"
			break
		fi   
    i=$((i+1))
    done
done

# === TEXT2VEST (reading in design files )===
 cd "${tbss_dir}/${randomise_folder}"
#===1) reading in sorted manner ===
mapfile -t txt_files < <(ls *.txt | sort)

n_txt=${#txt_files[@]}

#checking for even file count 
if (( n_txt % 2 != 0 )); then
    echo "ERROR: Uneven an .txt files (${n_txt})"
    exit 1
fi

n_designs=$(( n_txt / 2 ))

# === 2. initializing as array of pairs===
declare -a designs
for ((i=0; i<n_designs; i++)); do
    designs[$i]=""
done

#=== 3.Text2Vest + Pairing ===
for ((i=0; i<n_txt; i++)); do
    f="${txt_files[$i]}"
    base="${f%.txt}"

  ## Logic: basename[0] == d  then .mat, else .con
    if [[ ${base:0:1} == "d" ]]; then
        out="${base}.mat"
    else
        out="${base}.con"
    fi

   ## Text to VEST
    Text2Vest "${f}" "${out}"
	
    idx=$(( i % n_designs ))

    designs[$idx]="${designs[$idx]} ${out}"
done

#=== 4.validating ===
for ((i=0; i<n_designs; i++)); do
    pair="${designs[$i]}"

    mat_count=$(echo "${pair}" | grep -o '\.mat' | wc -l)
    con_count=$(echo "${pair}" | grep -o '\.con' | wc -l)

    if [[ ${mat_count} -ne 1 || ${con_count} -ne 1 ]]; then
        echo "ERROR: Design $i without valid pairing:"
        echo "       ${pair}"
        exit 1
    fi
done

echo "OK: ${n_designs} Creating Design/Contrast-pair successful"


#===setup_masks===
mask_files=(${tbss_dir}/masks_tbss_2/mask_sub-*)   

for i in "${!designs[@]}"; do
    read mat con <<< ${designs[$i]}
    setup_masks ${con} ${mat} output_con$((i+1)) ${mask_files[@]}
done

# ===Randomise ===
iters=5000
metrics=("FA" "MD" "L1"  "RD" "MO")
cons=("output_con1")
vxl=-8


for metric in "${metrics[@]}"; do
	dat=${tbss_dir}/stats/all_${metric}_skeletonised.nii.gz
	mask=${tbss_dir}/stats/mean_FA_skeleton_mask.nii.gz
	for con in "${cons[@]}"; do
		out_mat=${tbss_dir}/${randomise_folder}/${con}.mat
		out_con=${tbss_dir}/${randomise_folder}/${con}.con
		out_vxf=${tbss_dir}/${randomise_folder}/${con}.nii.gz
		outfile=${tbss_dir}/${randomise_folder}/COVRIATE_RESULT_${metric}_${iters}_${con}

		randomise \
		  -i ${dat} \
		  -o ${outfile} \
		  -d ${out_mat} \
		  -t ${out_con} \
		  -m ${mask} \
		  --vxl=${vxl}\
		  --vxf=${out_vxf}\
		  -n ${iters} \
		  --T2 \
		  -v 5
	done
done
echo "TBSS-Pipeline 2 finished"
