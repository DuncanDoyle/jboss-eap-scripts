JBoss EAP Scripts
======================
This repository contains a number of scripts to install, configure and customize a JBoss EAP 6 installation.
The focus is on JBoss EAP 6 standalone-mode, but the scripts should work with domain-mode installations as well (if they don't please let me know).

I mainly use these scripts in my Dockerfile build scripts to build JBoss EAP-based Docker containers (e.g. JBoss EAP, JBoss BPMSuite, JBoss Fuse Service Works, etc.).

setup-jboss-eap-profile.sh
-----------------------
This script creates a *target* JBoss EAP profile from a given *source* profile and applies a set of JBoss CLI scripts to the profile.
Because it does not directly alter the *source* profile, the script is idempotent and can be run multiple times. This eases the development and testing of your CLI scripts.

The scripts accepts 4 parameters:
- -j: The installation directory of JBoss EAP 6, e.g. */opt/jboss/jboss-eap-6.3/*
- -s: The source profile, e.g. *standalone-full-ha.xml*
- -t: The target profile, e.g. *standalone-full-ha-mycoolplatform.xml*
- -c: The directory that contains your CLI scripts.

The script copies the *source* profile to the *target* profile. Next, it starts-up the JBoss EAP 6 platform in *admin-only* mode. It applies the CLI scripts it finds in the given
directory in a the order defined by *sort* (a good tip is to prefix your scripts with 01,02,03,..,10,11,..,20,etc., to define the order in which the scripts need to be applied.

patch-jboss-eap.sh
-----------------------
As the name of the script suggests, this one patches a JBoss EAP 6 installation.
The implementation is somewhat the same as the *setup-jboss-eap-profile.sh* script in the sense that it starts up a given JBoss EAP instance in *admin-only* mode and uses the 
JBoss CLI to apply the patch.

The script accepts 2 parameters:
- -j: The installation directory of JBoss EAP 6, e.g. */opt/jboss/jboss-eap-6.3/*
- -p: The patch file that should be applied.

install-spring-module/install-spring-module.sh
-----------------------------------------------
Script that installs a Spring module (in a separare *spring* layer) into a JBoss EAP 6 installation.
Note that the script isn't very flexible atm. It uses the 'pom.xml' in the root directory to determine the module resources, which it downloads via Maven.
Also, the name of the layer and module is not configurable and it uses a default *module.xml.template* file as the template for the actual *module.xml*.
Third, if you want to use this script when creating a Docker container, the Docker container requires a Maven installation and Internet access (or at least access to a Maven repository).

The idea is to split this script into 2 scripts, one that creates the module and packages it in *module-{modulename}.zip*, and one that actually installs the module onto JBoss EAP 6.

This script accepts 4 parameters:
- -j: The installation directory of JBoss EAP 6, e.g. */opt/jboss/jboss-eap-6.3/*
- -l: The name of the layer in which the module should be installed.
- -e: The *enabled* boolean which defines whether the (new) layer should be enabled or not in the platforms *layers.conf* configuration file.

createJGroupsKeystore.sh
------------------------
Simple *keytool* command that creates a keystore for the JGroups ENCRYPT protocol (see the 09\_configureJGroups.cli script).

cli-scripts
-----------------------
Directory that contains a number of common CLI scripts that I've been using.




