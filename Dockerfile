
FROM httpd:2.4

RUN sed -i 's/Listen 80/Listen 10000/' /usr/local/apache2/conf/httpd.conf \
    && sed -i 's/^#LoadModule autoindex_module/LoadModule autoindex_module/' /usr/local/apache2/conf/httpd.conf \
    && sed -i 's/^#LoadModule dir_module/LoadModule dir_module/' /usr/local/apache2/conf/httpd.conf \
    && sed -i 's/DirectoryIndex index.html/DirectoryIndex disabled/' /usr/local/apache2/conf/httpd.conf \
    && printf '\n<Directory "/usr/local/apache2/htdocs">\n    Options +Indexes\n    AllowOverride None\n    Require all granted\n</Directory>\n' >> /usr/local/apache2/conf/httpd.conf

COPY ./ /usr/local/apache2/htdocs/
