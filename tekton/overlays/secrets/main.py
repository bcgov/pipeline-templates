import pystache
import sys
import os
import shutil
import configparser
from collections import OrderedDict

os.chdir("overlays/secrets")

Config = configparser.ConfigParser()
try:
    Config.read("secrets.ini")
except Exception:
    pass

# Order the content of DEFAULT section alphabetically
Config._defaults = OrderedDict(
    sorted(Config._defaults.items(), key=lambda t: t[0]))

# Order the content of each section alphabetically
for section in Config._sections:
    Config._sections[section] = OrderedDict(
        sorted(Config._sections[section].items(), key=lambda t: t[0]))

# Order all sections alphabetically
Config._sections = OrderedDict(
    sorted(Config._sections.items(), key=lambda t: t[0]))

# ssh = Config._sections['ssh']
literals = Config._sections['literals']

# try:
#     os.makedirs(".secrets")
# except FileExistsError:
#     pass
# for key, value in ssh.items():
#     if value:
#         new_path = shutil.copy(value, '.secrets')
#         ssh[key] = new_path

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
# {{#ssh}}
# - name: {{k}}
#   files:
#     - {{v}}
# {{/ssh}}
"""

literals = [{"k": k, "v": v} for k, v in literals.items()]
# ssh = [{"k": k, "v": v} for k, v in ssh.items()]


class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


print(bcolors.OKCYAN + "Writing secrets to Kustomize..." + bcolors.ENDC)

original_stdout = sys.stdout

with open('kustomization.yaml', 'w') as f:
    sys.stdout = f
    print(pystache.render(input, {"literals": literals}))
    sys.stdout = original_stdout

print(bcolors.OKGREEN + "Completed..." + bcolors.ENDC)
