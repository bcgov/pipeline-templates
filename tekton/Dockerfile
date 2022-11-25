FROM python:3.9

RUN mkdir /var/opt/tekton

WORKDIR /var/opt/


RUN 

# Get the kubectl binary.
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
# Make the kubectl binary executable.
RUN chmod +x ./kubectl
RUN  mv ./kubectl /usr/local/bin/kubectl

# Install OC command
RUN curl -o oc.tar https://downloads-openshift-console.apps.silver.devops.gov.bc.ca/amd64/linux/oc.tar
RUN tar -xvf oc.tar
RUN chmod +x ./oc
RUN mv ./oc /usr/local/bin/oc


WORKDIR /var/opt/tekton
ADD ./id_rsa /var/opt/tekton/id_rsa
COPY . .

# clean up this form
RUN sed -i 's/sonar-token=.*/sonar-token=/g ; s/ssh-key-path=.*/ssh-key-path=/g' ./overlays/secrets/secrets.ini

RUN sed -i 's/ssh-key-path=/ssh-key-path=\/var\/opt\/tekton\/id_rsa/g' ./overlays/secrets/secrets.ini
RUN echo $CONTEXT

COPY ./scripts/install.sh /docker-entrypoint-installTekton.sh
RUN chmod +x /docker-entrypoint-installTekton.sh

ENTRYPOINT [ "/docker-entrypoint-installTekton.sh" ]


