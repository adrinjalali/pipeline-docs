# pipeline-docs

## Background
My journey started with [this](http://stackoverflow.com/questions/42719953/how-to-develop-a-rest-api-using-an-ml-model-trained-on-apache-spark) question on StackOverflow. I wanted to be able to do my usual data science stuff, mostly in python, and then deploy them somewhere serving like a REST API, responding to requests in real-time, using the output of the trained models. My original line of thought was this workflow:
- train the model in python or pyspark or in scala in apache spark.
- get the model, put it in an apache flink stream and serve.

This was the point at which I had been reading and watching tutorials and attending meetups related to these technologies. I was looking for a solution which is better than:
- train models in python
- write a web-service using `flask`, put it behind a `apache2` server, and put a bunch of them behind a load balancer.

This just sounded wrong, or at its best, not scalable. After a bit of research, I came across [pipeline.io](https://github.com/fluxcapacitor/pipeline) which seems to promise exactly what I'm looking for.

I also went through these two videos:
* [Continuously Train & Deploy Spark ML and Tensorflow AI Models from Jupyter Notebook to Production (StartupML Conference Jan 2017)](https://www.youtube.com/embed/swiPWUxBvSc), Jupyter Notebook available [here](https://github.com/fluxcapacitor/pipeline/blob/master/jupyterhub.ml/notebooks/talks/StartupML/Jan-20-2017/SparkMLTensorflowAI-HybridCloud-ContinuousDeployment.ipynb)
* [Recent Advancements in Data Science Workflows: From Jupyter-based Notebook to NetflixOSS-based Production (Big Data Spain Nov 2016)](https://www.youtube.com/embed/QPI_RtIrO7g)

In the two videos it is shown how the system can be used, which is great. But then you go to the documentation part, which is [this repository](https://github.com/fluxcapacitor/education.ml) now, and it tells you how to install it on your own server. The instructions might seem like they are Amazon AWS and/or Google Cloud specific (some are), but they're pretty usual stuff, and can be followed. They basically tell you to get a docker image (which is a large >16GB one), and run it. Once done, you have your own demo server using which you can play around.

Another important piece of information is the architecture diagram:

![Architecture](http://pipeline.io/img/architecture-overview-768x563.png)

And as it says, mapped to code:

![Architecture mapped to code](http://pipeline.io/img/architecture-overview-mapped-to-code-768x563.png)

Now I'm trying to figure out what _PipelineIO_ exactly is. I can think of the following items, some of which I guess are included in this project:
- Scripts to create docker images for specific sub-systems, i.e. those boxes in the architecture diagram, such as Apache Spark, Apache Cassandra, Apache Flink, etc.
- Scripts to facilitate communication between those boxes in the diagram
- Scripts to launch clusters/nodes with a specific purpose, such as _train_ cluster, _serve_ cluster, _storage_ cluster, etc.

The [script](https://github.com/fluxcapacitor/pipeline/blob/master/jupyterhub.ml/notebooks/talks/StartupML/Jan-20-2017/SparkMLTensorflowAI-HybridCloud-ContinuousDeployment.ipynb) used in one of the talks, uses no library from _pipeline.io_ which in a sense is promising, meaning data scientist mostly won't have to worry about what they do. That script seems to deal with _pipeline.io_ when it comes to talking to some servers. But unfortunately I haven't been able to find pieces in the documentation pointing to what those servers are, how they handle load balancing, how to deploy them, etc.

The aim of this repository is to explain those involved components as I figure them out, and point to external related documentation wherever necessary.

## Setup
There are two sets of documentations, one available on [education.ml](https://github.com/fluxcapacitor/education.ml) repository, and another one as wiki pages to the [pipeline](https://github.com/fluxcapacitor/pipeline/wiki/) repository.

I started by following the instructions on `education.ml`, which resulted in a quick installation on a single machine. This machine doesn't have to be on any cloud service, but the system has requirements that are not met by usual laptops. Once you have that instance up and running, you can explore services on that machine.

In my opinion, following the instructions provided on [pipeline](https://github.com/fluxcapacitor/pipeline/wiki/) itself gives better understanding of the system.

### Setup Docker/Kubernetes
The first step is to have a working kubernetes client, which is provided in a docker. To setup the docker you can follow [here](https://github.com/fluxcapacitor/pipeline/wiki/Setup-Docker-and-Kubernetes-CLI)

``` bash
sudo docker pull fluxcapacitor/kubernetes:v1.2.0
#first time                                                                                                                                                                                                       
sudo docker run -itd --name=kubernetes --privileged --net=host -v /home/USERNAME/.ssh:/root/.ssh fluxcapacitor/kubernetes:v1.2.0
#other times                                                                                                                                                                                                      
docker start kubernetes
                                                                                                                                                                                                                  
docker exec -it kubernetes bash 
```

You will need to work with docker, so it's a good idea to go ahead and familiarize yourself with it before continuing the process.

### Setup a kubernetes cluster on the cloud

``` bash
export KOPS_STATE_STORE=s3://pydata-ready.homenet.org
export CLUSTER_NAME=pydata-ready.homenet.org

aws s3 mb ${KOPS_STATE_STORE}
```

You can choose between [Amazon AWS](https://github.com/fluxcapacitor/pipeline/wiki/Setup-Pipeline-AWS), [Google Cloud](https://github.com/fluxcapacitor/pipeline/wiki/Setup-Pipeline-Google), or [Microsoft Azure](https://github.com/fluxcapacitor/pipeline/wiki/Setup-Pipeline-Azure).

__PREREQUISITE__: FQDN. You need to have an FQDN for your cluster. I didn't, so I followed [this option](https://github.com/kubernetes/kops/blob/master/docs/aws.md#scenario-3-subdomain-for-clusters-in-route53-leaving-the-domain-at-another-registrar). To run that script you need [jq](https://github.com/stedolan/jq/wiki/Installation) and `uuid`. These scripts are AWS specific.

``` bash
export ID=`uuid`
aws route53 create-hosted-zone --name $CLUSTER_NAME --caller-reference $ID | jq .DelegationSet.NameServers

# if already there:
aws route53 list-hosted-zones | jq '.HostedZones[] | select(.Name=="CLUSTER NAME HERE.") | .Id'
aws route53 get-hosted-zone --id "COPY_FROM_ABOVE" | jq .DelegationSet.NameServer
```

Then use one of them to set a free NS record for the subdomain [somewhere](http://freedns.afraid.org/subdomain/). You may need to wait some time for the NS record to propagate through global servers, and may need to stop/start your docker make sure its DNS cache is cleared.

You can continue the scripts as explained in `setup-aws.sh`.

## Testing

Then you can try some of the codes available [here](https://github.com/fluxcapacitor/source.ml).

I started with a notebook which uses `scikit-learn` on `iris` data, then saves the model in `pmml`, and pushes the model to the `prediction-pmml` service. You can get the information about the server using

    kubectl describe svc prediction-pmml

[Here](https://github.com/fluxcapacitor/source.ml/blob/master/jupyterhub.ml/notebooks/scikit-learn/Deploy_Scikit_Learn_Iris_DecisionTree.ipynb) is the link to the notebook I tested. The notebook demonstrates an example of mutable model, in which you push your new model into the running server, and it replaces the model for you. There is another approach which takes model servers as immutable and with each change, it deploys new docker images, and then switches from the old ones to the new ones.

You can test the service using `Apache JMeter` included in _PipelineIO_ [here](https://github.com/fluxcapacitor/pipeline/tree/master/loadtest.ml/apache-jmeter-3.0). Simply run `pipeline/loadtest.ml/apache-jmeter-3.0/bin/jmeter.sh`, then open a file such as `pipeline/loadtest.ml/tests/RecommendationServiceStressTest-AWS-airbnb.jmx`. Now you need to change some settings such as the server, path, and the body data. An example body data can be:

```
{
	"sepal length (cm)":5.1,
	"sepal width (cm)":3.5,
	"petal length (cm)":1.4,
	"petal width (cm)":0.2
}
```

It will look similiar to this:

![Apache JMeter](docs/fig/apache-jmeter-iris.png)

Before running the test, you can setup `Hystrix` to monitor the traffic, and response times.

Get the IP of `Hystrix` using:

    kubectl describe svc hystrix

Then go to `http://<hystrix ip>/hystrix-dashboard/` and add the address of your `turbine` stream, which you can find using

    kubectl describe svc turbine

Then you put `http://<turbine ip>/turbine.stream` into the address and add the stream. Now if you click on "Monitor Streams" you should see models you've added.

![Hystrix Example](docs/fig/hystrix-load.png)

You can also up-scale and down-scale the `prediction-pmml` service in your `weavescope`. Again, get the ip using:

    kubectl describe svc weavescope

And go to `http://<weavescope ip>`, and explore a bit there. The plus and minus buttons in this screenshot are _Scale up_ and _Scale down_ buttons.

![weavescope example](docs/fig/weavescope-example.png)
