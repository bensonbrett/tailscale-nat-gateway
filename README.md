# Tailscale NAT Gateway

A containerized solution that leverages Tailscale and iptables to securely route incoming NAT traffic from your Tailscale tailnet to internal services. This project was born out of the need to avoid running Traefik in host mode and to work around the connectivity limitations when using Docker’s `network_mode: service`.

## Background

When integrating Tailscale with Traefik in a containerized environment, several challenges arose:

- **Avoiding Host Mode:**  
  Running Traefik in host mode is often not acceptable due to security and isolation concerns. This solution keeps Tailscale and NAT functionality entirely within containers, ensuring that the host network remains untouched.

- **Traefik Connectivity Issues:**  
  Using Docker’s `network_mode: service` to have Traefik share a container’s network namespace with Tailscale can limit Traefik’s connectivity to other containers. This project overcomes those limitations by introducing a NAT gateway container that bridges the Tailscale network with your internal Docker network without forcing Traefik into host mode.

## How It Works

1. **Tailscale Integration:**  
   The container runs the Tailscale client (`tailscaled`) to provide a secure VPN endpoint. It uses an authentication key and any extra flags (such as advertise-tags) to complete the login process.

2. **NAT Configuration:**  
   Once Tailscale is running, iptables rules are applied:
   - **DNAT:** Incoming TCP traffic on port 80 from the Tailscale interface (`tailscale0`) is redirected to a target internal service.
   - **SNAT/MASQUERADE:** Outbound traffic is masqueraded to ensure proper routing back through the container.
   
3. **Container Bridging:**  
   The NAT gateway container is attached to both the Tailscale network (`tailscale_net`) and your internal Docker network. This configuration bridges incoming VPN traffic to internal services (like Traefik) without exposing the host network.

## Getting Started

### Prerequisites

- Docker and Docker Compose installed.
- A valid Tailscale authentication key.
- Basic familiarity with Docker networking.

### Setup

1. **Clone the Repository**

   ```bash
   git clone https://github.com/bensonbrett/tailscale-nat-gateway.git
   cd tailscale-nat-gateway

2. **Update nat-gateway.env**
   ```
   TAILSCALE_SUBNET=100.64.0.0/10
   INTERNAL_SUBNET=172.22.0.0/24
   TARGET_IP=172.22.0.10
   TARGET_PORT=443

3. **Update tailscale.env**

   Replace placeholder auth key with your tailscale auth key. 
   ```
   TS_AUTHKEY=tskey-client-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

4. **Run with Docker Compose**

   Run the provided docker compose file with docker compose up -d and access the whoami container from your whoami fqdn that is pointed to your tailnet ip. 

