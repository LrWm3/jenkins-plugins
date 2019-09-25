FROM jenkins/jenkins:lts

USER root

# Must update AGAIN to install remaining
RUN apt-get update
RUN apt-get install -y apparmor \
  git \
  mercurial \
  openjdk-8-jdk

# install openjdk-11 for real
RUN wget https://download.java.net/openjdk/jdk11/ri/openjdk-11+28_linux-x64_bin.tar.gz -O /tmp/openjdk-11+28_linux-x64_bin.tar.gz && \
  tar xfvz /tmp/openjdk-11+28_linux-x64_bin.tar.gz --directory /usr/lib/jvm && \
  rm -f /tmp/openjdk-11+28_linux-x64_bin.tar.gz

# Setup Maven
ENV MAVEN_VERSION 3.3.3

RUN curl -fsSL http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /usr/share \
  && mv /usr/share/apache-maven-$MAVEN_VERSION /usr/share/maven \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
COPY settings.xml /root/.m2/settings.xml

# Configure Jenkins
COPY plugins.txt /usr/share/jenkins/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/plugins.txt

# Install extras for katalon
## Switch to user jenkins here because: https://forum.katalon.com/t/how-to-use-katalon-plugin-for-jenkins-on-ubuntu/17790
RUN wget https://github.com/katalon-studio/katalon-studio/releases/download/v5.10.1/Katalon_Studio_Linux_64-5.10.1.tar.gz && \
  tar -xzf Katalon_Studio_Linux_64-5.10.1.tar.gz && \
  mv Katalon_Studio_Linux_64-5.10.1 katalon_studio && \
  chmod 755 -R katalon_studio && \
  rm Katalon_Studio_Linux_64-5.10.1.tar.gz

RUN apt-get install -y firefox-esr xvfb fonts-liberation libxss1 xdg-utils lsb-release libappindicator3-1 libindicator7 \
  && wget -O google-chrome-stable_current_amd64.deb http://dl.google.com/linux/deb/pool/main/g/google-chrome-unstable/google-chrome-unstable_72.0.3595.2-1_amd64.deb \
  && dpkg -i google-chrome-stable_current_amd64.deb \
  && apt -y -f install

# Copy over xray into plugins folder directory (not part of the jenkins central repo for some reason)
COPY xray-for-jira-connector.hpi /var/jenkins_home/plugins/xray-for-jira-connector.hpi

# Copy over the groovy file
COPY config.groovy /usr/share/jenkins/ref/init.groovy.d/config.groovy
