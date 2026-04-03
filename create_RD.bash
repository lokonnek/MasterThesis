#!/usr/bin/env bash

# Basisverzeichnis
BASE_DIR="/mnt/e/Lilith/my_dataset_better_BIDS/derivatives/dti"

echo "Starting RD-calculation"

for subj_dir in "${BASE_DIR}"/sub-*; do
    # nur Verzeichnisse
    [ -d "$subj_dir" ] || continue

    subj=$(basename "$subj_dir")

    L2="${subj_dir}/${subj}_dti_L2.nii.gz"
    L3="${subj_dir}/${subj}_dti_L3.nii.gz"
    RD="${subj_dir}/${subj}_dti_RD.nii.gz"

    if [[ -f "$L2" && -f "$L3" ]]; then
        echo "Creating RD for ${subj}"

        fslmaths "$L2" -add "$L3" -div 2 "$RD"
    else
        echo "Skip ${subj} (L2 or L3 missing)"
    fi
done

echo "RD-calculations finished."
