#FROM maven:3.5.2-jdk-8-alpine AS BUILD
#ADD . /app/titan/parent-pom/
#RUN ls /app/titan/parent-pom/
#WORKDIR /app/
#USER root
#RUN cd titan/parent-pom/ && pwd && mvn clean install && cd iraksha-ear/ && mvn clean install
#FROM openjdk:8-jdk-alpine
#RUN apk add --no-cache python py-pip
#RUN pip install awscli
#RUN aws --version
#ARG AWS_ACCESS_KEY_ID
#ARG AWS_SECRET_ACCESS_KEY
#ARG AWS_REGION=ap-south-1
#RUN aws s3 cp s3://titan-wildfly/wildfly-9.0.2.Final/ wildfly/ --recursive
#ADD wildfly/ /wildfly/
#WORKDIR /wildfly/
#USER root
#RUN chmod +x /wildfly/bin/add-user.sh
#RUN chmod +x /wildfly/bin/jboss-cli.sh
#RUN chmod +x /wildfly/bin/standalone.sh
#RUN /wildfly/bin/add-user.sh admin admin --silent
#RUN /wildfly/bin/jboss-cli.sh --user=admin --password=admin
#RUN ls
#COPY --chown=root:root --from=BUILD /app/titan/parent-pom/iraksha-ear/target/iraksha-monolithic.ear /wildfly/standalone/deployments/
FROM openjdk:8-jdk-alpine
ADD wildfly/ /wildfly/
WORKDIR /wildfly/
EXPOSE 8080
EXPOSE 9990
ENTRYPOINT ["sh","/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]

# Dockerfile should as short as we can prepare
                                                                                
