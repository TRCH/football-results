#===========
#Build Stage
#===========
FROM bitwalker/alpine-elixir:1.7 as build


COPY config ./config
COPY lib ./lib
COPY priv ./priv
COPY proto ./proto
COPY rel ./rel
COPY mix.exs .
COPY mix.lock .

#Install dependencies and build Release
RUN export MIX_ENV=prod && \
    rm -Rf _build && \
    mix deps.get && \
    mix release

#Extract Release archive to /rel for copying in next stage
RUN APP_NAME="football_results" && \
    RELEASE_DIR=`ls -d _build/prod/rel/$APP_NAME/releases/*/` && \
    mkdir /export && \
    tar -xf "$RELEASE_DIR/$APP_NAME.tar.gz" -C /export

#================
#Deployment Stage
#================
FROM pentacent/alpine-erlang-base:latest

#Set environment variables and expose port
EXPOSE 8081
ENV REPLACE_OS_VARS=true \
    PORT=8081

#Copy and extract .tar.gz Release file from the previous stage
COPY --from=build /export/ .

#Change user
USER default

#Set default entrypoint and command
ENTRYPOINT ["/opt/app/bin/football_results"]
CMD ["foreground"]
