# Quick Database Connection Testing Guide

This guide helps you verify the Oracle Autonomous Database connection from your backend instances **without deploying your full application**.

## Prerequisites

After running `terraform apply`, you need:

1. **SSH access to a backend instance** (via bastion host)
2. **Database wallet** (download from Terraform output)
3. **Connection strings** (get from Terraform output)

## Step 1: Get Required Information

### 1.1 Get Database Connection Strings

```bash
# Get connection strings
terraform output adb_connection_strings

# Get wallet content (base64 encoded)
terraform output adb_wallet_content > wallet.b64
```

### 1.2 Get Backend Instance IP

```bash
# Get backend instance private IPs
terraform output instance_private_ips

# Get bastion public IP for SSH access
terraform output bastion_public_ip
```

### 1.3 SSH to Backend Instance

```bash
# SSH to bastion first
ssh -i ~/.ssh/your-key opc@<bastion-public-ip>

# From bastion, SSH to backend instance
ssh opc@<backend-private-ip>
```

Or use ProxyJump:
```bash
ssh -i ~/.ssh/your-key -J opc@<bastion-public-ip> opc@<backend-private-ip>
```

## Step 2: Quick Test Methods

### Method 1: Python Test Script (Recommended for Quick Test)

This is the fastest way to test connectivity without installing heavy tools.

#### Install Python Oracle Client

```bash
# On the backend instance
sudo dnf install -y python3 python3-pip

# Install cx_Oracle
pip3 install cx_Oracle --user
```

#### Download and Extract Wallet

```bash
# Create wallet directory
mkdir -p ~/wallet
cd ~/wallet

# Copy the base64 wallet from your local machine to the instance
# (Use scp or paste the content)

# Decode the wallet
base64 -d wallet.b64 > wallet.zip
unzip wallet.zip
```

#### Create Python Test Script

```bash
cat > test_db.py << 'EOF'
#!/usr/bin/env python3
import cx_Oracle
import os

# Configuration - UPDATE THESE VALUES
WALLET_LOCATION = os.path.expanduser("~/wallet")
USERNAME = "ADMIN"  # or your DB username
PASSWORD = "your-admin-password"  # Get from terraform.tfvars or terraform output
SERVICE_NAME = "your_db_name_high"  # From connection strings, e.g., "anonymousdb_high"

# Set wallet location
os.environ['TNS_ADMIN'] = WALLET_LOCATION

print(f"Testing connection to {SERVICE_NAME}...")
print(f"Using wallet from: {WALLET_LOCATION}")

try:
    # Attempt connection
    connection = cx_Oracle.connect(
        user=USERNAME,
        password=PASSWORD,
        dsn=SERVICE_NAME
    )
    
    print("✅ CONNECTION SUCCESSFUL!")
    
    # Test with a simple query
    cursor = connection.cursor()
    cursor.execute("SELECT 'Hello from Oracle ADB!' as message, SYSDATE as current_time FROM DUAL")
    row = cursor.fetchone()
    print(f"✅ Query successful: {row[0]}")
    print(f"   Database time: {row[1]}")
    
    # Get database info
    cursor.execute("SELECT * FROM v$version WHERE ROWNUM = 1")
    version = cursor.fetchone()
    print(f"✅ Database version: {version[0]}")
    
    cursor.close()
    connection.close()
    print("\n🎉 All tests passed! Database connection is working correctly.")
    
except cx_Oracle.Error as error:
    print(f"❌ CONNECTION FAILED!")
    print(f"Error: {error}")
    print("\nTroubleshooting tips:")
    print("1. Verify wallet files are in:", WALLET_LOCATION)
    print("2. Check your IP is whitelisted in OCI Console")
    print("3. Verify service name matches connection strings")
    print("4. Confirm password is correct")
    exit(1)
EOF

chmod +x test_db.py
```

#### Run the Test

```bash
# Update the script with your actual values first
nano test_db.py  # Edit USERNAME, PASSWORD, SERVICE_NAME

# Run the test
python3 test_db.py
```

### Method 2: SQL*Plus (Traditional Method)

#### Install Oracle Instant Client

```bash
# Download and install Oracle Instant Client
sudo dnf install -y oracle-instantclient-release-el8
sudo dnf install -y oracle-instantclient-basic oracle-instantclient-sqlplus

# Or manually download from Oracle website
```

#### Configure and Test

```bash
# Set environment variables
export TNS_ADMIN=~/wallet
export LD_LIBRARY_PATH=/usr/lib/oracle/21/client64/lib:$LD_LIBRARY_PATH
export PATH=/usr/lib/oracle/21/client64/bin:$PATH

# Test connection
sqlplus admin/<your-password>@<service_name>

# Once connected, try:
SELECT 'Connected!' FROM DUAL;
EXIT;
```

### Method 3: Java JDBC Test

#### Create Java Test Program

```bash
# Install Java if not present
sudo dnf install -y java-11-openjdk java-11-openjdk-devel

# Create test directory
mkdir -p ~/db-test
cd ~/db-test

# Download Oracle JDBC driver (or use existing one)
# wget https://download.oracle.com/otn-pub/otn_software/jdbc/ojdbc8.jar
```

