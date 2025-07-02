#### para jogar acesse > https://zednaked.github.io/2djoust/


## Bate-papo sobre o projeto

### Como foi o processo de criação?

Tudo começou com os assets. Olhando para eles, a ideia de um jogo top-down, com uma pegada meio *Vampire Survivors*, pareceu a mais promissora. A sugestão inicial era ter um pulo, mas acabei trocando por um sistema de dash e combos que combinou mais com a ação.

O desenvolvimento foi passo a passo:
1.  **Protótipo:** Criei uma arena bem simples, só com o jogador e um inimigo, para focar em deixar a jogabilidade principal - IA, state machine, knockback, dash - divertida.
2.  **Expansão:** Quando a base ficou legal, adicionei os spawners para os inimigos surgirem em ondas e construí o cenário definitivo.
3.  **UI e Efeitos:** Implementei a interface com vida e score.
4.  **Polimento:** Para dar um charme, adicionei uma tela de início, de fim de jogo e vários efeitos de partículas.

### E o que vem depois? Quais os próximos passos?

Para continuar, algumas possibilides de próximos passos:
- Adicionar mais tipos de inimigos, cada um com um comportamento diferente.
- Colocar efeitos sonoros e uma trilha sonora.
- Quem sabe um modo multiplayer
- Novas habilidades e power-ups para o jogador

### Gostou ou quer trocar uma ideia?

Pode me chamar no e-mail: zednaked@gmail.com 


# 2D Joust - Documentação do Projeto

Este documento detalha a arquitetura, as mecânicas e a estrutura de código do jogo de ação 2D top-down "2D Joust".

## 1. Visão Geral

"2D Joust" é um jogo de ação e sobrevivência com visão de cima. O jogador controla um soldado que deve enfrentar e derrotar hordas crescentes de inimigos (Orcs) em uma arena com obstáculos. O objetivo é sobreviver a todas as ondas de inimigos.

## 2. Mecânicas Principais

O jogo é construído sobre um conjunto de mecânicas de combate e movimento projetadas para serem responsivas e satisfatórias.

#### Movimento do Jogador
- **Movimento de 8 Direções:** O jogador pode se mover livremente no mapa usando as teclas direcionais.
- **Dash (Esquiva):** Ao pressionar uma tecla de direção duas vezes rapidamente, o jogador executa um "dash" naquela direção. Esta é uma manobra de alta velocidade usada para se esquivar de ataques e se reposicionar rapidamente.

#### Sistema de Combate
- **Combo de 3 Ataques:** O jogador pode executar um combo de até três ataques (`Attack01`, `Attack02`, `Attack03`). Após um ataque, há uma pequena janela de tempo para pressionar o botão de ataque novamente e continuar o combo. Se o jogador demorar, o combo é resetado.
- **Dano Baseado em Hitbox:** O dano não é instantâneo. Cada ataque tem uma `Hitbox` (uma `Area2D`) que é ativada apenas durante os frames ativos da animação. O dano só é registrado se a `Hitbox` do atacante colidir com a `Hurtbox` do alvo.
- **Knockback:** Para dar uma sensação de impacto, os inimigos são empurrados para trás (`knockback`) quando atingidos por um ataque do jogador.
- **Invencibilidade Pós-Dano (i-frames):** Ao receber dano, o jogador fica invencível por um curto período, indicado por um efeito de piscar. Isso evita que o jogador seja travado em um ciclo de dano contínuo.

#### Spawners
- **Spawners:** Inimigos são gerados em locais pré-determinados no mapa por nós `Spawner`. O `GameManager` escolhe aleatoriamente entre os spawners disponíveis para cada inimigo.

#### Condições de Vitória e Derrota
- **Derrota:** O jogo termina se a vida do jogador chegar a zero.


## 3. Estrutura de Código e Arquivos

O projeto é organizado em torno de cenas e scripts que representam cada entidade do jogo.

#### Scripts Principais (`.gd`)
- **`Player.gd`:** Controla toda a lógica do jogador, incluindo a máquina de estados (IDLE, WALK, DASH, ATTACK, HURT, DEATH), o sistema de combo, a lógica de dano e invencibilidade.
- **`Enemy.gd`:** Controla a IA do inimigo. Usa uma máquina de estados (CHASING, ATTACKING, HURT, DEATH) para determinar seu comportamento. Também gerencia sua saúde, knockback e a chance de dropar itens.
- **`Spawner.gd`:** Um script simples que se registra no grupo "spawners" e tem uma única função: instanciar a cena de um inimigo quando solicitado pelo `GameManager`.
- **`UI.gd`:** Gerencia todos os elementos da interface do usuário. Atualiza a barra de vida do jogador e exibe informações sobre as ondas e o estado do jogo.

#### Cenas Principais (`.tscn`)
- **`Main.tscn`:** A cena principal do jogo. Contém o `Player`, os `Spawner`s, os obstáculos do cenário e a `UI`. 
- **`Player.tscn`:** A cena do jogador. O nó raiz é um `CharacterBody2D`. Contém o `AnimatedSprite2D` para os visuais, `CollisionShape2D` para a física, e `Area2D`s para a `Hurtbox` (corpo) e `Hitbox` (ataque).
- **`Enemy.tscn`:** Estrutura similar à do jogador, mas com o script de IA. Também contém uma `ProgressBar` para a barra de vida que aparece sobre sua cabeça.
- **`UI.tscn`:** A interface do usuário. Usa um `CanvasLayer` para garantir que permaneça fixa na tela. Contém a barra de vida do jogador e os labels para as informações do jogo.
- **Cenas de Efeitos:** `HitEffect.tscn` são cenas de partículas autocontidas que são instanciadas para criar efeitos visuais e se autodestroem.
