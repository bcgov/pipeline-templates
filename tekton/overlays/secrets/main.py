from collections import OrderedDict
import pystache
import sys
import os
import shutil
import configparser
from dotenv.main import dotenv_values

os.chdir("overlays/secrets")

Config = configparser.ConfigParser()
try:
    Config.read("secrets.ini")
except Exception:
    pass
  
#Order the content of DEFAULT section alphabetically
Config._defaults = OrderedDict(
    sorted(Config._defaults.items(), key=lambda t: t[0]))

#Order the content of each section alphabetically
for section in Config._sections:
    Config._sections[section] = OrderedDict(
        sorted(Config._sections[section].items(), key=lambda t: t[0]))

# Order all sections alphabetically
Config._sections = OrderedDict(
    sorted(Config._sections.items(), key=lambda t: t[0]))

ssh      = Config._sections['ssh']
literals = Config._sections['literals']
docker   = Config._sections['docker']

try:
    os.makedirs(".secrets")
except FileExistsError:
    pass
for key, value in ssh.items():
    new_path = shutil.copy(value, '.secrets')
    ssh[key] = new_path
for key, value in docker.items():
    new_path = shutil.copy(value, '.secrets')
    docker[key] = new_path

input = """apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
generatorOptions:
  disableNameSuffixHash: true
secretGenerator:
{{#literals}}
- name: {{k}}
  type: Opaque
  literals:
    - {{k}}={{v}}
{{/literals}}
{{#ssh}}
- name: {{k}}
  files:
    - {{v}}
{{/ssh}}
{{#docker}}
- name: {{k}}
  files:
    - {{v}}
  type: kubernetes.io/dockerconfigjson
{{/docker}}
"""
#
literals = [{"k": k, "v": v} for k, v in literals.items()]
ssh      = [{"k": k, "v": v} for k, v in ssh.items()]
docker   = [{"k": k, "v": v} for k, v in docker.items()]

print('Writing secrets to Kustomize...')
#
original_stdout = sys.stdout
#
with open('kustomization.yaml', 'w') as f:
    sys.stdout = f
    print(pystache.render(input, {"literals": literals, "ssh": ssh, "docker": docker}))
    sys.stdout = original_stdout
