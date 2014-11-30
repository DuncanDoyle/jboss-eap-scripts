#
# Installs the Spring libraries as a module in JBoss EAP.
#
# author: ddoyle@redhat.com
#

# Source function library.
if [ -f /etc/init.d/functions ]
then
        . /etc/init.d/functions
fi

################################################ Parse input parameters #############################################
function usage {
      echo "Usage: install-spring-module.sh [args...]"
      echo "where args include:"
      echo "    -m              The JBoss module in ZIP format."
      echo "    -j              JBoss installation directory."
      echo "    -l              Name of the layer in which to install the module. Default is 'base'."
      echo "    -e              Enabled (truef/false) defines whether the layer should be enabled."
}

#Parse the params
while getopts ":m:j:l:e:h" opt; do
  case $opt in
    m)
      MODULE_FILE=$OPTARG
      ;;
    j)
      JBOSS_INSTALLATION_DIR=$OPTARG
      ;;
    l)
      MODULE_LAYER=$OPTARG
      ;;
    e)
      LAYER_ENABLED=$OPTARG
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
if [ -z "$MODULE_FILE" ]
then
        echo "No module ZIP file specified!"
        PARAMS_NOT_OK=true
fi
if [ -z "$JBOSS_INSTALLATION_DIR" ]
then
        echo "No JBoss installation directory specified!"
        PARAMS_NOT_OK=true
fi

if [ -z "$MODULE_LAYER" ]
then
	MODULE_LAYER="base"
fi

if [ -z "$LAYER_ENABLED" ]
then
	LAYER_ENABLED="true"
fi

if $PARAMS_NOT_OK
then
        usage
        exit 1
fi


################################################ Setup params.  #############################################


################################################ Unzip the module in the target layer  #############################################
unzip -d $JBOSS_INSTALLATION_DIR/modules/system/layers/$MODULE_LAYER $MODULE_FILE


################################################ Add module to layers.conf  #############################################
LAYERS_CONF=$JBOSS_INSTALLATION_DIR/modules/layers.conf

LAYERS_CONF_TEMP=layers.conf.temp

if $LAYER_ENABLED
then
        echo -e "Enabling module layer '$MODULE_LAYER' in '$LAYERS_CONF'.\n"
        if [ ! -f $LAYERS_CONF ]
        then
                echo "Creating layers.conf."
                echo "layers=$MODULE_LAYER" > $LAYERS_CONF_TEMP
        else
                gawk -v newItem=$MODULE_LAYER '{if (!match($0, /^layers=.*/))
                                        {print $0}
                                  else if (match($0,/.*\y'"$MODULE_LAYER"'\y.*/))
                                        {print $0}
                                  else
                                        {print $0","newItem}
                                }' $LAYERS_CONF > $LAYERS_CONF_TEMP
        fi
fi

# Replace the originl layers.conf with our temp file
cp $LAYERS_CONF_TEMP $LAYERS_CONF

echo -e "Layer installation complete.\n"
