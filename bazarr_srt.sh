#!/bin/bash

#how to use it,
#define path, filenames, language of srt.

#then add post processing command to bazarr
# /config/bazarr_srt.sh "{{episode}}" "{{episode_name}}" "{{subtitles_language_code3}}" "{{subtitles}}" 2>&1

[ $# -lt 4 ] && echo "Usage: bazarr_srt.sh  \"{{episode}}\" \"{{episode_name}}\" \"{{subtitles_language_code3}}\" \"{{subtitles}}\" 2>&1" && exit 1

#directory=$1  # /path/of/movie/
moviefullpath=$1  # /path/of/movie/moviefile.mp4
filename=$2    # moviefile
lang_code=$3   # eng
srt_file=$4    # /path/of/movie/moviefile.en.srt
#my movie disk was on smb share, i had to copy the file in to a backup folder to process it with ffmpeg, you can use directory variable if you are using local storage.
backupfolder="/home/bazarr_temp"

# check the files first

if [[ ! -f "/usr/bin/ffmpeg" ]]; then
    echo "ffmpeg not found in PATH, downloading..."
    wget -q "https://bitbucket.org/emre1393/xtreamui_mirror/downloads/ffmpeg_amd64-static_non_xc" -O /usr/bin/ffmpeg
    chmod +x /usr/bin/ffmpeg
    echo "ffmpeg downloaded and made executable"
fi

if [[ ! -f "/usr/bin/ffprobe" ]]; then
    echo "ffprobe not found in PATH, downloading..."
    wget -q "https://bitbucket.org/emre1393/xtreamui_mirror/downloads/ffprobe_amd64-static_non_xc" -O /usr/bin/ffprobe
    chmod +x /usr/bin/ffprobe
    echo "ffprobe downloaded and made executable"
fi
if [[ ! -f "$moviefullpath" ]]; then
    echo "$moviefullpath does not exist"; 
    exit;
fi
if [[ ! -f "$srt_file" ]]; then
    echo "$srt_file does not exist"; 
    exit;
fi
if [[ ! -d "$backupfolder" ]]; then
    /bin/mkdir -p "$backupfolder"  
fi

# copy the file to temp location with new names, get duration time, count subtitles
function renamethemovie {
    if [[ -f "$moviefullpath" ]]; then
        if [[ $moviefullpath == *.mp4 ]]; then 
            movie_ext="mp4";
        elif [[ $moviefullpath == *.mkv ]]; then
            movie_ext="mkv";
        else 
            echo ""$moviefullpath" is not an mp4 or an mkv"
            exit;
        fi
        moviein="$backupfolder/$filename.in.$movie_ext" 
        movieout="$backupfolder/$filename.out.$movie_ext"
        if [[ ! -f "$moviein" ]]; then
        /bin/cp "$moviefullpath" "$moviein";
        fi
        #infileduration=$(/usr/bin/ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$moviein" | awk -F\. '{print $1}')
        subtitle_count=$(/usr/bin/ffprobe -v error -show_entries stream=codec_type "$moviein" | grep "codec_type=subtitle" | wc -w)
        #echo "$subtitle_count"
    else
        echo ""$moviefullpath" does not exit -log from rename the movie function"
        exit;
    fi
}

#add subtitles to mp4 file #-map 0:v -map 0:a? -map 0:s? -map_metadata:g 0:g -c:v copy -c:a copy -c:s mov_text 
function mp4withsrt {
    if [[ -f "$moviein" ]]; then
        /usr/bin/ffmpeg -y -nostdin -loglevel error -i "$moviein" -f srt -i "$srt_file" -map 0 -c copy -c:s mov_text -map_metadata 0 -map 1 -c:s:$subtitle_count mov_text -metadata:s:s:$subtitle_count language="$lang_code" "$movieout";
        #outfileduration=$(/usr/bin/ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$movieout" | awk -F\. '{print $1}')
    else
        echo ""$moviein" does not exit -log from mp4 with srt function"
        exit;
    fi
}

#add subtitles to mkv file
function mkvwithsrt {
    if [[ -f "$moviein" ]]; then
        /usr/bin/ffmpeg -y -nostdin -loglevel error -i "$moviein" -f srt -i "$srt_file" -map 0 -c copy -c:s srt -map_metadata 0 -map 1 -c:s:$subtitle_count srt -metadata:s:s:$subtitle_count language="$lang_code" "$movieout";
        #outfileduration=$(/usr/bin/ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$movieout" | awk -F\. '{print $1}')
    else
        echo ""$moviein" does not exit -log from mkv with srt function"
        exit;
    fi
}

#copy out file to original location, delete temp files.
function removebakfile {
        # Calculate file sizes
        original_size=$(stat -c%s "$moviein")
        new_size=$(stat -c%s "$movieout")

        # Check if the file sizes are within a specified range (e.g., 5MB)
        size_difference=$((new_size - original_size))
        size_threshold=5000000  # 5MB

        

    if [[ -f "$movieout" ]]; then
        if [ $size_difference -le $size_threshold ] && [ $size_difference -ge -$size_threshold ]; then

    #if [[ -f "$movieout" ]]; then
        #if [[ "$infileduration" = "$outfileduration" ]]; then
            /usr/bin/cp "$movieout" "$moviefullpath";
            /usr/bin/rm "$moviein";
            /usr/bin/rm "$movieout";
            /usr/bin/rm "$srt_file";
		    echo "Success!! "$movieout" must be copied to original location. -log from remove bak file function"
	    else
            /usr/bin/rm "$moviein";
            /usr/bin/rm "$movieout";
            echo ""$movieout" ("$outfileduration") does not match with "$moviein"  ("$infileduration") -log from remove bak file function"
            exit;
        fi
    else
        /usr/bin/rm "$moviein";
        echo ""$movieout" does not exit -log from remove bak file function"
        exit;
    fi
}

# decide to file is mp4 or mkv, then run the script
function mergethesrt {
    if [[ $moviefullpath == *.mp4 ]]; then 
        renamethemovie
        mp4withsrt
        removebakfile
    elif [[ $moviefullpath == *.mkv ]]; then 
        renamethemovie
        mkvwithsrt
        removebakfile
    else
        echo "$moviefullpath is not an mp4 or an mkv"
        exit;
    fi
}

mergethesrt
exit $?;