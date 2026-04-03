#!/bin/bash


#paths
path_gen="/mnt/e/Lilith/my_dataset_better_BIDS/derivatives"
twenty_dir="${path_gen}/tbss_no_cut_strict/randomise"  
thirtyseven_dir="${path_gen}/tbss_no_4_20_38/randomise"

#cluster command for twenties (both modalities)
#testing either direction (patient> control and control>patient)

cd ${twenty_dir}

echo "Start 20 clusterizing FA significant"
cluster -i RESULT_FA_5000_output_con1_tfce_corrp_tstat2.nii.gz -t 0.95 -c RESULT_FA_5000_output_con1_tstat2.nii.gz --mm --scalarname="1-p" > FA_stat2_cluster_corrp1.txt
cluster -i RESULT_FA_5000_output_con1_tfce_corrp_tstat1.nii.gz -t 0.95 -c RESULT_FA_5000_output_con1_tstat1.nii.gz --mm --scalarname="1-p" > FA_stat1_cluster_corrp1.txt


echo "Start 20 clusterizing RD significant"
cluster -i RESULT_RD_5000_output_con1_tfce_corrp_tstat2.nii.gz -t 0.95 -c RESULT_RD_5000_output_con1_tstat2.nii.gz --mm --scalarname="1-p" > RD_stat2_cluster_corrp1.txt
cluster -i RESULT_RD_5000_output_con1_tfce_corrp_tstat1.nii.gz -t 0.95 -c RESULT_RD_5000_output_con1_tstat1.nii.gz --mm --scalarname="1-p" > RD_stat1_cluster_corrp1.txt





#cluster command for thirties (both modalities)
#testing either direction (patient> control and control>patient)

cd ${thirtyseven_dir}

echo "Start 37 clusterizing FA significant"
cluster -i RESULT_FA_5000_output_con1_tfce_corrp_tstat2.nii.gz -t 0.95 -c RESULT_FA_5000_output_con1_tstat2.nii.gz --mm --scalarname="1-p" > FA_stat2_cluster_corrp1.txt
cluster -i RESULT_FA_5000_output_con1_tfce_corrp_tstat1.nii.gz -t 0.95 -c RESULT_FA_5000_output_con1_tstat1.nii.gz --mm --scalarname="1-p" > FA_stat1_cluster_corrp1.txt


echo "Start 37 clusterizing RD significant"
cluster -i RESULT_RD_5000_output_con1_tfce_corrp_tstat2.nii.gz -t 0.95 -c RESULT_RD_5000_output_con1_tstat2.nii.gz --mm --scalarname="1-p" > RD_stat2_cluster_corrp1.txt
cluster -i RESULT_RD_5000_output_con1_tfce_corrp_tstat1.nii.gz -t 0.95 -c RESULT_RD_5000_output_con1_tstat1.nii.gz --mm --scalarname="1-p" > RD_stat1_cluster_corrp1.txt
