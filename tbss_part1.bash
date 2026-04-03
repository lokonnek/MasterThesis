#!/usr/bin/env bash

#Paths
path_gen="/mnt/e/Lilith/my_dataset_better_BIDS"  
WF_DIR="${path_gen}/derivatives"
TBSS_DIR="${WF_DIR}/tbss_no_bad_cut"

# List of subject
participants=($(basename -a $path_gen/derivatives/dti/sub-*)) 
PATIENTS=("sub-001" "sub-002" "sub-003" "sub-004" "sub-005" "sub-008" "sub-016" "sub-017" "sub-019" "sub-020" "sub-021" "sub-022" "sub-026" "sub-035" "sub-036" "sub-040" "sub-047" "sub-051" "sub-052" "sub-054")  #######hier patientn 


#####Case of analysis in reduced sample
# PATIENTS=("sub-001" "sub-005" "sub-017" "sub-019" "sub-021" "sub-035" "sub-040" "sub-051" "sub-052")  #######hier patientn 
# EXCLUDE=("sub-002" "sub-003" "sub-007" "sub-008" "sub-014" "sub-016" "sub-018" "sub-022" "sub-026" "sub-030" "sub-031" "sub-033" "sub-036" "sub-043" "sub-044" "sub-047" "sub-054" "sub-004" "sub-020" "sub-038")

# participants=()
# for sub in "${WF_DIR}/dti"/sub-*; do
    # ptc=$(basename "$sub")
    # [[  ${EXCLUDE[*]}  =~ ${ptc} ]] && continue  
    # participants+=("$ptc")  
# done



# Exit if no subjects found
if [ ${#participants[@]} -eq 0 ]; then
  echo -e "\e[31mNo participant directories found!\e[0m"
  exit 1
fi

mkdir -p "${TBSS_DIR}"

# --- FA-files ---
echo "Copying FA-Files..."
for ptc in "${participants[@]}"; do
    src="${WF_DIR}/dti/${ptc}/${ptc}_dti_FA.nii.gz"
	 dest="${TBSS_DIR}/FA_${ptc}.nii.gz"
	if [ -f "$src" ]; then
		cp "$src" "$dest"
	else
    echo -e "\e[33mWarning: FA file not found for $ptc, skipping.\e[0m"
fi
done

# === TBSS Step 1 ===
cd "${TBSS_DIR}" || exit
echo "Starting TBSS process 1..."
tbss_1_preproc -i *.nii.gz

# === preparing masks ===
mkdir -p "${TBSS_DIR}/masks"

for ptc in "${participants[@]}"; do
    lesionmask="${WF_DIR}/lesion_masks/${ptc}/${ptc}_lesion_in_dwi.nii.gz"
    lesionmask_out="${TBSS_DIR}/masks/FA_${ptc}.nii.gz"
    if [ -f "$lesionmask" ]; then
		cp "$lesionmask" "$lesionmask_out"
	else
		echo -e "\e[33mWarning: lesion mask not found for $ptc, skipping.\e[0m"
		continue
	fi

    # for patients: create inverted masks
    if [[ " ${PATIENTS[@]} " =~ " ${ptc} " ]]; then
        invmask="${TBSS_DIR}/masks/FA_${ptc}_mask.nii.gz"
        echo "Creating inverted mask for ${ptc}..."
        fslmaths "$lesionmask_out" -binv "$invmask"
    fi
done

# === TBSS processes 2-4 ===
echo "Starting TBSS process 2..."
# specification to account for lesions
tbss_2_reg_withmask.sh -T

echo "Starting TBSS process 3..."
tbss_3_postreg -S

echo "Starting TBSS process 4..."
#threshold set to 0.2
tbss_4_prestats 0.2

echo "TBSS-Pipeline finished!"
