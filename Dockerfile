FROM odoo:19.0

USER root
COPY render-entrypoint.sh /render-entrypoint.sh
RUN chmod +x /render-entrypoint.sh
USER odoo

ENTRYPOINT ["/render-entrypoint.sh"]
CMD ["odoo"]
