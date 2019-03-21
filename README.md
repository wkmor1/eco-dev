# eco-dev
Docker image for ecological software development

to run:

`docker pull wkmor1/eco-dev`

`docker run --volume="/path/on/host:/home/user" -p 8787:8787 --restart=no --detach=true --env="USER=user" --env="PASSWORD=pasword" --env="ROOT=TRUE" wkmor1/eco-dev`

access rstudio on:

`http://localhost:8787`

