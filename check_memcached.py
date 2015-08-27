#!/bin/env python
import sys
import memcache
from optparse import OptionParser


parser = OptionParser()
parser.add_option("-H", "--hostname", dest="hostname",
                  help="Host Address", metavar=" <hostaddr>")
parser.add_option("-p", "--port", dest="port",
                  help="Port number", metavar=" <port_number>", default=11211)
parser.add_option("-n", "--variable", dest="variable",
                  help="Stats variable to check", metavar=" <variable>")
parser.add_option("-w", "--warning", dest="warning",
                  help="Warning value", metavar=" <warning>")
parser.add_option("-c", "--critical", dest="critical",
                  help="Critical value", metavar=" <critical>")
(opts, args) = parser.parse_args()


try:
    mc = memcache.Client(['%s:%s' % (opts.hostname, opts.port)], debug=0)
    stats = mc.get_stats()[0][1]

    stats['capacity'] = float(stats['bytes']) * 100. / float(stats['limit_maxbytes'])
    stats['items'] = stats['curr_items']
    stats['connections'] = stats['curr_connections']
    stats['set_get'] = float(stats['cmd_set']) / float(stats['cmd_get'])
    stats['misses_hits'] = float(stats['get_misses']) / float(stats['get_hits'])
    stats['evictions'] = stats['evictions']
    stats['written_read'] = float(stats['bytes_written']) / float(stats['bytes_read'])
    stats['written'] = stats['bytes_written']
    stats['read'] = stats['bytes_read']

    line = "capacity={:.2f} items={} connections={} set_get={:.2f} " \
        "misses_hits={:.2f} evictions={} written_read={:.2f} " \
        "written={} read={}".format(
        stats['capacity'], stats['items'], stats['connections'], stats['set_get'],
        stats['misses_hits'], stats['evictions'], stats['written_read'],
        stats['written'], stats['read']
    )

    variable = float(stats[opts.variable])

    if variable >= opts.critical:
        print("CRITICAL - {.2f} | {}".format(variable, line))
        sys.exit(2)
    if variable >= opts.warning:
        print("WARNING - {.2f} | {}".format(variable, line))
        sys.exit(1)

    print("OK - {:.2f} | {}".format(variable, line))
    sys.exit(0)

except Exception as e:
    print("CRITICAL - {} {}".format(type(e).__name__, e))
    sys.exit(2)
