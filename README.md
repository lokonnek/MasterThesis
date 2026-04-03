# MasterThesis
This repository contains the .bash scripts to recapulate the TBSS results rendered during the Master's thesis of Lilith Okonnek

The included scripts account for a subset of performed processing scripts

1) Preprocessing_Mrtrix: takes raw files, performs preprocessing____
2) registertoanatomical: preprares transformation matrices between anatomical and diffusion space
3) transform_lesion: apply transformation matrix on lesion mask to acquire lesion mask in diffusion space
4) tbss_part1: perform tbss specific preprocessing to render FA skeleton for further processing
5) postreg_2: altered FSL script to incorporate lesion masks when creating the FA skeleton  (called upon by tbss_part1)
6) tbss_part2: perform TBSS on non FA statistics and call randomise
7) cluster_for_all: perform cluster command on significant output of tbss_part2

More details can be found in the comments of the individual scripts.
