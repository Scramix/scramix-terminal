FROM httpd:2.4

# Copy your website files
COPY . /usr/local/apache2/htdocs/

# Configure Apache's directory listing and classic icons
RUN printf '\nServerName localhost\n' >> /usr/local/apache2/conf/httpd.conf \
 && printf '\nAlias /icons/ "/usr/local/apache2/icons/"\n' >> /usr/local/apache2/conf/httpd.conf \
 && printf '<Directory "/usr/local/apache2/htdocs">\n    Options +Indexes\n    AllowOverride All\n    Require all granted\n</Directory>\n' >> /usr/local/apache2/conf/httpd.conf \
 && printf '<Directory "/usr/local/apache2/icons">\n    Require all granted\n</Directory>\n' >> /usr/local/apache2/conf/httpd.conf \
 && printf 'IndexOptions FancyIndexing HTMLTable NameWidth=* DescriptionWidth=* SuppressHTMLPreamble\n' > /usr/local/apache2/conf/extra/classic-index.conf \
 && printf 'AddIcon /icons/folder.gif ^^DIRECTORY^^\nAddIcon /icons/unknown.gif .\nDefaultIcon /icons/unknown.gif\n' >> /usr/local/apache2/conf/extra/classic-index.conf \
 && printf '\nInclude conf/extra/classic-index.conf\n' >> /usr/local/apache2/conf/httpd.conf
