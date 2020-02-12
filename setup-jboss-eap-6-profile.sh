#/bin/sh
#
# Configures a JBoss EAP profile.
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
      echo "Usage: setup-jboss-eap-profile.sh [args...]"
      echo "where args include:"
      echo "	-s		JBoss source configuration profile."
      echo "	-t		JBoss target configuration profile."
      echo "	-j		JBoss installation directory."
      echo "    -b 		JBoss base dir."
      echo "	-c		CLI scripst directory."
}

#Parse the params
while getopts ":s:t:j:b:c:h" opt; do
  case $opt in
    s)
      SOURCE_PROFILE=$OPTARG
      ;;
    t)
      TARGET_PROFILE=$OPTARG
      ;;
    j)
      JBOSS_INSTALLATION_DIR=$OPTARG
      ;;
    b)
      JBOSS_BASE_DIR=$OPTARG
      ;;
    c)
      CLI_SCRIPTS_DIR=$OPTARG 
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

if [ -z "$SOURCE_PROFILE" ]
then
	echo "No source profile specified!"
	PARAMS_NOT_OK=true
fi

if [ -z "$TARGET_PROFILE" ]
then
	echo "No target profile specified!"
	PARAMS_NOT_OK=true
fi

if $PARAMS_NOT_OK
then
	usage
	exit 1
fi

STARTUP_WAIT=30
# This is just a setup-script. We don't need an extensive console-log.
JBOSS_CONSOLE_LOG=jboss-setup-console.log

if [ -z "$JBOSS_BASE_DIR" ]
then
  JBOSS_SERVER_LOG=$JBOSS_INSTALLATION_DIR/standalone/log/server.log
else
  JBOSS_SERVER_LOG=$JBOSS_BASE_DIR/log/server.log
fi

echo "Source profile $SOURCE_PROFILE"
echo "Target profile $TARGET_PROFILE"
echo "JBoss installation directory: $JBOSS_INSTALLATION_DIR"
echo "CLI scripts directory: $CLI_SCRIPTS_DIR"

#Copy the source profile to target profile.
echo "Copying $SOURCE_PROFILE profile to $TARGET_PROFILE."

if [ -z "$JBOSS_BASE_DIR" ]
then
  cp $JBOSS_INSTALLATION_DIR/standalone/configuration/$SOURCE_PROFILE $JBOSS_INSTALLATION_DIR/standalone/configuration/$TARGET_PROFILE
else 
  cp $JBOSS_BASE_DIR/configuration/$SOURCE_PROFILE $JBOSS_BASE_DIR/configuration/$TARGET_PROFILE
fi

# Start EAP in admin-only mode with the target profile
# Note that we're not checking whether a process is already running.
#TODO: Add functionality to start JBoss EAP using the daemon function in RHEL/Linux.
echo "Starting JBoss EAP in 'admin-only' mode."

if [ -z "$JBOSS_BASE_DIR" ]
then
  $JBOSS_INSTALLATION_DIR/bin/standalone.sh -c $TARGET_PROFILE --admin-only 2>&1 > $JBOSS_CONSOLE_LOG &
else 
  $JBOSS_INSTALLATION_DIR/bin/standalone.sh -c $TARGET_PROFILE -Djboss.server.base.dir=$JBOSS_BASE_DIR --admin-only 2>&1 > $JBOSS_CONSOLE_LOG &
fi

# Some wait code. Wait till the system is ready. Basically copied from the EAP .sh scripts.
count=0
launched=false

#Backup the old server.log
if [ -f "$JBOSS_SERVER_LOG" ]
then
	now=$(date +"%Y-%m-%d-%S")
	mv $JBOSS_SERVER_LOG $JBOSS_SERVER_LOG.$now
	touch $JBOSS_SERVER_LOG
fi

until [ $count -gt $STARTUP_WAIT ]
  do
#    grep 'JBAS015874:' $JBOSS_CONSOLE_LOG > /dev/null
    grep 'JBAS015874:' $JBOSS_SERVER_LOG > /dev/null
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

#TODO: The idea of the script was to be idempotent, i.e. copy an existing profile to a target, and apply changes to the target.
# The problem we have now is that 'patching' is not idempotent. Patching gives a patch error when a patch is applied twice.
# So, in our patch CLI script, we first need to check whether a patch has already been applied, before applying it again.
 
if [ ! -z "$CLI_SCRIPTS_DIR" ]
then
# Now that the system is running, we can run our CLI scripts. They will be executed in the order defined by 'sort -V'
	for f in `ls $CLI_SCRIPTS_DIR/*.cli | sort`
	do 
		echo "Executing CLI script: " $f
		$JBOSS_INSTALLATION_DIR/bin/jboss-cli.sh -c --file=$f
	done
fi

# And we can shutdown the system using the CLI.
echo "Shutting down JBoss EAP."
$JBOSS_INSTALLATION_DIR/bin/jboss-cli.sh -c ":shutdown"
