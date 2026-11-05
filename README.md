# CrystalOS para CC:Tweaked

CrystalOS e um ambiente de desktop para computadores do Minecraft Java com CC:Tweaked.

## Instalar
Ative HTTP nas configuracoes do mundo/servidor e execute:
`wget run https://raw.githubusercontent.com/nicolastdr/CrystalOS/main/crystal_installer.lua`

## Atualizar
O carregador executa o atualizador na inicializacao. O atualizador consulta `manifest.txt`, prepara os arquivos em uma pasta temporaria e aplica a atualizacao. Os dados do usuario ficam fora do manifesto.

## Versao 0.6.0
- Logos dos aplicativos desenhadas como quatro pixels independentes (grade 2x2), cada pixel com sua propria cor.
- Editor de logos acessivel pela tecla **L** no desktop. Permite escolher quatro cores e um pequeno texto/rotulo para cada app.
- Preferencias das logos armazenadas em `/CrystalOS/user/logos`.
- Implementacoes iniciais utilizaveis para os 26 itens do catalogo, com armazenamento local para documentos, tarefas, planilhas CSV, diagramas, fluxos, projetos, modelos textuais e notas.
- Busca de arquivos, diagnostico, catalogo, editor de projetos, pacote proprio .car, comunicacao Rednet quando existe modem, e jogo simples incluidos.

## Limites funcionais conhecidos
Esta versao nao equivale a 26 aplicativos completos de escritorio. Alguns modulos sao ferramentas textuais iniciais:
- Flow Studio, Crystal Space, MindSpace, Crystal Motion e Crystal 3D Lab salvam projetos textuais; nao possuem editor visual completo nem motor de animacao/3D.
- Crystal Archive cria pacotes proprios `.car`; nao cria ZIP interoperavel.
- Crystal Store e Crystal Hub exibem o catalogo; nao fazem instalacao remota de apps.
- Crystal Vault organiza arquivos numa pasta local, mas **nao criptografa** os dados.
- Crystal Link detecta e abre Rednet se houver modem; nao oferece ainda mensageria completa.
- Crystal Capture informa a limitacao: CraftOS nao fornece uma API universal para capturar a tela do computador.
- Crystal AppForge cria um arquivo de projeto; ainda nao compila nem instala aplicativos dinamicos no catalogo.
- Crystal Sheets salva dados CSV em texto; ainda nao e uma planilha grafica com celulas editaveis.

O gerenciador de janelas independentes, redimensionamento, minimizar/maximizar, Snap Layouts, tela de login e desktop grafico completo ainda nao estao implementados. A interface e baseada no terminal colorido do CC:Tweaked, nao e pixel-perfect como Windows 11.

## Testes
A publicacao e os tamanhos dos arquivos no manifesto foram verificados no GitHub. Ainda nao foi executada em CraftOS-PC nem no Minecraft com CC:Tweaked. Teste primeiro num computador de mundo de teste e mantenha backup dos dados importantes.
