#This demo is using bash on a Mac. Some of the OS commands will need to change to match your local environment and working directories.

#Set password variable used for sa password for SQL Server - https://www.youtube.com/watch?v=WyBKzBtaKWM
PASSWORD='S0methingS@Str0ng!'

#Change working directory to demos
cd ~/Dropbox/Presentations/PowerShellOntheRiver-2019/Containers\ -\ You\ Better\ Get\ on\ Board/demos

#Pull a container, discuss layers. Defaults to pulling the most recent image
docker pull mcr.microsoft.com/mssql/server:2017-latest


#list of images on this system
docker images
docker images | grep sql
docker images | grep powershell


#Check out the docker image details
docker image inspect mcr.microsoft.com/mssql/server:2017-latest | less

#Run a container
docker run \
    -e 'ACCEPT_EULA=Y' -e 'MSSQL_SA_PASSWORD='$PASSWORD \
    --name 'sql1' \
    -p 1433:1433 \
    -d mcr.microsoft.com/mssql/server:2017-latest

#List running containers
docker ps

#Access our application
sqlcmd -S localhost,1433 -U sa -Q 'SELECT @@SERVERNAME' -P $PASSWORD

#Run a second container, new name, new port, same source image
docker run \
    -e 'ACCEPT_EULA=Y' -e 'MSSQL_SA_PASSWORD='$PASSWORD \
    --name 'sql2' \
    -p 1434:1433 \
    -d mcr.microsoft.com/mssql/server:2017-latest

#List running containers
docker ps

#Access our second application, discuss servername, connect to specific port
sqlcmd -S localhost,1434 -U sa -Q 'SELECT @@SERVERNAME' -P $PASSWORD

#Copy a file into a container
#You can get WideWorldImporters-Full.bak from - https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak
docker cp WideWorldImporters-Full.bak sql2:/var/opt/mssql/data

#Restore a database to our container
sqlcmd -S localhost,1434 -U sa -i restore_wwi.sql -P $PASSWORD

#Connect to the container, start an interactive bash session
docker exec -it sql2 /bin/bash

#Inside container, check out the uploaded and process listing
ps -aux
ls -la /var/opt/mssql/data
exit

#Stopping a container
docker stop sql2

#List all containers
docker ps
docker ps -a

#Starting a container that's already local. All the parameters from the docker run command perist
docker start sql2
docker ps

#Stop them containers...
docker stop sql{1,2}
docker ps -a

#Stop all containers
#docker stop $(docker ps -a -q)

#Removing THE Container...THIS WILL DELETE YOUR DATA IN THE CONTAINER
docker rm sql{1,2}

#Remove all containers
#docker rm $(docker ps -a -q)

#Even though the containers are gone, we still have the image!
docker image ls | grep sql
docker ps -a

#Persisting data with a Container
#Start up a container with a Data Volume
docker run \
    -e 'ACCEPT_EULA=Y' -e 'MSSQL_SA_PASSWORD='$PASSWORD \
    --name 'sql1' \
    -p 1433:1433 \
    -v sqldata1:/var/opt/mssql \
    -d mcr.microsoft.com/mssql/server:2017-latest

#Is that container running?
docker ps 

#Copy the database into the Container and restore it
docker cp WideWorldImporters-Full.bak sql1:/var/opt/mssql/data
sqlcmd -S localhost,1433 -U sa -i restore_wwi.sql -P $PASSWORD

#Check out our list of databases
sqlcmd -S localhost,1433 -U sa -Q 'SELECT name from sys.databases' -P $PASSWORD

#Stop the container then remove it. Which normally would destroy our data
docker stop sql1
docker rm sql1

#Start the container back up, using the same data volume. We need docker run since we deleted the container.
docker run \
    -e 'ACCEPT_EULA=Y' -e 'MSSQL_SA_PASSWORD='$PASSWORD \
    --name 'sql1' \
    -p 1433:1433 \
    -v sqldata1:/var/opt/mssql \
    -d \
    mcr.microsoft.com/mssql/server:2019-CTP3.0-ubuntu

#Check out our list of databases...wut?
sqlcmd -S localhost,1433 -U sa -Q 'SELECT name from sys.databases' -P $PASSWORD

#List our current volumes
docker volume ls

#Dig into the details about our volume
docker volume inspect sqldata1

#stop our container
docker stop sql1

#delete our container
docker rm sql1

#remove the created volume
docker volume rm sqldata1

#remove the image
#docker rmi mcr.microsoft.com/mssql/server:2017-latest

#Remove the containers based on the name
#docker ps -a -q | grep "^k8s" | awk '{print $1}' | xargs docker rm

#Remove a the images based on the name
#docker images | grep "^k8s" | awk '{print $3}' | xargs docker rmi

#if there's a new image available if you pull again only new containers will be sourced from that image.
#You'll need to create a new container and migrate your data to it.

