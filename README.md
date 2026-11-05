# CrystalOS para CC:Tweaked

Sistema inicial de desktop para computadores do Minecraft Java com CC:Tweaked.

## Instalacao online
1. Ative HTTP nas configuracoes do mundo/servidor.
2. No computador, execute:
   `wget run https://raw.githubusercontent.com/nicolastdr/CrystalOS/main/crystal_installer.lua`
3. Aguarde o instalador e reinicie o computador.

Alternativamente, baixe `crystal_installer.lua` e execute `crystal_installer`.

## Atualizacoes
O `startup.lua` executa `crystal_updater.lua` em cada inicializacao. O atualizador consulta `manifest.txt`, baixa a versao completa para uma pasta temporaria e so depois aplica os arquivos. Se um download falhar, a instalacao existente e mantida. Em caso de falha ao substituir arquivos, o atualizador tenta restaurar o backup.

Os arquivos de usuario em `/.crystal/data` e `/CrystalOS/user` nao fazem parte da lista de arquivos do sistema e nao sao apagados por atualizacoes. O atualizador exige HTTP e internet; sem conexao, inicia a versao instalada.

## Limites desta versao
- A interface atual usa o terminal de caracteres do CC:Tweaked; nao e uma implementacao grafica pixel-perfect do Windows.
- A verificacao de integridade usa tamanho dos arquivos, nao hash criptografico.
- O projeto ainda precisa de teste dentro do Minecraft/CC:Tweaked.
