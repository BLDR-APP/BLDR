# BLDR — Design System

Referência única de estilo para o app. Toda tela nova ou redesenhada deve sair daqui.
Se algo não estiver definido neste arquivo, não invente um valor novo: use o token mais próximo ou levante a dúvida.

---

## 0. Decisões pós-auditoria

Tomadas após o `INVENTARIO.md`. Elas limitam deliberadamente o alcance do design
system, porque a auditoria mostrou que o app não tem base de estilo:
**704 ocorrências de `Color(0x…)`, 97% fora do `AppTheme`**, três "cinza de card"
diferentes, e zero componentes reutilizados.

| Decisão | Escolha | Por quê |
|---|---|---|
| **Fonte** | **Inter** | Já é a fonte dos componentes do `AppTheme` (24 usos). Montserrat é mais decorativa; JetBrainsMono é de dados. Ambas permanecem no legado. |
| **Spacing** | **Pixel nas telas redesenhadas; `sizer` fica onde já está** | Converter `sizer` (`4.w`, `2.h`) → pixel em telas que não serão redesenhadas é risco sem ganho: `sizer` é proporcional à tela e não há teste de widget para pegar quebras. A conversão acontece naturalmente por tela. |
| **`AppTheme`** | **Não alterar `successGreen`/`warningAmber`/`errorRed` agora** | Vazam para `SnackBar`, `TextField` inválido e `Switch` via `ColorScheme`, atingindo ~45 telas fora do escopo sem revisão. `errorRed` é também o `--danger` legítimo de "Excluir conta". |
| **Alcance do G4** | **Por tela redesenhada, não global** | Consequência da decisão acima. |
| **Escopo** | **17 telas do `REDESIGN_SPEC.md`** | O app tem ~45 telas fora do SPEC (Arena, Tribunal, Corrida GPS, Portal Profissional, trackers). Ficam para depois. |

**Consequência aceita:** o app fica **bicolor** durante a migração — telas
redesenhadas com a linguagem nova, telas de cauda com a antiga. A ordem por
tráfego (Dashboard, Treinos, Nutrição, Perfil) minimiza o impacto percebido.

**Ícones:** o app usa três sistemas simultâneos — `CustomIconWidget` (mapa de
~2.100 entradas reconstruído **dentro do `build()`**, em 77 arquivos), `Icons.*`
direto (telas do Club) e `font_awesome_flutter`. Telas redesenhadas usam
`Icons.*` direto; não propagar o `CustomIconWidget`.

---

## 1. Princípios

1. **Uma cor de destaque.** Dourado. Tudo que não for ação, dado em foco ou estado ativo é branco ou cinza.
2. **Vidro, não caixa.** Superfícies são translúcidas com blur sobre um fundo com glow, não retângulos sólidos empilhados.
3. **Hierarquia por tamanho, não por cor.** O elemento mais importante da tela é o maior, não o mais colorido.
4. **Vazio é respiro.** Espaço em branco no fim de uma tela é aceitável. Não preencher só para não ficar vazio.
5. **Tom neutro.** O app informa, não repreende. Estados negativos (treino não feito, meta não batida) são cinza, nunca vermelho.

---

## 2. Cores

### Base

| Token | Valor | Uso |
|---|---|---|
| `--bg-base` | `#050505` | Fundo de todas as telas |
| `--bg-glow-primary` | `radial-gradient(ellipse at 50% 0%, rgba(201,162,39,0.20), transparent 45%)` | Glow superior — obrigatório em toda tela |
| `--bg-glow-secondary` | `radial-gradient(circle at 100% 40%, rgba(201,162,39,0.06), transparent 38%)` | Glow lateral — opcional, telas mais longas |

O glow é o que faz o glass funcionar. Sem ele, os cards translúcidos ficam cinza chapado.

### Dourado

| Token | Valor | Uso |
|---|---|---|
| `--gold-solid` | `#C9A227` | Preenchimento de botão primário |
| `--gold-bright` | `#E0B830` | Texto, ícones, barras de progresso, estados ativos |
| `--gold-gradient` | `linear-gradient(90deg, #8a6d1a, #E0B830)` | Barras de progresso longas (peso, nível, XP) |
| `--gold-tint` | `rgba(224,184,48,0.13)` | Fundo de ícone dentro de card |
| `--gold-tint-strong` | `rgba(201,162,39,0.13)` | Fundo de card em destaque (hero, CTA) |
| `--gold-border` | `rgba(201,162,39,0.28)` | Borda de card em destaque |

### Superfícies (glass)

