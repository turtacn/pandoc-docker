# ==============================================================
# jdcloudiaas/turta:pandoc
# 高度定制化 Pandoc 容器镜像（中文支持、Mermaid、GitHub CSS、LaTeX）
# ==============================================================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8

# 基本依赖 + 字体 + locale
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget git unzip locales \
    gnupg2 ca-certificates \
    fonts-noto-cjk fonts-noto-cjk-extra \
    fonts-wqy-microhei fonts-wqy-zenhei \
    fonts-dejavu-core fonts-dejavu-extra \
    fonts-lato \
    && locale-gen zh_CN.UTF-8 && update-locale LANG=zh_CN.UTF-8

# 安装 Pandoc（指定稳定版本）
ARG PANDOC_VERSION=3.7.0.1
RUN wget -q https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-1-amd64.deb \
    && dpkg -i pandoc-${PANDOC_VERSION}-1-amd64.deb || apt-get -f install -y \
    && rm -f pandoc-${PANDOC_VERSION}-1-amd64.deb

# 安装 LaTeX（XeTeX）、SVG 支持
RUN apt-get update && apt-get install -y --no-install-recommends \
    texlive-xetex texlive-latex-extra texlive-fonts-recommended \
    texlive-fonts-extra texlive-lang-chinese librsvg2-bin \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Python + Pandoc filters
RUN apt-get update && apt-get install -y --no-install-recommends python3 python3-pip \
    && pip3 install --no-cache-dir pandoc-crossref pandoc-tablenos pandoc-fignos pandoc-eqnos pandoc-mermaid-filter \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Node + mermaid-cli
RUN apt-get update && apt-get install -y --no-install-recommends nodejs npm \
    && npm install -g @mermaid-js/mermaid-cli@10.9.0 \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /root/.npm /root/.cache

# LibreOffice（增强 docx/pptx 兼容性）
RUN apt-get update && apt-get install -y --no-install-recommends libreoffice-writer libreoffice-impress \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 创建路径并复制模板与脚本（构建时会覆盖）
WORKDIR /opt/pandoc
RUN mkdir -p /opt/pandoc/templates /opt/pandoc/scripts /workspace

# 将容器默认工作目录设为 /workspace（挂载点）
WORKDIR /workspace

COPY scripts/ /opt/pandoc/scripts/
COPY templates/ /opt/pandoc/templates/

RUN chmod +x /opt/pandoc/scripts/*.sh


# 环境变量
ENV PATH="/opt/pandoc/scripts:${PATH}"

# 默认进入 bash
CMD ["/bin/bash"]
