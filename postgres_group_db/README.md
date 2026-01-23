cat > postgres_group_db/README.md <<'MD'
# PostgreSQL Group Database (DoziLab App)

Pro Gruppe wird eine Ubuntu-VM mit PostgreSQL bereitgestellt. Standardmäßig ist PostgreSQL nur auf `localhost` erreichbar; Zugriff erfolgt sicher via SSH-Tunnel über die Floating IP.

## Parameter (Backend -> App)
- instance_name
- image (Default: Ubuntu 22.04 2025-01)
- flavor (Default: gp1.small)
- network (Default: NAT)
- external_network (Default: DHBW)
- group_login
- group_public_key
- ssh_cidr (Default: 0.0.0.0/0)
- db_name
- db_user
- db_password (hidden)
- postgres_version (Default: 14)

## Outputs (App -> Backend)
- floating_ip
- ssh_user
- ssh_port
- private_ip
- db_name
- db_user
- server_id
- ssh_tunnel_hint

## Zugriff (SSH-Tunnel)
1) Tunnel öffnen:
```bash
ssh -i <private_key> -L 5432:localhost:5432 <ssh_user>@<floating_ip>
