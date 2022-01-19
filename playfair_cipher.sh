#!/bin/bash
#
# Author: Darren Foley
#
# Date: 2022-01-13
#
# Description: Implementation of the playfair cipher to encrypt text 
#
################

#Variables
declare -A KEYSQUARE_MAP
GENERATE_KEYSQUARE=0
INPUT_STRING=""
OUTPUT_PATH=/tmp/keysquare
KEYSQUARE_PATH=${OUTPUT_PATH}
ENCRYPT=0
DECRYPT=0
ALPHA=(a b c d e f g h i j k l m n o p q r s t u v w x y z)
KEY_SQUARE=()

usage(){
	echo "Usage: $0 [-g <string> ] [ -e <string> ] [ -d <string> ] [ -h help ]" 1>&2; exit 1;
}



while getopts "g:e:d:p:h" opt
do
	case "$opt" in 
	g)
		GENERATE_KEYSQUARE=1
		OUTPUT_PATH="${OPTARG}"
	;;
	e)
		INPUT_STRING="${OPTARG}"
		ENCRYPT=1
	;;
	d)
		INPUT_STRING="${OPTARG}"
		DECRYPT=1
	;;
	p)
		KEYSQUARE_PATH="${OPTARG}"
	;;
	h)
		usage
	;;
	*)
		usage
	;;
	esac
done
shift $((OPTIND-1))

# Validate user input
[ "${GENERATE_KEYSQUARE}" = "1" ] && [ "${ENCRYPT}" = "1" ] && echo "Multiple options cannot be performed at once" && usage
[ "${GENERATE_KEYSQUARE}" = "1" ] && [ "${DECRYPT}" = "1" ] && echo "Multiple options cannot be performed at once" && usage
[ "${DECRYPT}" = "1" ] && [ "${ENCRYPT}" = "1" ] && echo "Cannot perform decrypt and encrypt options at the same time" && usage


check_letter_exists() {

	letter="$1"
	for l in "${KEY_SQUARE[@]}"
	do
		[ "${letter}" = "$l" ] && return 0
	done
	return 1
}

# Pretty print key square
print_keysquare() {

	tmp=""
	count=0
	for i in "${KEY_SQUARE[@]}"
	do
		[ "${count}" != "5" ] && tmp="${tmp}${i} " && count=$((${count}+1))
		[ "${count}" = "5" ] && printf "%s\n" "${tmp}" && count=0 && tmp=""
	done
}
#KEY_SQUARE=(a b c d e f g h i j k l m n o p q r s t u v w x y z)
#print_keysquare > ${OUTPUT_PATH}

# Read inputfile into an HashMap
read_keysquare() {
	
	if [ -f "${KEYSQUARE_PATH}" ];
	then	
		row=0
		while read -r line;
		do
			tmp=($line)
			for i in ${!tmp[@]}
			do
				key="$row,$i"
				KEYSQUARE_MAP["$key"]="${tmp[$i]}"	
			done
			row=$(($row+1))
		done < ${KEYSQUARE_PATH}
	else
		echo "No keysquare file found, use -g to generate" && exit 1
	fi
}
#read_keysquare
#echo "${KEYSQUARE_MAP[@]}"
#echo "${!KEYSQUARE_MAP[@]}"
#echo "${KEYSQUARE_MAP[1,1]}"

# Generate the keysquare from users input word
generate_keysquare() {

	echo -e "Enter your cipher keyword below\nTry to use a simple 5 letter word"
	read -p "Cipher Keyword: " USER_INPUT_KEYWORD 
	USER_KEYWORD="${USER_INPUT_KEYWORD^^}"

	letters=($(echo "${USER_KEYWORD}" | awk '$1=$1' FS= OFS=" "))	

	tmp_array=(${letters[@]^^} ${ALPHA[@]^^})
	for i in ${tmp_array[@]}
	do
		#echo "$i"
		check_letter_exists ${i}
		RC=$?
		if [ "${RC}" = "1" ] && [ "${i}" != "J" ]; # If letter does not exist and is not equal to J
		then
			#echo ${i}
			KEY_SQUARE+=(${i})
		fi
	done	
	
	echo "Sending keysquare to ${OUTPUT_PATH}"
	print_keysquare > "${OUTPUT_PATH}"

}
#generate_keysquare
#echo "${KEY_SQUARE[@]}"

