# CrystalOS para CC:Tweaked

CrystalOS e um ambiente de desktop para computadores do Minecraft Java com CC:Tweaked.

## Instalar
Ative HTTP nas configuracoes do mundo/servidor e execute:
`wget run https://raw.githubusercontent.com/nicolastdr/CrystalOS/main/crystal_installer.lua`

## Atualizar
O carregador executa o atualizador na inicializacao. O atualizador consulta `manifest.txt`, prepara os arquivos em uma pasta temporaria e aplica a atualizacao. Os dados do usuario ficam fora do manifesto.

## Versao 0.5.0
- Desktop em formato de blocos/cartoes com navegacao por teclado e clique do mouse (quando o terminal suporta eventos de mouse).
- Identidade visual por aplicativo: cada app recebe um monograma colorido automaticamente.
- Crystal Logo Studio: tecla **L** no desktop permite escolher um aplicativo, definir um simbolo de ate dois caracteres e selecionar uma cor.
- Logos personalizados ficam em `/CrystalOS/user/logos` e nao sao apagados pelo atualizador.
- Catalogo continua listando os 26 aplicativos planejados.

## Estado dos recursos
Explorador, Notepad, Calculadora, Terminal e Configuracoes mantem funcoes basicas. Os demais aplicativos aparecem como modulos registrados, mas ainda nao possuem todos os recursos.

O gerenciador de janelas com varias janelas independentes, arrastar/redimensionar, minimizar/maximizar e Snap Layouts ainda nao foi integrado. A interface atual e baseada no terminal colorido do CC:Tweaked; nao e um desktop grafico pixel-perfect como o Windows 11.

## Testes
A publicacao e a consistencia dos tamanhos do manifesto foram verificadas no GitHub. Ainda nao foi executada em um ambiente CraftOS-PC nem dentro do Minecraft com CC:Tweaked.
