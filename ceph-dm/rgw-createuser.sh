#!/bin/bash

[[ $# -ne 1 ]] && echo "Usage: $0 <username>" && exit

username=$!

# radosgw-admin user create --uid="testuser" --display-name="First User"
radosgw-admin user create --uid="${username}"

radosgw-admin subuser create --uid="${username}" --subuser="${username}:swift" --access=readwrite

# radosgw-admin subuser create --uid="testuser" --subuser="testuser:swift" --access=full
# full is not readwrite, as it also includes the access control policy.

# Show user info.
radosgw-admin user info --uid=${username}
