# ==============================================================
# 📦 高度定制化 Pandoc 容器镜像
# 支持中文、Mermaid、GitHub 风格主题、多格式转换
# ==============================================================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8

# --------------------------------------------------------------
# 🧩 基础依赖 + 字体 + 中文环境
# --------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    wget curl git unzip locales ca-certificates gnupg \
    fonts-noto-cjk fonts-noto-cjk-extra \
    fonts-wqy-microhei fonts-wqy-zenhei \
    fonts-dejavu fonts-dejavu-core fonts-dejavu-extra \
    && locale-gen zh_CN.UTF-8 && update-locale LANG=zh_CN.UTF-8

# --------------------------------------------------------------
# 🧰 安装 Pandoc (最新版)
# --------------------------------------------------------------
RUN PANDOC_VERSION=3.7.0.1 && \
    wget https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-1-amd64.deb && \
    dpkg -i pandoc-${PANDOC_VERSION}-1-amd64.deb && \
    rm pandoc-${PANDOC_VERSION}-1-amd64.deb

# --------------------------------------------------------------
# ✏️ 安装 LaTeX / XeTeX 引擎
# --------------------------------------------------------------
RUN apt-get install -y \
    texlive-xetex texlive-latex-extra texlive-fonts-recommended \
    texlive-fonts-extra texlive-lang-chinese texlive-science \
    librsvg2-bin && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------------------
# 🧮 安装 Python + Pandoc Filters
# --------------------------------------------------------------
RUN apt-get update && apt-get install -y python3 python3-pip && \
    pip3 install --no-cache-dir \
      pandoc-crossref pandoc-tablenos pandoc-fignos pandoc-eqnos && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------------------
# 📊 Mermaid 图支持
# 通过 mermaid-cli (mmdc) 将 mermaid 转换为 SVG/PDF/PNG
# --------------------------------------------------------------
RUN apt-get update && apt-get install -y nodejs npm && \
    npm install -g @mermaid-js/mermaid-cli@10.9.0 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------------------
# 🧩 安装 pandoc-mermaid-filter
# 让 Pandoc 自动将 Markdown 内的 mermaid 块转为图像
# --------------------------------------------------------------
RUN pip3 install --no-cache-dir pandoc-mermaid-filter

# --------------------------------------------------------------
# 🪶 安装 GitHub Markdown CSS 模板
# --------------------------------------------------------------
RUN mkdir -p /opt/pandoc/templates && \
    wget -O /opt/pandoc/templates/github.css https://raw.githubusercontent.com/sindresorhus/github-markdown-css/main/github-markdown.css

# --------------------------------------------------------------
# 🧰 安装 LibreOffice (pptx/docx 优化)
# --------------------------------------------------------------
RUN apt-get update && apt-get install -y libreoffice-writer libreoffice-impress && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------------------
# 🧩 拷贝模板与脚本
# --------------------------------------------------------------
WORKDIR /workspace
COPY templates /opt/pandoc/templates
COPY scripts /opt/pandoc/scripts

# --------------------------------------------------------------
# 🧾 赋权 + PATH 环境变量
# --------------------------------------------------------------
RUN chmod +x /opt/pandoc/scripts/*.sh
ENV PATH="/opt/pandoc/scripts:${PATH}"

# --------------------------------------------------------------
# 🧠 默认命令
# --------------------------------------------------------------
CMD ["/bin/bash"]
