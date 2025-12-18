FROM p3terx/aria2-pro:latest

COPY aria2.conf /aria2.conf
COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
