# BLDR — Especificação de Redesign

Mudanças tela a tela. Segue o `DESIGN_SYSTEM.md` para tokens e componentes.

## Como ler este documento

Cada item tem uma etiqueta:

- **[V]** — **Visual puro.** Só CSS/markup. Usa dado que já existe. Pode ser feito agora sem tocar em lógica.
- **[F]** — **Requer funcionalidade.** Depende de dado, cálculo ou tela que ainda não existe. Está detalhado no `BACKLOG_FUNCIONAL.md`.

## Regras da fase visual

1. **Nada pode quebrar.** Nenhum item **[V]** remove um campo, altera contrato de dado ou muda navegação existente.
2. **Elemento sem dado fica oculto, não removido.** Onde o redesign esconde algo (card de Duelos, Parceiros), o componente permanece no código com renderização condicional. Volta sozinho quando houver dado.
3. **Itens [F] entram como placeholder estático** ou ficam ocultos até a fase de código. Não bloquear a fase visual por causa deles.
4. **Logo BLDR CLUB não muda.** Ver seção 9 do design system.

---

## ⚠️ Conteúdo dinâmico — não transformar em texto fixo

Os mockups mostram **valores de exemplo**. Todo texto abaixo é gerado em tempo de execução e deve continuar sendo.
Se hoje já existe lógica gerando essa string, **a lógica permanece intacta** — o redesign muda apenas onde e como o texto aparece.

| Onde | Texto no mockup | Origem |
|---|---|---|
| Nutrição → IQD | "Fibras baixas hoje. Vegetais ou grãos integrais melhoram o índice." | **Lógica existente.** Mensagem varia conforme a dieta do dia. Só mudou a apresentação: sem ícone de alerta, sem repetir o número do gauge, redigida como ação. Manter o gerador atual. |
| Nutrição → IQD | Badge "Regular" | Faixa calculada a partir da pontuação |
| Treinos → hero | "Hoje · Legs" | Dia atual dentro do ciclo do plano (Push/Pull/Legs). Dado já existe no plano. |
| Treinos → hero | "Pernas + glúteos" | Nome do treino agendado para hoje |
| Treinos → hero | "8 exercícios · ~50 min" | Contagem e duração estimada do treino |
| Dashboard | "Boa tarde" | Hora do dispositivo |
| Dashboard / Perfil | "faltam 8.221 XP" | `xp_proximo_nivel − xp_atual` |
| Dashboard | "meta 80 kg", "78%" | Meta do usuário e progresso calculado |
| Plano | "Amanhã · Sáb 1/8" | Data relativa ao dia atual |
| Plano | "4 restantes nesta semana" | `total_planejado − concluidos` |
| Comunidade | "+5.371 XP para o #6" | Diferença para a posição imediatamente acima |
| Comunidade → feed | "Concluiu Push A", "Correu 8,2 km" | Ação real registrada — ver F6 |
| Competição | "Termina em 3 dias", "2º na liga" | Prazo e colocação da operação |
| Esportes | "Dia 1 de 4", "25%" | Progresso do protocolo |
| Perfil | "Próxima: Streak 7 dias" | Conquista bloqueada mais próxima — ver F10 |
| Configurações | "Renova em 12 de agosto" | Data de renovação da assinatura |
| Progresso → Corpo | "+1,8 kg nos últimos 90 dias" | Variação no período selecionado |
| Progresso → Nutrição | "Melhorou 8 pontos na semana. Fibras seguem abaixo da meta." | Insight derivado do dado — ver F16 |

**Regra geral:** se o texto contém um número, um nome, uma data ou um nome de treino, ele é dinâmico. Na dúvida, tratar como dinâmico.

**Estados vazios:** todo texto dinâmico precisa de comportamento definido quando não há dado. O padrão é ocultar o elemento, não exibir "0" ou "—" solto. Exceções onde o zero é informativo: streak, contadores de progresso (`0 de 6`).

---

## Global — todas as telas

