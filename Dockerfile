FROM httpd:2.4
WORKDIR /usr/local/apache2/htdocs
COPY index.html .
EXPOSE 8080