# Get key that corresponds to input letter in playfair square
get_key() {
	INPUT_LETTER="$1"
	for i in ${!KEYSQUARE_MAP[@]}
	do
		key=${i}
		value="${KEYSQUARE_MAP[$i]}"
		[ "${value}" = "${INPUT_LETTER}" ] && echo "${key}"
	done

}
#get_key "X"

pretty_print() {
	INPUT_TEXT=""
	for i in "$*"; do INPUT_TEXT="${INPUT_TEXT}${i}"; done
	echo "${INPUT_TEXT}" | sed 's/ //g' | sed 's/\(.\{5\}\)/\1 /g' 
}

# Encrypt the plaintext message passed to the script
encrypt_message() {

	message_upper=${INPUT_STRING^^}

	# Read in key square into an HashMap
	read_keysquare

	#Remove spaces then split into digrams
	digram=$(echo "$message_upper" | sed 's/ //g' | sed 's/\(.\{2\}\)/\1 /g')
	#Remove any double characters in digram (e.g. MM with MX)
	digram_adj=$(echo "$digram" | sed 's/\(.\)\1/\1X/g')
	
	# If duplicates found then reshuffle again until resolved
	#while [ "${digram}" != "${digram_adj}" ];
	#do
	#	digram=$(echo "${digram_adj}" | sed 's/ //g' | sed 's/\(.\{2\}\)/\1 /g')
	#	digram_adj=$(echo "$digram" | sed 's/\(.\)\1/\1X/g')
	#done	
	#echo $digram_adj
	#If there is a lone digram add an X character to the end
	digram=$(echo "${digram_adj}" | awk '{ if(length($0) % 2 == 0) print $0 "X"; else print $0 }')
	#echo "$digram"	

	ENCRYPTED_TEXT=()
	#Rules for cipher	
	tmp=(${digram})
	for i in ${tmp[@]}
	do
		#echo "$i"
		letter1="${i:0:1}"
		letter2="${i:1:2}"
		#echo $letter2
		letter1_index=$(get_key "${letter1}")
		letter2_index=$(get_key "${letter2}")
		#echo $letter2_index	
		# Index looks like 1,1 -> row,col	
		row1=$(echo "${letter1_index}" | awk -F',' '{ print $1 }')
		col1=$(echo "${letter1_index}" | awk -F',' '{ print $2 }')
		row2=$(echo "${letter2_index}" | awk -F',' '{ print $1 }')
		col2=$(echo "${letter2_index}" | awk -F',' '{ print $2 }')
		#echo "$row1,$col1"
		#echo "$row2,$col2"
		# Check if on the same row, Take letter to the right
		if [ "$row1" = "$row2" ];
		then
			col1_n=$((${col1}+1))
			col2_n=$((${col2}+1))
			[ "${col1_n}" -gt "4" ] && col1_n=0
			[ "${col2_n}" -gt "4" ] && col2_n=0
			#echo "NEW: $row1,$col1_n"
			#echo "NEW: $row2,$col2_n"
			
			new_digram="${KEYSQUARE_MAP[$row1,$col1_n]}${KEYSQUARE_MAP[$row2,$col2_n]}"
			ENCRYPTED_TEXT+=(${new_digram})

		# Check if on the same column, take letter below
		elif [ "$col1" = "$col2" ]
		then
			row1_n=$(($row1+1))
			row2_n=$(($row2+1))
			[ "${row1_n}" -gt 4 ] && row1_n=0
			[ "${row2_n}" -gt 4 ] && row2_n=0 

			new_digram="${KEYSQUARE_MAP[$row1_n,$col1]}${KEYSQUARE_MAP[$row2_n,$col2]}"
			ENCRYPTED_TEXT+=(${new_digram})
		# Letters form a rectangle, switch column numbers
		else
			col1_n=$col2
			col2_n=$col1
			new_digram="${KEYSQUARE_MAP[$row1,$col1_n]}${KEYSQUARE_MAP[$row2,$col2_n]}"
                        ENCRYPTED_TEXT+=(${new_digram})
		fi
	done
	echo "${ENCRYPTED_TEXT[@]}"
	pretty_print "${ENCRYPTED_TEXT[@]}"
}
#echo "$INPUT_STRING"
#encrypt_message

