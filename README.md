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

![Architecture](https://camo.githubusercontent.com/c3f0ef3a99da84b0346c625601770baff5ec532d/687474703a2f2f706970656c696e652e696f2f696d616765732f6172636869746563747572652d6f766572766965772d373638783536332e706e67)

And as it says, mapped to code:

![Architecture mapped to code](https://camo.githubusercontent.com/c5e35d8b2c088776d9ec52b360fecb45e6e43224/687474703a2f2f706970656c696e652e696f2f696d616765732f6172636869746563747572652d6f766572766965772d6d61707065642d746f2d636f64652d373638783536332e706e67)

Now I'm trying to figure out what _PipelineIO_ exactly is. I can think of the following items, some of which I guess are included in this project:
- Scripts to create docker images for specific sub-systems, i.e. those boxes in the architecture diagram, such as Apache Spark, Apache Cassandra, Apache Flink, Kubernetes, etc.
- Scripts to facilitate communication between those boxes in the diagram
- Scripts to launch clusters with a specific purpose, such as _train_ cluster, _serve_ cluster, _storage_ cluster, etc.

The [script](https://github.com/fluxcapacitor/pipeline/blob/master/jupyterhub.ml/notebooks/talks/StartupML/Jan-20-2017/SparkMLTensorflowAI-HybridCloud-ContinuousDeployment.ipynb) used in one of the talks, uses no library from _pipeline.io_ which in a sense is promising, meaning data scientist mostly won't have to worry about what they do. That script seems to deal with _pipeline.io_ when it comes to talking to some servers. But unfortunately I haven't been able to find pieces in the documentation pointing to what those servers are, how they handle load balancing, how to deploy them, etc.

The aim of this repository is to explain those involved components as I figure them out, and point to external related documentation wherever necessary.

## Hands on
There are two sets of documentations, one available on [education.ml](https://github.com/fluxcapacitor/education.ml) repository, and another one as wiki pages to the [pipeline](https://github.com/fluxcapacitor/pipeline/wiki/) repository.

I started by following the instructions on `education.ml`, which resulted in a quick installation on a single machine. This machine doesn't have to be on any cloud service, but the system has requirements that are not met by usual laptops. Once you have that instance up and running, you can explore services on that machine.

In my opinion, following the instructions provided on [pipeline](https://github.com/fluxcapacitor/pipeline/wiki/) itself gives better understanding of the system.

I had a problem with setting the domain/subdomain names, which I solved as explained in [docs/kubernetes-dns.md](docs/kubernetes-dns.md).