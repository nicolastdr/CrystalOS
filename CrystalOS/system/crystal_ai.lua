-- Crystal Micro AI 0.1 - CrystalOS / CC:Tweaked
-- Intent classification, Portuguese vocabulary, persistent memory, optional Wiktionary.
local AI={}
local DIR="/CrystalOS/user/crystal_ai"
local DB=DIR.."/memory.db"
local CACHE=DIR.."/dictionary.db"
local function load(path,default)
 if not fs.exists(path) then return default end
 local f=fs.open(path,"r"); if not f then return default end
 local s=f.readAll(); f.close(); local ok,t=pcall(textutils.unserialize,s)
 if ok and type(t)=="table" then return t end
 return default
end
local function save(path,t)
 if not fs.exists(DIR) then fs.makeDir(DIR) end
 local f=fs.open(path,"w"); if not f then return false end
 f.write(textutils.serialize(t)); f.close(); return true
end
local mem=load(DB,{facts={},dict={}})
local cache=load(CACHE,{})
local accents={["á"]="a",["à"]="a",["ã"]="a",["â"]="a",["é"]="e",["ê"]="e",["í"]="i",["ó"]="o",["õ"]="o",["ô"]="o",["ú"]="u",["ç"]="c",["Á"]="a",["À"]="a",["Ã"]="a",["Â"]="a",["É"]="e",["Ê"]="e",["Í"]="i",["Ó"]="o",["Õ"]="o",["Ô"]="o",["Ú"]="u",["Ç"]="c"}
local function norm(s)
 s=tostring(s or ""):lower()
 for a,b in pairs(accents) do s=s:gsub(a,b) end
 s=s:gsub("[%p%c]"," "):gsub("%s+"," ")
 return " "..s:gsub("^%s+",""):gsub("%s+$"," ").." "
end
local stop={a=1,o=1,os=1,as=1,um=1,uma=1,de=1,do=1,da=1,dos=1,das=1,em=1,no=1,na=1,nos=1,nas=1,por=1,para=1,com=1,sem=1,e=1,ou=1,que=1,eu=1,voce=1,me=1,meu=1,minha=1,pode=1,poderia=1,quero=1,gostaria=1,preciso=1}
local function words(s)
 local t={}; for w in norm(s):gmatch("%S+") do if #w>1 and not stop[w] then t[#t+1]=w end end; return t