| # | Mudança | Tipo |
|---|---|---|
| G1 | Fundo `#050505` com glow radial dourado no topo em todas as telas | [V] |
| G2 | Cards sólidos → glass (`rgba(255,255,255,0.05)` + blur + borda 1px) | [V] |
| G3 | Remover borda dupla: card com borda **ou** fundo diferenciado, nunca os dois | [V] |
| G4 | Eliminar verde, azul, laranja, roxo, ciano e rosa. Tudo vira dourado ou neutro | [V] |
| G5 | Tab bar em glass, flutuando sobre o conteúdo rolável | [V] |
| G6 | `isolation: isolate` em containers com `overflow: hidden` + filhos com `backdrop-filter` | [V] |
| G7 | Peso tipográfico máximo 600, apenas em botões e números de destaque | [V] |
| G8 | Sentence case em todos os títulos e botões | [V] |
| G9 | Corrigir "Inicar Treino" → "Iniciar treino" | [V] |
| G10 | Nomes de treino: título curto + detalhe no subtítulo (fim do truncamento) | [V] |

---

## Dashboard

| # | Mudança | Tipo |
|---|---|---|
| D1 | Header compacto: saudação + nome + avatar circular | [V] |
| D2 | Faixa fina de Nível/XP abaixo do nome | [V] |
| D3 | Fileira de chips roláveis: Streak, Treinos/mês, Tempo total, Conquistas | [V] |
| D4 | Card hero "Treino de hoje" com botão primário interno | [V] |
| D5 | Grid 2×2: Peso alvo, Calorias, Macros, Últimos 7 dias | [V] |
| D6 | Macros em 3 linhas empilhadas (P/C/G) com mini-barras | [V] |
| D7 | Gráfico de barras dos últimos 7 dias | [F] |
| D8 | Cards "Consistência" e "Conquistas" grandes removidos (dado migrou para chips e grid) | [V] |
| D9 | Card "Parceiros" oculto enquanto não houver parceiro ativo | [V] |

Ordem final: header → nível/XP → chips → hero do treino → grid 2×2.

---

## Treinos

| # | Mudança | Tipo |
|---|---|---|
| T1 | Header com título + busca | [V] |
| T2 | Semana atual: pontos coloridos → quadrados com estado (ver componente 7.13) | [V] |
| T3 | Card hero do treino de hoje, com rótulo do ciclo. **Rótulo dinâmico** — deriva do dia atual dentro do plano ativo (ex.: "Hoje · Legs"), nunca string fixa | [V] |
| T4 | Biblioteca BLDR em carrossel, cards verticais com área de capa | [V] |
| T5 | Área de capa preparada para foto real do treino | [F] |
| T6 | "Meus treinos" em carrossel com botão "Iniciar" dentro de cada card | [V] |
| T7 | Empty state com borda tracejada | [V] |
| T8 | "Criar treino" e "A partir de foto" como dois botões quadrados lado a lado | [V] |
| T9 | Título "BLDR" centralizado gigante → cabeçalho de seção normal + "Ver tudo" | [V] |

---

## Meu Plano (semana atual)

| # | Mudança | Tipo |
|---|---|---|
| P1 | **Remover badge vermelho "Perdido"** → "Não feito" em cinza, card com opacidade reduzida | [V] |
| P2 | Barra de progresso segmentada só em dourado (sem segmentos vermelhos) | [V] |
| P3 | Timeline vertical com bolinhas conectadas por linha | [V] |
| P4 | Próximo treino destacado com card dourado + halo na bolinha + botão "Ver treino" | [V] |
| P5 | Dia de descanso com borda tracejada e ícone de sono | [V] |

---

## Nutrição

