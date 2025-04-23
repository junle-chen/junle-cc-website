---
layout: post
title: 搭建个人网站进行记录
gh-repo: https://github.com/junle-chen/junle-cc-website
tags:
  - note
mathjax: true
gh-badge:
  - star
  - follow
  - fork
comments: true
thumbnail-img: ../assets/img/Pasted%20image%2020241116200201.png
share-img: /assets/img/path.jpg
cover-img: /assets/img/path.jpg
---
## Motivation

- 目前的大多数方法都基于大量的标签数据进行训练，然后在一些的城市场景内的数据存在缺失性，我们需要构建一个泛化性强的时空大模型来进行优化流量，减少拥堵，提高移动性
- 目前的模型，如llama对于复杂的时空关系难以处理，对于baseline model, 他很容易出现overfit 在zero-shot 场景
- 文章通过将时空依赖编码器（spatio-temporal dependency encoder）与指令调优范式（instruction-tuning paradigm）无缝集成来实现将时空上下文与LLMs对齐。

### example
![](../assets/img/Pasted%20image%2020250423181223.png)




![](../assets/img/Pasted%20image%2020250423180836.png)

