FROM debian:bullseye-slim
RUN apt-get update && apt-get install gettext -y
