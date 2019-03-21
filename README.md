# eco-dev
Docker image for ecological software development

to run:

`docker pull wkmor1/eco-dev`

`docker run --volume="</path/on/host>:/home/<user>" -p 8787:8787 --restart=no --detach=true --env="USER=<user>" --env="PASSWORD=<password>" --env="ROOT=TRUE" wkmor1/eco-dev`

replacing `</path/on/host>`, `<user>`, `<password>` with appropriate values.

Access rstudio on: `http://localhost:8787`

