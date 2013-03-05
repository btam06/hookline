#!/bin/bash

print_help () {
	echo
	echo "Usage:"
	echo
	if [ -z "$1" ]; then
		echo "hookline [command] <arg1> ..."
		echo
		echo "Commands:"
		echo
		echo "    help  "
		echo "    add   "
		echo "    del   "
		echo "    stat  "
		echo "    start "
		echo "    stop  "
		echo

	elif [ "$1" == "help" ]; then
		if [ -z "$2" ]; then
			echo "    hookline help <command>"
			echo
			echo "    Get help on a specific command"
			echo

		elif [ "$2" == "add" ]; then
			echo "    hookline add <alias> <source> <target>"
			echo
			echo "    Adds a new syncer by alias"
			echo

		elif [ "$2" == "del" ]; then
			echo "    hookline del <alias>"
			echo
			echo "    Removes a syncer by alias"
			echo

		elif [ "$2" == "stat" ]; then
			echo "    hookline stat"
			echo
			echo "    Get the status of all syncers"
			echo

		elif [ "$2" == "start" ]; then
			echo "    hookline start <alias>"
			echo
			echo "    Starts a syncer by alias"
			echo

		elif [ "$2" == "stop" ]; then
			echo "    hookline stop <alias>"
			echo
			echo "    Stops a syncer by alias"
			echo

		fi
	fi
}

hl_dir="$HOME/.hookline"

if [ ! -d "$hl_dir" ]; then
	mkdir "$hl_dir"
fi

if [ "$#" == 0 ]; then
	print_help
	exit -1

elif [ "$1" == "help" ]; then
	print_help $1 $2

elif [ "$1" == "add" ]; then
	if [ ! "$#" == 4 ]; then
		print_help help $1
		exit -1
	fi

	echo "$3" > "$hl_dir/$2.src"
	echo "$4" > "$hl_dir/$2.dst"
	echo "0"  > "$hl_dir/$2.pid"

elif [ "$1" == "del" ]; then
	if [ ! "$#" == 2 ]; then
		print_help help $1
		exit -1
	fi

	$0 stop $2

	rm "$hl_dir/$2.src"
	rm "$hl_dir/$2.dst"
	rm "$hl_dir/$2.pid"

elif [ "$1" == "stat" ]; then
	for i in `ls -1 "$hl_dir/"*.pid 2>/dev/null`; do
		stat="off"

		aid=`basename "$i" | sed 's/.pid$//'`
		pid=`cat "$hl_dir/$aid.pid"`

		if [ ! "$pid" == "0" ]; then
			cmd=`ps -l $pid | awk '{ print $14 }' | tail -1`

			if [ -z "$cmd" ]; then
				stat="off"

			elif [ "$cmd" == "lsyncd" ]; then
				stat="on"

			else
				echo "0" > "$hl_dir/$aid.pid"
			fi
		fi

		echo -e "[$stat]\t\t$aid"
	done

elif [ "$1" == "start" ]; then
	if [ ! "$#" == 2 ]; then
		print_help help $1
		exit -1
	fi

	src=`cat "$hl_dir/$2.src"`
	dst=`cat "$hl_dir/$2.dst"`

	lsyncd -pidfile "$hl_dir/$2.pid" -rsync "$src" "$dst"

elif [ "$1" == "stop" ]; then
	if [ ! "$#" == 2 ]; then
		print_help help $1
		exit -1
	fi

	pid=`cat "$hl_dir/$2.pid"`

	if [ ! "$pid" == "0" ]; then
		cmd=`ps -l $pid | awk '{ print $14 }' | tail -1`

		if [ "$cmd" == "lsyncd" ]; then
			kill $pid
		fi
	fi

	echo "0" > "$hl_dir/$2.pid"

elif [ "$1" == "install" ]; then
	sudo cp $0 /usr/bin/hookline
	sudo chmod 755 /usr/bin/hookline

fi

