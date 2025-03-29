#!/bin/sh
set -e

# Enable IP forwarding at runtime. Enable IP forwarding on the host if this is disabled. 
#sysctl -w net.ipv4.ip_forward=1

#echo "Auth key ${TS_AUTHKEY}"
echo "Target port ${TARGET_PORT}"
echo "Target ip ${TARGET_IP}"

# Start tailscaled
tailscaled &

# Authenticate with Tailscale (you'll need to pass AUTH_KEY as an environment variable)
if [ -n ${TS_AUTHKEY} ]; then
    tailscale up --authkey=${TS_AUTHKEY} --advertise-tags=tag:containerdev
else
    echo "No Tailscale authentication key provided. You'll need to authenticate manually."
fi

# Optional: flush existing NAT rules (adjust as needed)
iptables -t nat -F

# Configure DNAT: forward incoming TCP traffic on port 80 from the tailscale interface (assumed here as tailscale0)
# to the internal target service defined by TARGET_IP:TARGET_PORT.
# Adjust the interface (-i eth0) if your Tailscale network interface has a different name.
iptables -t nat -A PREROUTING -i tailscale0 -p tcp --dport 443 -j DNAT --to-destination ${TARGET_IP}:${TARGET_PORT}

# Configure SNAT/MASQUERADE on the internal outbound interface (assumed here as eth1)
# Adjust the interface (-o eth1) if needed.
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

echo "Routing container is configured: forwarding traffic on port 80 to ${TARGET_IP}:${TARGET_PORT}"

# Keep the container running
tail -f /dev/null