# CamundaNotes
Notes on learnings with Camunda

## Download project from Camunda init

[Camunda Init](https://start.camunda.com/) is the web page that builds a springboot application with Camundad embeded for you. I'm using java 11 because why not.

The pom has postgres dependency added. 

I also added the goal to repackage so it will create the manifest for the jar file. 


Please remember to hide the important information that Camunda has in application.yaml
```yaml
camunda.bpm.admin-user:
  id: demo
  password: demo
```
You can add it to your CI/CD as a param. 
You can also add this information plus the database to a dev properties file if needed. For instance you can create a database in docker and run the application in development with the local database linked in the properties. 

```yaml
spring.datasource:
  url: jdbc:postgresql://localhost:21539/camundalocal
  username: admin
  password: admin
camunda.bpm.admin-user:
  id: admin
  password: admin
```
And run a postgres database with this command. 
```
docker run -p 21539:5432 --name camundalocal -d -e POSTGRES_PASSWORD=admin -e POSTGRES_USER=admin -e POSTGRES_DB=camundalocal postgres:13.1-alpine
```

## Docker
You could create a docker and docker compose to build a container.
Remember exposing the port, because Azure has an issue with this. 
```Docker
FROM maven:3.8.4-openjdk-11-slim

RUN mkdir -p /my-project

WORKDIR /my-project

ADD ./my-project  /my-project/

RUN mvn clean install

EXPOSE 8080

ENTRYPOINT java -jar -Xdebug /my-project/targe/my-project-1.0.0-SNAPSHOT.jar
```

If you want to test the container befor pushing, you can make a docker-compose file that will create the database and connections directly. Please check that you can, and should pass the camunda admin user information to the container and deployment. This is just for local runs, not deployment. 

```yaml
version: "3.9"
services:

  camunda-local-db:
    image: 'postgres:latest'
    container_name: camunda-local-db
    hostname: camunda-local-db
    expose:
      - 5432
    environment:
      - ENVIRONMENT=docker-compose
      - POSTGRES_USER=camunda_user
      - POSTGRES_PASSWORD=camunda_pass
      - POSTGRES_DB=camunda-local-db


  camunda-springboot:
    build: .
    container_name: camunda-springboot
    hostname: camunda-springboot
    depends_on:
      - camunda-local-db
    restart: always
    ports:
      - "8080:8080"
    environment:
      - SPRING_DATASOURCE_URL=jdbc:postgresql://camunda-local-db:5432/camunda-local-db
      - SPRING_DATASOURCE_USERNAME=camunda_user
      - SPRING_DATASOURCE_PASSWORD=camunda_pass
      - CAMUNDA_BPM_ADMIN_USER_ID=potatis
      - CAMUNDA_BPM_ADMIN_USER_PASSWORD=123
 ```

## Azure
### CI
Create a pipeline that connects with your repository, builds and pushes the docker image to a container registry (azure or not) You can set it up as well as you want, you can trigger the pipe with Pull Requests on several branches and then add the branch name to the image to use in different deployments.
```YAML
    - task: Docker@0
      displayName: 'Build an image'
      inputs:
        azureSubscription: 'FILLED IN AZURE DEVOPS'
        azureContainerRegistry: 'FILLED IN AZURE DEVOPS'
        action: Build an image
        imageName: $(Build.Repository.Name)-$(Build.SourceBranchName)
``` 

### CD
The most important thing when deploying an app service with azure devops is the app settings. 
Please remember to set up the port variable. 
```yaml
-DOCKER_REGISTRY_SERVER_PASSWORD YOUR_DOCKER_REGISTRY 
-DOCKER_REGISTRY_SERVER_USERNAME YOUR_USERNAME
-DOCKER_REGISTRY_SERVER_URL YOUR_REGISTRY_URL
-SPRING_DATASOURCE_PASSWORD YOUR_DATABASE_PASS
-SPRING_DATASOURCE_URL YOUR_DATABASE_URL
-SPRING_DATASOURCE_USERNAME YOUR_DATABASE_USERNAME 
-PORT 8080 
-WEBSITES_CONTAINER_START_TIME_LIMIT 1800 # The application make take longer to warm up the container so you may need to have more time before the app thinks the container died
-CAMUNDA_BPM_ADMIN_USER_ID YOUR_CAMUNDA_ADMIN_USERNAME 
-CAMUNDA_BPM_ADMIN_USER_PASSWORD YOUR_CAMUNDA_ADMING_PASS
```