# HAVOK — Especificação de Agente

Transformação do HAVOK de gerador de conteúdo em agente presente no app.

Complementa `REDESIGN_SPEC.md` e `BACKLOG_FUNCIONAL.md`. Todo o conteúdo aqui é
**[F]** — depende de código. Nada bloqueia a fase visual do redesign, exceto os
slots visuais marcados na seção 3, que já nascem no redesign como componente.

Base do diagnóstico: relatório de estado atual gerado em 31/07/2026.

---

## 1. Diagnóstico

HAVOK hoje **gera, mas não age e não interpreta**:

- **Gera** — produz treino e receita via Gemini. Funciona.
- **Age** — muda o estado do app (vira template, entra no plano, inicia sessão). Não faz.
- **Interpreta** — lê os dados do usuário e diz algo útil. Não faz.

Três promessas falsas no app hoje:

| Onde | Promete | Faz |
|---|---|---|
| Onboarding | "Montando sua divisão com o HAVOK…" | Só animação. Plano nasce vazio. |
| Match tracker | "Gerar ficha de treino com Havok" | Dois `Navigator.pop()` |
| Hub → treino gerado | Implícito: treinar | Lista de exercícios sem saída |

Promessa falsa é pior que ausência: treina o usuário a ignorar o nome.

---

## 2. Camadas do agente

Ordem de construção. Cada uma depende da anterior.

| # | Camada | O que é | Custo |
|---|---|---|---|
| 1 | **Contexto** | Saber quem é o usuário e o que aconteceu | Baixo — o dado já existe |
| 2 | **Interpretação** | Transformar dado em frase útil | Baixo — sem tools, sem chat |
| 3 | **Ação** | Criar treino, ajustar plano, registrar refeição | Médio — exige function calling |
| 4 | **Conversa** | Perguntar qualquer coisa | Alto — exige as três acima |

A tentação é começar pela 4 porque é o que se vê. Sem as camadas abaixo, é um
chatbot genérico com pantera.

### Contexto disponível (já existe no banco)

`onboarding_data` · histórico de treinos · plano da semana e aderência ·
diário nutricional e IQD · macros dos últimos dias · peso e medidas · streak ·
XP e nível · atividade no Club · protocolos ativos

Isso é mais variedade de dado do que a Whoop Coach tem. Não é preciso construir
nada para a camada 1 — é SELECT.

---

## 3. Onde o HAVOK vive

**HAVOK não é uma tela, é uma camada.** O ganho está em aparecer onde o usuário
já está, com o contexto daquela tela.

### 3.1 Card de insight (proativo)

Componente novo do design system. Assinatura visual: barra dourada vertical à
esquerda, avatar circular pequeno da pantera, palavra HAVOK em micro-caps.
Estrutura: **título → explicação → ação executável**. Dismissível.

O que o diferencia de um texto qualquer é a ação. "Três dias sem treinar" com
botão "Reorganizar semana" é agente; sem o botão é aviso.

**Regras:**
1. Máximo **um** por tela
2. Só renderiza quando há algo relevante a dizer — não existe insight obrigatório
3. Dispensar tem memória: dispensou hoje, não volta hoje

**Onde aparece:**

| Tela | Assunto |
|---|---|
| Dashboard | Situação da semana |
| Nutrição | **Substitui a dica do IQD** já desenhada no redesign (N4) |
| Meu Plano | Reorganização quando há dias perdidos |
| Progresso | Leitura da tendência do período |
| Treinos | Ajuste de volume, grupo negligenciado |

> O redesign já criou esses slots com lógica estática. Trocar o gerador daquelas
> frases pelo HAVOK é a implantação de maior impacto e menor custo do projeto.

### 3.2 Ponto de entrada (sob demanda)

**Ícone da pantera no header** das telas principais, com ponto dourado quando há
insight novo.

**Não usar FAB flutuante.** O slot visual equivalente ao do Whoop já está ocupado
pelo botão central do BLDR CLUB na tab bar; dois círculos flutuantes competindo
confundem a ação principal, e o FAB cobre conteúdo em telas longas (Nutrição com
6 refeições, Progresso).

