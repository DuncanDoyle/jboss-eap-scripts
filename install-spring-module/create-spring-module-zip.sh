#
# Creates a Spring module zip.
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
      echo "    -d              Output module zip file."
}

#Parse the params
while getopts ":d:h" opt; do
  case $opt in
    d)
      OUTPUT_MODULE_ZIP_FILE=$OPTARG
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
if [ -z "$OUTPUT_MODULE_ZIP_FILE" ]
then
        echo "No output zip file specified!"
        PARAMS_NOT_OK=true
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

MODULE_TARGET_PATH=./target/module
MODULE_RESOURCE_PATH=$MODULE_TARGET_PATH/$MODULE_PATH/$MODULE_SLOT/

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

################################################ Create the modules zip file.  #############################################
pushd $MODULE_TARGET_PATH
zip -r $OUTPUT_MODULE_ZIP_FILE *
popd

