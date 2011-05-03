#!/usr/bin/bash
#I expect to be called from harvest root
#you might need to d2u this file if it complains about \r missing

#echo "getting oai record"
#bin/harvest.pl conf/mimo-GetRecord-61117.mpx.yml
#bin/harvest.pl conf/mimo-GetRecord-61880.mpx.yml
#alternatively use Salsa_OAI/bin/extract.pl
#../Salsa_OAI2/bin/extract.pl 61117 mpx > xml-oai/extract61117.xml
#../Salsa_OAI2/bin/extract.pl 61880 mpx > xml-oai/extract61880.xml

#echo "unwrapping mpx inside oai record"
#bin/unwrap.pl xml-oai/GetRecord61117.xml xml-unwrapped/GetRecord61117.mpx
#bin/unwrap.pl xml-oai/GetRecord61880.xml xml-unwrapped/GetRecord61880.mpx

#echo "validate"
#bin/validate.pl xml-unwrapped/GetRecord61117.mpx mpx
#bin/validate.pl xml-unwrapped/GetRecord61880.mpx mpx

#
# I transform locally here. Alternatively validate online via data provider
#

#unwrapping now done as part of unwrap.pl
#echo "transform to lido"
#xsltproc ../Salsa_OAI2/xslt/mpx2lido/mpx2lido.xsl xml-unwrapped/GetRecord61117.mpx > xml-unwrapped/GetRecord61117.lido.xml
#xsltproc ../Salsa_OAI2/xslt/mpx2lido/mpx2lido.xsl xml-unwrapped/GetRecord61880.mpx > xml-unwrapped/GetRecord61880.lido.xml

echo "validate"
bin/validate.pl xml-unwrapped/GetRecord61117.lido.xml lido
bin/validate.pl xml-unwrapped/GetRecord61880.lido.xml lido

echo "fine testing transformation"
prove t/61117.lido.t
#bin/tron.pl xml-unwrapped/GetRecord61880.lido.xml tron/61880.lido.xml

