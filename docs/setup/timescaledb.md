


helm -n databases install refdataprecog helm/refdataprecog --set refdataprecog.db.defaultPassword="DEFAULT_PASSWD" --set refdataprecog.db.ownerPassword="OWNER_PASSWD" --set refdataprecog.db.authenticatorPassword="AUTH_PASSWD" --set refdataprecog.db.iotPassword="IOT_PASSWD" --set refdataprecog.db.hostname="timescaledb.databases.svc.cluster.local" --set refdataprecog.image.tag="IMAGE_TAG" 
