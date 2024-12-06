FROM jsreport/worker:4.7.0

USER root

# phantomjs
RUN apt-get update && \
    apt-get install -y libgtk2.0-dev pango1.0-dev libharfbuzz-dev libharfbuzz-icu0
RUN apt-get install -y bzip2 libxtst-dev libxss1 libnss3-dev libasound2-dev libnotify4 libxrender1 libxext6 xvfb dbus-x11
RUN apt-get install -y libfontconfig fonts-dejavu-core fonts-dejavu-extra fonts-droid-fallback fonts-tlwg-garuda fonts-tlwg-kinnari fonts-tlwg-laksaman fonts-tlwg-loma fonts-tlwg-mono fonts-tlwg-norasi fonts-tlwg-purisa fonts-tlwg-sawasdee fonts-tlwg-typewriter fonts-tlwg-typist fonts-tlwg-typo fonts-tlwg-umpush fonts-tlwg-waree

# phantomjs binary
RUN curl -Lo phantomjs.tar.bz2 https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.8-linux-x86_64.tar.bz2 && \
    tar jxvf phantomjs.tar.bz2 && \
    chmod +x phantomjs-1.9.8-linux-x86_64/bin/phantomjs && \
    mv phantomjs-1.9.8-linux-x86_64/bin/phantomjs /usr/local/bin/ && \
    rm -rf phantomjs*

RUN wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb && \
    dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb

# we need latest 0.12.6.1 wkhtmltopdf to fix the ssl issues with ubuntu focal
RUN wget -O wkhtmltox_0.12.6-1.focal_amd64.deb https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.focal_amd64.deb
RUN dpkg --install wkhtmltox_0.12.6-1.focal_amd64.deb && rm wkhtmltox_0.12.6-1.focal_amd64.deb

# unoconv - it needs an update of libreoffice on the xenial ubuntu
RUN apt-get -y install unoconv && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:libreoffice/ppa && \
    apt-get update && \
    apt install -y libreoffice

# cleanup
RUN rm -rf /var/lib/apt/lists/* /var/cache/apt/* && \
    rm -rf /src/*.deb && \
    rm -rf /tmp/*

USER jsreport:jsreport

RUN npm install @jsreport/jsreport-ejs@4.0.0 \
    @jsreport/jsreport-pug@5.0.0 \
    @jsreport/jsreport-html-to-text@4.2.0 \
    @jsreport/jsreport-docxtemplater@4.1.2 \
    @jsreport/jsreport-html-embedded-in-docx@4.1.2 \
    @jsreport/jsreport-office-password@4.1.0 \
    @jsreport/jsreport-unoconv@4.1.0 \
    @jsreport/jsreport-wkhtmltopdf@4.1.0 \
    @jsreport/jsreport-phantom-pdf@4.1.0 \
    @jsreport/jsreport-phantom-image@4.1.0 \
    phantomjs-exact-2-1-1@0.1.0 \
    cheerio-page-eval@1.0.0

RUN npm cache clean -f && \
    rm -rf /tmp/*

USER root