FROM google/cloud-sdk:slim

WORKDIR projet-sdtd

COPY . .

# Install kops, kubectl, terraform, ansible, jq for JSON parsing
RUN apt-get update &&\
    apt-get install -y gnupg software-properties-common curl apt-transport-https &&\
    curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - &&\
    apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" &&\
    curl -Lo kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64 &&\
    chmod +x kops &&\
    mv kops /usr/local/bin/kops &&\
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - &&\
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list &&\
    apt-get update &&\
    apt-get install -y kubectl terraform jq &&\
    pip3 install ansible

CMD ["bash"]
