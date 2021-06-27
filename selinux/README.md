## Example

Tested on CentOS 8 on Equinix Metal

```bash
#!/bin/bash

USER_DATA_VER=0a5deca59e1bc51e866e6659b549c6f2878af6d7

set -e

wget https://raw.githubusercontent.com/InjectiveLabs/mainnet-config/$USER_DATA_VER/selinux/scripts/user_data.sh \
	-O user_data.sh

echo "Starting user_data script"
chmod +x user_data.sh
./user_data.sh
```
