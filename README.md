# CrystalOS para CC:Tweaked

CrystalOS e um ambiente de desktop para computadores do Minecraft Java com CC:Tweaked.

## Instalar
Ative HTTP nas configuracoes do mundo/servidor e execute:
`wget run https://raw.githubusercontent.com/nicolastdr/CrystalOS/main/crystal_installer.lua`

## Atualizar
O carregador executa o atualizador na inicializacao. O atualizador consulta `manifest.txt`, prepara os arquivos em uma pasta temporaria e aplica a atualizacao. Os dados do usuario ficam fora do manifesto.

## Versao 0.4.0
Introduz um desktop escuro e um catalogo central com todos os aplicativos planejados. Explorador, Notepad, Calculadora, Terminal e Configuracoes mantem funcoes basicas. Os demais aparecem como modulos registrados, mas estao marcados como Planejado ou MVP e ainda nao possuem todos os recursos.

## Limites
A interface usa o terminal colorido do CC:Tweaked; ainda nao e um desktop grafico pixel-perfect como Windows 11. Esta versao ainda precisa de testes no CraftOS-PC e no CC:Tweaked dentro do Minecraft.