| # | Mudança | Tipo |
|---|---|---|
| N1 | Resumo diário compacto: anel + macros lado a lado no mesmo card | [V] |
| N2 | Carrossel arrastável entre "Resumo diário" e "Qualidade da dieta" (`scroll-snap`) | [V] |
| N3 | Gauge do IQD: remover gradiente arco-íris e ponteiro; arco preenchido em dourado | [V] |
| N4 | Alerta "⚠️ IQD 60/100: Regular. Fibras Baixas" → dica acionável com ícone de lâmpada. **Só muda a apresentação — o gerador de mensagem existente permanece intacto.** Remover o ícone de alerta (não é erro) e a repetição do número que já está no gauge | [V] |
| N5 | Nutrientes do IQD em grid 2×2 com barras, sem bolinhas coloridas | [V] |
| N6 | 6 refeições como linhas horizontais, não cards grandes | [V] |
| N7 | Diferenciação das refeições por ícone, não por cor de topo/botão | [V] |
| N8 | Linha da refeição mostra resumo dos alimentos quando houver ("Ovos, aveia · 430 kcal") | [F] |
| N9 | Atalhos "Foto do prato" e "Buscar alimento" no rodapé | [V] |

### Adicionar alimento (bottom sheet)

| # | Mudança | Tipo |
|---|---|---|
| N10 | Cabeçalho indicando a refeição de destino ("Adicionar em: Café da manhã") | [V] |
| N11 | Categorias em cards horizontais (emoji à esquerda + texto ao lado), 8 visíveis sem scroll | [V] |
| N12 | Chips Recentes/Favoritos/Manual neutros até serem selecionados | [V] |
| N13 | Lista de alimentos sem ícone repetido por item; emoji só no cabeçalho da categoria | [V] |
| N14 | Item da lista mostra porção de referência (100g) | [V] |
| N15 | Macros do item em cor única | [V] |
| N16 | Destaque para "Foto do prato" com identificação automática | [F] |

### Formulário manual

| # | Mudança | Tipo |
|---|---|---|
| N17 | Agrupar em "Essencial" (calorias + 3 macros) e opcional recolhido (sódio, fibras, açúcares) | [V] |
| N18 | Macros em 3 colunas com labels curtos (sem truncamento) | [V] |
| N19 | Label acima do valor, não como placeholder | [V] |
| N20 | Remover ícones decorativos de cada campo | [V] |
| N21 | Rodapé fixo com "Impacto no IQD" + botão primário | [V] |
| N22 | IQD atualiza em tempo real conforme os campos são preenchidos | [F] |

---

## BLDR Club — Hub

| # | Mudança | Tipo |
|---|---|---|
| C1 | **Logo mantida como está.** Glow movido para o fundo da tela (gradiente radial), não removido do asset | [V] |
| C2 | Nível + posição no ranking no mesmo card | [V] |
| C3 | Grid 2×2 de acessos com ícone alinhado à esquerda | [V] |
| C4 | Card do squad com nome, modo e colocação (sem corte na borda) | [V] |
| C5 | Seção "Operação da semana" com progresso e recompensa em XP | [F] |

---

## BLDR Club — Treinos

| # | Mudança | Tipo |
|---|---|---|
| CT1 | Semana atual com ícone da atividade registrada em cada dia concluído | [F] |
| CT2 | Legenda de tipos de atividade abaixo do seletor | [V] |
| CT3 | Stats da semana (Treinos / Extras / XP) como linha dentro do card, sem sub-cards | [V] |
| CT4 | "Meus treinos" em carrossel | [V] |
| CT5 | Botões "Iniciar" dourados grandes → botão outline dentro do card | [V] |
| CT6 | Cardio e Yoga & Pilates como carrosséis | [V] |
| CT7 | Programas Club: badges sobre a capa com fundo blur, no topo | [V] |

## BLDR Club — Meu Plano

| # | Mudança | Tipo |
|---|---|---|
| CP1 | Mesma estrutura da timeline padrão | [V] |
| CP2 | Ícone da atividade em cada dia concluído | [F] |
| CP3 | XP e métrica por dia ("+40 XP · 58 min", "+30 XP · 5,2 km") | [F] |
| CP4 | Atividades extras aparecem na timeline sem contar no progresso do plano | [F] |
| CP5 | Botão "Registrar extra" | [F] |

