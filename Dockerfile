FROM centos/mongodb-32-centos7

USER root

RUN yum --enablerepo=extras install -y epel-release && \
    yum install -y --setopt=tsflags=nodocs python-pip && \
    yum clean all && \
    pip install awscli

ADD scripts/backup.sh /opt/rh/

RUN ["chmod", "+x", "/opt/rh/backup.sh"]
