#!/bin/bash

# Crear estructura de carpetas según la guía [cite: 25-45]
mkdir -p app
mkdir -p ansible/inventories
mkdir -p ansible/playbooks
mkdir -p ansible/roles/node_app/tasks
mkdir -p ansible/roles/node_app/templates
mkdir -p ansible/roles/node_app/handlers
mkdir -p .github/workflows

# 1. Crear un archivo de ejemplo de la App (Node.js) [cite: 27, 28]
cat <<EOF > app/index.js
const http = require('http');
const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end('Hola Mundo desde Ansible y GitHub Actions\n');
});
server.listen(3000, '0.0.0.0', () => {
  console.log('Servidor corriendo en el puerto 3000');
});
EOF

cat <<EOF > app/package.json
{
  "name": "myapp",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Sin tests por ahora\" && exit 0",
    "start": "node index.js"
  }
}
EOF

# 2. Configuración de Ansible (ansible.cfg) [cite: 47-51]
cat <<EOF > ansible/ansible.cfg
[defaults]
inventory = inventories/production.yml
host_key_checking = False
deprecation_warnings = False
EOF

# 3. Inventario (production.yml) [cite: 53-59]
# NOTA: Aquí debes cambiar la IP por la de tu túnel (ej: serveo.net)
cat <<EOF > ansible/inventories/production.yml
all:
  hosts:
    web1:
      ansible_host: TU_IP_O_TUNEL
      ansible_port: TU_PUERTO
      ansible_user: deploy
      ansible_python_interpreter: /usr/bin/python3
EOF

# 4. Tareas del Role (tasks/main.yml) [cite: 60-72]
cat <<EOF > ansible/roles/node_app/tasks/main.yml
- name: Ensure git is present
  apt:
    name: git
    state: present
  become: yes

- name: Ensure nodejs is installed
  apt:
    name: nodejs
    state: present
  become: yes

- name: Include deploy tasks
  import_tasks: deploy.yml
EOF

# 5. Tareas de Despliegue (tasks/deploy.yml) [cite: 73-106]
cat <<EOF > ansible/roles/node_app/tasks/deploy.yml
- name: Ensure app dir exists
  file:
    path: /home/deploy/apps/myapp
    state: directory
    owner: deploy
    group: deploy
    mode: '0755'

- name: Checkout app code from repo
  git:
    repo: 'https://github.com/TU_USUARIO/TU_REPO.git'
    dest: /home/deploy/apps/myapp
    version: "{{ git_ref | default('main') }}"
    force: yes
  become: no

- name: Install npm dependencies
  npm:
    path: /home/deploy/apps/myapp
    production: yes

- name: Copy systemd service file
  template:
    src: node-app.service.j2
    dest: /etc/systemd/system/myapp.service
  become: yes
  notify: Reload systemd

- name: Ensure service is started and enabled
  systemd:
    name: myapp
    state: started
    enabled: yes
  become: yes
EOF

# 6. Handler para Systemd [cite: 107-110]
cat <<EOF > ansible/roles/node_app/handlers/main.yml
- name: Reload systemd
  command: systemctl daemon-reload
  become: yes
EOF

# 7. Template del servicio (node-app.service.j2) [cite: 111-123]
cat <<EOF > ansible/roles/node_app/templates/node-app.service.j2
[Unit]
Description=My Node.js App
After=network.target

[Service]
User=deploy
WorkingDirectory=/home/deploy/apps/myapp
ExecStart=/usr/bin/node /home/deploy/apps/myapp/index.js
Restart=always
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# 8. Playbook principal (deploy.yml) [cite: 125-131]
cat <<EOF > ansible/playbooks/deploy.yml
- name: Deploy Node.js app to production
  hosts: all
  become: no
  vars:
    git_ref: "{{ lookup('env', 'GIT_REF') | default('main') }}"
  roles:
    - node_app
EOF

echo "¡Estructura creada con éxito! No olvides configurar tus Secrets en GitHub [cite: 185-187]."