# Decrypt any encrypted text
decrypt_message() {

	message_upper=${INPUT_STRING^^}
	# Read in key square into an HashMap
	read_keysquare

	#Remove spaces then split into digrams
	digram=$(echo "$message_upper" | sed 's/ //g' | sed 's/\(.\{2\}\)/\1 /g')
	#Remove any double characters in digram (e.g. MM with MX)
	#digram_adj=$(echo "$digram" | sed 's/\(.\)\1/\1X/g')
	
	# If duplicates found then reshuffle again until resolved
	#while [ "${digram}" != "${digram_adj}" ];
	#do
	#	digram=$(echo "${digram_adj}" | sed 's/ //g' | sed 's/\(.\{2\}\)/\1 /g')
	#	digram_adj=$(echo "$digram" | sed 's/\(.\)\1/\1X/g')
	#done	
	#echo $digram_adj
	#If there is a lone digram add an X character to the end
	#digram=$(echo "${digram_adj}" | awk '{ if(length($0) % 2 == 0) print $0 "X"; else print $0 }')
	#echo "$digram"
	DECRYPTED_TEXT=()
	#Rules for cipher	
	tmp=(${digram})
	for i in ${tmp[@]}
	do
		#echo "$i"
		letter1="${i:0:1}"
		letter2="${i:1:2}"
		#echo $letter2
		letter1_index=$(get_key "${letter1}")
		letter2_index=$(get_key "${letter2}")
		#echo $letter2_index	
		# Index looks like 1,1 -> row,col	
		row1=$(echo "${letter1_index}" | awk -F',' '{ print $1 }')
		col1=$(echo "${letter1_index}" | awk -F',' '{ print $2 }')
		row2=$(echo "${letter2_index}" | awk -F',' '{ print $1 }')
		col2=$(echo "${letter2_index}" | awk -F',' '{ print $2 }')
		#echo "$row1,$col1"
		#echo "$row2,$col2"
		# Check if on the same row, Take letter to the left
		if [ "$row1" = "$row2" ];
		then
			col1_n=$((${col1}-1))
			col2_n=$((${col2}-1))
			[ "${col1_n}" -lt "0" ] && col1_n=4
			[ "${col2_n}" -lt "0" ] && col2_n=4
			#echo "NEW: $row1,$col1_n"
			#echo "NEW: $row2,$col2_n"
			
			new_digram="${KEYSQUARE_MAP[$row1,$col1_n]}${KEYSQUARE_MAP[$row2,$col2_n]}"
			DECRYPTED_TEXT+=(${new_digram})

		# Check if on the same column, take letter above
		elif [ "$col1" = "$col2" ]
		then
			row1_n=$(($row1-1))
			row2_n=$(($row2-1))
			[ "${row1_n}" -lt "0" ] && row1_n=4
			[ "${row2_n}" -lt "0" ] && row2_n=4
			
			new_digram="${KEYSQUARE_MAP[$row1_n,$col1]}${KEYSQUARE_MAP[$row2_n,$col2]}"
			DECRYPTED_TEXT+=(${new_digram})
		# Letters form a rectangle, switch column numbers
		else
			col1_n=$col2
			col2_n=$col1
			new_digram="${KEYSQUARE_MAP[$row1,$col1_n]}${KEYSQUARE_MAP[$row2,$col2_n]}"
                        DECRYPTED_TEXT+=(${new_digram})
		fi
	done
	echo "${DECRYPTED_TEXT[@]}" | sed 's/ //g' | sed 's/X$//g'

}
#decrypt_message

main() {
	[ "${GENERATE_KEYSQUARE}" = "1" ] && generate_keysquare 

	[ "${ENCRYPT}" = "1" ] && encrypt_message
	
	[ "${DECRYPT}" = "1" ] && decrypt_message
}
