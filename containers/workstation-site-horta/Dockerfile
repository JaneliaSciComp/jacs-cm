# Build the Workstation website
FROM jekyll/jekyll:3.3.1 as jekyll
WORKDIR /tmp/website
RUN git clone https://github.com/JaneliaSciComp/workstation-website.git .
COPY jekyll_config.yml _config.yml

# This doesn't work, still complains about needing bundler 2.0 or higher
#RUN gem update --system && gem uninstall bundler && gem install bundler -v 2.0.1

# For now we remove the version lock
RUN rm Gemfile.lock && bundler exec jekyll build

# Build the Workstation installers and update center
FROM janeliascicomp/builder:1.1.0 as builder
ARG APP_TAG=master
ARG KEYSTORE_PASSWORD=password
ARG WORKSTATION_CLIENT_MEM=8192m

COPY cert.crt /tmp/cert.crt
COPY cert.key /tmp/cert.key

WORKDIR /tmp/workstation
RUN git clone --branch $APP_TAG --depth 1 https://github.com/JaneliaSciComp/workstation.git . \
    && mkdir private \
    # Uses the certificate placed in the current folder
    && openssl pkcs12 -export -in /tmp/cert.crt -inkey /tmp/cert.key -name janeliaws -out cert.p12 -passout pass:$KEYSTORE_PASSWORD \
    && keytool -noprompt -importkeystore -srcstorepass $KEYSTORE_PASSWORD -deststorepass $KEYSTORE_PASSWORD -destkeystore private/keystore -srckeystore cert.p12 -srcstoretype PKCS12
    # To generate a self-signed certificate during the build, use this instead:
    #&& keytool -noprompt -genkey -validity 360 -storepass $KEYSTORE_PASSWORD -keypass $KEYSTORE_PASSWORD -alias janeliaws \
    #   -keystore private/keystore -dname "C=US, ST=VA, L=Ashburn, O=Janelia, CN=localhost"

COPY my.properties .
RUN WORKSTATION_BUILD_VERSION=$APP_TAG \
    envsubst < my.properties > ./modules/Core/src/main/resources/my.properties \
    && cat ./modules/Core/src/main/resources/my.properties \
    && sed -i "s/-J-Xmx[^[:space:]]\+/-J-Xmx${WORKSTATION_CLIENT_MEM}/" ./modules/application_horta/src/main/resources/horta.conf \
    && cat ./modules/application_horta/src/main/resources/horta.conf

RUN mvn --batch-mode -Djava.awt.headless=true -Dkeystorepass=$KEYSTORE_PASSWORD clean install -P horta \
    && cd modules/application_horta \
    && mvn --batch-mode -Djava.awt.headless=true -Dkeystorepass=$KEYSTORE_PASSWORD package -P horta,deployment

# Build the final container for serving the website and update center using Nginx
FROM nginx:stable
LABEL maintainer="rokickik@janelia.hhmi.org"
LABEL description="Horta Workstation Website and Update Center"

RUN mkdir -p /var/www/files /var/www/updates
COPY --from=jekyll /tmp/website/_site/ /var/www/
COPY --from=builder /tmp/workstation/modules/application_horta/src/main/app-resources/horta48.png /var/www/files/
COPY --from=builder /tmp/workstation/modules/application_horta/target/Horta* /var/www/files/
COPY --from=builder /tmp/workstation/modules/application_horta/target/netbeans_site/* /var/www/updates/
COPY ./nginx.conf /etc/nginx/conf.d/default.conf
