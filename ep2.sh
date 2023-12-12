#!/bin/bash
#
# DESCRIÇÃO:
# Este Exercício de Programação se trata de um sistema de chat, interterminais, implementado
# em Bash Script. Tem suporte para um servidor e vários clientes, com algumas funções básicas 
# disponíveis,
# como mandar mensagens e listar usuários em linha.
# Ademais, há um suporte para notificações via telegram ao servidor, que avisa dos 
# usuários em linha, logins, logouts e erros de senha.
#
# COMO EXECUTAR:
# No diretório que contém este arquivo, rode-o no terminal com os comandos
# $<user>@<máquina> ./ep2.sh <cliente|servidor>
#
# Na modalidade servidor, você terá acesso ao seguinte Prompt:
# servidor> |
# Dos comandos, temos:
# 1) list, que lista os nomes dos usuários em linha
# 2) time, que informa o tempo desde que o servidor foi iniciado
# 3) reset, que remove todos os clientes criados
# 4) quit, finaliza o servidor
# 
# Na modalidade cliente, você terá acesso ao seguinte Prompt:
# cliente> |
# Dos comandos, temos:
# 1) create, que cria um novo usuário, sob os parâmetros <usuário> <senha>
# 2) passwd, que troca a senha de um usuário já existente, sob os parâmteros
#	 <usuário> <senha antiga> <senha nova>
# 3) login, que acessa o sistema de chat, sob os parâmetros <usuário> <senha>
#	 logado, tem-se os seguintes comandos
#    3') list, que lista os usuários em linha
#	 3'') logout, que desloga do sistema
#    3''') msg, que envia uma mensagem para outro usuário em linha, sob os comandos
#		   <usuário destinatário> <mensagem>
# 4) quit, finaliza a execução do cliente
# 
# TESTES:
# Um servidor, três clientes logados simultaneamente e quatro usuários criados.
# Por meio de um teste de resistência, verificou-se que, o sistema de chat suporta,
# tranquilamente, o acesso simultâneo de três clientes se comunicando entre si.
#
# Testes de erros de senha e envio de mensagens para usuários inxistentes foram executados
# tranquilamente.
#
# Sequência de comandos como list, time e msg foram executadas sem problemas, tanto pelos 
# usuários, quanto pelo servidor.
#
# Houve uma troca entre um cliente e aquele que ainda não estava logado e tudo correu bem.
#
# Por fim, encerrou-se o programa sem muitos problemas e com limpeza dos arquivos utilizados no
# diretório /tmp/
#
# DEPENDÊNCIAS:
# Para o envio das mensagens no Telegram, é necessário ter baixado o curl
# Para isso, tenha o comando: sudo apt-get install curl
# 
# Dos dados da máquina em que os testes foram executados 
# Processador: 11th Gen Intel(R) Core(TM) i5-1135G7 @ 2.40GHz
# Memória Ram: 7844120 bytes
# Sistema Operacional: Ubuntu 20.04.6 LTS
# 
# É interessante notar que, logo após rodar esse programa, os respectivos prompts serão 
# impressos na tela.

# Número de argumentos: Verificação da quantidade de parâmetros passados inicialmente na execução
# do programa, que deve ser exatamente um.
NumArgs=$#

if [ ${NumArgs} -ne 1 ]; then
	# Usuário não respeitou o número de argumentos.
	echo "Uso correto do programa: "$0 "<cliente|servidor>"
	exit 1 # O programa encerra com número de saída diferente de zero.
		
