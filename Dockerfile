FROM ubuntu
MAINTAINER William K Morris <wkmor1@gmail.com>

# Set env vars
ENV PATH        /opt/julia:/usr/lib/rstudio-server/bin:/zonation/zig4:$PATH
ENV R_LIBS_USER ~/.r-dir/R/library

# Create directories
RUN    mkdir -p \
         /opt/julia \
         /zonation \
         /var/log/supervisor \
         /var/run/sshd

# Install Ubuntu packages
RUN    apt-get update \
    && apt-get install -y --no-install-recommends \
         apt-transport-https \
         cmake \
         curl \
         default-jdk \
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
         openssh-server \
         python3-dev \
         python3-pip \
         supervisor \
         texinfo \
         texlive \
         texlive-latex-extra \
         zip

# Download Rstudio, Shiny, Julia and Zonation,
RUN    RSTUDIOVER=$(curl https://s3.amazonaws.com/rstudio-server/current.ver) \
    && SHINYVER=$(curl https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION) \
    && JULIAVER=$(curl https://api.github.com/repos/JuliaLang/julia/releases/latest | grep tag_name | cut -d \" -f4 | sed 's/v//g') \
    && curl \
         -o rstudio.deb https://download2.rstudio.org/rstudio-server-$RSTUDIOVER-amd64.deb \
         -o shiny.deb https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$SHINYVER-amd64.deb \
         -o julia.tar.gz https://julialang.s3.amazonaws.com/bin/linux/x64/0.4/julia-$JULIAVER-linux-x86_64.tar.gz \
         -OL https://bintray.com/artifact/download/wkmor1/binaries/zonation.tar.gz 

# Install Jupyter
RUN    pip3 install jupyter ipyparallel

# Install Julia
RUN    tar xzf julia.tar.gz -C /opt/julia --strip 1 \
    && ln -s /opt/julia/bin/julia /usr/local/bin/julia

# Install R, RStudio, Shiny, Jags
RUN     echo "deb http://ppa.launchpad.net/marutter/rrutter/ubuntu trusty main" >> /etc/apt/sources.list \
    &&  gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys B04C661B \
    &&  gpg -a --export B04C661B | apt-key add - \
    &&  apt-get update \
    &&  apt-get install -y --no-install-recommends \
          r-base-dev \
          jags \
    && echo 'options(repos = list(CRAN = "https://cran.rstudio.com/"), unzip = "internal")' > /etc/R/Rprofile.site \
    && gdebi -n rstudio.deb \
    && echo r-libs-user=$R_LIBS_USER >> /etc/rstudio/rsession.conf \
    && ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc /usr/local/bin \
    && ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc-citeproc /usr/local/bin \
    && gdebi -n shiny.deb
    
# Install Zonation
RUN    tar xzf zonation.tar.gz -C zonation

# Set locale
ENV LANG        en_US.UTF-8
ENV LANGUAGE    $LANG
RUN    echo "en_US "$LANG" UTF-8" >> /etc/locale.gen \
    && locale-gen en_US $LANG \ 
    && update-locale LANG=$LANG LANGUAGE=$LANG \
    && dpkg-reconfigure locales
ENV LC_ALL      $LANG

# Clean up
RUN    apt-get clean \
    && apt-get autoremove \
    && rm -rf \
         var/lib/apt/lists \
         julia.tar.gz \
         rstudio.deb \
         shiny.deb \
         home/shiny \
         zonation.tar.gz

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
EXPOSE 3838
EXPOSE 8888
EXPOSE 22

# Start supervisor
CMD    supervisord