## BLDR Club — Esportes

| # | Mudança | Tipo |
|---|---|---|
| CE1 | BLDR Run com stats inline (último, pace médio, volume da semana) | [F] |
| CE2 | Protocolos ativos em carrossel, descrições encurtadas | [V] |
| CE3 | Trackers sem botão "ACESSAR" — card inteiro clicável | [V] |
| CE4 | Havok compacto: chips em wrap + campo + CTA | [V] |
| CE5 | Card "Sua semana" com sessões, tempo ativo, XP e recorde | [F] |

### Round Timer

| # | Mudança | Tipo |
|---|---|---|
| CR1 | Anel de progresso circular ao redor do tempo | [V] |
| CR2 | Controles antes da configuração quando o timer está rodando | [V] |
| CR3 | Configuração vira leitura compacta; ajuste abre sheet | [V] |
| CR4 | Remover badge numérico solto entre timer e configuração | [V] |
| CR5 | Histórico com modalidade, data, rounds e duração | [V] |

### Match Tracker

| # | Mudança | Tipo |
|---|---|---|
| CM1 | Cada lado do placar vira bloco próprio; o seu com tint dourado | [V] |
| CM2 | Cronômetro grande → contador discreto no cabeçalho do card | [V] |
| CM3 | "Iniciar" some após o início; vira "Pausar" + "Finalizar" | [V] |
| CM4 | Histórico de sets acumulados abaixo do placar | [F] |
| CM5 | Seção "Últimas partidas" com resultado | [F] |

### Protocolo (detalhe do dia)

| # | Mudança | Tipo |
|---|---|---|
| CX1 | Nome do exercício: título curto + tradução no subtítulo | [V] |
| CX2 | Notas em texto normal (fim do itálico cinza de baixo contraste) | [V] |
| CX3 | Checkbox por exercício + contador "0 de 5" | [F] |
| CX4 | Botão fixo "Iniciar dia N" no rodapé | [F] |

### Comunidade

| # | Mudança | Tipo |
|---|---|---|
| CC1 | Card "Grupo VIP Oficial" verde → dourado | [V] |
| CC2 | Pódio com coroa; 2º e 3º em prata fosca e dourado fosco | [V] |
| CC3 | Card "sua posição" com XP e diferença para a posição acima | [V] |
| CC4 | Feed descreve a ação real ("Concluiu Push A", "Correu 8,2 km") | [F] |
| CC5 | Reação com dois estados visuais (reagido / não reagido) | [F] |

### Competição

| # | Mudança | Tipo |
|---|---|---|
| CQ1 | **Card "ALISTAR-SE AGORA" ciano → glass neutro** | [V] |
| CQ2 | "Criar operação" mantém tint dourado como ação principal | [V] |
| CQ3 | Card do squad com ranking interno dos membros em barras | [F] |
| CQ4 | Seção explicando os 4 modos de jogo na tela principal | [V] |
| CQ5 | No formulário de novo squad: modo padrão deixa de ser "Survivor"; aviso do modo em tom informativo, não vermelho | [V] |

---

## Perfil

| # | Mudança | Tipo |
|---|---|---|
| PF1 | **Remover e-mail da tela** (risco de vazamento ao compartilhar) — migra para Configurações | [V] |
| PF2 | Header horizontal: avatar + nome + badges | [V] |
| PF3 | Remover chip "Nível 5" duplicado (já está no card de XP) | [V] |
| PF4 | Grid 2×2 de stats | [V] |
| PF5 | Conquistas em grid 5×2; obtidas em dourado, bloqueadas em cinza com cadeado | [V] |
| PF6 | Linha "Próxima conquista" com critério | [F] |
| PF7 | Card de Duelos oculto até haver dado | [V] |
| PF8 | Ícone de engrenagem no header → Configurações | [V] |
| PF9 | Todo o bloco de configurações sai do Perfil | [V] |

