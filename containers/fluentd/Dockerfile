FROM fluent/fluentd:v1.2-debian

RUN ["gem", "install", "fluent-plugin-elasticsearch", "--no-rdoc", "--no-ri", "--version", "2.11.10"]
RUN ["gem", "install", "fluent-plugin-grok-parser", "--no-rdoc", "--no-ri", "--version", "2.3.0"]
RUN ["gem", "install", "fluent-plugin-concat", "--no-rdoc", "--no-ri", "--version", "2.3.0"]

COPY ./conf /fluentd/etc

