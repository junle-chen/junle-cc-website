```ad-tip
轨迹分析的一项基本任务是轨迹表征学习（Trajectory Representation Learning, TRL），其目标是从高维原始轨迹数据中学习轨迹的低维且有意义的表征。
```

## Motivation
- 目前的轨迹表示学习是基于这两个方法：基于网格的方法和基于道路的方法，这两个方法，两种模态在本质上是不同的，因此能够捕捉不同的轨迹特征并具有独特的优势。同时目前缺乏这两个模态的对比研究
- 此外，当前的路网表征学习（TRL）方法在很大程度上忽略了时空动态性。尽管最近的一些方法已经纳入了时间数据，但它们仍然将路网视为静态的这种局限性阻碍了关键时空模式的提取，例如高峰时段交通状况的剧烈变化。这些动态因素极大地影响了下游应用，如行程时间估计，这突显了在路网表征学习方法中融入时空动态性的必要性。
- 基于我们之前的观察，我们发现了两个主要挑战：(1) 网格（grid）与道路模态（road modality）之间的异构性。两种模态使用了完全不同的空间离散化方法，因此难以直接组合或融合这两种类型的信息。(2) 时空动态性（Spatio-temporal dynamics）。城市交通具有高度的动态性，并且随时间和空间的变化而显著不同。有效地建模这些动态变化极具挑战性。
- 为了应对这些挑战，TIGR采用了一种三分支架构，并行处理网格数据、道路网络数据以及时空动态信息。其中，网格分支和道路分支代表了我们两个主要模态（modalities），而时空分支则提取源自道路模态的动态交通模式。我们将每个分支嵌入到潜在轨迹表征（latent trajectory representations）中，并在不同分支内（模态内，intra-modal）和分支间（模态间，inter-modal）对齐这些表征。通过结合这三个组成部分，TIGR能够更精细地提取多样的轨迹特征。这种集成方法使得我们的模型能够充分利用基于网格和基于道路的方法的优势，同时考虑到城市交通的动态特性。

### Problem Definition
给定一个轨迹集合  $\mathcal{D} = \{\mathcal{T}_i\}_{i=1}^{|\mathcal{D}|}$，轨迹表征学习的任务是学习一个轨迹编码器 F : T  → z，该编码器将轨迹 T 嵌入到一个通用的表征 z ∈$\mathbb{R}^d$ 中，其中 d 是表征的维度。该表征 z 应该准确地代表轨迹 T，并适用于各种下游应用，例如轨迹相似度计算、旅行时间估计和目的地预测。为此，轨迹编码器以无监督的方式进行训练。

### 方法
方法主要由三个核心部分组成：动态交通嵌入（dynamic traffic embedding）、时间嵌入（temporal embedding）以及通过局部多头注意力机制（local multi-head attention）进行的融合。

![[Pasted image 20250422174501.png]]
对于两个相连的路段 vi 和 vj，其转移概率 (transition probability) 由 P[i,j] 给出，并通过历史轨迹计算得出。
$$
P_{[i,j]}=\frac{\#transitions(v_i\to v_j)+1}{\#total\_visits(v_i)+|\mathcal{N}(v_i)|}
$$
其中$|\mathcal{N}(v_i)|$是vi的邻居个数，接下来对$P^{\prime}=D^{-1}(P+I)$规范化，D为度矩阵，I为单位矩阵

$$\mathbf{h}_i=P_{[i,i]}^{\prime}w_i\mathbf{x}_i^{(t_d,t_h)}+\sum_{v_j\in\mathcal{N}(v_i)}P_{[i,j]}^{\prime}w_j\mathbf{x}_j^{t_h},$$
其中，N是邻域函数（neighbor function），返回一条道路的所有相邻道路；w是可学习的参数；$x^{t_h}$ ∈ X 表示第$t^h$小时的交通状态；hi是道路路段vi的动态交通嵌入（dynamic traffic embedding）。给定Tr中的道路序列，我们获得动态交通嵌入的序列$T^s = (h_1, h_2, h_3, . . . , h_|T^r |)$。
