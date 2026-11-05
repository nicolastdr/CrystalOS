# CrystalOS para CC:Tweaked

CrystalOS e um ambiente de desktop multitarefa para computadores do Minecraft Java com CC:Tweaked.

## Instalar
Ative HTTP nas configuracoes do mundo/servidor e execute:
`wget run https://raw.githubusercontent.com/nicolastdr/CrystalOS/main/crystal_installer.lua`

## Atualizar
O carregador executa o atualizador na inicializacao. O atualizador consulta manifest.txt, prepara os arquivos em uma pasta temporaria e aplica a atualizacao. Os dados do usuario ficam fora do manifesto.

## Versao 0.9.0
- Desktop com papel de parede pixel-art integrado.
- Tela inicial mostra apenas atalhos favoritos, separados do catalogo completo.
- Atalhos podem ser adicionados com a tecla A, removidos com Delete/Backspace e movidos com o mouse.
- Clique duplo abre atalhos; Enter abre o atalho selecionado.
- Botao Iniciar abre a pesquisa/lista de aplicativos.

## Versao 0.8.0
- Desktop compacto com logos 2x2 e nomes abaixo ou ao lado, conforme a preferencia salva.
- Barra de tarefas com atalhos Iniciar, Pesquisar e botoes para alternar entre aplicativos abertos.
- Pesquisa de aplicativos por nome ou ID, com filtragem enquanto digita; corrigido o tratamento dos eventos de mouse.
- Gerenciador multitarefa com uma coroutine por aplicativo e uma janela/area de terminal independente.
- Janelas podem ser movidas pela barra de titulo, minimizadas, restauradas, maximizadas e fechadas.
- Clique nos icones do desktop para abrir aplicativos; Tab alterna o foco entre janelas.
- Dados pessoais e logos continuam fora da lista de arquivos substituidos pelo atualizador.

## Limites funcionais
A interface e baseada no terminal colorido do CC:Tweaked, nao e pixel-perfect como Windows 11. O tamanho e a resolucao das janelas dependem do terminal ou monitor conectado. O redimensionamento livre, Snap Layouts e suporte a janelas graficas com pixels nao estao incluidos.
Os aplicativos existentes ainda variam de ferramentas iniciais a MVPs; nem todos sao equivalentes a programas completos de escritorio. Crystal Archive usa formato proprio .car, Crystal Vault nao criptografa, Crystal Store ainda e um catalogo e alguns editores guardam projetos em texto.

## Testes
A publicacao e os tamanhos dos arquivos no manifesto sao verificados no GitHub. A versao 0.9.0 ainda precisa de teste de execucao no CraftOS-PC e no Minecraft com CC:Tweaked. Teste primeiro num computador de mundo de teste e mantenha backup dos dados importantes.
