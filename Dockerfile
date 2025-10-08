#
# 高度定制化的 Pandoc 容器镜像
# 特性: 中文支持, Mermaid 图表, GitHub 风格, 多格式转换
# 版本: 1.0
#
FROM ubuntu:22.04

# 设置时区和语言环境, 避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8 \
    TZ=Asia/Shanghai \
    PUPPETEER_CONFIG=/opt/puppeteer-config.json

# ------------------------------------------------------------------
# 1. 安装基础依赖、中英文字体和本地化配置
# ------------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget curl git ca-certificates locales gnupg software-properties-common \
        fonts-noto-cjk fonts-noto-cjk-extra fonts-wqy-microhei fonts-wqy-zenhei \
        fonts-dejavu fonts-dejavu-core fonts-dejavu-extra \
        fonts-noto-color-emoji && \
    locale-gen zh_CN.UTF-8 && \
    update-locale LANG=zh_CN.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------
# 2. 安装最新版 Pandoc
# ------------------------------------------------------------------
RUN PANDOC_VERSION="3.2" && \
    wget -q "https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-1-amd64.deb" && \
    dpkg -i "pandoc-${PANDOC_VERSION}-1-amd64.deb" && \
    rm "pandoc-${PANDOC_VERSION}-1-amd64.deb" && \
    pandoc --version

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
# 4. 安装 Node.js 和 Mermaid CLI
# ------------------------------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get update && \
    apt-get install -y --no-install-recommends nodejs && \
    npm install -g @mermaid-js/mermaid-cli && \
    npm cache clean --force && \
    apt-get install -y --no-install-recommends \
        libasound2 libatk1.0-0 libatk-bridge2.0-0 libc6 libcairo2 libcups2 \
        libdbus-1-3 libexpat1 libfontconfig1 libgbm1 libglib2.0-0 libgtk-3-0 \
        libnspr4 libnss3 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 \
        libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 \
        libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------
# 5. 配置 Puppeteer 和 Mermaid 包装脚本
# ------------------------------------------------------------------
RUN echo '{"args":["--no-sandbox","--disable-setuid-sandbox"]}' > /opt/puppeteer-config.json

# 创建 Mermaid 包装脚本(移除验证命令避免依赖问题)
COPY tools  /usr/local/bin
RUN chmod +x /usr/local/bin/mermaid


# ------------------------------------------------------------------
# 6. 安装 Python 和 Pandoc 过滤器
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
    rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------
# 7. 安装 LibreOffice (用于增强 docx/pptx 转换)
# ------------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libreoffice-writer \
        libreoffice-impress && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------
# 8. 配置工作环境
# ------------------------------------------------------------------
RUN mkdir -p /opt/pandoc/templates /opt/pandoc/scripts /workspace
COPY templates /opt/pandoc/templates
COPY scripts /opt/pandoc/scripts
RUN chmod +x /opt/pandoc/scripts/*.sh




ENV PATH="/opt/pandoc/scripts:${PATH}"

WORKDIR /workspace

RUN ln -s /usr/local/bin/pandoc-mermaid /usr/local/bin/pandoc-mermaid-filter

# ------------------------------------------------------------------
# 9. 验证安装
# ------------------------------------------------------------------
RUN echo "=== 验证安装 ===" && \
    pandoc --version && \
    echo "---" && \
    xelatex --version | head -n 1 && \
    echo "---" && \
    mmdc --version && \
    echo "---" && \
    python3 --version && \
    echo "---" && \
    which pandoc-mermaid-filter && \
    echo "---" && \
    test -x /usr/local/bin/mermaid && echo "Mermaid wrapper: OK" && \
    echo "=== 所有组件安装成功 ==="

# 创建启动脚本
RUN printf '#!/bin/bash\n\
set -e\n\
\n\
echo "Pandoc Docker 环境已就绪"\n\
echo "Pandoc 版本: $(pandoc --version | head -n 1)"\n\
echo "工作目录: $(pwd)"\n\
\n\
exec "$@"\n' \
    > /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh




ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]
