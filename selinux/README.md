## Example

Tested on CentOS 8 on Equinix Metal

```bash
#!/bin/bash

USER_DATA_VER=f56dbf35e2cdf470c26960c07b6d99c624397eb6

set -e

wget https://raw.githubusercontent.com/InjectiveLabs/mainnet-config/$USER_DATA_VER/selinux/scripts/user_data.sh \
	-O user_data.sh

echo "Starting user_data script"
chmod +x user_data.sh
./user_data.sh
```