end
local function sim(a,b)
 if a==b then return 1 end
 if #a<4 or #b<4 then return 0 end
 if a:find(b,1,true) or b:find(a,1,true) then return .75 end
 local p={}; for j=0,#b do p[j]=j end
 for i=1,#a do local c={[0]=i}; for j=1,#b do local cost=a:sub(i,i)==b:sub(j,j) and 0 or 1; c[j]=math.min(c[j-1]+1,p[j]+1,p[j-1]+cost) end; p=c end
 return 1-p[#b]/math.max(#a,#b)
end
local intents={
 {id="cumprimento",terms={"oi","ola","eai","iae","salve","bom dia","boa tarde","boa noite","fala"},reply="Ola! Sou a Crystal AI. Sobre o que vamos conversar?"},
 {id="despedida",terms={"tchau","ate mais","falou","flw","fui","adeus"},reply="Ate mais! Estarei aqui quando voltar."},
 {id="agradecimento",terms={"obrigado","obrigada","valeu","vlw","agradeco"},reply="Por nada! Fico feliz em ajudar."},
 {id="identidade",terms={"quem e voce","qual seu nome","seu nome","quem e crystal"},reply="Sou a Crystal Micro AI, assistente local do CrystalOS. Identifico intencoes, consulto vocabulario e guardo memoria."},
 {id="ajuda",terms={"ajuda","como funciona","o que voce faz","comandos"},reply="Converse normalmente. Exemplos: 'defina algoritmo', 'lembre que meu projeto e CrystalOS', 'o que voce lembra?' e 'quanto e 12 vezes 8'."},
 {id="lembrar",terms={"lembre que","memorize que","guarde que","anote que"},reply="REMEMBER"},
 {id="memoria",terms={"o que voce lembra","mostre sua memoria","o que guardou","lembra de mim"},reply="MEMORY"},
 {id="definicao",terms={"defina","o que significa","significado de","quer dizer","conceito de","dicionario"},reply="DEFINE"},
 {id="calculo",terms={"quanto e","calcule","calcular","resultado de","vezes","dividido por"},reply="CALCULATE"},
 {id="hora",terms={"que horas sao","hora agora","horario atual"},reply="TIME"},
 {id="abrir_app",terms={"abra","abrir","inicie","iniciar","execute","executar"},reply="Entendi que voce quer abrir um aplicativo. A execucao por linguagem natural sera conectada ao gerenciador de aplicativos em uma etapa posterior."},
 {id="emocao",terms={"estou triste","estou feliz","estou cansado","estou ansioso","estou entediado"},reply="Entendi. Se quiser, pode me contar mais. Vou tentar ajudar."}
}
local function classify(input)
 local msg=norm(input); local best,score=nil,0; local inputWords=words(input)
 for _,it in ipairs(intents) do
  local n=0
  for _,term in ipairs(it.terms) do
   if msg:find(norm(term),1,true) then
    local count=0; for _ in term:gmatch("%S+") do count=count+1 end
    n=math.max(n,1.1+count*.8)
   else
    local tw=words(term); local hits=0
    for _,w in ipairs(tw) do local m=0; for _,iw in ipairs(inputWords) do m=math.max(m,sim(w,iw)) end; if m>=.78 then hits=hits+m end end
    if #tw>0 then n=math.max(n,(hits/#tw)*1.65) end
   end
  end
  if n>score then best,score=it,n end
 end
 if score<1.05 then return nil,score end
 return best,math.min(.99,score/2.8)
end
local function extract(input,phrases)
 local msg=norm(input)
 for _,p in ipairs(phrases) do
  local _,e=msg:find(norm(p),1,true)
  if e then local rest=input:sub(math.min(#input+1,e+1)):gsub("^%s+",""):gsub("[%?%!%.]+$",""); if rest~="" then return rest end end
 end
end
local function define(term,online)
 local key=norm(term):gsub("^%s+",""):gsub("%s+$","")
 local basic={algoritmo="Sequencia finita de passos para resolver um problema.",inteligencia="Capacidade de aprender, compreender, raciocinar e resolver problemas.",programacao="Processo de criar instrucoes executaveis por um computador.",computador="Dispositivo eletronico que processa dados seguindo instrucoes.",memoria="Capacidade de armazenar e recuperar informacoes.",linguagem="Sistema de sinais usado para comunicar ideias.",internet="Rede mundial que conecta dispositivos e permite trocar informacoes."}
 if mem.dict[key] then return mem.dict[key] end
 if basic[key] then return basic[key] end
 if not online or not http then return nil,"Nao encontrei no vocabulario offline." end
 if cache[key] then return cache[key] end
 local encoded=key:gsub("([^%w%-_%.~])",function(c) return string.format("%%%02X",string.byte(c)) end)
 local ok,h=pcall(http.get,"https://pt.wiktionary.org/w/api.php?action=query&prop=extracts&explaintext=1&titles="..encoded.."&format=json")
 if not ok or not h then return nil,"Falha ao consultar o Wikcionario." end
 local raw=h.readAll(); h.close(); local good,data=pcall(textutils.unserializeJSON,raw)
 if not good or type(data)~="table" then return nil,"Resposta do dicionario invalida." end
 for _,page in pairs(data.query and data.query.pages or {}) do
  if type(page.extract)=="string" and page.extract~="" then cache[key]=page.extract:sub(1,1600); save(CACHE,cache); return cache[key] end
 end
 return nil,"Definicao nao encontrada."
end
local function remember(input)
 local p=extract(input,{"lembre que","memorize que","guarde que","anote que"})
 if not p then return false end
 local k,v=p:match("^(.-)%s+e%s+(.+)$"); if not k then k,v=p:match("^(.-)%s*:%s*(.+)$") end
 if not k or k=="" or not v then return false end
 mem.facts[k]=v; save(DB,mem); return true
end
local function calc(input)
 local s=norm(input); local a,b,op
 a,b=s:match(" (%-?%d+)%s+mais%s+(%-?%d+)"); op="+"
 if not a then a,b=s:match(" (%-?%d+)%s+menos%s+(%-?%d+)"); op="-" end
 if not a then a,b=s:match(" (%-?%d+)%s+vezes%s+(%-?%d+)"); op="*" end
 if not a then a,b=s:match(" (%-?%d+)%s+dividido por%s+(%-?%d+)"); op="/" end
 if not a then a,op,b=s:match(" (%-?%d+)%s*([%+%-%*/])%s*(%-?%d+)") end
 if not a then return nil end
 a,b=tonumber(a),tonumber(b)
 if op=="+" then return a+b elseif op=="-" then return a-b elseif op=="*" then return a*b elseif op=="/" then if b==0 then return "Nao se divide por zero." end; return a/b end
end
local function reply(input,online)
 local it,confidence=classify(input)
 if not it then
  local m=norm(input); for k,v in pairs(mem.facts) do if m:find(norm(k),1,true) then return "Lembro que "..v,"memoria",.65 end end
  return "Ainda nao tenho conhecimento suficiente para responder isso. Voce pode me ensinar uma definicao com /ensinar palavra = explicacao.","nao_identificada",confidence
 end
 if it.id=="lembrar" then return remember(input) and "Informacao guardada na memoria permanente." or "Use: lembre que meu projeto e CrystalOS.",it.id,confidence end
 if it.id=="memoria" then local t={}; for k,v in pairs(mem.facts) do t[#t+1]=k.." = "..v end; return (#t==0 and "Minha memoria esta vazia." or table.concat(t,"\n")),it.id,confidence end
 if it.id=="definicao" then local term=extract(input,{"defina","significado de","o que significa","conceito de","dicionario"}); if not term then return "Qual palavra devo definir?",it.id,confidence end; local d,e=define(term,online); return d and (term..": "..d) or e,it.id,confidence end
 if it.id=="calculo" then local r=calc(input); return r~=nil and ("Resultado: "..tostring(r)) or "Exemplos: 12 mais 8; 9 vezes 7; 100 dividido por 4.",it.id,confidence end
 if it.id=="hora" then return "Agora sao "..textutils.formatTime(os.time(),true)..".",it.id,confidence end
 return it.reply,it.id,confidence
end
function AI.run(ui)
 local online=true
 while true do
  ui.clear(); ui.header("Crystal AI")
  print("Assistente local | sem API paga")
  print("Dicionario online opcional: Wikcionario")
  print("/ajuda /online /offline /sair")
  print("")
  write("Voce > "); local input=read()
  if not input or input=="/sair" then return end
  if input=="/ajuda" then ui.message("Crystal AI","Converse naturalmente.\nExemplos:\nDefina algoritmo\nLembre que meu projeto e CrystalOS\nO que voce lembra?\nQuanto e 12 vezes 8?\n/ensinar palavra = definicao\n/online e /offline controlam consultas web.")
  elseif input=="/online" then online=true; ui.message("Crystal AI","Consulta opcional ao Wikcionario ativada.")
  elseif input=="/offline" then online=false; ui.message("Crystal AI","Consultas online desativadas.")
  elseif input:sub(1,9)=="/ensinar " then local k,v=input:sub(10):match("^(.-)%s*=%s*(.+)$"); if k and v then mem.dict[norm(k):gsub("^%s+",""):gsub("%s+$","")]=v; save(DB,mem); ui.message("Aprendizado","Definicao salva localmente.") else ui.message("Aprendizado","Use /ensinar palavra = definicao") end
  else
   local ok,r,id,c=pcall(reply,input,online)
   if ok then ui.message("Crystal AI",tostring(r).."\n\n[Intencao: "..tostring(id).." | confianca aproximada: "..math.floor((c or 0)*100).."%]")
   else ui.message("Crystal AI","Erro: "..tostring(r)) end
  end
 end
end
return AI
