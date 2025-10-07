FROM ubuntu:22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8

# 安装基础依赖和中文支持
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    ca-certificates \
    locales \
    fonts-noto-cjk \
    fonts-noto-cjk-extra \
    fonts-wqy-microhei \
    fonts-wqy-zenhei \
    fonts-dejavu \
    fonts-dejavu-core \
    fonts-dejavu-extra \
    && locale-gen zh_CN.UTF-8 \
    && update-locale LANG=zh_CN.UTF-8

# 安装 Pandoc (最新版本)
RUN PANDOC_VERSION=3.7.0.1 && \
    wget https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-1-amd64.deb && \
    dpkg -i pandoc-${PANDOC_VERSION}-1-amd64.deb && \
    rm pandoc-${PANDOC_VERSION}-1-amd64.deb

# 安装 TeX Live 和相关工具
RUN apt-get install -y \
    texlive-xetex \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-lang-chinese \
    texlive-science \
    librsvg2-bin \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 安装 Python 和过滤器
RUN apt-get update && apt-get install -y python3 python3-pip && \
    pip3 install --no-cache-dir \
    pandoc-crossref \
    pandoc-tablenos \
    pandoc-fignos \
    pandoc-eqnos \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 安装 LibreOffice (用于 PPTX 转换优化)
RUN apt-get update && apt-get install -y \
    libreoffice-writer \
    libreoffice-impress \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 创建工作目录
WORKDIR /workspace

# 复制配置文件和模板
COPY templates /opt/pandoc/templates
COPY scripts /opt/pandoc/scripts

# 设置脚本执行权限
RUN chmod +x /opt/pandoc/scripts/*.sh

# 添加脚本到 PATH
ENV PATH="/opt/pandoc/scripts:${PATH}"

# 默认命令
CMD ["/bin/bash"]
