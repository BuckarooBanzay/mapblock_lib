FROM registry.gitlab.com/minetest/minetest/server:5.5.0

USER root
RUN apk add git &&\
    mkdir -p /root/.minetest/worlds/world/worldmods/ &&\
    git clone https://github.com/BuckarooBanzay/mtzip /root/.minetest/worlds/world/worldmods/mtzip


ENTRYPOINT minetestserver --config /minetest.conf