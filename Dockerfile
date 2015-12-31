FROM ubuntu:trusty-20151208
MAINTAINER William K Morris <wkmor1@gmail.com>

# Versions
ENV RSTUDIOVER 0.99.489
ENV SHINYVER   1.5.0.730
ENV JULIAVER   0.4.2
ENV BUGSVER    3.2.3-1
ENV ZIGVER     4.0.0

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
         apt-transport-https=1.0.1ubuntu2.5 \
         cmake=2.8.12.2-0ubuntu3 \
         curl=7.35.0-1ubuntu2.5 \
         default-jre=2:1.7-51 \
         gdal-bin=1.10.1+dfsg-5ubuntu1 \
         gdebi-core=0.9.5.3 \
         gfortran=4:4.8.2-1ubuntu6 \
         git=1:1.9.1-1ubuntu0.2 \
         libav-tools=6:9.18-0ubuntu0.14.04.1 \
         libboost-all-dev=1.54.0.1ubuntu1 \
         libgdal-dev=1.10.1+dfsg-5ubuntu1 \
         libfftw3-dev=3.3.3-7ubuntu3 \
         libproj-dev=4.8.0-2ubuntu2 \
         libqt4-dev=4:4.8.5+git192-g085f851+dfsg-2ubuntu4.1 \
         libqwt-dev=6.0.0-1.2 \
         libv8-dev=3.14.5.8-5ubuntu2 \
         libzmq3-dev=4.0.4+dfsg-2 \
         openssh-server=1:6.6p1-2ubuntu2.3 \
         python3-dev=3.4.0-0ubuntu2 \
         python3-pip=1.5.4-1ubuntu3 \
         supervisor=3.0b2-1 

# Download Rstudio, Shiny, Julia, OpenBUGS and Zonation,
RUN    curl \
         -O https://download2.rstudio.org/rstudio-server-$RSTUDIOVER-amd64.deb \
         -O https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$SHINYVER-amd64.deb \
         -O https://julialang.s3.amazonaws.com/bin/linux/x64/0.4/julia-$JULIAVER-linux-x86_64.tar.gz \
         -O http://pj.freefaculty.org/Ubuntu/15.04/amd64/openbugs/openbugs_${BUGSVER}_amd64.deb \
         -OL https://github.com/cbig/zonation-core/archive/$ZIGVER.tar.gz 

# Install Jupyter
RUN    pip3 install jupyter ipyparallel

# Install Julia
RUN    tar xzf julia-$JULIAVER-linux-x86_64.tar.gz -C /opt/julia --strip 1 \
    && ln -s /opt/julia/bin/julia /usr/local/bin/julia

# Install R, RStudio, Shiny, Jags and OpenBUGS
RUN     echo "deb http://ppa.launchpad.net/marutter/rrutter/ubuntu trusty main" >> /etc/apt/sources.list \
    &&  gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys B04C661B \
    &&  gpg -a --export B04C661B | apt-key add - \
    &&  apt-get update \
    &&  apt-get install -y --no-install-recommends \
          r-base-dev=3.2.3-1trusty0 \
          jags=4.0.0-1trusty2 \
    && echo 'options(repos = list(CRAN = "https://cran.rstudio.com/"), unzip = "internal")' > /etc/R/Rprofile.site \
    && gdebi -n rstudio-server-$RSTUDIOVER-amd64.deb \
    && echo r-libs-user=$R_LIBS_USER >> /etc/rstudio/rsession.conf \
    && gdebi -n shiny-server-$SHINYVER-amd64.deb \
    && gdebi -n openbugs_${BUGSVER}_amd64.deb 
    
# Install Zonation
RUN    tar xzf $ZIGVER.tar.gz \
    && cd zonation \
    && cmake ../zonation-core-$ZIGVER \
    && make

# Set local
ENV LANG        en_US.UTF-8
ENV LANGUAGE    $LANG
RUN    echo "en_US en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US en_US.UTF-8 \ 
    && update-locale LANG=$LANG LANGUAGE=$LANG \
    && dpkg-reconfigure locales
ENV LC_ALL      $LANG

# Clean up
RUN    apt-get clean \
    && apt-get autoremove \
    && rm -rf \
         var/lib/apt/lists \
         julia-$JULIAVER-linux-x86_64.tar.gz \
         rstudio-server-$RSTUDIOVER-amd64.deb \
         shiny-server-$SHINYVER-amd64.deb \
         home/shiny \
         openbugs_${BUGSVER}_amd64.deb \
         $ZIGVER.tar.gz \
         zonation-core-$ZIGVER 

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

CMD    supervisord