else
	# Tipo do argumento: deve ser restrito aos tipos cliente ou servidor.
	TipoArgs=$1
	
	# Condicional de controle: redirecionamento para o modo de usuário correto.
	if [ ${TipoArgs} = "servidor" ]; then # Usuário quer logar como servidor.
		# Inicialização de variáveis essenciais.
		PromptServidor="servidor"
		# Construção de diretórios temporários para reservar logins e cliente em linha.
		cd /tmp/
		LoginUsuarios=$( mktemp -d LOGEP2XXX )
		OnlineUsuarios=$( mktemp -d ONLEP2XXX )
		AvisosTelegram=$( mktemp -d TELEP2XXX )
		
		# Enviar mensagens para o Telegram da lista de usuários em linha
    	while [ 1 ]; do
        	for user in $( ls ${OnlineUsuarios} ); do
				curl -s --data "text=Usuário online ${user}" [Insira seu TOKEN aqui] 1>/dev/null
			done
        	sleep 60
    	done &
    	
    	# Enviar outras notificações pontuais ao Telegram
    	while [ 1 ]; do
        	for user in $( ls ${AvisosTelegram} ); do
        		notificacao=$( cat ${AvisosTelegram}/${user} )
				curl -s --data "text=${notificacao}" [Insira seu TOKEN aqui] 1>/dev/null
				rm -r /tmp/${AvisosTelegram}/${user}
			done
    	done &
		
		# Enquanto o servidor não sair do programa, ele continuará rodando.
		while [ ${PromptServidor} != "quit" ]; do
			# Interface do sistema
			echo -n "servidor> " # Prompt do servidor.
			read PromptServidor # Armazena dos dados passados ao prompt do servidor.
			
			# Redirecionamento para o devido tratamento das informações
			if [ ${PromptServidor} = "list" ]; then # Listar usuários online.
				for user in $( ls ${OnlineUsuarios} ); do
					echo -e ${user}
				done
				
			elif [ ${PromptServidor} = "time" ]; then # Imprimir tempo desde a criação do servidor.
				echo $SECONDS
				
			elif [ ${PromptServidor} = "reset" ]; then # Remover todos os usuários.
				for user in $( ls ${LoginUsuarios} ); do
					rm -r ${LoginUsuarios}/${user}
				done
				
			elif [ ${PromptServidor} != "quit" ]; then # Usuario não selecionou uma opção válida.
				echo "Comando inválido: ${PromptServidor} não é uma opção válida"
				
			fi
			
		done
		
		# Matar todos os processos
		pkill -P $$
		
		# Após o término do programa, os usuários em linha são excluídos.
		rm -r ${OnlineUsuarios}
		rm -r ${LoginUsuarios}
		rm -r ${AvisosTelegram}
	
	elif [ ${TipoArgs} = "cliente" ]; then # Usuário quer logar como cliente.
		# Inicialização de variáveis essenciais.
		PromptCliente="cliente"
		ComandoCliente="cliente"
		TelaLogin=0
		# Criação do terminal do cliente
		TerminalCliente=$(tty)
		chmod u+x ${TerminalCliente}
		# Para notificar o Telegram
		AvisosTelegram=$( find /tmp/ -name "TELEP2*" 2> /dev/null )
		
		# Enquanto o servidor não sair do programa, ele continuará rodando.
		while [ ${ComandoCliente} != "quit" ]; do
			# Interface do sistema
			echo -n "cliente> "
			read PromptCliente
			
			# Redirecionamento para o devido tratamento das informações
			# Recepção dos dados
			ComandoCliente=$( echo ${PromptCliente} | cut -f 1 -d " " )
			# Funcionalidades sem necessidade de login
			if [ ${TelaLogin} -eq 0 ]; then
				# Acesso à pasta temporária de login
				LoginCliente=$( find /tmp/ -name "LOGEP2*" 2> /dev/null ) # Busca uma pasta com esse nome
				
				# Redirecionamento para o devido tratamento das informações
				if [ ${ComandoCliente} = "create" ]; then # criar de usuário
					# Nome de usuário
					NomeUsuario=$( echo ${PromptCliente} | cut -f 2 -d " " )
					
					# Se já existir o cliente
					if [ $( find ${LoginCliente} -name ${NomeUsuario} 2> /dev/null | wc -l ) -ne 0 ]; then
						echo "ERRO"
						
					else
						# Se ainda não existir o cliente
						SenhaUsuario=$( echo ${PromptCliente} | cut -f 3 -d " " ) # Busca da senha
						echo ${SenhaUsuario} > ${LoginCliente}/${NomeUsuario} # Impressão da senha no aqruivo homônimo ao usuário na pasta de login
					fi
					
				elif [ ${ComandoCliente} = "passwd" ]; then # Alterar a senha
					# Nome de usuário
					NomeUsuario=$( echo ${PromptCliente} | cut -f 2 -d " " )
					# Senhas antiga e nova do cliente
					SenhaAntiga=$( echo ${PromptCliente} | cut -f 3 -d " " )
					SenhaNova=$( echo ${PromptCliente} | cut -f 4 -d " " )
					
					# Se não existe o cliente.
					if [ $( find ${LoginCliente} -name ${NomeUsuario} 2> /dev/null | wc -l ) -eq 0 ]; then
						echo "ERRO"
					
					# Se a senha atual está incorreta.
					elif [ $( cd ${LoginCliente}; cat -s ${NomeUsuario} ) != ${SenhaAntiga} ]; then
						echo "ERRO"
						echo "Usuário ${NomeUsuario} errou a senha às $( date ${ddmmyyyyhhmin} )" > ${AvisosTelegram}/${NomeUsuario}
					
					else
						# Caso contrário, é possível alterar a senha.
						echo ${SenhaNova} > ${LoginCliente}/${NomeUsuario}
					fi
					
				elif [ ${ComandoCliente} = "login" ]; then # Logar no sistema
					# Nome do usuário.
					NomeUsuario=$( echo ${PromptCliente} | cut -f 2 -d " " )
					# Senha do cliente.
					SenhaUsuario=$( echo ${PromptCliente} | cut -f 3 -d " " )
					
					# Se não existe o cliente.
					if [ $( find ${LoginCliente} -name ${NomeUsuario} 2> /dev/null | wc -l ) -eq 0 ]; then
						echo "ERRO"
				
					# Se a senha está errada.
					elif [ $( cd ${LoginCliente}; cat -s ${NomeUsuario} ) != ${SenhaUsuario} ]; then
						echo "ERRO"
						echo "Usuário ${NomeUsuario} errou a senha às $( date ${ddmmyyyyhhmin} )" > ${AvisosTelegram}/${NomeUsuario}
					
					else
						# Caso contrário, é possível logar.
						TelaLogin=1
						# Acesso à pasta temporária de usuários em linha
						OnlineCliente=$( find /tmp/ -name "ONLEP2*" 2> /dev/null ) # Busca uma pasta com esse nome
						# Cria um arquivo com o terminal desse cliente.
						echo ${TerminalCliente} > ${OnlineCliente}/${NomeUsuario}
						echo "Usuário ${NomeUsuario} logou com sucesso às $( date ${ddmmyyyyhhmin} )" > ${AvisosTelegram}/${NomeUsuario}
						
					fi
					
				# O usuário digitou um comando inválido
				elif [ ${ComandoCliente} != "quit" ]; then
					echo "ERRO"
				fi
			
			# Funcionalidades com necessidade de login
			elif [ ${TelaLogin} -eq 1 ]; then
				
				# Redirecionamento para o devido tratamento das informações
				if  [ ${ComandoCliente} = "list" ]; then # Listar usuários online.
					for user in $( ls ${OnlineCliente} ); do
						echo -e ${user}
					done
					
				elif [ ${ComandoCliente} = "logout" ]; then # Deslogar do sistema.
					TelaLogin=0
					echo "Usuário ${NomeUsuario} deslogou com sucesso às $( date ${ddmmyyyyhhmin} )" > ${AvisosTelegram}/${NomeUsuario}
					rm ${OnlineCliente}/${NomeUsuario}
					
				elif [ ${ComandoCliente} = "quit" ]; then
					# Desloga antes de sair do programa
					echo "Usuário ${NomeUsuario} deslogou com sucesso às $( date ${ddmmyyyyhhmin} )" > ${AvisosTelegram}/${NomeUsuario}
					rm ${OnlineCliente}/${NomeUsuario}
				
				elif [ ${ComandoCliente} = "msg" ]; then
					# Nome do destinatário
					DestinatarioCliente=$( echo ${PromptCliente} | cut -f 2 -d " " )
					
					# Se o destinatário não está logado
					if [ $( find ${OnlineCliente}/ -name ${DestinatarioCliente} 2> /dev/null | wc -l ) -eq 0 ]; then
						echo "ERRO"
						
					else					
						# Caso contrário, é possível enviar mensagens
						TerminalDestinatario=$( cd ${OnlineCliente}; cat -s ${DestinatarioCliente} )
						MensagemCliente=$( echo ${PromptCliente} | cut -d " " -f 1,2 --complement )
						echo -n -e "[Mensagem de ${NomeUsuario}] ${MensagemCliente}\ncliente> " | cat > ${TerminalDestinatario}
					fi
					
				# O usuário digitou um comando inválido
				elif [ ${ComandoCliente} != "quit" ]; then
					echo "ERRO"
				fi
			fi
		done
	
	else # Usuário não respeitou o tipo de argumentos.	
		echo "Uso correto do programa: "$0 "<cliente|servidor>"		
	fi

fi

    pkill -P $$

exit 0
