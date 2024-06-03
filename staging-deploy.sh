# Docker
sudo apt-get update
sudo apt-get -yq install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -yq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo service docker start
sudo docker run hello-world

# edit.tosdr.org
git clone https://github.com/tosdr/edit.tosdr.org.git
cd edit.tosdr.org
docker compose build
docker network create elasticsearch
docker network create dbs
docker compose up -d
docker exec -it edittosdrorg-web-1 rails db:seed
docker compose down
cd ..

# pyenv
apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
curl https://pyenv.run | bash
echo -e 'export PYENV_ROOT="$HOME/.pyenv"\nexport PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo -e 'eval "$(pyenv init --path)"\neval "$(pyenv init -)"' >> ~/.bashrc
source ~/.bashrc

# Hypothesis
git clone https://github.com/tosdr/h
cd h
git checkout do-staging
echo Note this will take several minutes...
pyenv install 3.11.7
pyenv init
pyenv shell 3.11.7
python -m pip install -rrequirements/dockercompose.txt
make services
make dev