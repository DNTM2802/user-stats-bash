#!/bin/bash
data() {
	if [[ "$file" != "" ]]; then 												# SE HOUVER FILE
		if [[ "$user" != "" ]]; then 											# SE HOUVER FILTRAGEM POR USER
			data=$(last -f $file | awk '{print $1}' | grep $user | sort | uniq) # UTILIZAÇÃO DO LAST C/ O FILE, SELEÇÃO DOS USERS ESPECÍFICOS NO FILE -> DATA CONTEM OS USERS UNICOS
		else
			data=$(last -f $file | awk '{print $1}' | sort | uniq) 				# UTILIZAÇÃO DO LAST C/ O FILE, SELEÇÃO DOS USERS NO FILE -> DATA CONTEM OS USERS UNICOS
		fi
	else																		# SE NÃO HOUVER FILE
		if [[ "$user" != "" ]]; then 											# SE HOUVER FILTRAGEM POR USER
			data=$(last | awk '{print $1}' | grep $user | sort | uniq)
		elif [[ "$group" != "" ]]; then 										# SE HOUVER FILTRAGEM POR GRUPO
			users_group=""
			data1=$(last | awk '{print $1}' | sort | uniq)
			for var in $data1; do														# PARA TODOS OS USERS
				if [[ "reboot" != "$var" && "" != "$var" && "wtmp" != "$var" ]]; then	# IGNORAR EXCEÇÕES
					groups_var=$(id -G -n $var)											# GRUPOS DE UM USER
					exists=$(echo $groups_var | grep $group)							# FLAG - O GRUPO PROCURADO EXISTE NO GROUPS DO USER?
					if [[ "$exists" != "" ]]; then 										# SE SIM, ENTRA PARA A ARRAY DE USERS COM AQUELE GRUPO
						users_group="${users_group}${var}\|"							# ARRAY CONSTRUÍDA DE FORMA A EXECUTAR O COMANDO grep
					fi
				fi
			done
			users_group=${users_group%??}												# REMOÇÃO DOS DOIS ÚLTIMOS CARACTERES
			if [[ "$users_group" == "" ]]; then											# TERMINAR SE NÃO FOREM ENCONTRADOS USERS COM O GRUPO PASSADO COMO ARGUMENTO
				echo "No users found for group."
				exit
			fi
			data=$(last | awk '{print $1}' | grep "$users_group" | sort | uniq) 		#UTILIZAÇÃO DO LAST, SELEÇÃO DOS USERS COM O GROUP -> DATA CONTEM OS USERS UNICO
		else
			data=$(last | awk '{print $1}' | sort | uniq) 								#UTILIZAÇÃO DO LAST -> DATA CONTEM OS USERS UNICOS
		fi
	fi
	declare -a my_array 																#ARRAY QUE VAI CONTER O CONTEÚDO A SER IMPRESSO
	for var in $data; do 																#PARA CADA UTILIZADOR NO DATA
		if [[ "reboot" != "$var" && "" != "$var" && "$file" != "$var" ]]; then 			#IGNORAR EXCEÇÕES
			sessions="0"
			i='1'
			if [[ "$file" != "" ]]; then #SE HOUVER FILE                                	#index para as linhas
				time_eval_group=$(last -f $file | grep "$var" | awk '{print $9 $10}')       #COLUNAS NECESSÁRIAS PARA VERIFICAR SE SÃO time_evaluedS A IGNORAR OU NÃO
				date_group=$(last -f $file | grep "$var" | awk '{print $5 " " $6 " " $7} ') #DATA DE TODAS AS SESSOES
			else
				time_eval_group=$(last | grep "$var" | awk '{print $9 $10}')       			#COLUNAS NECESSÁRIAS PARA VERIFICAR SE SÃO time_evaluedS A IGNORAR OU NÃO
				date_group=$(last | grep "$var" | awk '{print $5 " " $6 " " $7} ') 			#DATA DE TODAS AS SESSOES
			fi
			tot_time_count="0" 																# TEMPO TOTAL DE TODAS AS SESSÕES
			min_time="525600"
			max_time="-1"
			for time_evalued in $time_eval_group; do 										# PARA CADA TEMPO
				date=$(echo "$date_group" | sed -n ''$i'p')
				numdate=$(date -d "$date" +%s) 												#DATA COVERTIDA EM INTEIRO PARA COMPARACAO
				if [[ $flag_s="1" && "$numdate" -gt "$ini_session" && "$numdate" -lt "$fin_session" || $flag_s -eq "0" ]]; then
					if [[ $time_evalued == [0-9]* ]]; then 									# SE O PRIMEIRO CARACTERE É NUMERO (DESCARTAR down, still, logged in, etc)
						sessions=$(($sessions + 1))                      					# COMO É UM TEMPO A NÃO IGNORAR, INCREMENTAR O NÚMERO DE SESSÕES
						time_evalued_length=$(echo "${time_evalued#*(}") 					# VER SE O TEMPO ESTÁ NA FORMA 12:34 OU 56+12:34
						if [[ "${#time_evalued_length}" -eq 6 ]]; then 						# SE ESTIVER NA FORMA NA FORMA 12:34 ( length("12:34)") = 6 )
							hora=$(echo "$time_evalued" | cut -c 7-8 | sed 's/^0*//') 		# EXTRAÇÃO DA HORA DO TIME EVALUED --> 12:34(23:45) --> 23 , C/ REMOÇÃO DOS 0's À ESQUERDA
							if [[ $hora -eq "" ]]; then 									# CASO NA LINHA ACIMA A HORA FOSSE 00, A REMOÇÃO DOS 0's À ESQUERDA DEIXA A VARIÁVEL EM BRANCO ""
								hora="0"
							fi
							minuto=$(echo "$time_evalued" | cut -c 10-11 | sed 's/^0*//') 	# EXTRAÇÃO DO MINUTO DO TIME EVALUED --> 12:34(23:45) --> 45 , C/ REMOÇÃO DOS 0's À ESQUERDA
							if [[ $minuto -eq "" ]]; then 									# CASO NA LINHA ACIMA O MINUTO FOSSE 00, A REMOÇÃO DOS 0's À ESQUERDA DEIXA A VARIÁVEL EM BRANCO ""
								minuto="0"
							fi
							if [[ $(($hora * 60 + $minuto)) -lt $min_time ]]; then			# VERIFICAÇÃO SE ESTA SESSÃO É A SESSÃO DE DURAÇÃO MÍNIMA
								min_time=$(($hora * 60 + $minuto)) 							# SE SIM, ATUALIZAR O VALOR DA DURAÇÃO DA SESSÃO MÍNIMA
							fi
							if [[ $(($hora * 60 + $minuto)) -gt $max_time ]]; then 			# VERIFICAÇÃO SE ESTA SESSÃO É A SESSÃO DE DURAÇÃO MÁXIMA
								max_time=$(($hora * 60 + $minuto)) 							# SE SIM, ATUALIZAR O VALOR DA DURAÇÃO DA SESSÃO MÁXIMA
							fi
							tot_time_count=$(($tot_time_count + 60 * $hora + $minuto)) 		# ADICIONAR O TEMPO ACIMA (CONVERTIDO EM MINUTOS) AO TEMPO TOTAL
						else
							dia_finchar=$(($time_evalued_length - 1))             			# CALCULO DO VALOR DO CARACTER FINAL DO DIA
							dia=$(echo "$time_evalued" | cut -c 7-"$dia_finchar") 			# EXTRAÇÃO DO DIA DO TIME EVALUED --> 12:34(5+23:45) -->5
							hora_inchar=$(($dia_finchar + 2))
							hora_finchar=$(($dia_finchar + 3))
							hora=$(echo "$time_evalued" | cut -c "$hora_inchar"-"$hora_finchar" | sed 's/^0*//') 	# EXTRAÇÃO DA HORA DO TIME EVALUED --> 12:34(23:45) --> 23 , C/ REMOÇÃO DOS 0's À ESQUERDA
							if [[ $hora -eq "" ]]; then 															# CASO NA LINHA ACIMA A HORA FOSSE 00, A REMOÇÃO DOS 0's À ESQUERDA DEIXA A VARIÁVEL EM BRANCO ""
								hora="0"
							fi
							minuto_inchar=$(($hora_finchar + 2))
							minuto_finchar=$(($hora_finchar + 3))
							minuto=$(echo "$time_evalued" | cut -c "$minuto_inchar"-"$minuto_finchar" | sed 's/^0*//') 	# EXTRAÇÃO DO MINUTO DO TIME EVALUED --> 12:34(23:45) --> 45 , C/ REMOÇÃO DOS 0's À ESQUERDA
							if [[ $minuto -eq "" ]]; then 																# CASO NA LINHA ACIMA O MINUTO FOSSE 00, A REMOÇÃO DOS 0's À ESQUERDA DEIXA A VARIÁVEL EM BRANCO ""
								minuto="0"
							fi
							if [[ $(($hora * 60 + $minuto + $dia * 1440)) -lt $min_time ]]; then 		# VERIFICAÇÃO SE ESTA SESSÃO É A SESSÃO DE DURAÇÃO MÍNIMA
								min_time=$(($hora * 60 + $minuto + $dia * 1440)) 						# SE SIM, ATUALIZAR O VALOR DA DURAÇÃO DA SESSÃO MÍNIMA
							fi
							if [[ $(($hora * 60 + $minuto + $dia * 1440)) -gt $max_time ]]; then 		# VERIFICAÇÃO SE ESTA SESSÃO É A SESSÃO DE DURAÇÃO MÁXIMA
								max_time=$(($hora * 60 + $minuto + $dia * 1440)) 						# SE SIM, ATUALIZAR O VALOR DA DURAÇÃO DA SESSÃO MÁXIMA
							fi
							tot_time_count=$(($tot_time_count + 60 * $hora + $minuto + $dia * 1440)) 	# ADICIONAR O TEMPO ACIMA (CONVERTIDO EM MINUTOS) AO TEMPO TOTAL
						fi
					fi
				fi
				i=$(($i + 1))
			done
			if [ $sessions -ne 0 ]; then 														# IGNORAR AS EXCEÇÕES DERIVADAS DO USO DE -s E -e
				my_array+=($"${var} ${sessions} ${tot_time_count} ${max_time} ${min_time}") 	# ADICIONAR LINHA COM TODOS OS DADOS DE 1 UTILIZADOR AO ARRAY
			fi
		fi
	done

### VERIFICAÇÃO DO SORTING

	if [[ $flag_sorted -eq "1" ]]; then 				# O UTILIZADOR PASSOU ALGUM SORTING? SE SIM...
		if [[ $flag_r -eq "1" ]]; then					# SE O UTILIZADOR PASSOU REVERSE SORTING...
			if [[ $flag_n -eq "1" ]]; then				# IMPRIMIR O CONTEÚDO DO ARRAY | SORT POR NÚMERO TOTAL DE SESSÕES
				for element in "${my_array[@]}"; do
					echo $element
				done | sort -k 2nr
			elif [[ $flag_t -eq "1" ]]; then			# IMPRIMIR O CONTEÚDO DO ARRAY | SORT POR TEMPO TOTAL
				for element in "${my_array[@]}"; do
					echo $element
				done | sort -k 3nr
			elif [[ $flag_a -eq "1" ]]; then			# IMPRIMIR O CONTEÚDO DO ARRAY | SORT POR TEMPO MÁXIMO
				for element in "${my_array[@]}"; do
					echo $element
				done | sort -k 4nr
			elif [[ $flag_i -eq "1" ]]; then			# IMPRIMIR O CONTEÚDO DO ARRAY | SORT POR TEMPO MÍNIMO
				for element in "${my_array[@]}"; do
					echo $element
				done | sort -k 5nr
			else
				for element in "${my_array[@]}"; do		# IMPRIMIR O CONTEÚDO DO ARRAY | APENAS EM REVERSE ALFABETICO
					echo $element
				done | sort -k 1nr
			fi
		else											# SE NÃO FOI PASSADO NENHUM SORTING...
			if [[ $flag_n -eq "1" ]]; then				# IMPRIMIR O CONTEÚDO DO ARRAY | SORT POR NÚMERO TOTAL DE SESSÕES
				for element in "${my_array[@]}"; do
					echo $element
				done | sort -k 2n
			elif [[ $flag_t -eq "1" ]]; then			# IMPRIMIR O CONTEÚDO DO ARRAY | SORT POR TEMPO TOTAL
				for element in "${my_array[@]}"; do
					echo $element
				done | sort -k 3n
			elif [[ $flag_a -eq "1" ]]; then			# IMPRIMIR O CONTEÚDO DO ARRAY | SORT POR TEMPO MÁXIMO
				for element in "${my_array[@]}"; do
					echo $element
				done | sort -k 4n
			elif [[ $flag_i -eq "1" ]]; then			# IMPRIMIR O CONTEÚDO DO ARRAY | SORT POR TEMPO MÍNIMO
				for element in "${my_array[@]}"; do
					echo $element
				done | sort -k 5n
			else
				echo "Sorting method not found."
				exit
			fi
		fi
	else												# SE O UTILIZADOR NÃO PASSOU NENHUM SORTING
		for element in "${my_array[@]}"; do				# IMPRIMIR O CONTEÚDO DO ARRAY
			echo $element
		done
	fi
}
flag_s="0"
flag_e="0"
flag_u="0"
flag_g="0"
flag_sorted="0"

