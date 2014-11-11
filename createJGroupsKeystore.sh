#!/bin/sh
keytool -genseckey -alias jgroupsKey -keypass jgroups_pass@01 -storepass jgroups_pass@01 -keyalg Blowfish -keysize 56 -keystore jgroups.keystore -storetype JCEKS