| Token | Valor | Uso |
|---|---|---|
| `--surface` | `rgba(255,255,255,0.05)` | Card padrão |
| `--surface-subtle` | `rgba(255,255,255,0.04)` | Card secundário, faixa fina |
| `--surface-inset` | `rgba(255,255,255,0.03)` | Bloco dentro de card |
| `--border` | `rgba(255,255,255,0.08)` | Borda de card padrão |
| `--border-subtle` | `rgba(255,255,255,0.07)` | Borda de card secundário, divisórias |
| `--nav-bg` | `rgba(10,10,10,0.55)` | Barra de navegação inferior |

### Texto

| Token | Valor | Uso |
|---|---|---|
| `--text-primary` | `#FFFFFF` | Títulos, números, nomes |
| `--text-secondary` | `rgba(255,255,255,0.45)` | Labels, descrições |
| `--text-tertiary` | `rgba(255,255,255,0.35)` | Metadados, unidades, timestamps |
| `--text-muted` | `rgba(255,255,255,0.25)` | Placeholders, estados inativos |

### Semânticas

| Token | Valor | Uso |
|---|---|---|
| `--danger` | `#E06B5A` | **Exclusivamente** ações irreversíveis (excluir conta). Nunca para "não feito", "cancelar" ou "sair". |

**Não existem** verde, azul, laranja, roxo, ciano ou rosa no app. Se um estado precisa se distinguir, use opacidade do dourado ou um ícone diferente — não outra cor.

---

## 3. Tipografia

Peso máximo: **600**, e apenas em botões e números de destaque. Nunca 700+.

| Papel | Tamanho | Peso | Cor |
|---|---|---|---|
| Título de tela | 21–23px | 500 | primary |
| Título de seção | 15px | 500 | primary |
| Título de card | 13–14px | 500 | primary |
| Número KPI grande | 26–34px | 500 | primary |
| Número KPI médio | 17–20px | 500 | primary |
| Corpo | 12–13px | 400 | primary |
| Descrição | 11px | 400 | secondary |
| Metadado | 10–11px | 400 | tertiary |
| Label maiúsculo | 9–10px | 500–600 | secondary, `letter-spacing: 0.5px` |
| Texto de botão | 13–14px | 600 | conforme variante |

**Unidades sempre menores que o valor**, em `tertiary`: `62<span>kg</span>`, `11<span>/34</span>`.

---

## 4. Espaçamento

| Token | Valor | Uso |
|---|---|---|
| `--page-x` | `22px` | Margem lateral de toda tela |
| `--gap-card` | `11–12px` | Entre cards do mesmo grupo |
| `--gap-section` | `22–24px` | Entre seções distintas |
| `--pad-card` | `16–18px` | Interno de card padrão |
| `--pad-card-lg` | `18–20px` | Interno de card hero |
| `--pad-row` | `13–15px` | Interno de linha de lista |
| `--nav-clearance` | `100px` | Padding inferior do scroll em telas com tab bar |

---

## 5. Raios

| Contexto | Raio |
|---|---|
| Frame da tela | 32px |
| Card hero / destaque | 26px |
| Card grande | 22–24px |
| Card pequeno / linha de lista | 18–20px |
| Botão | 12–16px |
| Input / campo | 14–16px |
| Caixa de ícone | 10–13px |
| Chip / pill / badge | 16–20px |
| Barra de progresso | 3–4px |
| Avatar, botão circular | 50% |

---

## 6. Blur (glass)

| Contexto | Valor |
|---|---|
| Card padrão | `backdrop-filter: blur(16px)` |
| Card grande / hero | `blur(18px)` |
| Barra de navegação | `blur(24px)` |
| Bottom sheet | `blur(30px)` |
| Badge sobre imagem | `blur(8px)` |

**Regra de contenção:** em Flutter, todo `BackdropFilter` precisa de um `ClipRRect` ao redor. Sem isso o blur vaza para fora dos cantos arredondados. O widget `BldrGlassCard` já resolve isso — usar sempre ele em vez de montar o efeito à mão.

**⚠️ Conversão CSS → Flutter:** `blur(Npx)` do CSS equivale a `sigma = N / 2` no `ImageFilter.blur`. Passar o valor do CSS direto no sigma dobra a intensidade e deixa o vidro leitoso. Os valores já convertidos estão em `BldrBlur`.

**Glow de fundo:** implementado como `RadialGradient` em `BldrColors.glowPrimary` / `glowSecondary`, aplicado pelo widget `BldrBackground`. Sem o glow, os cards de vidro não têm o que refratar e ficam cinza chapado — ele não é opcional.

