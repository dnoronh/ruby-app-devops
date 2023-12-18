
#!/bin/bash

    docker build -t localhost:5000/ruby-app:2.0 ./docker-build/2
    docker push localhost:5000/ruby-app:2.0
    # ./docker-build/update-tag.sh "2.0"
