#!/bin/bash

#path
path_gen="/mnt/e/Lilith/my_dataset_better_BIDS"

# get all subjects
participants=($path_gen/sub-*)

# Exit if no subjects found
if [ ${#participants[@]} -eq 0 ]; then
  echo -e "\e[31mKNo participant directories found!\e[0m"
  exit 1
fi

# Loop over each subject
for ptc in "${participants[@]}"; do
  echo -e "\e[34mProcessing: $ptc\e[0m"

  # Extract subject ID
  sub_id=$(basename "$ptc")
  
  # Define file paths
  lesion_t1="$path_gen/${sub_id}/derivatives/${sub_id}_desc-lesion_mask.nii.gz"
  dwi_img="$path_gen/derivatives/register/${sub_id}/${sub_id}_b0_mean.nii.gz"
  mat_inv="$path_gen/derivatives/register/${sub_id}/${sub_id}_T1_to_dwi.mat"
  
  # Check if essential files exist
  if [ ! -f "$mat_inv" ]; then
    echo -e "\e[31mMissing inverse Matrix for $sub_id\e[0m"
    continue
  fi
  if [ ! -f "$dwi_img" ]; then
    echo -e "\e[31mDWI image not found for $sub_id\e[0m"
    continue
  fi
  
  if [ ! -f "$lesion_t1" ]; then
    echo -e "\e[33m$sub_id is control\e[0m"
  else 
    echo -e "\e[33m$sub_id is patient\e[0m"
  fi
  
  #make directory if it doesn't exist
  mkdir -p "$path_gen/derivatives/lesion_masks/${sub_id}"

  # for patients
  if [ -f "$lesion_t1" ]; then
    echo -e "\e[33mTransforming mask to diffusion space\e[0m"

    flirt -in "$lesion_t1" \
          -ref "$dwi_img" \
          -out "$path_gen/derivatives/lesion_masks/${sub_id}/${sub_id}_lesion_in_dwi.nii.gz" \
          -applyxfm -init "$mat_inv" \
          -interp nearestneighbour

    if [ $? -eq 0 ]; then
      echo -e "\e[32mlesion mask transformed for $sub_id\e[0m"
    else
      echo -e "\e[31mError in transforming $sub_id\e[0m"
      continue
    fi

  # no lesion mask found
  else
    echo -e "\e[33mEmpty mask for $sub_id\e[0m"
    fslmaths "$dwi_img" -mul 0 "$path_gen/derivatives/lesion_masks/${sub_id}/${sub_id}_lesion_in_dwi.nii.gz"
  fi
done

echo -e "\e[32mAll masks processed\e[0m"
