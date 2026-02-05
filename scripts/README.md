# Testing Scripts

This directory contains utility scripts for testing and validating the infrastructure.

## Available Scripts

### `test_adb_connection.py`

Quick Python script to test Oracle Autonomous Database connectivity.

**Purpose**: Verify database connection without deploying your full application.

**Prerequisites**:
- Python 3.x
- cx_Oracle package: `pip3 install cx_Oracle --user`
- Database wallet files extracted
- SSH access to backend instance

**Usage**:

```bash
# Set environment variables
export DB_PASSWORD='your-admin-password'
export SERVICE_NAME='your_db_high'
export WALLET_LOCATION='~/wallet'

# Run the test
python3 test_adb_connection.py
```

**Or edit the script directly** and set the CONFIG values at the top.

**What it tests**:
- ✅ Connection establishment
- ✅ Basic query execution
- ✅ Database version check
- ✅ User authentication

**Expected output** (on success):
```
======================================================================
Oracle Autonomous Database Connection Test
======================================================================

Configuration:
  Wallet Location: /home/opc/wallet
  Username:        ADMIN
  Password:        ******** (hidden)
  Service Name:    mydb_high

Step 1: Attempting to connect...
         Using service: mydb_high
✅ CONNECTION SUCCESSFUL!

Step 2: Running test query...
✅ Query successful!
   Message: Hello from Oracle ADB!
   Database time: 2026-02-05 03:35:42

Step 3: Checking database version...
✅ Database version: Oracle Database 19c Enterprise Edition

Step 4: Getting database information...
✅ Database name: MYDB
   Unique name: mydb_unique

Step 5: Checking user information...
✅ Connected as: ADMIN

======================================================================
🎉 ALL TESTS PASSED!
======================================================================

Your database connection is working correctly.
You can now configure your application with the same settings.
```

## More Information

See [DATABASE_TESTING.md](../DATABASE_TESTING.md) for comprehensive testing guide with multiple methods.
