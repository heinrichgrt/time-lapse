#!/bin/bash

set -e

WORKINGDIR=./source
EXIF=/opt/homebrew/bin/exif
DATE=/opt/homebrew/bin/gdate

FFMPEG=/opt/homebrew/bin/ffmpeg
MAGICK=/opt/homebrew/bin/magick
# defaults
FRAMERATE=60
VIDEOSCALE=320

# some vars
last_epoch=0
last_frame=0
first_frame=0

get_epoch_of_file() {
    image_name=$1
    image_name=${image_name:?"usage $0 [image_file_name]"}
    date_in=$($EXIF $image_name | grep "Date and Time (Origi" | cut -f2 -d'|' | tr ' ' ':' | awk -F":" '{print $1"-"$2"-"$3,$4":"$5":"$6}')
    echo $($DATE +%s -d "$date_in")
}

get_duration_per_second() {
    start=$1
    end=$2
    ((total = $end - $start))

    weight=$(echo "$DURATION / $total" | bc -l)
    echo $weight
}

## getopts
while getopts "s:d:f:o:" opts; do
    case $opts in
    s) SOURCE=$OPTARG ;;
    d) DURATION=$OPTARG ;;
    f) FRAMERATE=$OPTARG ;;
    vs) VIDEOSCALE=$OPTARG ;;
    o) OUTPUTDIR=$OPTARG ;;
    esac
done

make_sequence() {
    image=$1
    duration=$2
    tmp=$(basename $image)
    outfile=${tmp%.*}
    # -pix_fmt yuvj422p ffmpeg -loop 1 -t   -r 60 -i ./short/IMG_5775.jpg  -c:v libx265 -pix_fmt yuvj422p -vf scale=-1:1080  output.mp4
    #   $FFMPEG -loop 1 -t $duration -r $FRAMERATE -i $image -c:v libx265 -pix_fmt yuvj422p -vf scale=-1:${VIDEOSCALE} ${OUTPUTDIR}/${outfile}.mp4
    
    $FFMPEG  -t $duration -loop 1 -r $FRAMERATE -i $image ${OUTPUTDIR}/${outfile}.mp4
}
# is_this_an_image(){
#     $MAGICK identify $1
# }
analyze_files() {
    for image in $(ls -r ${SOURCE}/*); do
        # is this a valid image file?get_duration_per_second $first_frame $last_frame
        $MAGICK identify $image || continue
        epoch=$(get_epoch_of_file $image)
        duration=$(expr $last_epoch - $epoch)ff
        if [ $last_epoch == 0 ]; then
            echo $image $epoch END
            last_frame=$epoch
        else
            echo $image $epoch $duration
        fi
        last_epoch=$epoch
    done
    first_frame=$epoch
    echo "first: $first_frame last: $last_frame"
}
write_files() {
    # almost the same as analyze_files, since compared to video rendering this costs nothing
    for image in $(ls -r ${SOURCE}/*); do
        $MAGICK identify $image || continue
        epoch=$(get_epoch_of_file $image)
        duration=$(expr $last_epoch - $epoch)
        if [ $last_epoch == 0 ]; then
            # last frame give it a second
            make_sequence $image 1
            echo "wieder reintun!"
        else
            footage_length=$(echo $duration \* $weight_per_second | bc -l | awk '{printf "%f", $0}')
            #ffmpeg seems to have a bug when the duration is less then one frame
            ctrlval=$(echo " $footage_length * $FRAMERATE " | bc -l | awk '{printf "%.0f\n", $0}' )
            if [ $ctrlval  -le 1 ]; then
               make_sequence $image $minimum_sequence
            else
               make_sequence $image $footage_length
            fi
        fi
        last_epoch=$epoch
    done




}
concat_footage() {
    rm filelist || true
    touch filelist
    for flix in $(ls ${OUTPUTDIR}/*.mp4); do
        echo "file '$flix'" >>filelist
    done
    ffmpeg -f concat -safe 0 -i ./filelist -c copy ${OUTPUTDIR}/fertig.mp4

}

format_time() {
    weighted_time=$1

}

analyze_files
minimum_sequence=$(echo "1 / $FRAMERATE" | bc -l | awk '{printf "%f", $0}')
weight_per_second=$(get_duration_per_second $first_frame $last_frame)
last_epoch=0
write_files
concat_footage
echo $DURATION
echo $first_frame
echo $last_frame
echo $weight_per_second
echo "hä?"