O FAB da pantera **permanece dentro do Club**, onde não há competição e ele já é
a porta do hub.

**Não criar uma sexta aba.** As cinco posições estão ocupadas e a central é o Club.

### 3.3 Formato de abertura

| Origem | Formato |
|---|---|
| Ícone no header | Bottom sheet (~90% da tela) |
| Card de insight → ação | Bottom sheet, já com o contexto |
| FAB da pantera no Club | Tela cheia |
| Botão expandir dentro da sheet | Promove para tela cheia |

Racional: pelo header, o usuário está no meio de outra coisa e quer resposta
rápida — perder a tela é atrito que desencoraja uso casual, e uso casual é o que
vira hábito. Pelo Club, ele foi até o HAVOK de propósito.

Sheet sempre pode virar tela cheia; o contrário, não.

---

## 4. Conversa e memória

Três coisas distintas, frequentemente confundidas:

### 4.1 Continuidade da thread — **fazer agora**
A conversa não reinicia ao fechar a sheet. Persistida em tabela, sobrevive ao
fechamento do app.

### 4.2 Contexto injetado por mensagem — **fazer agora**
Antes de cada chamada, o backend monta o prompt com os dados do usuário. É o que
permite abrir com "2 de 6 treinos, proteína 22% abaixo há 4 dias".
**Não guarda nada** — é SELECT. Vocês já fazem isso parcialmente em
`gerar-treino-havok`, que lê `onboarding_data`.

### 4.3 Memória de longo prazo — **adiar**
Lembrar de fatos contados ("machuquei o ombro", "não como lactose"). Exige
extração de fatos, recuperação seletiva e resolução de contradições. É um sistema
à parte. As camadas 4.1 e 4.2 cobrem ~80% da percepção de inteligência.

### 4.4 Regra de sessão (resolve o conflito contexto × continuidade)

Saudação contextual é comportamento de **thread vazia**, não de toda abertura.

| Situação | Comportamento |
|---|---|
| Thread vazia | Saudação contextual da tela de origem |
| Thread ativa, mesmo dia — inclusive vindo de outra tela | **Continua de onde parou.** Sem saudação nova. Só as sugestões mudam |
| Virada do dia | Nova sessão com saudação. Histórico acessível rolando para cima |

Corte por **virada do dia**, não por horas: é previsível e casa com o resto do app,
que já é organizado por dia (nutrição, plano, streak).

**Recursos visuais que evitam confusão:**
- Marcador de origem no histórico: "Mais cedo · Dashboard"
- Divisor de mudança de contexto: "Agora em Nutrição"
- Mensagens antigas com opacidade reduzida
- Sugestões contextuais como cards com dado real ("Faltam 68 g de proteína hoje")

> **Descartado:** threads separadas por tela. Resolveria a confusão mas criaria
> outra pior — o usuário nunca saberia qual HAVOK sabe o quê.

### 4.5 Custo da thread

Cada mensagem reenvia o histórico. Conversa de 40 turnos custa muito mais que a
primeira. **Janela deslizante (últimas N mensagens) + resumo do que ficou para
trás precisa estar no desenho desde o início.**

### 4.6 Privacidade

Conversa é dado sensível de saúde: lesão, peso, alimentação, possivelmente
conteúdo pessoal.

- RLS por `user_id`, como o resto
- Política de retenção definida
- Exclusão amarrada ao "Excluir conta" das Configurações

---

## 5. Limites

### 5.1 Nunca — sem exceção

Não negociáveis por preferência do usuário nem por modo de intensidade:

- **Diagnóstico e tratamento.** Não nomeia lesão, não indica remédio ou dose, não avalia sintoma.
- **Déficit calórico agressivo ou meta de peso perigosa.** Mesmo sob insistência.
- **Validação de comportamento restritivo.** Jejum prolongado para emagrecer, "compensar" comida com treino extra, pular refeição para bater meta.
- **Suplementação além do básico.** Whey, creatina e cafeína são consenso e pode falar. Termogênico, hormônio, qualquer coisa com prescrição — não.
- **Treinar com dor.** Nunca diz para continuar quando há dor relatada durante o movimento.

