#!/bin/bash
flag_sorted="0"
flag_files="0"
file1=""
file2=""

### TRATAMENTO DE ARGUMENTOS

for args in "$@" ; do
	case $args in
	"-n")
		flag_n="1"
		if [[ $flag_t -eq "1" || $flag_a -eq "1" || $flag_i -eq "1" ]];then
			echo "To much sort arguments"
			exit
		fi
		flag_sorted="1"
		;;
	"-t")
		flag_t="1"
		if [[ $flag_n -eq "1" || $flag_a -eq "1" || $flag_i -eq "1" ]];then
			echo "To much sort arguments"
			exit
		fi
		flag_sorted="1"
		;;
	"-a")
		flag_a="1"
		if [[ $flag_t -eq "1" || $flag_n -eq "1" || $flag_i -eq "1" ]];then
			echo "To much sort arguments"
			exit
		fi
		flag_sorted="1"
		;;
	"-i")
		flag_i="1"
		if [[ $flag_t -eq "1" || $flag_a -eq "1" || $flag_n -eq "1" ]];then
			echo "To much sort arguments"
			exit
		fi
		flag_sorted="1"
		;;
	"-r")
		flag_r="1"
		;;
	*) #default o primeir default (não é opcao) deverá ser o primeiro ficheiro, o outro o segundo
		flag_files=$(( $flag_files +1 ))
		if [[ $file1 = "" ]];then
			file1=$args
		else
			file2=$args
		fi
		
		;;
	esac
done 
if [[ $flag_files -ne "2" ]];then # verificar o numero de ficheiros
	echo "Wrong number of files. Only two files allowed."
	exit
fi

if [[ -f $file1 && -f $file2 ]];then 	# verificar se os ficheiros existem
	declare -a first_array 				# colocar os dados do primeiro ficheiro num array
	while IFS="": read -r line; do
		first_array+=($"$line")
	done < $file1
	declare -a second_array 			# colocar os dados do segundo ficheiro num array
	while IFS="": read -r line; do
		second_array+=($"$line")
	done < $file2
	declare -a final_array
	for e1 in "${first_array[@]}"; do 
		has="0"
		for e2 in "${second_array[@]}"; do
			if [[ $(echo "$e1" | awk '{print $1}' ) == $(echo "$e2" | awk '{print $1}' )   ]];then # calcular as diferencas entre os elementos que existam nos dois ficheiros
				has="1"
				c1=$(echo "$e1" | awk '{print $1}' ) 
				c2=$(( $(echo "$e1" | awk '{print $2}' ) - $(echo "$e2" | awk '{print $2}' ) )) 
				c3=$(( $(echo "$e1" | awk '{print $3}' ) - $(echo "$e2" | awk '{print $3}' ) )) 
				c4=$(( $(echo "$e1" | awk '{print $4}' ) - $(echo "$e2" | awk '{print $4}' ) )) 
				c5=$(( $(echo "$e1" | awk '{print $5}' ) - $(echo "$e2" | awk '{print $5}' ) )) 
				break;
			fi
		done
		if [[ $has -eq "0" ]];then # se os elementos nao existirem no segundo array guardar no final sem qualquer tipo de calculos
			c1=$(echo "$e1" | awk '{print $1}' ) 
			c2=$(( $(echo "$e1" | awk '{print $2}' ) )) 
			c3=$(( $(echo "$e1" | awk '{print $3}' ) )) 
			c4=$(( $(echo "$e1" | awk '{print $4}' ) )) 
			c5=$(( $(echo "$e1" | awk '{print $5}' ) )) 
		fi
		final_array+=($"${c1} ${c2} ${c3} ${c4} ${c5}") 
	done
	for e2 in "${second_array[@]}"; do
		has="0"
		for e1 in "${first_array[@]}"; do
			if [[ $(echo "$e1" | awk '{print $1}' ) == $(echo "$e2" | awk '{print $1}' )   ]];then # os elementos em comum já foram calculados
				has="1"
				break;
			fi
		done
		if [[ $has -eq "0" ]];then # se os elementos nao existirem no primeiro array guardar no final sem qualquer tipo de calculos
			c1=$(echo "$e2" | awk '{print $1}' ) 
			c2=$(( $(echo "$e2" | awk '{print $2}' ) )) 
			c3=$(( $(echo "$e2" | awk '{print $3}' ) )) 
			c4=$(( $(echo "$e2" | awk '{print $4}' ) )) 
			c5=$(( $(echo "$e2" | awk '{print $5}' ) )) 
			final_array+=($"${c1} ${c2} ${c3} ${c4} ${c5}") 
		fi
		
	done 

	### VERIFICAÇÃO DO SORTING (IGUAL AO USERSTATS.SH)

	if [[ $flag_sorted -eq "1" ]];then
			if [[ $flag_r -eq "1" ]];then
				if [[ $flag_n -eq "1" ]]; then
					for element in "${final_array[@]}"; do
						echo $element
					done | sort  -k 2nr 
				fi
				if [[ $flag_t -eq "1" ]]; then
					for element in "${final_array[@]}"; do
						echo $element
					done | sort -k 3nr
				fi
				if [[ $flag_a -eq "1" ]]; then
					for element in "${final_array[@]}"; do
						echo $element
					done | sort -k  4nr 
				fi
				if [[ $flag_i -eq "1" ]]; then
					for element in "${final_array[@]}"; do
						echo $element
					done | sort -k 5nr
			fi
			else
					if [[ $flag_n -eq "1" ]]; then
					for element in "${final_array[@]}"; do
						echo $element
					done | sort -k 2n
				fi
				if [[ $flag_t -eq "1" ]]; then
					for element in "${final_array[@]}"; do
						echo $element
					done | sort -k 3n
				fi
				if [[ $flag_a -eq "1" ]]; then
					for element in "${final_array[@]}"; do
						echo $element
					done | sort -k 4n
				fi
				if [[ $flag_i -eq "1" ]]; then
					for element in "${final_array[@]}"; do
						echo $element
					done | sort -k 5n
				fi
			fi
		else 
			for element in "${final_array[@]}"; do
						echo $element
			done 
		fi
	
else
	echo "Error: Files do not exist."
fi
