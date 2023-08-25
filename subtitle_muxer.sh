#!/bin/bash

# Check if ffmpeg is present, otherwise download and make it executable
if ! [ -f "ffmpeg" ]; then
    echo "ffmpeg not found in PATH, downloading..."
    wget -q "https://bitbucket.org/emre1393/xtreamui_mirror/downloads/ffmpeg_amd64-static_non_xc" -O ffmpeg
    chmod +x ffmpeg
    echo "ffmpeg downloaded and made executable"
fi

# Check for the folder path argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 \"<folder_path>\""
    exit 1
fi

folder_path="$1"

# Print main folder
echo "Processing movies in folder: $folder_path"
echo

# Ask for confirmation to continue
read -p "Press Enter to continue or Ctrl+C to abort..."

# Array to store input subtitle options for ffmpeg
input_list=""
# Array to store metadata options for ffmpeg
metadata_list=""
# Counter for subtitle languages
count=0

# Map language codes to their full names
declare -A language_names=(
    ["en"]="eng"
    ["de"]="ger"
    ["fr"]="fre"
    ["es"]="spa"
    ["it"]="ita"
    ["tr"]="tur"
)

# Retry configuration
max_retries=3  # Maximum number of retries
retry_wait_time=10  # Wait time in seconds between retries

# Find all MKV and MP4 files in the folder and its subfolders
IFS=$'\n'
movie_files_x=($(find "$folder_path" -type f -name "*.mkv" -o -name "*.mp4"))
movie_files=($(sort <<<"${movie_files_x[*]}")); 
unset IFS
total_movies=${#movie_files[@]}


# Show total number of found movies
echo -e "\nTotal number of movies found: $total_movies"
echo

# Iterate through each movie file
for ((i=0; i<$total_movies; i++)); do
    movie_file="${movie_files[$i]}"
    order_number=$((i + 1))
    
    # Extract file name without extension
    #file_name="${movie_file##*/}"
    file_name="$(/usr/bin/basename "$movie_file")"
    file_name_without_extension="${file_name%.*}"
    
    # Determine container format
    if [[ "${file_name: -4}" == .mkv ]]; then
        container_format="mkv"
        subtitle_codec="srt"
    elif [[ "${file_name: -4}" == .mp4 ]]; then
        container_format="mp4"
        subtitle_codec="mov_text"
    else
        continue
    fi

    echo -e "Processing movie $order_number/$total_movies: $file_name \n\n"
    
    # Retry loop
    for ((retry=0; retry<$max_retries; retry++)); do
        # Clear input_list and metadata_list for the next iteration
        input_list=""
        metadata_list=""
        count=0
        
        # Extract file path without extension
        file_path_noext="${movie_file%????}"
        
        # Loop through available subtitle languages 
        found_subtitles=false
        for lang in en de fr es it tr; do
            # Construct subtitle file path
            srt_path="${file_path_noext}.${lang}.srt"
            if [ -f "$srt_path" ]; then
                found_subtitles=true
                input_list+=" -i " 
                input_list+=\"$srt_path\"
                language_name="${language_names[$lang]}"
                metadata_list+=" -map $((count + 1)) -metadata:s:s:$count language=$language_name"
                count=$((count + 1))
            fi
        done
        if [ -f "${file_path_noext}.srt" ]; then
            srt_path="${file_path_noext}.srt"
            found_subtitles=true
            input_list+=" -i " 
            input_list+=\"$srt_path\"
            metadata_list+=" -map $((count + 1)) "
        fi

        if ! $found_subtitles; then
            echo -e "\nNo subtitles found, skipping $file_name"
            break
        fi

        # Output movie file with embedded subtitles
        output_movie="${folder_path}/${file_name_without_extension}_with_subtitles.${container_format}"

        # Remove existing subtitles and copy streams -v quiet -stats 
        temp_output_movie="${folder_path}/${file_name_without_extension}_temp.${container_format}"
        run_ff1="./ffmpeg -v quiet -stats  -i \"$movie_file\" -c copy -map 0:v -map 0:a -map_metadata 0 -movflags use_metadata_tags \"$temp_output_movie\""
        eval $run_ff1



        # Use ffmpeg to add the subtitles and metadata
        run_ff2="./ffmpeg -v quiet -stats  -i \"$temp_output_movie\" $input_list -map 0 -c:v copy -c:a copy -c:s $subtitle_codec -map_metadata 0 -movflags use_metadata_tags $metadata_list \"$output_movie\""
        eval $run_ff2
        echo -e "\n\nSubtitles added to $file_name and saved as $output_movie"

        # Calculate file sizes
        original_size=$(stat -c%s "$movie_file")
        new_size=$(stat -c%s "$output_movie")

        # Check if the file sizes are within a specified range (e.g., 5MB)
        size_difference=$((new_size - original_size))
        size_threshold=5000000  # 5MB

        if [ $size_difference -le $size_threshold ] && [ $size_difference -ge -$size_threshold ]; then
            # Remove corresponding .srt files and replace the original file with the new one
            for lang in en de fr es it tr; do
                subtitle_file="${file_path_noext}.${lang}.srt"
                if [ -f "$subtitle_file" ]; then
                    rm "$subtitle_file"
                fi
            done
            if [ -f "${file_path_noext}.srt" ]; then 
                rm "${file_path_noext}.srt"
            fi
            mv "$output_movie" "$movie_file"
            rm "$temp_output_movie"
            echo -e "\nReplaced $file_name with updated version"
            break  # Exit the retry loop if successful
        else
            echo -e "\nFile size difference exceeds threshold, retrying..."
            rm "$temp_output_movie" # Remove the new file
            rm "$output_movie"
            sleep "$retry_wait_time"
        fi
        [[ -f "$temp_output_movie" ]] | rm "$temp_output_movie"
    done

    echo  # Add a newline after each movie processing
done

echo -e "\n\nSubtitles added to all MKV and MP4 files in $folder_path and its subfolders"
