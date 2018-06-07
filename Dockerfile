FROM centos/mongodb-32-centos7

USER root

COPY scripts /opt/rh/scripts

RUN yum --enablerepo=extras install -y epel-release && \
    yum install -y --setopt=tsflags=nodocs python-pip mysql && \
    yum clean all && \
    pip install -U pip && \
    pip install awscli s3cmd && \
    mkdir -p /opt/rh/scripts && \
    chown -R default:root /opt/rh/scripts

USER default
# Make backup scripts executable
RUN find /opt/rh/scripts -type f -exec chmod +x {} \;
