#!/bin/bash

# declare working directory compliant with temp folder of dwi
cd /mnt/e/lilith/Skripte || { echo "Cannot cd to /mnt/e/lilith/Skripte"; exit 1; }

# Set data root path
path_gen="/mnt/e/lilith/my_dataset_better_BIDS"
participants=($path_gen/sub-*) 

#option C to run script for specific participants
#wanted_subs=("sub-007" "sub-018" "sub-035")

#If no subjects found, exit
 if [ ${#participants[@]} -eq 0 ]; then
   echo -e "\e[31mNo participant directories found!\e[0m"
   exit 1
 fi

 for ptc in "${participants[@]}"; do
   echo -e " \e[33mProcessing: $ptc\e[0m"
   sub_id=$(basename "$ptc")
 
		
	  if [[ ! " ${wanted_subs[@]} " =~ " ${sub_id} " ]]; then
		    echo -e "\e[34mSkipping $sub_id\e[0m"
		    continue
	  fi
	#sub_id="sub-001"  # option B for single subject analysis
	
	# get sub number
    # num=${sub_id#sub-}
    # # option C starting from specific subject
     # if [ "$num" -le 1 ]; then
         # echo -e "\e[34mSkipping $sub_id (ID <= 2)\e[0m"
         # continue
     # fi

	ptc="${path_gen}/${sub_id}"

	# file paths to all raw files
	dwi_AP_file="${ptc}/dwi/${sub_id}_dir-AP_dwi.nii.gz"
	bvec_AP_file="${ptc}/dwi/${sub_id}_dir-AP_dwi.bvec"
	bval_AP_file="${ptc}/dwi/${sub_id}_dir-AP_dwi.bval"
	json_AP_file="${ptc}/dwi/${sub_id}_dir-AP_dwi.json"
	dwi_PA_file="${ptc}/fmap/${sub_id}_dir-PA_epi.nii.gz"
	bvec_PA_file="${ptc}/fmap/${sub_id}_dir-PA_epi.bvec"
	bval_PA_file="${ptc}/fmap/${sub_id}_dir-PA_epi.bval"

	# Check for required input files
	if [ ! -f "$dwi_AP_file" ]; then echo -e "\e[31mERROR: AP DWI file not found\e[0m"; exit 1; fi
	if [ ! -f "$bvec_AP_file" ]; then echo -e "\e[31mERROR: BVEC file for AP not found\e[0m"; exit 1; fi
	if [ ! -f "$bval_AP_file" ]; then echo -e "\e[31mERROR: BVAL file for AP not found\e[0m"; exit 1; fi
	if [ ! -f "$json_AP_file" ]; then echo -e "\e[31mERROR: JSON file for AP not found\e[0m"; exit 1; fi
	if [ ! -f "$dwi_PA_file" ]; then echo -e "\e[31mERROR: PA DWI file not found\e[0m"; exit 1; fi

	# define output directory
	output_dir="${path_gen}/derivatives/preprocessing_Mrtrix/${sub_id}"
	echo -e "\e[33m "$output_dir"\e[0m"
	mkdir -p "$output_dir"

	 # === 1. Convert to .mif ===
	echo -e "\e[33m[1] Converting to .mif\e[0m"
	mrconvert "$dwi_AP_file" "${output_dir}/${sub_id}_AP.mif" -fslgrad "$bvec_AP_file" "$bval_AP_file" -json_import "$json_AP_file" -force
	mrconvert "$dwi_PA_file" "${output_dir}/${sub_id}_PA.mif" -fslgrad "$bvec_PA_file" "$bval_PA_file" -force

	# === 2. Denoise AP ===
	echo -e "\e[33m[2] Denoising AP.mif\e[0m"
	dwidenoise "${output_dir}/${sub_id}_AP.mif" "${output_dir}/${sub_id}_AP_den.mif" -noise "${output_dir}/${sub_id}_AP_noise.mif" -force

	# === 3. Gibbs Ringing Correction AP ===
	echo -e "\e[33m[3] Gibbs ringing correction (AP)\e[0m"
	mrdegibbs "${output_dir}/${sub_id}_AP_den.mif" "${output_dir}/${sub_id}_AP_den_gib.mif" -force

	# === 4. Denoise PA ===
	echo -e "\e[33m[4] Denoising PA.mif\e[0m"
	dwidenoise "${output_dir}/${sub_id}_PA.mif" "${output_dir}/${sub_id}_PA_den.mif" -noise "${output_dir}/${sub_id}_PA_noise.mif" -force

	# === 5. Gibbs Ringing Correction PA ===
	echo -e "\e[33m[5] Gibbs ringing correction (PA)\e[0m"
	mrdegibbs "${output_dir}/${sub_id}_PA_den.mif" "${output_dir}/${sub_id}_PA_den_gib.mif" -force
	
	# === 6. Extract mean b0 images ===
	 echo -e "\e[33m[6] Extracting mean b0 images\e[0m"
	 dwiextract "${output_dir}/${sub_id}_AP_den_gib.mif" - -bzero | mrmath - mean "${output_dir}/${sub_id}_mean_b0_AP.mif" -axis 3 -force
	 dwiextract "${output_dir}/${sub_id}_PA_den_gib.mif" - -bzero | mrmath - mean "${output_dir}/${sub_id}_mean_b0_PA.mif" -axis 3 -force

	# === 7. Merge b0s for topup ===
	echo -e "\e[33m[7] Merging mean b0s for topup\e[0m"
	mrcat "${output_dir}/${sub_id}_mean_b0_AP.mif" "${output_dir}/${sub_id}_mean_b0_PA.mif" "${output_dir}/${sub_id}_both_b0.mif" -axis 3 -force

	# === 8. Eddy + Topup (dwifslpreproc) ===
	echo -e "\e[33m[8] Running dwifslpreproc (eddy + topup)\e[0m"

	#temporary directory
	scratch_dir="/mnt/e/tmp/mrtrix_scratch_${sub_id}"
	mkdir -p "$scratch_dir"

	  (
	  cd "$output_dir" || exit 1

	  dwifslpreproc "${output_dir}/${sub_id}_AP_den_gib.mif" "${output_dir}/${sub_id}_eddy_corrected.mif" \
		-pe_dir AP \
		-rpe_pair \
		-se_epi "${output_dir}/${sub_id}_both_b0.mif" \
		-eddy_options " --slm=linear --repol --resamp=jac --data_is_shelled" \
		-nocleanup \
		-scratch "$scratch_dir" \
		-force
	)
	if [ ! -f "${output_dir}/${sub_id}_eddy_corrected.mif" ]; then
		echo -e "\e[31mERROR: Eddy corrected file not created  skipping subject $sub_id\e[0m"
		continue
	fi

	# === 9. Create brain mask with FSL BET ===
	echo -e "\e[33m[9] Creating brain mask with BET\e[0m"

	# convert eddy_corrected.mif to nifti
	mrconvert "${output_dir}/${sub_id}_eddy_corrected.mif" "${output_dir}/${sub_id}_eddy_corrected.nii.gz" -force

	# execute BET 
	bet "${output_dir}/${sub_id}_eddy_corrected.nii.gz" "${output_dir}/${sub_id}_mask.nii.gz" -m -f 0.3

	# convert mask back
	mrconvert "${output_dir}/${sub_id}_mask_mask.nii.gz" "${output_dir}/${sub_id}_mask.mif" -force


	# === 10. dStripe via Docker ===
	echo -e "\e[33m[10] Running dStripe via Docker\e[0m"
	docker run --rm -v "${output_dir}:/data" maxpietsch/dstripe:1.1 \
	  dwidestripe /data/${sub_id}_AP_den_gib.mif /data/${sub_id}_mask.mif /data/${sub_id}_dstripe_field.mif -device cpu -force

	docker run --rm -v "${output_dir}:/data" mrtrix3/mrtrix3 \
	  mrcalc /data/${sub_id}_eddy_corrected.mif /data/${sub_id}_dstripe_field.mif -mult /data/${sub_id}_destriped.mif

	if [ ! -f "${output_dir}/${sub_id}_destriped.mif" ]; then
	  echo -e "\e[31mERROR: Destriped file not created! Check Docker mrcalc step.\e[0m"
	  exit 1
	fi

	#=== 11. Bias Field Correction === 
	echo -e "\e[33m[11] Running Bias Field Correction\e[0m"
 
	(
	  cd "$output_dir" || exit 1
	  dwibiascorrect ants "${output_dir}/${sub_id}_destriped.mif" "${output_dir}/${sub_id}_bias_corrected.mif" \
		-mask "${output_dir}/${sub_id}_mask.mif" -force
	)
	if [ ! -f "${output_dir}/${sub_id}_bias_corrected.mif" ]; then
	  echo -e "\e[31mERROR: Bias corrected file not created  skipping subject $sub_id\e[0m"
	  continue
	fi

	mrconvert "${output_dir}/${sub_id}_bias_corrected.mif" "${output_dir}/${sub_id}_dwi_bias_corrected.nii.gz" \
		 -export_grad_fsl "${output_dir}/${sub_id}_bvecs" "${output_dir}/${sub_id}_bvals" -force 


	echo -e "\e[32m Finished preprocessing for $sub_id\e[0m"
done

echo -e "\e[32m Preprocessing completed for all subjects\e[0m"
