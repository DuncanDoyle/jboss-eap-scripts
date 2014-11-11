#/bin/sh
#
# Script that patches a JBoss EAP installation.
#
# This script expects EAP not to be running. If EAP is already running, this script will produce undefined results.
#
# author: duncan.doyle@redhat.com
#

# Source function library.
if [ -f /etc/init.d/functions ]
then
	. /etc/init.d/functions
fi

function usage {
      echo "Usage: patch-jboss-eap.sh [args...]"
      echo "where args include:"
      echo "	-j		JBoss installation directory."
      echo "	-p		JBoss EAP patch file."
}

#Parse the params
while getopts ":j:p:h" opt; do
  case $opt in
    j)
      JBOSS_INSTALLATION_DIR=$OPTARG
      ;;
    p)
      PATCH_FILE=$OPTARG 
      ;;
    h)
      usage
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

PARAMS_NOT_OK=false

#Check params
if [ -z "$JBOSS_INSTALLATION_DIR" ] 
then
	echo "No JBoss installation directory specified!"
	PARAMS_NOT_OK=true
fi

if [ -z "$PATCH_FILE" ]
then
	echo "No patch file specified!"
	PARAMS_NOT_OK=true
fi

if $PARAMS_NOT_OK
then
	usage
	exit 1
fi

STARTUP_WAIT=30
# This is just a patch-script. W don't need an extensive console-log.
JBOSS_CONSOLE_LOG=jboss-patch-console.log

echo "JBoss installation directory: $JBOSS_INSTALLATION_DIR"
echo "Patch file: $PATCH_FILE"

# Start EAP in admin-only mode with the target profile
# Note that we're not checking whether a process is already running.
# We can use any profile we want when patching the installation.
#TODO: Add functionality to start JBoss EAP using the daemon function in RHEL/Linux.
echo "Starting JBoss EAP in 'admin-only' mode."
$JBOSS_INSTALLATION_DIR/bin/standalone.sh -c standalone.xml --admin-only 2>&1 > $JBOSS_CONSOLE_LOG &

# Some wait code. Wait till the system is ready. Basically copied from the EAP .sh scripts.
count=0
launched=false

until [ $count -gt $STARTUP_WAIT ]
  do
    grep 'JBAS015874:' $JBOSS_CONSOLE_LOG > /dev/null
    if [ $? -eq 0 ] ; then
      launched=true
      break
    fi
    sleep 1
    let count=$count+1;
  done
  
#Check that the platform has started, otherwise exit.

 if [ $launched = "false" ]
 then
	echo "JBoss EAP did not start correctly. Exiting."
	exit 1
else
	echo "JBoss EAP started."
fi

# Apply the patch
echo "Applying patch: $PATCH_FILE"
$JBOSS_INSTALLATION_DIR/bin/jboss-cli.sh -c "patch apply $PATCH_FILE"

# And we can shutdown the system using the CLI.
echo "Shutting down JBoss EAP."
$JBOSS_INSTALLATION_DIR/bin/jboss-cli.sh -c ":shutdown"
