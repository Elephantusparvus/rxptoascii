#!/bin/bash
#
# This script iterates through all ScanPos folders of a
# RIEGL-Laserscan project and converts one scan per
# pose(the last recorded) to ascii-format using slam6d
# with the riegllib.
# Each scan is saved to the defined folder with the following
# format: scan[PosNr].txt ($PosNr is the three digit number
# of the ScanPos)
#
# Example:
# ./rxptoascii.sh
# /path/to/rieglproj/
# /path/to/slam6d
# /path/to/rxpdir
# /path/to/asciidir
#
# Example for scanpos001:
# /path/to/riegl/proj/SCANS/ScanPos001/SINGLESCANS/160624_120918.rxp
#
# produces:
# /path/to/rxpdir/scan001.rxp
# and
# /path/to/asciidir/scan001.3d

# enable extended globbing. necessary for determining the correct rxp-scans
shopt -s extglob

help="./rxptoascii /path/to/rieglproj/ /path/to/slam6d /path/to/renamedrxpdir /path/to/asciidir"

print_help() {
    echo ""
    echo "Usage:"
    echo "$help"
    exit
}

project_path=$1
slam6d=$2
rxp_dir=$3
scans_txt_path=$4

if [ -z $project_path ]; then
    echo "Please specify the path to the project (root directory)"
    print_help
fi

if [ -z $slam6d ]; then
    echo "Please specify the path to slam6D (root directory)"
    print_help
fi

if [ -z $rxp_dir ]; then
    echo "No directory for renamed rxp"
    print_help
fi

if [ -z $scans_txt_path ]; then
    echo "No directory for converted scans"
    print_help
fi

if ! [ -a "$scans_txt_path" ]; then
    mkdir -p $scans_txt_path
fi

if ! [ -d "$scans_txt_path" ]; then
    echo "$scans_txt_path is existing but no directory. Please enter correct destination folder"
    print_help
fi

if ! [ -a "$rxp_dir" ]; then
    mkdir -p $rxp_dir
fi

if ! [ -d "$rxp_dir" ]; then
    echo "$rxp_dir is existing but no directory. Please enter correct destination folder"
    print_help
fi

if ! [ -a "$project_path" ]; then
    echo "$project_path is not existing. Please enter correct project path."
    print_help
fi

if ! [ -d "$project_path" ]; then
    echo "$project_path is existing but no directory. Please enter correct project path."
    print_help
fi

if ! [ -a "$slam6d/bin/slam6D" ]; then
    echo "Could not find a bin directory for slam6D in $slam6d. Please enter the correct slam6d path(root directory)."
    print_help
fi

if ! [ -d "$slam6d" ]; then
    echo "$slam6d is existing but no directory. Please enter correct slam6d path."
    print_help
fi



# Determine how many scanposes are in this project.
# Folders must have the name scheme ScanPosXXX
scanposcount=0
for folder in $project_path/SCANS/ScanPos*;
do
    if [ -d "$folder" ]; then
        scanposcount=$(($scanposcount+1))
    fi
done

echo $scanposcount

#iterate over all scanposes
for i in `seq 1 $scanposcount`;
do
    # adding "0" or "00" prefix, because it has to be three digits numer(folder/file structure)
    if [ "$i" -lt "10" ]; then
        c="00$i"
    else
        if [ "$i" -lt "100" ]; then
            c="0$i"
        else
            c="$i"
        fi
    fi

    # the path where the actual scans of this iteration are located. Change to this path

    path="$project_path/SCANS/ScanPos$c/SINGLESCANS/"
    if [ -a "$path" ]; then

        cd $path

        # get all .rxp-files(these are the scans of this position)
        # exclude monitor files.
        count=-1
        for j in !(*["m"]["o"]["n"]).rxp; do
            count=$(($count+1))
            echo $j
            names[$count]=$j
        done

        latestscan=${names[0]}
        if [ -a "$latestscan" ]; then

            # if there is more than one scan, use the last one
            # luckily all the filenames of the scans have the same structure
            # simply compare their timestamps in the filename
            # (actually the whole filename is a timestamp (YYMMDD_hhmmss.rxp),
            # but the date is ignored)
            if [ "$count" -gt "0" ]; then
                timestamp=${latestscan:7:6}
                for k in `seq 1 $count`; do
                    tmp=${names[$k]}
                    echo $tmp
                    tmp=${tmp:7:6}
                    echo $tmp
                    if [ "$tmp" -gt "$timestamp" ]; then
                        latestscan=${names[$k]}
                        timestamp=$tmp
                    fi
                done
            fi

            echo "Copying $latestscan to scan$c.rxp"

            cp $latestscan scan$c.rxp

            echo "Creating dummypose: scan$c.pose"
            touch scan$c.pose
            echo -e "0 0 0\n0 0 0" > scan$c.pose


            echo "Converting scan$c.rxp"
            $slam6d/bin/slam6D -f rxp -s$i -e$i --exportAllPoints $path

            echo "Moving converted scans to destination directory ($path/points.pts to $scans_txt_path/scan$c.3d)"

            mv points.pts $scans_txt_path/scan$c.3d


            mv scan$c.rxp $rxp_dir
            mv scan$c.pose $rxp_dir
            mv scan$c.frames $rxp_dir

        else
            echo "There were no rxp-scans in $project_path/ScanPos$c"
        fi
        else
            echo "$project_path/ScanPos$c/SINGLESCANS does not exist"
    fi
done
