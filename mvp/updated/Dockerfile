RUN apt-get update && \
    apt-get install -y curl gnupg && \
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/debian/12/prod.list \
        > /etc/apt/sources.list.d/microsoft-prod.list
 
RUN apt-get update && \
    apt-get install -y msodbcsql18 unixodbc-dev krb5-user && \
    apt-get clean
