FROM httpd:2.4

COPY . /usr/local/apache2/htdocs/

RUN printf '\nServerName localhost\n' >> /usr/local/apache2/conf/httpd.conf \
 && sed -i 's/^DirectoryIndex .*/DirectoryIndex disabled/' /usr/local/apache2/conf/httpd.conf \
 && printf '\n<Directory "/usr/local/apache2/htdocs">\n    Options +Indexes\n    Require all granted\n</Directory>\n' >> /usr/local/apache2/conf/httpd.conf \
 && printf '\nIndexOptions FancyIndexing HTMLTable\n' >> /usr/local/apache2/conf/httpd.conf
