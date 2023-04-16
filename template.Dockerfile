FROM ${OLD_IMAGE}
ADD files-to-add.tar files-to-remove.list /
RUN if [ -s /files-to-remove.list ]; then xargs -d '\n' -a /files-to-remove.list rm -f ; fi; rm /files-to-remove.list;
