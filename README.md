<p align="center">
  <img src="assets/logo.png" alt="YAWSIR (Yet Another Web Server In Rust) .. according to ChatGPT"/>
</p>

<h1 align="center">🤖🦀YAWSIR:YetAnotherWebServerInRust🦀🤖</h1>

## 🧾 Intro

This repo provides a Web Server based on Rocket and Rust and all the related
tools to deploy it on Kubernetes, via Helm.

Plus, you can now add some humor to your web-server with this amazing surfing logo! (*)

***Happy Surf-ing!***

(*): thanks to [ChatGPT](https://chat.openai.com/) for the nice image! <3

## 🔌 Requirements

### Minimum
* [Docker](https://www.docker.com/) running on a Linux system
* working Internet connectvity (to download the tools and Docker images)

### Suggested
#### Local version
* [Git](https://git-scm.com/) .. to clone this repo .. unless you want to download it as a zip ;)
* [Make](https://www.gnu.org/software/make/)
* [KIND](https://kind.sigs.k8s.io/)
#### Full GitOps version
* [OpenTofu/Terraform](https://opentofu.org/)
* [AWS](https://console.aws.com)
* [Cloudflare](https://www.cloudflare.com)

## 📥 Quickstart (short version)
Using this repo is as simple as following the 3 steps below:

1. Clone this repo via Git. Usually:
```
git clone https://github.com/eldios/yawsir
```
2. cd into the directory and run Make:
```
cd yawsir && make
```
3. ✅ Done! ✅ 

## 🤖 Setup (longer version)

### 📖 If you want to know more before running any command
This repo comes with a handy Makefile that explains all the commands offered.

To get the full Help message, simply run:

```shell
make help
```
And you should get an output like:
```
################################################################################
#      yawsir (Yet Another Web Server in Rust)- app w/ Helm, Kind and AWS      #
################################################################################

# Install/Setup targets

all             - alias  -> full-up
[...]
```
## 🤠 Usage

You can work on this repo via KIND by simply running:
```shell
make
```
And waiting for KIND and Helm to finish their deployment.

Then you should be able to skip to the next secion.

## 😎 (Advanced) Usage

The true power of this setup though comes when you add ArgoCD in the mix,
and pair it with your Kubernetes cluster.

In the `terraform` directory there's enough boilerplate for your to deploy
you own AWS EKS Fargate Kubernetes cluster behind a Cloudflare proxy.

Then you can just use your own Repo plus ArgoCD to manage everything through
pure joy of GitOps!

### 🎉 ENJOY! 🎉

At this point you should be able to reach your running YAWSIR and get the help:
```shell
$ curl -ks http://yawsir.lele.rip/

YAWSIR (Yet Another Web Server In Rust)

USAGE:
    [GET]  /
[...]
```

Or even use its super-advanced auto-responding technology!
```shell
$ curl -ks https://yawsir.lele.rip/ -d '{"name": "Lele"}'
Hello, Lele!
```
Amazing, isn't it?!? 😲

## 🧹 Clean up

To clean up the KIND installation just run:
```shell
make down
```
And it should automatically take care of cleaning your KIND cluster.
