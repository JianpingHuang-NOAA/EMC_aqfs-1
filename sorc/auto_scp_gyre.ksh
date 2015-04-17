#!/bin/ksh

set -ax
export fdir=/naqfc/save/${USER}  
export usrdir=/naqfc/save/${USER}
export model_ver=v4.6.3
export envir=para
export fdir=${fdir:-}
export fdir=${fdir}/nw${envir}/cmaq.${model_ver}/sorc

#for src in prep_nmmb premaq_nmmb_v46 fcst_nmmb_v46 cmaq2grib post_maxi_CHA rdgrbwt_aot_CHA 
for src in snowdust fengsha fengsha_merge emmod emutil emqa smkinven point temporal grdmat spcmat smkmerge 
do
scp -rp aqm_${src}.fd  gyre:/naqfc/save/Jianping.Huang/nwpara/cmaq.v4.6.3/sorc
done