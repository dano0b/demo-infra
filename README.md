# demo-infra

# Requirements:
* empty aws account
* aws credentials and region exported in your shell
*

# instructions
* fork https://github.com/dano0b/demo-nodejs-mongodb-rest
  * update Jenkinsfile with a valid docker hub account
* update `main.tf` aws_key_pair with your public ssh key (used for manual login, ansible and jenkins)
* run `terraform apply`
* wait a few seconds (ec2.py dynamic inventory take sometimes some seconds)
* run `ansible-playbook initial.yml`
* run `ansible-playbook jenkins.yml`

setup jenkins with:
* `docker exec -it jenkins sh` on the jenkins server and install dependencies:
  * `apt install -y docker python-pip`
  * `pip install ansible boto`
  * `curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh`
* install ansible plugin
* add github server (personal access token with hook rights)
* add credentials
  * github
  * docker hub
* add multibranch pipeline "build"
  * use your fork for the demo nodejs app
* build at least once the the demoapp image


unfinished:
* second pipeline triggered after build
* tls certificate for elb

manual app deployment:
* run `ansible-playbook app.yml` (can be run manually with exported IMAGEVERSION variable)