**Fallback de performance:** se o blur pesar em dispositivos mais antigos (especialmente Android), trocar o `background` do `BldrGlassCard` por `#131313` sólido e remover o `BackdropFilter`, mantendo borda, raio e espaçamento idênticos. Como todos os cards passam pelo mesmo widget, isso é uma alteração num arquivo só. Decidir por dispositivo, não por tela.

### Implementação

Os tokens desta seção e de todas as anteriores estão em código:

- `lib/theme/bldr_tokens.dart` — cores, tipografia, espaçamento, raios, blur
- `lib/design_system/bldr_components.dart` — componentes prontos

> Pasta própria (`design_system/`), **não** `lib/widgets/`: aquela contém
> `custom_icon_widget.dart` (2189 l.) e código morto, e é exportada por
> `app_export.dart` para 77 arquivos. Separar deixa óbvio no diff o que é redesign.

**As telas devem ser compostas a partir desses widgets, não reimplementadas.** É isso que garante fidelidade aos mockups: se um card sair diferente, o ajuste é no componente e propaga para o app inteiro.

**Padrões que já existem duplicados no app e devem ser substituídos:**

| Padrão duplicado hoje | Cópias | Componente |
|---|---|---|
| Fundo com glow (`_GoldRadialBackground` + `_RadialBlob`) | **5** | `BldrBackground` |
| Círculo tracejado de descanso (`_DashedCirclePainter`) | **3** | seletor de dias (7.13) |
| Chip de stat (`_StatPill`, `_infoChip`, `_summaryChip`…) | 5+ | `BldrChip` |
| Botão primário (`ElevatedButton` + `styleFrom` inline) | todas as telas | `BldrPrimaryButton` |

---

## 7. Componentes

### 7.1 Card padrão

```
background: var(--surface);
backdrop-filter: blur(16px);
border: 1px solid var(--border);
border-radius: 20-22px;
padding: 16-18px;
```

Nunca combinar borda visível **e** fundo mais claro que o normal ao mesmo tempo — escolher um.

### 7.2 Card em destaque (hero / CTA)

```
background: var(--gold-tint-strong);
backdrop-filter: blur(18px);
border: 1px solid var(--gold-border);
border-radius: 26px;
padding: 18-20px;
```

Opcional: glow decorativo no canto superior direito —
`radial-gradient(circle, rgba(224,184,48,0.22), transparent 70%)`, 120×130px, `position: absolute; top: -30px; right: -30px`.

**Máximo um card em destaque por tela.**

### 7.3 Botões

| Variante | Fundo | Borda | Texto |
|---|---|---|---|
| Primário | `--gold-solid` | nenhuma | `#0A0A0A`, 600 |
| Secundário | `rgba(224,184,48,0.15)` | `rgba(224,184,48,0.25)` | `--gold-bright`, 500 |
| Terciário | `--surface` | `--border` | branco, 500 |
| Ícone circular | `--gold-solid` ou `--surface` | conforme | ícone |

Altura: 40–48px. Padding vertical 10–14px. Só **um** botão primário por tela.

### 7.4 Chip / filtro

```
Ativo:   background: rgba(224,184,48,0.15); border: 1px solid rgba(224,184,48,0.30); color: var(--gold-bright);
Inativo: background: var(--surface); border: 1px solid var(--border); color: var(--text-secondary);
padding: 7-8px 13-16px; border-radius: 20px;
```

### 7.5 Segmented control (abas internas)

```
Container: background: var(--surface-subtle); border: 1px solid var(--border-subtle);
           border-radius: 14px; padding: 4px; display: flex; gap: 6-8px;
Item ativo: background: rgba(224,184,48,0.15); color: var(--gold-bright); 500;
Item inativo: transparent; color: var(--text-secondary);
Item: flex: 1; padding: 8-9px; border-radius: 11px;
```

### 7.6 Barra de progresso

```
Trilho:      height: 4-6px; background: rgba(255,255,255,0.08); border-radius: 3-4px;
Preenchido:  var(--gold-bright) — barras curtas
             var(--gold-gradient) — barras longas (peso, nível, XP)
```

### 7.7 Linha de lista

```
background: var(--surface); border: 1px solid var(--border);
border-radius: 18-20px; padding: 13-15px;
display: flex; align-items: center; gap: 12-13px;
```

Estrutura: `[caixa de ícone 32-38px] [título 13px + subtítulo 11px] [valor / chevron]`

Caixa de ícone: `--gold-tint`, raio 11–13px, ícone `--gold-bright` 15–17px.

