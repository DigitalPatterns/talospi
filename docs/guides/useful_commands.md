

kubectl create ns test

kubectl -n test run -i -t test --restart=Never --rm --generator=run-pod/v1 \
--image=busybox 
--image-pull-policy="Always" \
-- /bin/bash -c "echo hello;sleep 3600"

kubectl -n test run -i -t test --restart=Never --rm --generator=run-pod/v1 \
--image=praqma/network-multitool \
--image-pull-policy="Always" \
-- /bin/sh -c "echo hello;sleep 3600"

kubectl -n test patch serviceaccount default -p '{"imagePullSecrets": [{"name": "regcred"}]}'


kubectl -n test exec -it test /bin/bash




java -Djavax.net.debug=ssl -Djavax.net.ssl.trustStore=/etc/keystore/cacerts -jar ./sslpoke-1.0.jar keycloak.pi.talos.rocks 443


keytool -list -keystore /etc/keystore/cacerts

mongodb://camundaAdmin:TALOS@mongodb-0.mongodb.databases.svc.cluster.local:27017,mongodb-1.mongodb.databases.svc.cluster.local:27017,mongodb-2.mongodb.databases.svc.cluster.local:27017/talos?replicaSet=rs0\&authSource=admin\&ssl=true\&retryWrites=true\&w=majority


openssl x509 -in certfile.pem -text –noout
