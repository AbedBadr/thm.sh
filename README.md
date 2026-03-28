# thm.sh

thm.sh is a helper script for TryHackMe - connecting and disconnecting the vpn, saving the target koth/lab machine's ip in a variable, $VMIP and logging the session.

The reason for 2 different VPN's is that after TryHackMe updated their VPN's, they don't work with King of The Hill and therefore the old VPN has to be used when playing KOTH. 

## Usage
```
./thm.sh [OPTIONS]
  -x, --koth    Use KOTH VPN
  -b, --lab     Use Lab VPN
  -i, --ip      Set VM IP (updates shell config file)
  -k, --kill    Kill active VPN session
  -h, --help    Show this help
```