Use lista (não grid de cards) sempre que houver **4 ou mais itens** do mesmo tipo.

### 7.8 Grupo de configurações

Linhas dentro de um container único com divisórias, padrão iOS:

```
Container: background: var(--surface); border: 1px solid var(--border);
           border-radius: 18px; overflow: hidden;
Item:      padding: 14px 16px; display: flex; gap: 13px;
Divisória: height: 1px; background: var(--border-subtle); margin-left: 52px;
```

### 7.9 Empty state

```
background: rgba(255,255,255,0.03);
border: 1px dashed rgba(255,255,255,0.10-0.12);
border-radius: 22px; padding: 28px 18px; text-align: center;
```

Ícone `rgba(255,255,255,0.2)` → título 13px `rgba(255,255,255,0.6)` → instrução 11px `--text-muted`.

Tracejado é o que diferencia "espaço a preencher" de "conteúdo". **Nunca empilhar mais de um empty state visível na mesma tela.**

### 7.10 Carrossel

```
display: flex; gap: 11-12px; overflow-x: auto;
scroll-snap-type: x proximity;  /* mandatory apenas para páginas cheias */
scrollbar-width: none;
padding: 0 22px;   /* padding no container, não margin nos filhos */
Item: scroll-snap-align: start;
```

O último card deve ficar **parcialmente cortado** na borda direita — é o que sinaliza que dá para arrastar.

Largura de item: 106–120px (chip de stat), 146–160px (card de treino), 180–215px (card de programa/protocolo).

### 7.11 Barra de navegação inferior

```
position: absolute; bottom: 0; left: 0; right: 0; z-index: 2;
background: var(--nav-bg); backdrop-filter: blur(24px);
border-top: 1px solid var(--border);
padding: 14px 12px 22px;
display: flex; justify-content: space-around; align-items: center;
```

Item: ícone 19px + label 10px. Ativo em `--gold-bright`, inativo em `rgba(255,255,255,0.35)`.
Botão central BLDR CLUB: 44px, circular, `margin-top: -18px` (flutua acima da barra).

O conteúdo rola **por trás** da barra — não reservar espaço abaixo dela.

### 7.12 Bottom sheet

```
position: absolute; top: 56px; left/right/bottom: 0;
background: rgba(18,18,18,0.92); backdrop-filter: blur(30px);
border-top: 1px solid rgba(255,255,255,0.09);
border-radius: 28px 28px 0 0;
display: flex; flex-direction: column;
```

Handle no topo: 38×4px, `rgba(255,255,255,0.18)`, centralizado.
Header e footer fixos (`flex-shrink: 0`), conteúdo rolável no meio (`flex: 1; overflow-y: auto`).

### 7.13 Seletor de dias da semana

Quadrado `aspect-ratio: 1`, raio 10–11px:

| Estado | Estilo |
|---|---|
| Concluído | `rgba(224,184,48,0.16-0.18)` + ícone da atividade em `--gold-bright` |
| Hoje | `--gold-bright` sólido + ícone em `#0A0A0A` |
| Futuro | `--surface` + `1px solid var(--border-subtle)` |
| Descanso | `rgba(255,255,255,0.02)` + `1px dashed rgba(255,255,255,0.10)` |

**Ícone reflete a atividade registrada:** halter (musculação), corrida, cronômetro (outro).
Quando houver mais de um tipo de ícone em uso, incluir legenda discreta abaixo do seletor.

### 7.14 Heatmap de consistência

Células `aspect-ratio: 1`, raio 6px, gap 6px, grid de 7 colunas.
Intensidade: `rgba(255,255,255,0.05)` (nenhum) → `rgba(224,184,48,0.4)` → `0.55` → `0.7` → `#E0B830` (máximo).
Dia atual: borda `1.5px solid rgba(255,255,255,0.5)`.
Legenda "Menos ▪▪▪ Mais" no cabeçalho do card, não abaixo do grid.

### 7.15 Gráficos

- **Linha:** `stroke: #E0B830; stroke-width: 2.5; stroke-linecap: round; stroke-linejoin: round`. Ponto final com `circle r=4`. Grid opcional em `rgba(255,255,255,0.05)`.
- **Barra:** raio 5px no topo, `rgba(224,184,48,0.3–0.7)` conforme valor, dia atual em `#E0B830` sólido. Dias sem dado em `rgba(255,255,255,0.07)`.
- **Anel:** `stroke-width: 8`, trilho `rgba(255,255,255,0.07)`, preenchido `#E0B830`, `stroke-linecap: round`, rotação `-90deg`.
- **Arco (gauge):** semicírculo, `stroke-width: 11`, mesmo esquema. **Sem ponteiro e sem gradiente arco-íris** — o preenchimento do arco já comunica a posição.
- **Linha de meta:** tracejada em `rgba(224,184,48,0.4)`.

