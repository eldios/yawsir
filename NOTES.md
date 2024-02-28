# Switchboard interview - Lele's technical submission

Hi, I'm Lele and this is my submission for the technical part.

Here is a quick explanation that follows the tech assignment ..plus some more.

## Assignment

SRE Project Requirements
---
Deliverables:
- Produce a basic “Hello, world!” HTTP server written in Rust.
  + POST / with JSON payload `{“name”: “Lele”} returns {“message”: “Hello, Lele”}`
    * The “Hello” is substituted for the `$GREETING` env variable (if present)
  - Includes necessary k8s manifests to deploy
- Write CI/CD Pipeline
  + Github actions (or your choice as long as you justify it) for CI
    * Build, test, publish (testing can just be 1 basic test so the CI has something to run)
  + Argo for CD
    * Basic gitops automated update flow
    * Must be able to configure `$MESSAGE` via argo GUI

## High-level description of the solution

### ChatGPT and online docs
While I extensively used Rocket documentation and online hints, I intentionally
did NOT use ChatGPT on the code side, especially since this was my first real
use of Rust I wanted to challenge the code and my approach to it.

I DID use ChatGPT to create the logo the ChatGPT Prompt I used for the image is:
```
You should draw an intro image for a github repo.
The github repo is called `yawsir` which stands for:

yet
another
web
server
in
rust

the logo should have a stickman which represents the software itself and should
be the "le fu" meme stickman and it should be surfing on a wave of web requests
and in the wave it's full of crabs and those crabs are the Rust logo.

Image should be 800x800 pixel

make it round with a trasparent background (sticker-like)
```
Then I cut the background with Gimp since ChatGPT didn't make it transparent
and converted from `webp` to `png`.

### Rust code
The Rust code I wrote, satisfies all the requisites of the assignment.
I actually started writing a web server from scratch, but then quickly realised
that it was not part of the requirements and fallback on using a more efficient
framework called [Rocket](https://rocket.rs) that is pretty much the de-facto
standard when writing simlar applications.

### Repository structure and reuse
This repository is heavily based and reuses lots of stuff I created in another
repo, for a similar project, [Nomar on Docker](https://github.com/eldios/nomad-on-docker).

The directory structure, Makefiles and much of the "kube"-related code is taken
from there and then adapted to this different project.


### Makefile
The repo code revolves around a series of `Makefile` which are set to tackle
each area of the submission (docker, kind, helm, ecc...) and tie everything
together for ease of use and expandability.

Ideally I'd move this to [`Just`](https://just.systems) as I think it's better/easier/faster to use
instead of the goold ol' faithful Make, but that was not in scope nor I had
time, sadly.

### Binaries pre-req
The first step that the `Makefile` will go through is check that all the needed
software are available, namely `kind`, `helm` & `kubectl`.

### Docker
The Rust code is packaged into a Docker container that uses the multi-phase 
approach and builds in a builder image and runs in the runtime phase.

The image is published automatically via GHA here https://hub.docker.com/repository/docker/eldios/yawsir

### KIND
I used KIND mostly for local development and tests, then most of the deployment
and code focuses on the AWS EKS implementation with full GitOps via ArgoCD.

### HELM
I packages the application via Helm in the `helm/yawsir` directory.
This is the way ArgoCD also installs and keeps the application in sync.

### ArgoCD
ArgoCD is setup with the _app-of-apps_ paradigm apprach in the `argo` directory.
I preferred not to expose ArgoCD to the public and used the common approach of
port-forwarding to reach it to verify that everything was working correctly.

### Terraform/OpenTofu
The entire infrastructure is entirely setup and managed via OpenTofu on AWS/EKS.
The code lives in the `terraform/` directory and it's based on some old modules
I had around that I updated to install the latest versions of all the Terraform
modules used.
