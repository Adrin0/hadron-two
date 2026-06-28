# Beats Configuration

Configure Filebeat, Metricbeat, and Packetbeat on LXC 105 (DVWA) to forward logs to LXC 104 (ELK). The same pattern applies to any other container you want to monitor.

Replace `<ELK_LXC_IP>` below with the actual LAN IP of LXC 104 (get it with `pct exec 104 -- hostname -I`).

---

## Filebeat

Edit `/etc/filebeat/filebeat.yml`:

```yaml
output.elasticsearch:
  hosts: ["<ELK_LXC_IP>:9201"]
  username: "<your_username>"
  password: "<your_password>"

setup.kibana:
  host: "<ELK_LXC_IP>:5602"
```

Enable the elasticsearch-xpack module and load dashboards:
```bash
sudo filebeat modules enable elasticsearch-xpack
sudo filebeat setup --dashboards
sudo systemctl start filebeat
```

Test the output:
```bash
sudo filebeat test output
```

---

## Metricbeat

Edit `/etc/metricbeat/metricbeat.yml`:

```yaml
output.elasticsearch:
  hosts: ["<ELK_LXC_IP>:9201"]
  username: "<your_username>"
  password: "<your_password>"

setup.kibana:
  host: "<ELK_LXC_IP>:5602"

xpack.monitoring.enabled: true
```

Enable the elasticsearch-xpack module and load dashboards:
```bash
sudo metricbeat modules enable elasticsearch-xpack
sudo metricbeat setup --dashboards
sudo systemctl start metricbeat
```

Test:
```bash
sudo metricbeat test output
```

---

## Packetbeat

Edit `/etc/packetbeat/packetbeat.yml`:

```yaml
output.elasticsearch:
  hosts: ["<ELK_LXC_IP>:9201"]
  username: "<your_username>"
  password: "<your_password>"

setup.kibana:
  host: "<ELK_LXC_IP>:5602"
```

Load dashboards and start:
```bash
sudo packetbeat setup --dashboards
sudo systemctl start packetbeat
```

Test:
```bash
sudo packetbeat test output
```

---

## Verify in Kibana

1. Open `http://<ELK_LXC_IP>:5602`.
2. Go to **Dashboard** in the left menu.
3. Search for `Filebeat`, `Metricbeat`, or `Packetbeat` to confirm pre-built dashboards loaded.

---

## Adding Beats to Other Containers

To monitor LXC 101/102/103 as well, install Beats inside each container using the same process:

```bash
# On the Proxmox host — execute inside any container
pct exec <CTID> -- bash -c "
  wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch \
    | gpg --dearmor -o /usr/share/keyrings/elasticsearch-archive-keyring.gpg
  echo 'deb [signed-by=/usr/share/keyrings/elasticsearch-archive-keyring.gpg] \
    https://artifacts.elastic.co/packages/7.x/apt stable main' \
    | tee /etc/apt/sources.list.d/elastic-7.x.list
  apt update && apt install -y filebeat metricbeat
  systemctl enable filebeat metricbeat
"
```

Then update the config files with `<ELK_LXC_IP>` as above.
