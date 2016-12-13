FROM debian

RUN apt-get update \
 && apt-get --no-install-recommends -y install \
    ganglia-monitor \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists 

#   -c, --conf=STRING      Location of gmond configuration file  
#                          (default=`/etc/ganglia/gmond.conf')
#  -f, --foreground       Run in foreground (don't daemonize)  (default=off)
CMD ["/usr/sbin/gmond", "-c", "/etc/ganglia/gmond.conf", "-f"]
