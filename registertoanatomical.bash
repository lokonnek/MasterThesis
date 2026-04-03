#!/bin/bash

# Paths
path_gen="/mnt/e/Lilith/my_dataset_better_BIDS"

# Get all subjects in the preprocessing folder
participants=($path_gen/derivatives/preprocessing_Mrtrix/sub-*)

# Exit if no subjects found
if [ ${#participants[@]} -eq 0 ]; then
  echo -e "\e[31mNo participant directories found!\e[0m"
  exit 1
fi

# Loop over each subject
for ptc in "${participants[@]}"; do
  echo -e "\e[34mProcessing: $ptc\e[0m"

  # Extract subject ID
  sub_id=$(basename "$ptc")

  # Define file paths
  dwi_img="$path_gen/derivatives/preprocessing_Mrtrix/${sub_id}/${sub_id}_dwi_bias_corrected.nii.gz"
  bval_AP_file="$path_gen/${sub_id}/dwi/${sub_id}_dir-AP_dwi.bval"
  t1_img="$path_gen/${sub_id}/anat/${sub_id}_acq-mprageDefaced_T1w.nii.gz"
  flirt_mat="$path_gen/derivatives/register/${sub_id}/${sub_id}_dwi_to_T1.mat"
  flirt_mat_inv="$path_gen/derivatives/register/${sub_id}/${sub_id}_T1_to_dwi.mat"
  flirt_out="$path_gen/derivatives/register/${sub_id}/${sub_id}_dwi_registered_to_T1.nii.gz"
  
  # Check if essential files exist
  if [ ! -f "$dwi_img" ]; then
    echo -e "\e[31mFA image not found for $sub_id\e[0m"
    continue
  fi

  if [ ! -f "$t1_img" ]; then
    echo -e "\e[31mT1 image not found for $sub_id\e[0m"
    continue
  fi
  
  if [ ! -f "$bval_AP_file" ]; then
    echo -e "\e[31mBVAL file not found for $sub_id\e[0m"
    continue
  fi

   # Create output directory if it doesn't exist
  mkdir -p "$path_gen/derivatives/register/${sub_id}"
  
  #creating mean b0 of dwi 
  fslselectvols -i "$dwi_img" -o "$path_gen/derivatives/register/${sub_id}/${sub_id}_b0_all.nii.gz" --vols=$(awk '{for(i=1;i<=NF;i++) if ($i<50) printf "%d,",i-1}' "$bval_AP_file" | sed 's/,$//')
  fslmaths "$path_gen/derivatives/register/${sub_id}/${sub_id}_b0_all.nii.gz" -Tmean "$path_gen/derivatives/register/${sub_id}/${sub_id}_b0_mean.nii.gz"

  # Run FLIRT registration: DWI mean b0 to T1 (reference)
  echo -e "\e[33mRunning FLIRT registration for $sub_id\e[0m"
  flirt -in "$path_gen/derivatives/register/${sub_id}/${sub_id}_b0_mean.nii.gz" -ref "$t1_img" -out "$flirt_out" -omat "$flirt_mat" -dof 6 -cost mutualinfo 

  if [ $? -ne 0 ]; then
    echo -e "\e[31mFLIRT failed for $sub_id\e[0m"
    continue
  fi

  # Invert the transformation matrix
  convert_xfm -inverse -omat "$flirt_mat_inv" "$flirt_mat"

  if [ $? -ne 0 ]; then
    echo -e "\e[31mMatrix inversion failed for $sub_id\e[0m"
    continue
  fi

  echo -e "\e[32mFLIRT and matrix inversion completed for $sub_id\e[0m"

done

echo -e "\e[32mFLIRT registration completed for all subjects.\e[0m"
