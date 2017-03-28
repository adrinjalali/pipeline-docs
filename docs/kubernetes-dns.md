## Problem

`Kubernetes` wants you to associate an FQDN with your cluster. I personally find it a bug, not a feature, since it's extremely annoying when you don't have a domain for your experiment and you don't even want to. That's why there is [this](https://github.com/fluxcapacitor/pipeline/wiki/Setup-Pipeline-AWS#setup-environment-variables) step in the documentation.

There are some workarounds suggested [here](https://github.com/kubernetes-incubator/kube-aws/issues/244), and I took the one using [this](http://www.homenet.org/) service.

Basically, you follow [Scenario 3](https://github.com/kubernetes/kops/blob/master/docs/aws.md#scenario-3-subdomain-for-clusters-in-route53-leaving-the-domain-at-another-registrar), which gives you 4 nameservers. Then you choose one of them, and create an `NS` record on [homenet.org](http://www.homenet.org/), e.g. `your-random-pipeline-subdomain.homenet.org`.

Now you can continue from where you left [here](https://github.com/fluxcapacitor/pipeline/wiki/Setup-Pipeline-AWS#setup-environment-variables).