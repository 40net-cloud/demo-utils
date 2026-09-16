#cloud-config
package_upgrade: true
packages:
  - curl
  - ca-certificates
runcmd:
  - install -m 0755 -d /etc/apt/keyrings
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  - chmod a+r /etc/apt/keyrings/docker.asc
  - '. /etc/os-release && CODENAME="$${UBUNTU_CODENAME:-$VERSION_CODENAME}" && ARCH="$(dpkg --print-architecture)" && printf ''Types: deb\nURIs: https://download.docker.com/linux/ubuntu\nSuites: %s\nComponents: stable\nArchitectures: %s\nSigned-By: /etc/apt/keyrings/docker.asc\n'' "$CODENAME" "$ARCH" > /etc/apt/sources.list.d/docker.sources'
  - DEBIAN_FRONTEND=noninteractive apt update
  - DEBIAN_FRONTEND=noninteractive apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  - docker run -d --name demoapp1 --restart always -p 80:5000 bencuk/python-demoapp
  - docker run -d --name demoapp2 --restart always -p 81:5000 bencuk/python-demoapp