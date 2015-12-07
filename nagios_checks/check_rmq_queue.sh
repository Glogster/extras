#!/bin/bash

while [[ $# -gt 1 ]]; do
	key="$1"
	case "$key" in
		-p|--vhost)
			VHOST="$2"
			shift
			;;
		-q|--queues)
			Q_TYPE="$2"
			shift
			;;
		-w|--warning)
			WARN_COUNT="$2"
			shift
			;;
		-c|--critical)
			CRIT_COUNT="$2"
			shift
			;;
		*)
			echo "WRONG OPTION"
			exit 3
		;;
	esac
	shift
done

RAW_DATA=$(sudo /usr/sbin/rabbitmqctl -p "$VHOST" list_queues | grep -v "\.\.\." | grep -v pidbox)

ALLQUEUES=$(echo "$RAW_DATA" | grep ^"$Q_TYPE" | awk '{print $NF}' | xargs | sed 's/ /+/g' | bc)
PERFDATA=$(echo "$RAW_DATA" | grep ^"$Q_TYPE" | sort -rn -k 2,2  | sed 's/\t/=/' | sed 's/$/, /g' |xargs | sed 's/,$//')


if [ "$ALLQUEUES" -gt "$CRIT_COUNT" ] ; then
	echo "CRITICAL Queue_usage - $ALLQUEUES | $PERFDATA"
	exit 2
elif [ "$ALLQUEUES" -gt "$WARN_COUNT" ] ; then
	echo "WARNING Queue_usage - $ALLQUEUES | $PERFDATA"
	exit 1
elif [ "$ALLQUEUES" -le "$WARN_COUNT" ] ; then
	echo "OK Queue_usage - $ALLQUEUES | $PERFDATA"
        exit 0
else
	echo "UNKNOWN STATE"
	exit 3
fi

