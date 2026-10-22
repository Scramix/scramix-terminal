FROM httpd:2.4

# Copy the repository into Apache's public directory
COPY . /usr/local/apache2/htdocs/

# Enable Apache's classic icons and directory-listing configuration
RUN sed -i \
    -e 's|^#Include conf/extra/httpd-autoindex.conf|Include conf/extra/httpd-autoindex.conf|' \
    -e 's|^DirectoryIndex index.html$|DirectoryIndex disabled|' \
    /usr/local/apache2/conf/httpd.conf
