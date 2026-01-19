#!/bin/bash

# Script to add new users to the HTU environment
# Usage: ./htu_user_add.sh [username] [department]

USERNAME=$1
DEPARTMENT=$2
DEFAULT_PASS="Htu@123"

if [ -z "$USERNAME" ] || [ -z "$DEPARTMENT" ]; then
    echo "Usage: $0 [username] [department]"
    echo "Departments: hr, finance, engineering, management, it"
    exit 1
fi

# Check if group exists
if ! getent group "$DEPARTMENT" > /dev/null; then
    echo "Error: Department '$DEPARTMENT' does not exist."
    exit 2
fi

# Create User
# -m: Create home directory
# -G: Add to department group
# -s: Set shell
useradd -m -G "$DEPARTMENT" -s /bin/bash "$USERNAME"

if [ $? -eq 0 ]; then
    # Set Password
    echo "$USERNAME:$DEFAULT_PASS" | chpasswd
    
    # Force password change on first login
    chage -d 0 "$USERNAME"
    
    echo "User $USERNAME created successfully in group $DEPARTMENT."
    echo "Temporary password: $DEFAULT_PASS"
else
    echo "Failed to create user $USERNAME."
    exit 3
fi