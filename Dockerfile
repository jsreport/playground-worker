FROM jsreport/worker:4.14.4

USER root

# Runtime libraries, fonts and LibreOffice for the legacy rendering recipes.
RUN apt-get -o Acquire::Retries=5 update --error-on=any && \
    apt-get install -y --no-install-recommends \
      bzip2 libfontconfig1 libfreetype6 libharfbuzz0b libharfbuzz-icu0 \
      libgtk2.0-0t64 libxtst6 libxss1 libnss3 libasound2t64 libnotify4 \
      libxrender1 libxext6 xvfb xauth dbus-x11 \
      fonts-dejavu-core fonts-dejavu-extra fonts-droid-fallback fonts-thai-tlwg \
      xfonts-base xfonts-75dpi unoconv libreoffice && \
    rm -rf /var/lib/apt/lists/*

# LibreOffice 26 exposes absolutize through uno rather than unohelper.
RUN sed -i 's/unohelper\.absolutize/uno.absolutize/g' /usr/bin/unoconv

# Keep PhantomJS 1.9 for legacy templates.
RUN curl -fL --retry 5 -o /tmp/phantomjs.tar.bz2 https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.8-linux-x86_64.tar.bz2 && \
    tar -xjf /tmp/phantomjs.tar.bz2 -C /tmp && \
    install -m 755 /tmp/phantomjs-1.9.8-linux-x86_64/bin/phantomjs /usr/local/bin/phantomjs && \
    rm -rf /tmp/phantomjs* && \
    phantomjs --version

# The Jammy build uses OpenSSL 3, avoiding the obsolete libssl1.1 package.
RUN curl -fL --retry 5 -o /tmp/wkhtmltox.deb https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.jammy_amd64.deb && \
    apt-get -o Acquire::Retries=5 update --error-on=any && \
    apt-get install -y --no-install-recommends /tmp/wkhtmltox.deb && \
    rm -f /tmp/wkhtmltox.deb && \
    rm -rf /var/lib/apt/lists/* && \
    wkhtmltopdf --version && \
    unoconv --version

USER jsreport:jsreport

RUN npm install --save-exact @jsreport/jsreport-ejs@4.1.0 \
    @jsreport/jsreport-pug@5.1.0 \
    @jsreport/jsreport-html-to-text@4.3.0 \
    @jsreport/jsreport-docxtemplater@4.2.4 \
    @jsreport/jsreport-html-embedded-in-docx@4.2.4 \
    @jsreport/jsreport-office-password@4.2.0 \
    @jsreport/jsreport-unoconv@4.2.1 \
    @jsreport/jsreport-wkhtmltopdf@4.2.0 \
    @jsreport/jsreport-phantom-pdf@4.2.0 \
    @jsreport/jsreport-phantom-image@4.2.0 \
    phantomjs-exact-2-1-1@0.1.0 \
    cheerio-page-eval@1.0.0 && \
    npm cache clean -f && \
    rm -rf /tmp/*

USER root

# PhantomJS 2 bundles an older OpenSSL parser that cannot read Ubuntu's config.
# Limit the empty config to this legacy binary.
RUN phantom_path=node_modules/phantomjs-prebuilt/lib/phantom/bin/phantomjs && \
    mv "$phantom_path" "$phantom_path.bin" && \
    printf '%s\n' '#!/bin/sh' 'OPENSSL_CONF=/dev/null exec "$(dirname "$0")/phantomjs.bin" "$@"' > "$phantom_path" && \
    chmod 755 "$phantom_path" && \
    "$phantom_path" --version
