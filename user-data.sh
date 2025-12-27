#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install PostgreSQL client
apt-get install -y postgresql-client

# Create a connection script
cat > /home/ubuntu/connect-db.sh << 'SCRIPT'
#!/bin/bash
echo "Connecting to PostgreSQL database..."
echo "Host: ${db_address}"
echo "Port: ${db_port}"
echo "Database: ${db_name}"
echo "Username: ${db_username}"
echo ""
PGPASSWORD='${db_password}' psql -h ${db_address} -p ${db_port} -U ${db_username} -d ${db_name}
SCRIPT

chmod +x /home/ubuntu/connect-db.sh
chown ubuntu:ubuntu /home/ubuntu/connect-db.sh

# Save connection details
cat > /home/ubuntu/db-connection-info.txt << 'INFO'
Database Connection Information
================================
Host: ${db_address}
Port: ${db_port}
Database: ${db_name}
Username: ${db_username}
Password: ${db_password}

To connect, run: ./connect-db.sh
INFO

chown ubuntu:ubuntu /home/ubuntu/db-connection-info.txt
chmod 600 /home/ubuntu/db-connection-info.txt
