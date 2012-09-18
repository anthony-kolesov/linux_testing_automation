#!/bin/csh
source /u/vijayb/.cshrc
module load grd
echo "Config : $config"
set workarea="${WORKSPACE}/${BUILD_NUMBER}/"
echo "Running command : qsub -cwd -V -P 'bnormal' -N 'linuxbuild' -o ${workarea}/output.log -e ${workarea}/error.log -l os_distribution=redhat,os_bit=64 ${workarea}/automated_scripts/linux_build.pl -config $config"
cd "$workarea/automated_scripts/"
echo "$workarea/automated_scripts/"
echo "working under "
pwd
ls ./lib
qsub -cwd -V -P 'bnormal' -N 'linuxbuild' -o ${workarea}/output.log -e ${workarea}/error.log -l os_distribution=redhat,os_bit=64 ${workarea}/automated_scripts/linux/test.pl -config $config -configfile $configfile -testconfig $testconfig
while (1)
    if ( -e "${workarea}/alldone" ) then
        echo "Completed successfully"
	exit 0
        break
    else if ( -e "${workarea}/failed" ) then
	exit 1
    else
        sleep 100
    endif
end