### 7.16 Card de insight do HAVOK

Ver `HAVOK_SPEC.md` para comportamento e regras de exibição.

```
background: var(--surface); backdrop-filter: blur(18px);
border: 1px solid var(--border); border-radius: 22px; padding: 16px;
position: relative; overflow: hidden;
```

Assinatura visual — é o que faz o usuário reconhecer que é o HAVOK falando:

- **Barra vertical** à esquerda, 2px, colada na borda: `linear-gradient(180deg, #E0B830, rgba(224,184,48,0.1))`
- **Avatar** circular 24px com `--gold-tint`, ícone da pantera em `--gold-bright`
- **"HAVOK"** em 9px, peso 600, `letter-spacing: 1.2px`, cor `--gold-bright`
- **Botão de dispensar** (×) alinhado à direita, `rgba(255,255,255,0.25)`

Estrutura do conteúdo: **título** (13px, 500) → **explicação** (12px, secondary) →
**ações** (botão secundário + terciário).

A ação executável é obrigatória. Insight sem ação é aviso, não agente.

### 7.17 Mensagem de conversa

```
Do HAVOK:   background: var(--surface); border: 1px solid var(--border);
            border-radius: 6px 18px 18px 18px;   /* canto superior esquerdo vivo */
            padding: 14px 16px; avatar 26px à esquerda

Do usuário: background: rgba(201,162,39,0.16); border: 1px solid rgba(201,162,39,0.28);
            border-radius: 18px 6px 18px 18px;   /* canto superior direito vivo */
            padding: 12px 15px; alinhado à direita, max-width: 80%
```

Mensagens de sessões anteriores: `opacity: 0.55`.

Divisores de sessão: linha `--border-subtle` com label centralizado em
`--text-muted` 10px ("Mais cedo · Dashboard", "Agora em Nutrição").

Artefato gerado dentro da conversa (treino, receita) usa o card em destaque
(7.2) com ações executáveis — nunca é só texto.

---

## 8. Ícones

Biblioteca única, estilo outline, peso consistente. Tamanhos: 15px (dentro de card), 17px (linha de lista), 19px (navegação), 22–26px (destaque/capa).

**Exceção deliberada:** as categorias de alimentos do seletor de nutrição usam emoji (🥩 🐟 🥚 🥛 🍓 🥦 🌾 🫒). Mantido por decisão de produto.

Não repetir o mesmo ícone em todos os itens de uma lista — se todos são da mesma categoria, o ícone vai no cabeçalho.

---

## 9. Marca

**A logo BLDR CLUB permanece exatamente como está hoje, em todas as telas onde já aparece.** Não substituir por versão tipográfica, não remover o glow, não alterar proporção ou tratamento. Os mockups de redesign usam um placeholder textual apenas por limitação da ferramenta — na implementação, usar o asset original.

Onde o logo aparece: BLDR Club (hub), Club → Treinos, Club → Comunidade, Club → Ranking, botão central da tab bar.

---

## 10. Escrita

- Frases em **sentence case**, não Title Case. "Iniciar treino", não "Iniciar Treino".
- Nomes de treino: título curto + detalhe no subtítulo. `Legs A` / `Quadríceps, glúteos, panturrilha · 60 min` — nunca `LEGS A | QUADS, GLUTE, PANTU...`.
- Botões nomeiam o resultado: "Atualizar progresso", não "Enviar".
- Empty states orientam a ação: "Monte seu primeiro treino personalizado", não "Nenhum dado".
- Estados negativos são neutros: "Não feito", nunca "Perdido" ou "Falhou".
- Alertas informativos usam ícone de dica (lâmpada), não de erro (triângulo), quando não há erro real.

---

## 11. Acessibilidade

- Área de toque mínima 44×44px, mesmo quando o alvo visual é menor.
- Texto em `--text-muted` (25% de opacidade) só para conteúdo decorativo ou placeholder — nunca informação necessária.
- Ícones decorativos: `aria-hidden="true"`. Ícones que carregam significado sozinhos (estado de dia, reação) precisam de label acessível.
- Nunca comunicar estado **apenas** por cor: o dia concluído tem ícone além do fundo dourado; a conquista obtida tem check além do fundo.
- Respeitar `prefers-reduced-motion` em qualquer transição adicionada.
