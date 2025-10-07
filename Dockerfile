#
# 高度定制化的 Pandoc 容器镜像
# 特性: 中文支持, Mermaid 图表, GitHub 风格, 多格式转换
#
FROM ubuntu:22.04

# 设置时区和语言环境, 避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8 \
    TZ=Asia/Shanghai

# ------------------------------------------------------------------
# 1. 安装基础依赖、中英文字体和本地化配置
# ------------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget curl git ca-certificates locales gnupg software-properties-common && \
    # 中文字体
    apt-get install -y --no-install-recommends \
    fonts-noto-cjk fonts-noto-cjk-extra fonts-wqy-microhei fonts-wqy-zenhei && \
    # 额外西文字体
    apt-get install -y --no-install-recommends \
    fonts-dejavu fonts-dejavu-core fonts-dejavu-extra && \
    # 生成中文 locale
    locale-gen zh_CN.UTF-8 && \
    update-locale LANG=zh_CN.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------
# 2. 安装最新版 Pandoc
# ------------------------------------------------------------------
RUN PANDOC_VERSION="3.2" && \
    wget "https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-1-amd64.deb" && \
    dpkg -i "pandoc-${PANDOC_VERSION}-1-amd64.deb" && \
    rm "pandoc-${PANDOC_VERSION}-1-amd64.deb"

# ------------------------------------------------------------------
# 3. 安装 TeX Live (用于 PDF 生成)
# ------------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    texlive-xetex \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-lang-chinese \
    texlive-science \
    librsvg2-bin \
    lmodern && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------
# 4. 安装 Mermaid 支持 (Node.js + mermaid-cli)
# ------------------------------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get update && \
    apt-get install -y --no-install-recommends nodejs && \
    npm install -g @mermaid-js/mermaid-cli && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


# ------------------------------------------------------------------
# 5. 安装 Python 和 Pandoc 过滤器
# ------------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3 python3-pip && \
    pip3 install --no-cache-dir \
    pandoc-crossref \
    pandoc-tablenos \
    pandoc-fignos \
    pandoc-eqnos \
    pandoc-mermaid-filter && \
    apt-get clean && \
    rm -rf /var-lib/apt/lists/*

# ------------------------------------------------------------------
# 6. 安装 LibreOffice (用于增强 docx/pptx 转换)
# ------------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libreoffice-writer \
    libreoffice-impress && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------
# 7. 配置工作环境
# ------------------------------------------------------------------
# 创建工作目录
WORKDIR /workspace

# 复制配置文件和模板
COPY templates /opt/pandoc/templates
COPY scripts /opt/pandoc/scripts

# 设置脚本执行权限并添加到 PATH
RUN chmod +x /opt/pandoc/scripts/*.sh
ENV PATH="/opt/pandoc/scripts:${PATH}"

# 默认进入 bash 环境
CMD ["/bin/bash"]