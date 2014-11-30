#
# Builds a JBoss EAP module and packages it as a ZIP file.
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
      echo "    -f              Maven POM file that defines the resources of the module."
      echo "    -p              The modules path."
      echo "    -n              Name of the module."
      echo "    -s              Slot of the module."
      echo "    -d              Comma delimeted string of module dependencies."
      echo "    -o              Name of the output ZIP file in which to store the module."
      echo "    -h              Display help information."
}

#Parse the params
while getopts ":f:p:n:s:d:o:h" opt; do
  case $opt in
    f)
      POM_FILE=$OPTARG
      ;;
    p)
      MODULE_PATH=$OPTARG
      ;;
    n)
      MODULE_NAME=$OPTARG
      ;;
    s)
      MODULE_SLOT=$OPTARG
      ;;
    d)
      MODULE_DEPENDENCIES=$OPTARG
      ;;
    o)
      OUTPUT_FILE=$OPTARG
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
if [ -z "$POM_FILE" ]
then
        echo "No Maven POM file specified!"
        PARAMS_NOT_OK=true
fi

if [ -z "$MODULE_PATH" ]
then
        echo "No module path specified!"
        PARAMS_NOT_OK=true
fi

if [ -z "$MODULE_NAME" ]
then
        echo "No module name specified!"
        PARAMS_NOT_OK=true
fi

if [ -z "$MODULE_SLOT" ]
then
        MODULE_SLOT=main
fi

#if [ -z "$MODULE_DEPENDENCIES" ]
#then
	# Do nothing. Module doesn't have any dependencies.
#fi

if [ -z "$OUTPUT_FILE" ]
then
	OUTPUT_FILE="module.zip"
fi

if $PARAMS_NOT_OK
then
        usage
        exit 1
fi


################################################ Setup params.  #############################################

MODULE_XML=module.xml
MODULE_TEMPLATE_XML=module.xml.template
MODULE_BUILD_PATH=./target/module
MODULE_RESOURCE_PATH=$MODULE_BUILD_PATH/$MODULE_PATH/$MODULE_SLOT/

################################################ Retrieve Dependencies  #############################################
echo -e "Running Maven to download dependencies defined in the pom.xml. These dependencies define the content of the module.\n"
PWD=$(pwd -P)
mvn -f $POM_FILE clean dependency:copy-dependencies -DexcludeTransitive -DoutputDirectory="$PWD/target/dependency"

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

DEPENDENCIES_XML="./dependencies.xml"

#Create dependencies.xml which will hold the dependency-names we need to add to "module.xml"
echo "<?xml version=\"1.0\"?>" > $DEPENDENCIES_XML
echo "<dependencies xmlns=\"urn:jboss:ddoyle:dependencies:1.0\">" >> $DEPENDENCIES_XML

# The 'basename' command is used to strip the pathname from the result of 'ls', so only the filename is shown.
DEPENDENCIES_ARRAY=$(echo $MODULE_DEPENDENCIES | tr "," "\n")

for x in $DEPENDENCIES_ARRAY
do
	echo "    <module name=\"$x\"/>" >> $DEPENDENCIES_XML
done

echo "</dependencies>" >> $DEPENDENCIES_XML


xsltproc --stringparam moduleName $MODULE_NAME -o $MODULE_XML jboss-module.xslt $MODULE_XML
xmllint --format -o $MODULE_XML $MODULE_XML

rm $RESOURCES_XML
rm $DEPENDENCIES_XML

mv $MODULE_XML $MODULE_RESOURCE_PATH

################################################ Copy the layer to the JBoss EAP modules directory  #############################################
ZIP_TEMP="module-temp.zip"
cd $MODULE_BUILD_PATH ; zip -r $ZIP_TEMP * ; cd ../../
cp $MODULE_BUILD_PATH/$ZIP_TEMP $OUTPUT_FILE
 
################################################ Add module to layers.conf  #############################################

echo -e "\nModule build complete.\n"
