FROM centos/mongodb-32-centos7

USER root

RUN yum --enablerepo=extras install -y epel-release && \
    yum install -y --setopt=tsflags=nodocs python-pip mysql && \
    yum clean all && \
    pip install awscli

COPY scripts /opt/rh/scripts

# Make backup scripts executable
RUN find /opt/rh/scripts -type f -exec chmod +x {} \;