### TRATAMENTO DE ARGUMENTOS

while getopts 'g:u:s:e:f:rntai' c; do
	case $c in
	f)
		file=$OPTARG
		;;
	g)
		if [[ $flag_u -eq "1" ]]; then
			echo "Can't sort by group and user at the same time."
			exit
		fi
		flag_g="1"
		group=$OPTARG
		;;
	u)
		if [[ $flag_g -eq "1" ]]; then
			echo "Can't sort by group and user at the same time."
			exit
		fi
		flag_u="1"
		user=$OPTARG
		;;
	s)
		flag_s="1"
		ini_session=$(date -d "$OPTARG" +%s) #CONVERTER PARA INTEIRO PARA SER POSSIVEL COMPARAR
		;;
	e)
		flag_e="1"
		fin_session=$(date -d "$OPTARG" +%s) #CONVERTER PARA INTEIRO PARA SER POSSIVEL COMPARAR
		;;
	n)
		flag_n="1"
		if [[ $flag_t -eq "1" || $flag_a -eq "1" || $flag_i -eq "1" ]]; then
			echo "Too much sort arguments."
			exit
		fi
		flag_sorted="1"
		;;
	t)
		flag_t="1"
		if [[ $flag_n -eq "1" || $flag_a -eq "1" || $flag_i -eq "1" ]]; then
			echo "Too much sort arguments."
			exit
		fi
		flag_sorted="1"
		;;
	a)
		flag_a="1"
		if [[ $flag_t -eq "1" || $flag_n -eq "1" || $flag_i -eq "1" ]]; then
			echo "Too much sort arguments."
			exit
		fi
		flag_sorted="1"
		;;
	i)
		flag_i="1"
		if [[ $flag_t -eq "1" || $flag_a -eq "1" || $flag_n -eq "1" ]]; then
			echo "Too much sort arguments."
			exit
		fi
		flag_sorted="1"
		;;
	r)
		flag_r="1"
		;;
	\?)
		echo "Usage: cmd [-f]"
		exit
		;;
	esac
done
if [[ $flag_s -eq "1" && $flag_e -eq "0" || $flag_s -eq "0" && $flag_e -eq "1" ]]; then
	echo "Argument -s and -e are required together."
	exit
fi
data
