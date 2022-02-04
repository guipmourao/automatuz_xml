#!/bin/bash
#

# Debug
#set -x
#trap read debug

# Faz upload de arquivos para o linux
printf "  Fazendo upload de arquivos.............. "
base_dir=$(wslpath "$(wslvar USERPROFILE)")
ls "$base_dir"/Desktop/Notas/Upload/notas/* >> ./config/txts/upload.txt
upload=$(wc -l ./config/txts/upload.txt | awk '{print $1}' | bc)
mv "$base_dir"/Desktop/Notas/Upload/pdfs/* ./config/pdfs/notas.pdf
mv "$base_dir"/Desktop/Notas/Upload/notas/* ./notas/cliente
printf "[Ok]\n"
echo

# Imprimendo o relatório na tela
printf "  Notas copiadas.....: $upload \n"
echo