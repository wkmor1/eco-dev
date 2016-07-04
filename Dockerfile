FROM ubuntu:trusty
MAINTAINER William K Morris <wkmor1@gmail.com>

# Set env vars
ENV PATH        /usr/lib/rstudio-server/bin:/zonation/zig4:$PATH
ENV R_LIBS_USER ~/.r-dir/R/library

# Create directories
RUN    mkdir -p \
         /zonation \
         /var/log/supervisor \
         /var/run/sshd

# Install Ubuntu packages
RUN    apt-get update \
    && apt-get install -y --no-install-recommends \
         apt-transport-https \
         curl \
         default-jdk \
         default-jre \
         gdal-bin \
         gdebi-core \
         gfortran \
         git \
         libboost-filesystem-dev \
         libboost-program-options-dev \
         libboost-thread-dev \
         libcairo2-dev \
         libfftw3-dev \
         libgdal-dev \
         libproj-dev \
         libqt4-dev \
         libzmq3-dev \
         lmodern \
         openssh-server \
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
         zip

# Set locale
ENV LANG        en_US.UTF-8
ENV LANGUAGE    $LANG
RUN    echo "en_US "$LANG" UTF-8" >> /etc/locale.gen \
    && locale-gen en_US $LANG \ 
    && update-locale LANG=$LANG LANGUAGE=$LANG

# Download Rstudio, Zonation and inconsolata,
RUN    RSTUDIOVER=$(curl https://s3.amazonaws.com/rstudio-server/current.ver) \
    && curl \
         -o rstudio.deb https://download2.rstudio.org/rstudio-server-$RSTUDIOVER-amd64.deb \
         -OL https://bintray.com/artifact/download/wkmor1/binaries/zonation.tar.gz \
         -O http://mirrors.ibiblio.org/pub/mirrors/CTAN/install/fonts/inconsolata.tds.zip

# Install Jupyter
RUN    pip3 install jupyter sympy

# Install R, RStudio, Jags
RUN    echo "deb http://ppa.launchpad.net/marutter/rrutter/ubuntu trusty main" >> /etc/apt/sources.list \
    && gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys B04C661B \
    && gpg -a --export B04C661B | apt-key add - \
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
    && ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc-citeproc /usr/local/bin 
    
# Install Zonation
RUN    tar xzf zonation.tar.gz -C zonation

# Install inconsolata font
RUN    unzip inconsolata.tds.zip -d /usr/share/texlive/texmf-dist \
    && echo "Map zi4.map" >> /usr/share/texlive/texmf-dist/web2c/updmap.cfg \
    && cd /usr/share/texlive/texmf-dist \
    && mktexlsr \
    && updmap-sys 
    
# Clean up
RUN    apt-get clean \
    && apt-get autoremove \
    && rm -rf \
         var/lib/apt/lists/* \
         rstudio.deb \
         zonation.tar.gz \
         inconsolata.tds.zip

# Copy scripts
COPY   supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY   userconf.sh /usr/bin/userconf.sh
COPY   jupyter_notebook_config.py jupyter_notebook_config.py
COPY   sshd_config /etc/ssh/sshd_config

# Config
RUN    chgrp staff /var/log/supervisor \
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
