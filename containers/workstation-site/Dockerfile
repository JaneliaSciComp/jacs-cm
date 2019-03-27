FROM jekyll/jekyll:3.3.1 as jekyll
WORKDIR /tmp/website
RUN git clone https://github.com/JaneliaSciComp/workstation-website.git .

# This doesn't work, still complains about needing bundler 2.0 or higher
#RUN gem update --system && gem uninstall bundler && gem install bundler -v 2.0.1

# For now we remove the version lock
RUN rm Gemfile.lock && bundler exec jekyll build

FROM registry.int.janelia.org/jacs/builder as builder
ARG APP_TAG
ARG API_GATEWAY_EXPOSED_HOST
ARG RABBITMQ_EXPOSED_HOST
ARG RABBITMQ_USER
ARG RABBITMQ_PASSWORD
ARG WORKSTATION_DISPLAY_VERSION
ARG KEYSTORE_PASSWORD

WORKDIR /tmp/workstation
RUN git clone https://github.com/JaneliaSciComp/workstation.git . && git fetch --tags && git checkout $APP_TAG

RUN mkdir private && \
    keytool -noprompt -genkey -validity 360 -storepass $KEYSTORE_PASSWORD -keypass $KEYSTORE_PASSWORD -alias janeliaws \
    -keystore private/keystore -dname "C=US, ST=VA, L=Ashburn, O=Janelia, CN=localhost"

COPY my.properties .
RUN API_GATEWAY_EXPOSED_HOST=$API_GATEWAY_EXPOSED_HOST \
    RABBITMQ_EXPOSED_HOST=$RABBITMQ_EXPOSED_HOST \
    WORKSTATION_DISPLAY_VERSION=$WORKSTATION_DISPLAY_VERSION \
    RABBITMQ_USER=$RABBITMQ_USER \
    RABBITMQ_PASSWORD=$RABBITMQ_PASSWORD \
    envsubst < my.properties > ./modules/DataBrowser/src/main/resources/my.properties
RUN cat ./modules/DataBrowser/src/main/resources/my.properties

RUN echo "org_janelia_it_workstation_nb_action_update_center=https://${API_GATEWAY_EXPOSED_HOST}/updates/updates.xml" \
    >> ./modules/DataBrowser/src/main/resources/org/janelia/it/workstation/gui/browser/Bundle.properties

RUN mvn --batch-mode -Djava.awt.headless=true -Dkeystorepass=$KEYSTORE_PASSWORD clean install \
    && cd modules/application \
    && mvn --batch-mode -Djava.awt.headless=true -Dkeystorepass=$KEYSTORE_PASSWORD package -P deployment

FROM nginx:stable
LABEL maintainer="rokickik@janelia.hhmi.org"
LABEL description="Workstation Website and Update Center"

RUN mkdir -p /var/www/files /var/www/updates
COPY --from=jekyll /tmp/website/_site/ /var/www/
COPY --from=builder /tmp/workstation/modules/application/target/JaneliaWorkstation* /var/www/files/
COPY --from=builder /tmp/workstation/modules/application/target/netbeans_site/* /var/www/updates/
COPY ./nginx.conf /etc/nginx/conf.d/default.conf

