#!/bin/bash

# Set the path to your data directory
path_gen="/mnt/e/Lilith/my_dataset_better_BIDS"

# Store all existing participant directories in an array
participants=($path_gen/derivatives/preprocessing_Mrtrix/sub-*)  #  loop over participants
#participants=($path_gen/derivatives/preprocessing/sub-001)  # trial run for one subject only

# If no participants are found, exit the script
if [ ${#participants[@]} -eq 0 ]; then
  echo -e "\e[31mNo participant directories found!\e[0m"
  exit 1
fi

# Loop through each subject directory
for ptc in "${participants[@]}"; do
  echo -e " \e[33mProcessing: $ptc\e[0m"
  
  # Extract the subject ID
  sub_id=$(basename "$ptc")
  #sub_id="sub-001"
  

  #file paths
  dwi_file="$path_gen/derivatives/preprocessing_Mrtrix/${sub_id}/${sub_id}_dwi_bias_corrected.nii.gz"
  bvec_file="$path_gen/${sub_id}/dwi/${sub_id}_dir-AP_dwi.bvec"
  bval_file="$path_gen/${sub_id}/dwi/${sub_id}_dir-AP_dwi.bval"
  mask_file="$path_gen/derivatives/preprocessing_Mrtrix/${sub_id}/${sub_id}_mask_mask.nii.gz"
  output_dir="$path_gen/derivatives/dti/${sub_id}"
  
  # Check if essential files exist
  if [ ! -f "$dwi_file" ]; then
    echo -e "\e[31mERROR: DWI file not found for $sub_id\e[0m"
    continue
  fi
  if [ ! -f "$bvec_file" ]; then
    echo -e "\e[31mERROR: BVEC file not found for $sub_id\e[0m"
    continue
  fi
  if [ ! -f "$bval_file" ]; then
    echo -e "\e[31mERROR: BVAL file not found for $sub_id\e[0m"
    continue
  fi
  if [ ! -f "$mask_file" ]; then
    echo -e "\e[31mERROR: Brain mask file not found for $sub_id\e[0m"
    continue
  fi
  
  # Create an output directory
  mkdir -p $output_dir
 
  
  # Run DTI fitting
  echo -e "\e[33mRunning DTI fit for $sub_id\e[0m"
  dtifit -k $dwi_file -o $output_dir/${sub_id}_dti -m $mask_file -r $bvec_file -b $bval_file
  
  if [ $? -ne 0 ]; then
    echo -e "\e[31mERROR: DTI fit failed for $sub_id\e[0m"
    continue
  fi
  
  echo -e "\e[32mDTI fit completed successfully for $sub_id\e[0m"

done

echo -e "\e[32mDTI fitting completed for all subjects\e[0m."