### 5.2 Com cuidado — recusa a parte perigosa, entrega o resto

**Recusa sem alternativa é beco sem saída.** O padrão é sempre "não faço X, mas faço Y".

| Situação | Comportamento |
|---|---|
| Dor relatada | Não avalia. Adapta o treino contornando a região + recomenda avaliação profissional. *"Não consigo avaliar a dor, mas dá pra treinar sem sobrecarregar o ombro. Montei uma versão sem movimento acima da cabeça. Se persistir, vale um fisio."* |
| Meta de perda irreal | Não monta. Reancora com prazo saudável e oferece montar assim. |
| Sinais de relação problemática com comida | Não reforça, **não fornece números**, redireciona com cuidado. |
| Retorno de lesão | Pode adaptar volume, nunca contra orientação médica mencionada pelo usuário. |
| Perfil indica menor de idade | Sem protocolo intenso, sem meta de emagrecimento. |

### 5.3 Livre

Técnica de exercício · montagem e ajuste de treino · explicação de conceito ·
leitura dos dados do próprio usuário · sugestão de refeição dentro das metas ·
motivação.

### 5.4 Salvaguardas específicas de transtorno alimentar

O app tem contagem de calorias, peso, IQD e streaks — o conjunto exato de
recursos usados de forma problemática por pessoas com TA.

- Nunca sugere meta abaixo de um piso definido
- Nunca comenta peso de forma valorativa
- Ao detectar padrão de restrição severa: para de dar números e redireciona

> Verificar alinhamento com a política já existente nas metas do app.

### 5.5 Disclaimer

Linha discreta no rodapé do hub:
*"HAVOK é uma IA e pode errar. Não substitui orientação médica ou nutricional."*

### 5.6 Implementação dos limites

Prompt vaza. Precisa de duas camadas:

1. **Prompt de sistema** com as regras, injetado em toda chamada
2. **Validação no backend** para o quantificável: resposta com meta calórica abaixo do piso não passa

Casos de recusa viram **teste de unidade** — é o tipo de comportamento que
regride silenciosamente quando alguém mexe no prompt.

---

## 6. Tom

⚠️ **Decisão pendente.**

Existe uma tensão não resolvida: a linguagem do Club é militar e agressiva
("Central de Operações", "Squad Operante", "Alistar-se", "Tribunal", modo
"Survivor" com eliminação, "DESAFIE O HAVOK"). Já o redesign removeu
deliberadamente o tom punitivo ("Perdido" em vermelho → "Não feito" neutro),
porque app de fitness que repreende aumenta abandono.

Se o HAVOK fala em todas as telas, essas duas coisas não coexistem sem decisão.

**Recomendação:** técnico como padrão, intensidade opcional nas preferências.
O HAVOK observa e propõe; a agressividade fica confinada ao Club, onde é opt-in e
faz parte do jogo.

**Risco de não decidir:** HAVOK neutro no Dashboard e agressivo no Club vira dois
personagens.

**Padronizar também o nome.** Hoje aparece como "HAVOK", "Havok", "a HAVOK"
(onboarding) e "o Havok" (outros pontos). Escolher caixa e gênero.

---

## 7. Momentos de aparição

### 7.1 Onboarding — gerar o plano de verdade

Substitui a animação falsa. É o momento de **maior contexto disponível em toda a
jornada** (objetivo, experiência, frequência, equipamentos, split acabaram de ser
coletados) e hoje está desperdiçado.

**Tela de geração:** etapas refletindo trabalho real, cada uma devolvendo o que o
usuário informou ("Objetivo: ganho de massa", "6 dias · academia completa").
Se forem timers encadeados, é a mesma mentira com visual melhor.

**Tela de resultado:** semana montada + treino de hoje + metas nutricionais
calculadas (que o app já usa mas o usuário nunca viu nascer).

