#!/usr/bin/env python3
"""
Quick Oracle Autonomous Database Connection Test
-------------------------------------------------
This script tests connectivity to Oracle ADB with mTLS (wallet required).

Prerequisites:
1. Python 3.x installed
2. cx_Oracle installed: pip3 install cx_Oracle --user
3. Wallet files extracted in a directory
4. Database credentials available

Usage:
    python3 test_adb_connection.py

Configuration:
    Edit the CONFIG section below or set environment variables.
"""

import cx_Oracle
import os
import sys
from pathlib import Path

# ============================================================================
# CONFIG - Update these values or set environment variables
# ============================================================================

CONFIG = {
    # Wallet location (directory containing tnsnames.ora, sqlnet.ora, etc.)
    'WALLET_LOCATION': os.getenv('WALLET_LOCATION', os.path.expanduser('~/wallet')),
    
    # Database credentials
    'DB_USERNAME': os.getenv('DB_USERNAME', 'ADMIN'),
    'DB_PASSWORD': os.getenv('DB_PASSWORD', ''),  # REQUIRED
    
    # Service name from tnsnames.ora (e.g., "mydb_high", "mydb_medium", "mydb_low")
    'SERVICE_NAME': os.getenv('SERVICE_NAME', ''),  # REQUIRED
}

# ============================================================================
# Functions
# ============================================================================

def print_header():
    """Print script header"""
    print("=" * 70)
    print("Oracle Autonomous Database Connection Test")
    print("=" * 70)
    print()

def validate_config():
    """Validate configuration before attempting connection"""
    errors = []
    
    # Check wallet location
    wallet_path = Path(CONFIG['WALLET_LOCATION'])
    if not wallet_path.exists():
        errors.append(f"Wallet directory not found: {CONFIG['WALLET_LOCATION']}")
    else:
        # Check for required wallet files
        required_files = ['tnsnames.ora', 'sqlnet.ora']
        for file in required_files:
            if not (wallet_path / file).exists():
                errors.append(f"Required wallet file missing: {file}")
    
    # Check password
    if not CONFIG['DB_PASSWORD']:
        errors.append("DB_PASSWORD is required. Set it in the script or via environment variable.")
    
    # Check service name
    if not CONFIG['SERVICE_NAME']:
        errors.append("SERVICE_NAME is required. Set it in the script or via environment variable.")
    
    if errors:
        print("❌ Configuration errors:")
        for error in errors:
            print(f"   - {error}")
        print()
        print("Please fix the configuration and try again.")
        print()
        print("Quick fix:")
        print("  export DB_PASSWORD='your-password'")
        print("  export SERVICE_NAME='your_db_high'")
        print("  export WALLET_LOCATION='~/wallet'")
        return False
    
    return True

def print_config():
    """Print current configuration (without password)"""
    print("Configuration:")
    print(f"  Wallet Location: {CONFIG['WALLET_LOCATION']}")
    print(f"  Username:        {CONFIG['DB_USERNAME']}")
    print(f"  Password:        {'*' * len(CONFIG['DB_PASSWORD'])} (hidden)")
    print(f"  Service Name:    {CONFIG['SERVICE_NAME']}")
    print()

def test_connection():
    """Test database connection and run basic queries"""
    
    # Set TNS_ADMIN environment variable for Oracle client
    os.environ['TNS_ADMIN'] = CONFIG['WALLET_LOCATION']
    
    print("Step 1: Attempting to connect...")
    print(f"         Using service: {CONFIG['SERVICE_NAME']}")
    
    try:
        # Attempt connection
        connection = cx_Oracle.connect(
            user=CONFIG['DB_USERNAME'],
            password=CONFIG['DB_PASSWORD'],
            dsn=CONFIG['SERVICE_NAME']
        )
        
        print("✅ CONNECTION SUCCESSFUL!")
        print()
        
        # Test 1: Simple query
        print("Step 2: Running test query...")
        cursor = connection.cursor()
        cursor.execute("SELECT 'Hello from Oracle ADB!' as message, SYSDATE as current_time FROM DUAL")
        row = cursor.fetchone()
        print(f"✅ Query successful!")
        print(f"   Message: {row[0]}")
        print(f"   Database time: {row[1]}")
        print()
        
        # Test 2: Get database version
        print("Step 3: Checking database version...")
        cursor.execute("SELECT BANNER FROM v$version WHERE ROWNUM = 1")
        version = cursor.fetchone()
        print(f"✅ Database version: {version[0]}")
        print()
        
        # Test 3: Get database name
        print("Step 4: Getting database information...")
        cursor.execute("SELECT name, db_unique_name FROM v$database")
        db_info = cursor.fetchone()
        print(f"✅ Database name: {db_info[0]}")
        print(f"   Unique name: {db_info[1]}")
        print()
        
        # Test 4: Check user info
        print("Step 5: Checking user information...")
        cursor.execute("SELECT USER, SYS_CONTEXT('USERENV', 'SESSION_USER') FROM DUAL")
        user_info = cursor.fetchone()
        print(f"✅ Connected as: {user_info[0]}")
        print()
        
        # Cleanup
        cursor.close()
        connection.close()
        
        print("=" * 70)
        print("🎉 ALL TESTS PASSED!")
        print("=" * 70)
        print()
        print("Your database connection is working correctly.")
        print("You can now configure your application with the same settings.")
        print()
        
        return True
        
    except cx_Oracle.Error as error:
        print("❌ CONNECTION FAILED!")
        print()
        print(f"Error: {error}")
        print()
        print_troubleshooting()
        return False
    
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False

def print_troubleshooting():
    """Print troubleshooting tips"""
    print("=" * 70)
    print("Troubleshooting Tips:")
    print("=" * 70)
    print()
    print("1. Verify wallet files:")
    print(f"   ls -la {CONFIG['WALLET_LOCATION']}")
    print()
    print("2. Check your IP is whitelisted:")
    print("   curl ifconfig.me")
    print("   Compare with OCI Console → ADB → Access Control List")
    print()
    print("3. Verify service name in tnsnames.ora:")
    print(f"   cat {CONFIG['WALLET_LOCATION']}/tnsnames.ora")
    print()
    print("4. Check password:")
    print("   Confirm it matches your ADB admin password")
    print()
    print("5. Wait for ACL propagation:")
    print("   After updating ACL, wait 2-5 minutes and retry")
    print()
    print("6. Test network connectivity:")
    print("   nc -zv <adb-hostname> 1522")
    print()

def main():
    """Main function"""
    print_header()
    
    # Validate configuration
    if not validate_config():
        sys.exit(1)
    
    # Print configuration
    print_config()
    
    # Run connection test
    success = test_connection()
    
    # Exit with appropriate code
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
