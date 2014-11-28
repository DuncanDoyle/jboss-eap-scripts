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
      echo "    -j              JBoss installation directory."
      echo "    -l              Name of the layer in which to install the module. Default is 'base'."
      echo "    -e              Enabled (truef/false) defines whether the layer should be enabled."
}

#Parse the params
while getopts ":j:l:e:h" opt; do
  case $opt in
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

MODULE_PATH=org/springframework
MODULE_SLOT=main

MODULE_XML=module.xml
MODULE_TEMPLATE_XML=module.xml.template

MODULE_LAYER_PATH=./target/layer/$MODULE_LAYER
MODULE_RESOURCE_PATH=$MODULE_LAYER_PATH/$MODULE_PATH/$MODULE_SLOT/

################################################ Retrieve Dependencies  #############################################
echo -e "Running Maven to download dependencies defined in the pom.xml. These dependencies define the content of the module.\n"
mvn clean dependency:copy-dependencies -DexcludeTransitive

################################################ Copy Dependencies to module directory  #############################################
echo -e "\nBuilding the layer and module.\n"
#first create the modules directory.
mkdir -p $MODULE_RESOURCE_PATH
echo -e "Copying resources to the new module.\n"
cp ./target/dependency/* $MODULE_RESOURCE_PATH

################################################ Create the module.xml file.  #############################################
echo -e "Creating the module.xml definition file.\n"

cp $MODULE_TEMPLATE_XML $MODULE_XML 

RESOURCES_XML="./resources.xml"

#Create resources.xml which will hold the file-names of the resource files we need to add to "module.xml"
echo "<?xml version=\"1.0\"?>" > $RESOURCES_XML
echo "<resources xmlns=\"urn:jboss:ddoyle:resources:1.0\">" >> $RESOURCES_XML

# The 'basename' command is used to strip the pathname from the result of 'ls', so only the filename is shown.
for f in `ls $MODULE_RESOURCE_PATH/*.jar | xargs -n1 basename | sort`
do
	echo "    <resource>$f</resource>" >> $RESOURCES_XML
done

echo "</resources>" >> $RESOURCES_XML

xsltproc -o $MODULE_XML jboss-module.xslt $MODULE_XML
xmllint --format -o $MODULE_XML $MODULE_XML

rm $RESOURCES_XML

mv $MODULE_XML $MODULE_RESOURCE_PATH

################################################ Copy the layer to the JBoss EAP modules directory  #############################################
cp -r $MODULE_LAYER_PATH $JBOSS_INSTALLATION_DIR/modules/system/layers/$MODULE_LAYER 

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