Create `TestConnection.java`:

```java
import java.sql.*;
import java.util.Properties;

public class TestConnection {
    public static void main(String[] args) {
        // UPDATE THESE VALUES
        String dbURL = "jdbc:oracle:thin:@<service_name>?TNS_ADMIN=/home/opc/wallet";
        String username = "ADMIN";
        String password = "your-password";
        
        System.out.println("Testing Oracle ADB connection...");
        System.out.println("URL: " + dbURL);
        
        try {
            // Register JDBC driver
            Class.forName("oracle.jdbc.driver.OracleDriver");
            
            // Open connection
            System.out.println("Connecting to database...");
            Connection conn = DriverManager.getConnection(dbURL, username, password);
            System.out.println("✅ CONNECTION SUCCESSFUL!");
            
            // Test query
            Statement stmt = conn.createStatement();
            ResultSet rs = stmt.executeQuery("SELECT 'Hello!' as msg, SYSDATE FROM DUAL");
            
            if (rs.next()) {
                System.out.println("✅ Query successful: " + rs.getString(1));
                System.out.println("   Database time: " + rs.getString(2));
            }
            
            rs.close();
            stmt.close();
            conn.close();
            System.out.println("\n🎉 All tests passed!");
            
        } catch (SQLException e) {
            System.err.println("❌ SQL Error: " + e.getMessage());
            e.printStackTrace();
        } catch (Exception e) {
            System.err.println("❌ Error: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
```

Compile and run:
```bash
javac -cp ojdbc8.jar TestConnection.java
java -cp .:ojdbc8.jar TestConnection
```

### Method 4: Quick cURL Test (Check Network Connectivity)

Test if you can reach the database endpoint:

```bash
# Get the hostname from connection strings
# Example: adb.us-ashburn-1.oraclecloud.com

# Test port 1522 (mTLS)
nc -zv <adb-hostname> 1522

# Or use telnet
telnet <adb-hostname> 1522
```

## Step 3: Verify IP Whitelisting

### Check Your Public IP

```bash
# From the backend instance, check what IP the database sees
curl ifconfig.me
```

This should match the NAT Gateway IP that's whitelisted (e.g., `129.153.63.37`).

### Verify in OCI Console

1. Go to **Oracle Cloud Console** → **Autonomous Database** → Your Database
2. Click **Access Control List**
3. Verify your NAT Gateway IP is listed with `/32` suffix

## Troubleshooting

### Connection Refused or ORA-12506

**Problem**: `ORA-12506: TNS:listener rejected connection based on service ACL filtering`

**Solutions**:
- Verify your IP is whitelisted: `curl ifconfig.me` should match ACL
- Check OCI Console → ADB → Access Control List
- Wait 2-5 minutes after updating ACL for propagation
- Run `terraform apply` to ensure whitelisting is applied

### Wallet Issues

**Problem**: Wallet-related errors

**Solutions**:
- Verify wallet files are extracted: `ls ~/wallet` should show `tnsnames.ora`, `sqlnet.ora`, etc.
- Check TNS_ADMIN is set: `echo $TNS_ADMIN`
- Verify wallet permissions: `chmod 600 ~/wallet/*`
- Ensure wallet password matches admin password

### Service Name Issues

**Problem**: `ORA-12154: TNS:could not resolve the connect identifier`

**Solutions**:
- Check service name in `~/wallet/tnsnames.ora`
- Use exact service name from connection strings
- Common names: `<dbname>_high`, `<dbname>_medium`, `<dbname>_low`

### Authentication Failures

**Problem**: `ORA-01017: invalid username/password`

**Solutions**:
- Verify admin password from `terraform.tfvars`
- Check if using correct username (default is `ADMIN`)
- Password must meet complexity requirements

## Quick Reference Commands

```bash
# Get all needed info
terraform output adb_connection_strings
terraform output instance_private_ips
terraform output bastion_public_ip
terraform output nat_gateway_public_ip

# Check your egress IP from backend
curl ifconfig.me

# Test with Python (fastest)
python3 test_db.py

# Test with SQL*Plus
sqlplus admin/<password>@<service_name>

# Check wallet contents
ls -la ~/wallet/
cat ~/wallet/tnsnames.ora
```

## Success Indicators

✅ You should see:
- Connection established successfully
- Query returns results
- Database version displayed
- No firewall or ACL errors

## Next Steps

Once the connection test passes:
1. Configure your application with the same wallet and connection settings
2. Deploy your application
3. Monitor application logs for any connection issues

## Additional Resources

- [Oracle ADB Documentation](https://docs.oracle.com/en/cloud/paas/autonomous-database/)
- [cx_Oracle Documentation](https://cx-oracle.readthedocs.io/)
- [Oracle JDBC Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/21/jjdbc/)
- QUICKSTART.md - For infrastructure setup
- ARCHITECTURE.md - For understanding the network configuration
