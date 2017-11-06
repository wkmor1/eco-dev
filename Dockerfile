FROM ubuntu:trusty
MAINTAINER William K Morris <wkmor1@gmail.com>

# Install Ubuntu packages
RUN    apt-get update \
    && apt-get install -y --no-install-recommends \
         apt-transport-https \
         curl \
         cmake \
         default-jdk \
         default-jre \
         fonts-texgyre \
         fonts-droid \
         g++-multilib \
         gdal-bin \
         gdebi-core \
         gfortran \
         ghostscript \
         git \
         libavcodec-extra-54 \
         libavdevice53 \
         libavfilter3 \
         libboost-filesystem-dev \
         libboost-program-options-dev \
         libboost-thread-dev \
         libcairo2-dev \
         libfftw3-dev \
         libgdal-dev \
         libmagick++-dev \
         libmagickwand5 \
         libpoppler-cpp-dev \
         libproj-dev \
         librsvg2-dev \
         libqt4-dev \
         libv8-dev \
         libzmq3-dev \
         lmodern \
         openssh-server \
         pgf \
         pdf2svg \
         python3-dev \
         python3-pip \
         python3-setuptools \
         qpdf \
         sudo \
         supervisor \
         texinfo \
         texlive \
         texlive-humanities \
         texlive-latex-extra \
         texlive-bibtex-extra \
         zip \
    && apt-get clean \
    && apt-get autoremove \
    && rm -rf var/lib/apt/lists/*

# Set locale
ENV LANG        en_US.UTF-8
ENV LANGUAGE    $LANG
RUN    echo "en_US "$LANG" UTF-8" >> /etc/locale.gen \
    && locale-gen en_US $LANG \
    && update-locale LANG=$LANG LANGUAGE=$LANG

# Download Rstudio, Julia, Zonation, Inconsolata and OpenBUGS
RUN    RSTUDIOVER=$(curl https://s3.amazonaws.com/rstudio-server/current.ver) \
    && JULIAVER=$(curl https://api.github.com/repos/JuliaLang/julia/releases/latest | grep tag_name | cut -d \" -f4 | sed 's/v//g') \
    && JULIAMAJOR=$(echo $JULIAVER | cut -c -3) \
    && curl \
         -o rstudio.deb https://download2.rstudio.org/rstudio-server-$RSTUDIOVER-amd64.deb \
         -o julia.tar.gz https://julialang-s3.julialang.org/bin/linux/x64/$JULIAMAJOR/julia-$JULIAVER-linux-x86_64.tar.gz \ 
         -OL https://bintray.com/artifact/download/wkmor1/binaries/zonation.tar.gz \
         -OL http://mirrors.ctan.org/install/fonts/inconsolata.tds.zip \
         -o OpenBUGS-3.2.3.tar.gz -L "http://www.openbugs.net/w/OpenBUGS_3_2_3?action=AttachFile&do=get&target=OpenBUGS-3.2.3.tar.gz"

# Install Jupyter
RUN    pip3 install --upgrade pip \
    && /usr/local/bin/pip3 install --upgrade six \
    && /usr/local/bin/pip3 install notebook

# Install Julia
RUN    mkdir -p /opt/julia \
    && tar xzf julia.tar.gz -C /opt/julia --strip 1 \
    && ln -s /opt/julia/bin/julia /usr/local/bin/julia \
    && rm -rf julia.tar.gz

# Install R, RStudio, rJava and JAGS
ENV R_LIBS_USER ~/.r-dir/R/library
RUN    echo "deb https://cran.rstudio.com/bin/linux/ubuntu trusty/" >> /etc/apt/sources.list \
    && gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E084DAB9 \
    && gpg -a --export E084DAB9 | apt-key add - \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
         r-base-dev \
         jags \
    && R CMD javareconf \
    && echo 'options(repos = list(CRAN = "https://cran.rstudio.com/"), download.file.method = "libcurl")' > /etc/R/Rprofile.site \
    && R -e 'install.packages("rJava")' \
    && gdebi -n rstudio.deb \
    && echo r-libs-user=$R_LIBS_USER >> /etc/rstudio/rsession.conf \
    && ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc /usr/local/bin \
    && ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc-citeproc /usr/local/bin \
    && apt-get clean \
    && apt-get autoremove \
    && rm -rf var/lib/apt/lists/* rstudio.deb

# Install Zonation
RUN    mkdir -p zonation \
    && tar xzf zonation.tar.gz -C zonation \
    && rm -rf zonation.tar.gz

# Install OpenBUGS
RUN    tar zxf OpenBUGS-3.2.3.tar.gz \
    && cd OpenBUGS-3.2.3 \
    && ./configure \
    && make \
    && make install \
    && cd / \
    && rm OpenBUGS-3.2.3.tar.gz \
    && rm -rf OpenBUGS-3.2.3

# Set path
ENV PATH /opt/julia:/usr/lib/rstudio-server/bin:/zonation/zig4:$PATH

# Install Inconsolata
RUN    unzip inconsolata.tds.zip -d /usr/share/texlive/texmf-dist \
    && echo "Map zi4.map" >> /usr/share/texlive/texmf-dist/web2c/updmap.cfg \
    && cd /usr/share/texlive/texmf-dist \
    && mktexlsr \
    && updmap-sys \
    && cd / \
    && rm -rf inconsolata.tds.zip

# Copy scripts
COPY   supervisord.conf /etc/supervisor/conf.d/
COPY   userconf.sh /usr/bin/
COPY   jupyter_notebook_config.py /
COPY   sshd_config /etc/ssh/

# Config
RUN    mkdir -p /var/log/supervisor /var/run/sshd \
    && chgrp staff /var/log/supervisor \
    && chmod g+w /var/log/supervisor \
    && chgrp staff /etc/supervisor/conf.d/supervisord.conf \
    && git config --system push.default simple \
    && git config --system url.'https://github.com/'.insteadOf git://github.com/

# Open ports
EXPOSE 8787
EXPOSE 8888
EXPOSE 22

# Start supervisor
CMD    supervisord
