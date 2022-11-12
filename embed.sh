#!/usr/bin/env bash

# Command for quickly and easily embedding a thumbnail with `ffmpeg`

show_help_message () {
    cat <<- _help-message
		Usage: ${0##*/} [input.mp4] [input{.png|.jpg|.jpeg|.webp}] output.mp4
		
		A utility for quickly embedding a thumbnail into a video file using ffmpeg

		Always pass three arguments to ${0##*/}. Two of them should be .mp4 files, and one
		should be an image file in one of the formats listed above. The order of the .mp4
		files MATTERS. The first mp4 file is the input and the second is the output file.
		_help-message
};

fatal () {
    printf "fatal error: $0: $*\n"
	show_help_message
    exit 1
};

# The only time there can be fewer than 3 arguments is when the user needs help
[[ $# < 3 ]] && \
    if [[ ( $1 = '-h' || $1 = '--help' ) ]]; then
        show_help_message
        exit 0
    else
        fatal not enough arguments
    fi

[[ $# > 3 ]] && fatal too many arguments

# it doesn't matter which order the .mp4 file and the image file are passed
# the video is always the video and the image is always the thumbnail

# note that the order of .mp4 files matters; the first is the input and the second is the output

input_video=
for i in $*; do
    case ${i##*.} in
		('-h'|'--help') show_help_message; exit 0;;
        (mp4) if [[ $input_video = "" ]]; then input_video=$i; else output_video=$i; fi;;
        (png|jpg|jpeg|webp) thumbnail=$i;;
        (*) fatal unrecognized argument: $i;;
    esac
done


# Make sure input video exists
if [[ ! -e $input_video ]]; then 
    printf "file $input_video does not exist!"
    exit 1
fi

# Make sure thumbnail file exists
if [[ ! -e $thumbnail ]]; then
    printf "file $thumbnail does not exist!"
    exit 1
fi

# Check whether overwrite confirmation will be necessary
if [[ -e $output_video ]]; then
    printf "Target file: $output_video already exists. Overwrite? (y/N) "
    read answer
    case answer in
        (y|Y|yes|Yes) printf "\nOverwriting...\n";;
        (n|N|no|No|NO) printf "\nAborting...\n"; exit 0;;
    esac
else
    printf "Target destination: $output_video\n"
    printf "Input video: $input_video\n"
    printf "Thumbnail: $thumbnail\n"
fi

# Finally -- embed the thumbnail in the video!
ffmpeg -hide_banner \
    -i $input_video -i $thumbnail \
    -map 0 -map 1 \
    -c copy -c:v:1 ${thumbnail##*.} \
    -disposition:v:1 attached_pic \
    $output_video

# Exit message(s)
if [[ $? = 0 ]]; then
    printf "\nOperation Complete! Generated file: $output_video"
elif [[ $? = 1 ]]; then
    printf "\nUnable to process video"; exit 1
else
    printf "\nUnknown exit code from \`ffmpeg\`"; exit 1
fi

exit 0
