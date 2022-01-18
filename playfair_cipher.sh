#!/bin/bash
#
# Author: Darren Foley
#
# Date: 2022-01-13
#
# Description: Implementation of the playfair cipher to encrypt text 
#
################

declare -A KEYSQUARE_MAP
GENERATE_KEYSQUARE=0
INPUT_STRING=""
OUTPUT_PATH=/tmp/keysquare
KEYSQUARE_PATH=${OUTPUT_PATH}
ENCRYPT=0
DECRYPT=0
ALPHA=(a b c d e f g h i j k l m n o p q r s t u v w x y z)
N_ROW=5
N_COL=5
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

# Encrypt the plaintext message passed to the script
encrypt_message() {
	message_upper=${INPUT_STRING^^}

	#Remove spaces then split into digrams
	digram=$(echo "$message_upper" | sed 's/ //g' | sed 's/\(.\{2\}\)/\1 /g')
	#Remove any double characters in digram (e.g. MM)
	digram_adj=$(echo "$digram" | sed 's/\(.\)\1/\1/g')

	# If duplicates found then reshuffle again until resolved
	while [ "${digram}" != "${digram_adj}" ];
	do
		digram=$(echo "${digram_adj}" | sed 's/ //g' | sed 's/\(.\{2\}\)/\1 /g')
		digram_adj=$(echo "$digram" | sed 's/\(.\)\1/\1/g')
	done	

	#If there is a lone digram add an X character to the end
	digram=$(echo "${digram}" | awk '{ if(length($0) % 2 != 0) print $0 "X"; else print $0 }')

	#TODO: Implement Rules for cipher	
}


# Decrypt any encrypted text
decrypt_message() {
	message_upper=${INPUT_STRING^^}
}


main() {
	[ "${GENERATE_KEYSQUARE}" = "1" ] && generate_keysquare 

	[ "${ENCRYPT}" = "1" ] && encrypt_message
	
	[ "${DECRYPT}" = "1" ] && decrypt_message
}