## Configurações (nova tela)

| # | Mudança | Tipo |
|---|---|---|
| S1 | Linhas agrupadas com divisórias, não cards individuais | [V] |
| S2 | **Vermelho só em "Excluir conta".** "Sair" e "Cancelar assinatura" em tom neutro | [V] |
| S3 | "Cancelar assinatura" migra para dentro de "Gerenciar assinatura" | [V] |
| S4 | "Refazer onboarding" → "Preferências de treino" | [V] |
| S5 | Seção Metas (peso, calorias, macros) | [F] |
| S6 | Seção Integrações (Apple Saúde, relógios) | [F] |
| S7 | Seção Privacidade (visibilidade no ranking e feed) | [F] |
| S8 | Central de ajuda e Termos | [F] |
| S9 | Versão do app no rodapé | [V] |

---

## Progresso

### Aba Geral

| # | Mudança | Tipo |
|---|---|---|
| PG1 | Card contendo sub-cards → 4 cards diretos no grid 2×2 | [V] |
| PG2 | Remover badge "100%" verde (não explicava a métrica) | [V] |
| PG3 | Conquistas obtidas com fundo dourado + check, sem badge "Obtido" repetido | [V] |
| PG4 | Conquistas bloqueadas com barra de progresso e XP | [V] |
| PG5 | **Corrigir contadores inconsistentes** ("26/10" e "26/25" apareciam como pendentes já cumpridos) | [F] |

### Aba Corpo

| # | Mudança | Tipo |
|---|---|---|
| PC1 | Card "Foto do Progresso" verde → glass | [V] |
| PC2 | Seletores de métrica: cards com ícones coloridos → chips horizontais (fim do corte na borda) | [V] |
| PC3 | **Eliminar os três empty states empilhados** — reorganizar em: métrica → gráfico → registro rápido → fotos | [V] |
| PC4 | Gráfico de linha com valor atual e variação no período | [F] |
| PC5 | Fotos de progresso em carrossel horizontal com data | [F] |
| PC6 | "Comparar fotos" (antes/depois lado a lado) | [F] |
| PC7 | Lista de últimos registros em grupo com divisórias | [F] |

### Aba Treinos

| # | Mudança | Tipo |
|---|---|---|
| PT1 | Heatmap com células menores; legenda no cabeçalho do card | [V] |
| PT2 | Stats com ícone verde/laranja → 3 cards neutros | [V] |
| PT3 | **Corrigir "Duração média: 0m"** com treinos de 22 e 53 min registrados | [F] |
| PT4 | Treinos recentes: título curto + detalhe, ícone dourado no lugar do check verde | [V] |

### Aba Nutrição

| # | Mudança | Tipo |
|---|---|---|
| PN1 | Remover toggle Consistência/Calorias — as duas visões cabem empilhadas | [V] |
| PN2 | Badge verde "0/7 Dias" → cards neutros de média diária e dias na meta | [V] |
| PN3 | Gráfico de calorias por dia com linha de meta tracejada | [F] |
| PN4 | Média de macros no período com barras | [F] |
| PN5 | Evolução do IQD em gráfico de linha | [F] |
| PN6 | **Card verde "Dicas Nutricionais" removido** — dicas genéricas substituídas por leitura do próprio dado | [F] |
| PN7 | Refeições recentes com alimentos e calorias | [F] |

---

## Ordem sugerida de implementação

1. **Global (G1–G10)** — estabelece a base. Todas as telas mudam de aparência de uma vez.
2. **Dashboard, Treinos, Perfil** — telas de maior tráfego, retorno visual imediato.
3. **Configurações** — extração do Perfil. Tela nova, baixo risco.
4. **Nutrição + sheet de adicionar alimento** — maior volume de mudança.
5. **BLDR Club** — mais telas, todas dependendo dos componentes já validados.
6. **Progresso** — quatro abas; deixar por último porque tem a maior proporção de itens **[F]**.
