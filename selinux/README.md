## Example

Tested on CentOS 8 on Equnix Metal

```bash
#!/bin/bash

USER_DATA_VER=1e0ff2ab67534321f598050776ad62cb028857ea

set -e

wget https://raw.githubusercontent.com/InjectiveLabs/mainnet-config/$USER_DATA_VER/selinux/scripts/user_data.sh \
	-O user_data.sh

echo "Starting user_data script"
chmod +x user_data.sh
./user_data.sh
```
