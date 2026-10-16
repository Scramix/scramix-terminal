
FROM httpd:2.4

RUN sed -i 's/Listen 80/Listen 10000/' /usr/local/apache2/conf/httpd.conf \
    && printf '\n<Directory "/usr/local/apache2/htdocs">\n    Options +Indexes\n    IndexOptions FancyIndexing HTMLTable NameWidth=* DescriptionWidth=*\n    IndexStyleSheet "/style.css"\n    DirectoryIndex disabled\n    Require all granted\n</Directory>\n' >> /usr/local/apache2/conf/httpd.conf

COPY ./ /usr/local/apache2/htdocs/

RUN rm -f /usr/local/apache2/htdocs/index.html

EXPOSE 10000


