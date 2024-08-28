#!/bin/bash
 
if [ "$2" == "" ]; then
    	echo usage: $0 \<Branch\> \<RState\>
    	exit -1
else
	versionProperties=install/version.properties
	theDate=\#$(date +"%c")
	module=$1
	branch=$2
	workspace=$3
fi

function getProductNumber {
        product=`cat $PWD/build.cfg | grep $module | grep $branch | awk -F " " '{print $3}'`
}

function setRstate {
        revision=`cat $PWD/build.cfg | grep $module | grep $branch | awk -F " " '{print $4}'`
	
	if git tag | grep $product-$revision; then
        	rstate=`git tag | grep ${product}-${revision} | tail -1 | sed s/.*-// | perl -nle 'sub nxt{$_=shift;$l=length$_;sprintf"%0${l}d",++$_}print $1.nxt($2) if/^(.*?)(\d+$)/';`
        else
		ammendment_level=01
	        rstate=$revision$ammendment_level
	fi
	mv volte/build/feature-release.xml volte/build/feature-release.${rstate}.xml
	echo "Building rstate:$rstate"
}

function Arm104nexusDeploy {
	RepoURL=https://arm1s11-eiffel013.eiffel.gic.ericsson.se:8443/nexus/content/repositories/assure-releases 

	GroupId=com.ericsson.eniq.netanserver.features
	ArtifactId=$module
	zipName=Ericsson-VoLte-Report
	
	echo "****"	
	echo "Deploying the zip /$zipName-18A.zip as ${ArtifactId}${rstate}.zip to Nexus...."
        mv target/$zipName-18A.zip target/${ArtifactId}.zip
	echo "****"	

  	mvn deploy:deploy-file \
	        	-Durl=${RepoURL} \
		        -DrepositoryId=assure-releases \
		        -DgroupId=${GroupId} \
		        -Dversion=${rstate} \
		        -DartifactId=${ArtifactId} \
		        -Dfile=target/${ArtifactId}.zip
		      
}


getProductNumber
setRstate

#add maven command here
mvn package

Arm104nexusDeploy

rsp=$?

if [ $rsp == 0 ]; then

  git tag $product-$rstate
  git pull
  git push --tag origin $branch

fi

exit $rsp
