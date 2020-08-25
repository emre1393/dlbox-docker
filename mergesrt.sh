#!/bin/bash

#how to use it,
#define path, filenames, language of srt.

#then add post processing command to bazarr
# /config/mergesrt.sh "{{directory}}" "{{episode}}" "{{episode_name}}" "{{subtitles_language_code3}}" "{{subtitles}}" 2>&1

[ $# -lt 5 ] && echo "Usage: mergesrt.sh \"{{directory}}\" \"{{episode}}\" \"{{episode_name}}\" \"{{subtitles_language_code3}}\" \"{{subtitles}}\"" && exit 1

directory=$1  # /path/of/movie/
moviefullpath=$2  # /path/of/movie/moviefile.mp4
filename=$3    # moviefile
lang_code=$4   # eng
srt_file=$5    # /path/of/movie/moviefile.en.srt
#my movie disk was on smb share, i had to copy the file in to a backup folder to process it with ffmpeg, you can use directory variable if you are using local storage.
backupfolder="/config/bak"

# check the files first
if [[ ! -f "/usr/bin/ffmpeg" ]]; then
    echo "ffmpeg does not exist"; 
    exit;
fi
if [[ ! -f "/usr/bin/ffprobe" ]]; then
    echo "ffprobe does not exist"; 
    exit;
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
        infileduration=$(/usr/bin/ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$moviein")
        subtitle_count=$(/usr/bin/ffprobe -v error -show_entries stream=codec_type "$moviein" | grep "codec_type=subtitle" | wc -w)
        #echo "$subtitle_count"
    else
        echo ""$moviefullpath" does not exit -rename the movie function"
        exit;
    fi
}

#add subtitles to mp4 file #-map 0:v -map 0:a? -map 0:s? -map_metadata:g 0:g -c:v copy -c:a copy -c:s mov_text 
function mp4withsrt {
    if [[ -f "$moviein" ]]; then
        /usr/bin/ffmpeg -y -nostdin -loglevel error -i "$moviein" -f srt -i "$srt_file" -map 0 -c copy -c:s mov_text -map_metadata 0 -map 1 -c:s:$subtitle_count mov_text -metadata:s:s:$subtitle_count language="$lang_code" "$movieout";
        outfileduration=$(/usr/bin/ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$movieout")
    else
        echo ""$moviein" does not exit -mp4 with srt function"
        exit;
    fi
}

#add subtitles to mkv file
function mkvwithsrt {
    if [[ -f "$moviein" ]]; then
        /usr/bin/ffmpeg -y -nostdin -loglevel error -i "$moviein" -f srt -i "$srt_file" -map 0 -c copy -c:s srt -map_metadata 0 -map 1 -c:s:$subtitle_count srt -metadata:s:s:$subtitle_count language="$lang_code" "$movieout";
        outfileduration=$(/usr/bin/ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$movieout")
    else
        echo ""$moviein" does not exit -mkv with srt function"
        exit;
    fi
}

#copy out file to original location, delete temp files.
function removebakfile {
    if [[ -f "$movieout" ]]; then
        if [[ "$infileduration" = "$outfileduration" ]]; then
            /bin/cp "$movieout" "$moviefullpath";
            /bin/rm "$moviein";
            /bin/rm "$movieout";
        fi
    else
        /bin/rm "$moviein";
        /bin/rm "$movieout";
        echo ""$movieout" does not exit -remove bak file function"
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