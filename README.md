# hadron-two

So... I overengineered hadron-one and basically got sucked into the wormhole. I've simplified the design to be managed by terminal and utilize natively installed networking components on proxmox. VLANs are still being decided on, ELK will be used for endpoint monitoring, firewall will isolate sandbox. wireguard is on the host as well. 


ollama ui: http://<container-LAN-IP>:11434
proxmox ui: https://192.168.1.32:8006
openui: http://192.168.1.46:3000
n8n: http://192.168.1.47:5678
claude --resume 882b281a-ce3b-4b75-a0ec-7b1236d3bab3