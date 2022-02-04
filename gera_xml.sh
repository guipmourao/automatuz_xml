#!/bin/bash
#

# Debug
#set -x
#trap read debug

# Vesão do script
ver="1.0"

# Setando lista de pastas
folders=(
./notas
./notas/cliente
./notas/contabilidade
./config
./config/pdfs
./config/txts
./logs
)

# Limpa a tela
clear
printf "\n"
printf "  Gerador de notas v$ver\n"
printf "========================================== "
echo
read -p '  Digite o nome do cliente: ' nome_cliente
echo

# Criando as pastas
for folder in "${folders[@]}"; do
  [[ ! -d "$folder" ]] && mkdir "$folder"
done

# Renomeando notas
printf "  Corrigindo o nome das notas............. "
ls ./notas/cliente >> ./logs/log_notas_cliente.txt
ls ./notas/cliente >> ./config/txts/xmls.txt
file="./config/txts/xmls.txt"

while IFS= read -r line; do
  nfe_end=$(echo "$line" | tr -d '0123456789')
  nfe_arq=$(echo "$line" | sed 's/-.*//g')

  if [[ -f ./notas/cliente/"$line" ]]; then

    if [[ "$nfe_end" == "-procNFe.xml" ]]; then
      nfe_num=$(xmllint --xpath "//*[local-name()='infNFe']/@*[local-name()='Id']" ./notas/cliente/$line | cut -b 9- | rev | cut -b 2- | rev)
    fi

    if [[ "$nfe_end" == "-procInutNfe.xml" ]]; then
      nfe_num=$(xmllint --xpath "//*[local-name()='infInut']/@*[local-name()='Id']" ./notas/cliente/$line | head -n 1 | cut -b 8- | rev | cut -b 2- | rev)
    fi

    if [[ "$nfe_num" != "$nfe_arq" ]]; then
      mv -f ./notas/cliente/$line ./notas/cliente/$nfe_num$nfe_end
      echo $line >> ./logs/log_notas_renomeadas.txt
    fi

    if [[ "$nfe_num" == "$nfe_arq" ]]; then
      echo $nfe_num$nfe_end >> ./logs/log_notas_mantidas.txt
    fi

  fi

done < $file
printf "[Ok]\n"

# Convertendo PDFs em TXT
pdftotext -layout ./config/pdfs/notas.pdf ./config/txts/pdf.txt
cat ./config/txts/pdf.txt | grep -E '^\s*[0-9][0-9][0-9][0-9][0-9][0-9]' | sed 's/^\s*//g' >> ./config/txts/pdf_formatado.txt

# Gerndo as listas das notas
file="./config/txts/pdf_formatado.txt"
while IFS= read -r line; do
  if [[ "$line" == *"/"* ]]; then
    num_1=$(echo "$line" | awk '{print $1}' | bc)
    num_2=$(echo "$line" | awk '{print $3}' | bc)
    while [ "$num_1" -le $num_2 ]; do
      #printf "gerando nota %06d\n" $num_1
      printf "%06d\n" $num_1 >> ./config/txts/notas.txt
      num_1=$((num_1 + 1))
    done
  else
    num_1=$(echo "$line" | awk '{print $1}' | bc)
    #printf "gerando nota %06d\n" $num_1
    printf "%06d\n" $num_1 >> ./config/txts/notas.txt
  fi
done < $file

# Copiando notas para os contadores
ls ./notas/cliente >> ./config/txts/notas_cliente.txt
file="./config/txts/notas_cliente.txt"
printf "  Separando notas para os contadores...... "

while IFS= read -r line; do

  if [[ -f ./notas/cliente/"$line" ]]; then
    mv -f ./notas/cliente/$line ./notas/contabilidade
    echo $line >> ./logs/log_notas_copiadas.txt
  fi

done < $file
printf "[Ok]\n"

# Coletando dados para o relatório
if [[ -f "./logs/log_notas_renomeadas.txt" ]]; then
    notas_renomeadas=$(wc -l ./logs/log_notas_renomeadas.txt | awk '{print $1}' | bc)
fi
notas_renomeadas=0
notas_cliente=$(wc -l ./logs/log_notas_cliente.txt | awk '{print $1}' | bc)
notas_mantidas=$(wc -l ./logs/log_notas_mantidas.txt | awk '{print $1}' | bc)


# Criando pastas no Desktop
printf "  Copiando arquivos para o Desktop........ "
base_dir=$(wslpath "$(wslvar USERPROFILE)")
mkdir -p "$base_dir"/Desktop/Notas/Clientes
mkdir -p "$base_dir"/Desktop/Notas/Clientes/$nome_cliente
mkdir -p "$base_dir"/Desktop/Notas/Clientes/$nome_cliente/logs
mkdir -p "$base_dir"/Desktop/Notas/Clientes/$nome_cliente/contabilidade
mkdir -p "$base_dir"/Desktop/Notas/Clientes/$nome_cliente/pdfs

# Movendo arquivos para o Desktops
mv ./logs/* "$base_dir"/Desktop/Notas/Clientes/$nome_cliente/logs
mv ./notas/contabilidade/* "$base_dir"/Desktop/Notas/Clientes/$nome_cliente/contabilidade
mv ./config/pdfs/notas.pdf "$base_dir"/Desktop/Notas/Clientes/$nome_cliente/pdfs

# Limpando o script
rm -rf ./config/txts/*
printf "[Ok]\n"
echo

# Imprimendo o relatório na tela
printf "  Notas analisadas...: $notas_cliente \n"
echo
printf "  Notas mantidas.....: $notas_mantidas \n"
printf "  Notas renomeadas...: $notas_renomeadas \n"
echo