- **"Quero outra divisão"** como ação secundária visível. Sem isso, o usuário começa com um plano que não quer e abandona na primeira semana. Com isso, aprende desde o início que o HAVOK é ajustável.
- **"Pode ajustar tudo depois"** reduz ansiedade de decisão.
- Sai do onboarding direto para o Dashboard com o hero card preenchido.

**Fallback:** se a geração falhar, plano padrão da biblioteca com mensagem honesta.
Nunca mostrar "pronto" sem estar. Ainda assim é melhor que o estado atual (vazio).

> Este item força a construção da cadeia de execução (§8.1): se o plano gerado no
> onboarding precisa ser executável, o treino gerado precisa virar template.

### 7.2 Pós-treino

O melhor momento emocional do app e hoje ninguém ocupa. Comentário com dado real:
*"48 min, seu Legs mais longo até agora — 8 min acima da média."*
Barato, é interpretação pura, e chega quando a pessoa está mais receptiva.

### 7.3 Limpeza de promessas falsas

- **Match tracker:** remover a faixa ou ligá-la de verdade
- **Arena:** "Diretrizes do HAVOK" são texto estático — renomear ou gerar de fato

---

## 8. Ordem de implantação

### 8.1 Cadeia de execução — **primeiro, é o desbloqueio**
Treino gerado vira template → entra no plano → inicia sessão.
Sem isso nada acima importa: o usuário gera e não consegue treinar.
(Item 2 do relatório de estado atual.)

### 8.2 Insights nos slots existentes
HAVOK assume os slots que o redesign já criou. Interpretação pura, sem chat, sem
function calling. Maior impacto percebido pelo menor custo.

### 8.3 Onboarding com geração real
Depende de 8.1.

### 8.4 Sheet com conversa e contexto
Camadas 4.1 e 4.2. Ainda sem ação.

### 8.5 Ação sob comando
Function calling: "reorganiza minha semana", "troca o treino de hoje por algo de
30 min", "adiciona isso no almoço".

### 8.6 Memória de longo prazo
Só com dado de uso real para saber o que vale a pena lembrar.

---

## 9. Bloqueadores antes de lançar

| # | Item | Por quê |
|---|---|---|
| 1 | **Paywall real** | `panther_fab.dart:17` tem `isPremiumUser = true` hardcoded. HAVOK é provavelmente o maior argumento de venda do Club e está liberado para todos. **Sugestão: insight gratuito (isca), conversa e geração pagas** — o usuário sente o valor antes de pagar. |
| 2 | **Rate limit por plano** | Hoje é dívida pequena; com chat aberto vira risco financeiro direto. Cada mensagem é uma chamada paga. |
| 3 | **Superfície de erro** | 4 telas engolem falha com `print`. O `Failure.message` em pt-BR já existe e não é usado. |
| 4 | **Migrações versionadas** | `havok_workouts` e `havok_recipes` foram criadas direto no painel do Supabase. A tabela de threads não pode repetir isso. |
| 5 | **Testes** | Nenhum teste cobre HAVOK hoje, violando a regra 7 do `CLAUDE.md`. Casos de recusa (§5) são prioridade. |

## 10. Dívidas técnicas a resolver no caminho

Do relatório de estado atual, o que cruza com esta especificação:

- `havok_hub.dart:42` usa `UserService.instance` na presentation — viola a regra 1 do `CLAUDE.md`
- `GenerateHavokWorkout` retorna `Result<void>` e descarta o treino recém-gerado; a biblioteca refaz o SELECT. Round-trip desperdiçado
- Parsing frágil: `fromMap` assume campos não-nulos; `repeticoes` castado para `String` quebra se vier número
- JSON sem contrato forte — usar `responseMimeType: application/json` + response schema do Gemini elimina a classe de erro
- `gerar-treino-havok` e `gerar-treino-livre` são ~90% o mesmo arquivo
- `gerar-plano-performance` está em `UserService` (legado) em vez do `HavokRepository`
- Cores (`goldColor` etc.) vivem dentro de `havok_hub.dart` e são importadas por outras telas — **migrar para `BldrColors`** durante o redesign resolve o acoplamento invertido
